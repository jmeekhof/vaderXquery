xquery version "1.0-ml";

module namespace vader = "http://vaderSentiment/vader";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace func = "http://snelson.org.uk/functions/functional" at "functionalxq/functional.xq";
import module namespace vc = "http://vaderSentiment/vader/constants" at "vader-constants.xqy";

declare option xdmp:mapping "false";

declare function vader:negated ( $input-words as xs:string* )  {
  vader:negated($input-words, fn:true())
};

declare function vader:negated ( $input-words as xs:string*,
  $include-nt as xs:boolean) {
  (:~
   : Determine if input words contain negation words
   :)
  let $test :=

    if ($include-nt) then
      function($words) {
        (
          some $w in
          ($words !  map:contains($vc:NEGATE_DICT, .) )
          satisfies ($w = fn:true())
        )
        or
        (
          some $wd in
          ($words ! fn:matches(., "n't") )
          satisfies ($wd = fn:true())
        )
      }
    else
      function($words) {
        map:contains($vc:NEGATE_DICT, $words)
      }

  return
  if ( $test($input-words) ) then
    fn:true()
  else
    if ( "least" = $input-words ) then
      let $_ := xdmp:log(">>>>input-words: " || fn:string-join($input-words, " "), "debug")
      let $ws := vader:create-word-structure($input-words)
      let $i := fn:index-of($ws/word, "least")
      let $_ := xdmp:log(">>>>> found 'least' " || fn:count($i) || " times", "debug")

      let $foo := fn:map(function($idx){
        let $prior-word := $ws/word[$idx]/preceding-sibling::*[1]
        let $_:= xdmp:log(">>> prior word is:" || $prior-word, "debug")
        return
          fn:lower-case($prior-word) ne "at"
      }, $i)
      let $_ :=
        $foo !
          xdmp:log(">>>>foo: " || ., "debug")

      return some $x in $foo satisfies ($x = fn:true())
    else
      fn:false()

(:
      let $_ := xdmp:log(">>> pw: " || $prior-words[1])

      let $_ := ( $i ! xdmp:log(">>>>>>index of 'least': " || . ) )
      let $x :=
        $i !
        (
        xdmp:log(">>>>> current node is: " || .),
        if ( . > 1 and fn:not($input-words[. - 1] = "at") ) then
          fn:true()
        else
          fn:false()
        )
      return $x
    else
      fn:false()
:)
};

declare function normalize ($score as xs:double) as xs:double {
  vader:normalize($score, xs:double(15))
};

declare function normalize ($score as xs:double, $alpha as xs:double) {
  (:~
   : Normalizes the score to be between -1 and 1 using an alpha that
   : approximates the max expected value
   :)
  let $norm-score := $score div math:sqrt($score*$score + $alpha)

  return

    if ( $norm-score < -1.0 ) then
      -1.0
    else
      if ( $norm-score > 1.0 ) then
        1.0
      else
        $norm-score
};

declare function allcap_differential($words as xs:string+) as xs:boolean {
  (:~
   :  Check whether just some words in the input are ALL CAPS
   :  param list words: The words to inspect
   :  returns: `True` if some but not all items in `words` are ALL CAPS
   :)
  let $is-different := fn:false()
  let $all-cap-words := fn:count( fn:filter(function($a) {$a = fn:upper-case($a)}, $words))
  let $cap-differential := fn:count($words) - $all-cap-words

  return
    if ($cap-differential gt 0 and $cap-differential lt fn:count($words) ) then
      fn:true()
    else
      fn:false()
};

declare function vader:scalar_inc_dec( $word as xs:string, $valence as xs:double, $is_cap_diff as xs:boolean) as xs:double {
  (:~
   : Check if the preceding words increase, decrease, or negate/nullify the
   : valence
   :)
  let $word_lower := fn:lower-case($word)

  let $scalar :=
    if (map:contains($vc:BOOSTER_DICT, $word_lower) ) then
      let $s := map:get($vc:BOOSTER_DICT, $word_lower)
      return
        if ( $valence lt 0 ) then
          $s * (-1)
        else
          $s
    else
      0.0
  (:check if booster/dampener word is in ALLCAPS (while others aren't) :)
  return
    if ( fn:upper-case($word) = $word and $is_cap_diff) then
      if ( $valence gt 0 ) then
        $scalar + $vc:C_INCR
      else
        $scalar - $vc:C_INCR
    else
      $scalar
};

declare function vader:_words_plus_punc($text as xs:string) as map:map {
  let $no_punc_text := vader:remove-punctuation($text)
  let $words_only := vader:remove-singeltons($no_punc_text)

  let $combinator := function ( $a, $b ) {
    element seq {
      element itm { $a },
      element itm { $b }
    }
  }

  let $entry := function ($m as element(), $i as xs:integer, $key as function(*) ) {
    map:entry($key($m/itm), $m/itm[$i])
  }

  return
    map:new((
      vader:product(map:keys($vc:PUNC_DICT), $words_only, $combinator) !
      $entry(., 2, fn:string-join(?)),
      vader:product($words_only, map:keys($vc:PUNC_DICT), $combinator) !
      $entry(., 1, fn:string-join(?))
    ))

};

declare function _words_and_emoticons($text as xs:string) as element(wrapper) {
  (:~
   : Removes leading and trailing punctuation.
   : Leaves contractions and most emoticons
   :)
  let $wes := vader:remove-singeltons($text)

  let $f := function($map, $word) {
    if ( map:contains($map, $word) ) then
      map:get($map, $word)
    else
      $word
  }

  let $g := $f(vader:_words_plus_punc($text), ?)

  return vader:create-word-structure(fn:map($g(?), $wes))
};

declare function vader:remove-punctuation( $text as xs:string) as xs:string {
  (:~
   : Removes standard punctuation from a string of text.
   : @author Josh Meekhof
   : @version 1.1
   : @param $text as xs:string The text that needs punctuation removed
   : @return xs:string All the punctuation will be removed
   :)
  let $f :=
  fn:map(function($x){
    typeswitch ($x)
    case $x as cts:word return $x
    default return ()
  },
  cts:tokenize($text))

  return fn:string-join($f, ' ')
};

declare function vader:remove-singeltons( $text as xs:string) as xs:string* {
  (:~
   : Removes singletons from a string
   :
   : Returns a sequence of strings with singletons removed
   :)
  let $filter-func := function ($x) {
    fn:string-length($x) gt 1
  }

  return fn:filter($filter-func, fn:tokenize($text, ' '))
};

declare function vader:product(
  $a as item()*,
  $b as item()*,
  $f as function(item()*, item()*) as item()*
  ) as item()* {
  (:~
   : creates a cartesion product of $a and $b combined with the function $f
   :)
  fn:map(
    function($x){
      fn:map(
        function($y){
          $f($x,$y)
        },
        $b
      )
    },
    $a
  )
};

declare function polarity_scores($text as xs:string) {
  (:~
   : Return a float for sentiment strength based on the input text.
   : Positive values are positive valence, negative value are negative valence.
   :
   :)
   let $wae := vader:_words_and_emoticons(xdmp:diacritic-less($text))

   let $sentiments as xs:double* :=
     fn:map(
       function ($item as xs:string?) {
        if (
          (
            fn:lower-case($item) = "kind" and fn:lower-case($item/following-sibling::*[1]) = "of"
          ) or map:contains($vc:BOOSTER_DICT, fn:lower-case($item))
        ) then
          0
        else
          vader:sentiment_valence($wae)
      },
      $wae)

  let $b_check := vader:_but_check($wae, $sentiments)

  return vader:score_valence($b_check, $text)

};

declare function vader:create-word-structure($text as xs:string*) as element(wrapper) {
  (:~
   : takes a sequence of strings, creates a xml structure of the words
   :)
  element wrapper {
    fn:map(
      function($x){
        element word { $x }
      },
      $text
    )
  }
};

declare function vader:determine-word-position(
  $word as xs:string,
  $words-xml as element(wrapper)) {
  (:~
   : Take the $word,  find it in wrapper, return it's position in the document
   : This won't work correctly if the same word occurs more than once in a
   : sentence.
   :)
  fn:count(
    $words-xml/word[ . = $word]/preceding-sibling::*
  ) + 1
};

declare function vader:cap-valence($valence as xs:double?, $word as xs:string, $is_cap_diff as xs:boolean) as xs:double {
  (:~
   : Determines valence score depending upon it's intitial valence score and
   : it's capitalization
   :)
  if ( fn:exists($valence) ) then
    if ( fn:upper-case($word) = $word and $is_cap_diff ) then
      if ( $valence gt 0 ) then
        $valence + $vc:C_INCR
      else if ( $valence lt 0 ) then (:may just leaving this as an else would work:)
        $valence - $vc:C_INCR
      else
        $valence
    else
      $valence
  else
    0.0
};

declare function vader:sentiment_valence($wae as element(wrapper) ) as xs:double* {
  (:~
   : Given a sequence of words, return a sequence of valence scores for each
   : word.
   :)

  let $is_cap_diff := vader:allcap_differential(fn:string-join($wae/word, " "))
  let $dwp := vader:determine-word-position(?, $wae)

  (:~
   : Take a first pass through all the words. Determine each words score based
   : only upon itself.
   :)
  let $v :=
    fn:map(
      function($word as element(word)) {
        let $valence := vader:get-valence-measure(fn:lower-case($word))
        (:let $prior-words := fn:reverse($wae/word[. =
         : $word]/preceding-sibling::*):)
        let $prior-words := $wae/word[. = $word]/preceding-sibling::*
        let $_ := xdmp:log($prior-words, "debug")
        let $check := func:compose(fn:not#1,fn:exists#1,vader:get-valence-measure#1)
        return
          let $x := vader:cap-valence($valence, $word, $is_cap_diff)
          let $score :=
            fn:fold-left(function ( $scores, $idx ) as xs:double {
              let $score :=
              $scores +
              (
                if (fn:exists($prior-words[$idx]) and $check($prior-words[$idx]/fn:string() )) then
                  (: $is is intermediate s value. It's a modifier to the valence
                   : for the word ($x)
                   :)
                  let $is := vader:scalar_inc_dec($prior-words[$idx], $x, $is_cap_diff)
                  return
                  if ( fn:not($is = 0) ) then
                    switch ( $idx )
                      case 2 return $is * 0.95
                      case 3 return $is * 0.90
                      default return $is
                  else
                    $is
                else
                  xs:double(0.0)
              )
              (: We've calculated our score, added our scalar modifiers. Do
               : some other checks with this value.
               :)
              return vader:_never_check($score, $wae, $idx, fn:count($prior-words) + 1 )
              (: Need to do the idioms check :)
            }, $x, (1 to 3))

          (: Score as has created, checked for negation and proximity to
           : booster words. One final chcek and return
           :)
         return vader:_least_check($score, $wae, fn:count($prior-words) + 1)
      },
      $wae/word)
  return $v
};

declare private function vader:valence-map() as map:map {
  (:~
   : Creates a map of the vader lexicon. Intended to be called by
   : get-valence-measure to populate server field
   :)
  map:new(
    fn:map(
      function($x) {
        map:entry($x/vader:word/fn:string(), $x/vader:score/xs:double(.))
    },
    fn:collection('vader-lexicon')/vader:lexicon/vader:lex
  )
)
};

declare function vader:get-valence-measure($word as xs:string) as xs:double?  {
  (:~
   : Retrieves the valence measure from the vader-lexicon
   :)

  let $valence-map :=
    if ("valence-map" = xdmp:get-server-field-names()) then
      xdmp:get-server-field("valence-map")
    else
      xdmp:set-server-field("valence-map", vader:valence-map())
  return map:get($valence-map, $word)
};

declare function vader:determine-valence-cap($word as xs:string, $is_cap_diff as xs:boolean) {
  (:~
   : Valence may be modified if it's capitalized. This function determines
   : that.
   :)
  let $valence := vader:get-valence-measure(fn:lower-case($word))

  return
    if ($valence gt 0) then
      $valence + (
        if ( $is_cap_diff and ( $word = fn:upper-case($word) ) ) then
          $vc:C_INCR
        else
          $vc:C_INCR * -1
      )
    else
      $valence
};

declare function vader:exists-in-lexicon($word as xs:string) as xs:boolean {
  let $f := func:compose(fn:exists#1,vader:get-valence-measure#1,fn:lower-case#1)
  return $f($word)
};

declare function vader:_least_check(
  $valence as xs:double,
  $wae as element(wrapper),
  $i as xs:integer) {
  (:~
   : Makes a negation check by looking for the word 'least'
   :)

  let $chk := func:compose(fn:not#1,vader:exists-in-lexicon#1)
  return
    if (
      $i gt 2 and
      $chk($wae/word[$i - 1]) and
      fn:lower-case($wae/word[$i - 1]) = "least"
    ) then

      if (fn:not(fn:lower-case($wae/word[$i - 2]) = ("at","very"))) then
        $valence * $vc:N_SCALAR
      else
        $valence
    else
      if (
        $i gt 1 and
        $chk($wae/word[$i - 1]) and
        fn:lower-case($wae/word[$i - 1]) = "least"
      ) then
        $valence * $vc:N_SCALAR
      else
        $valence
};

declare function vader:_but_check($wae as element(wrapper), $sentiments as xs:double*) {
  (:~
   : check for modification in sentiment due to contrastive conjunction 'but'
   :)

  let $bi := fn:index-of($wae/word/fn:string()!fn:lower-case(.),'but' )[1]
  return
    if ( fn:exists($bi) ) then
      (: look for the sentiments before and after the but :)
      let $ws := $wae
      (: all the preceding items get their sentiments lowered :)
      let $preceding-i := $ws/word[$bi]/preceding-sibling::*/fn:position()
      (:
      let $_ := xdmp:log(">>>preceding count: " || fn:count($preceding-i), "debug")
      let $_ := $preceding-i ! xdmp:log(">>>preceding idx: " || . , "debug")
      :)
      (: all the following items get their sentiments raised :)
      let $following-i := $ws/word[$bi]/following-sibling::*/fn:position()
      (:
      let $_ := xdmp:log(">>>following count: " || fn:count($following-i))
      let $_ := $following-i ! xdmp:log(">>>following idx: " || . , "debug")
      :)
      return (
        fn:map(function($pos) { $sentiments[$pos] * 0.5 }, $preceding-i),
        $sentiments[$bi],
        fn:map(function($pos) { $sentiments[$bi + $pos] * 1.5}, $following-i)
      )
    else
      $sentiments
};

declare function vader:_idioms_check($valence as xs:double, $wae as element(wrapper), $i as xs:integer) {
  (:~
   : Need to implement
   :)
  $valence
};

declare function vader:_never_check(
  $valence as xs:double, $wae as element(wrapper),
  $start_i as xs:integer, $i as xs:integer) {
  let $n := "never"
  let $st := ("so","this")
  return
  switch ($start_i)
    case 1 return
      if (vader:negated($wae/word[$i - 1]) ) then
        $valence * $vc:N_SCALAR
      else
        $valence

    case 2 return
      if ( $wae/word[$i - 2] = $n and $wae/word[$i - 1] = $st) then
        $valence * 1.5
      else
        (: this needs some work. This is using the pypthon list syntax where
         : negative numbers give you the last x items in the list
         :)
        if ( vader:negated($wae/word[$i - ($start_i + 1)]) ) then
          $valence * $vc:N_SCALAR
        else
          $valence

    case 3 return
      if (
        $wae/word[$i - 3] = $n and
        $wae/word[$i - 2] = $st or
        $wae/word[$i - 1] = $st
      ) then
        $valence * 1.25
      else
        (: this needs some work. This is using the pypthon list syntax where
         : negative numbers give you the last x items in the list
         :)
        if ( vader:negated($wae/word[$i - ($start_i + 1)] ) ) then
          $valence * $vc:N_SCALAR
        else
          $valence

    default return
      $valence
};

declare function vader:_amplify_ep($text as xs:string) as xs:double {
  (:~
   : count exclamation points, up to 4. Retrun a booster based upon that.
   :)
  let $ep := fn:index-of(?, "!")
  let $f := func:compose(fn:count#1,$ep,functx:chars#1)

  return fn:min(($f($text),4)) * 0.292
};

declare function vader:_amplify_qm($text as xs:string) as xs:double {
  let $qm := fn:index-of(?, "?")
  let $f := func:compose(fn:count#1,$qm,functx:chars#1)

  let $qm-count := $f($text)

  return
    if ( $qm-count > 1 ) then
      if ( $qm-count <= 3 ) then
        $qm-count * 0.18
      else
        0.96
    else
      0
};

declare function vader:_punctuation_emphasis($text as xs:string) as xs:double {
  vader:_amplify_ep($text) + vader:_amplify_qm($text)
};

declare function vader:_sift_sentiment_scores( $sentiments as xs:double* ) as map:map {
  map:new((
    map:entry(
      'pos',
      fn:fold-right(
        function( $score as xs:double, $scores as xs:double* ) {
          $scores + (
            if ( $score gt 0 ) then
              $score + 1
            else
              0
          )
        },
        0.0,
        $sentiments)
    ),
    map:entry(
      'neg',
      fn:fold-right(
        function($score as xs:double, $scores as xs:double*){
          $scores + (
            if ($score lt 0) then
              $score - 1
            else
              0
          )
        },
        0.0,
        $sentiments)
    ),
    map:entry(
      'neu',
      fn:fold-right(
        function($score as xs:double, $scores as xs:double*){
          $scores + (
            if ($score = 0) then
              1
            else
              0
          )
        },
        0,
        $sentiments)
    )

  ))

};

declare function vader:score_valence ( $sentiments as xs:double*, $text as xs:string) {
  (:~
   : Need to compute multiple scores and return as map:map
   :)


  let $f := function($map as map:map, $amp as xs:double) {
    let $p := map:get($map, 'pos')
    let $n := map:get($map, 'neg')

    return
      if ( $p gt math:fabs($n) ) then
        map:put($map, 'pos', ( $p + $amp))
      else if ( $p lt math:fabs($n) ) then
        map:put($map, 'neg', ( $p - $amp))
      else
        ()
  }

  let $sifted := vader:_sift_sentiment_scores($sentiments)
  let $punc_emph_amplipher := vader:_punctuation_emphasis($text)
  let $_ := $f($sifted, $punc_emph_amplipher)
  let $pos_sum := map:get($sifted, 'pos')
  let $neg_sum := map:get($sifted, 'neg')
  let $neu_count := map:get($sifted, 'neu')
  let $sum_s :=
    let $sum := fn:sum($sentiments)
    return
      if ( $sum gt 0 ) then
        $sum + $punc_emph_amplipher
      else if ( $sum lt 0 ) then
        $sum - $punc_emph_amplipher
      else
        $sum


  let $total := $pos_sum + math:fabs($neg_sum) + $neu_count

  let $pos :=
    if ( fn:exists($sentiments) ) then
      math:fabs($pos_sum div $total)
    else
      0.0
  let $neg :=
    if ( fn:exists($sentiments) ) then
      math:fabs($neg_sum div $total)
    else
      0.0
  let $neu :=
    if ( fn:exists($sentiments) ) then
      math:fabs($neu_count div $total)
    else
      0.0

  let $compound :=
    if ( fn:exists($sentiments) ) then
      vader:normalize($sum_s)
    else
      0.0

  let $r := fn:format-number(?,"#.###")
  return map:new((
    map:entry("neg", $r($neg)),
    map:entry("pos", $r($pos)),
    map:entry("neu", $r($neu)),
    map:entry("compound", fn:format-number($compound, "#.####"))
  ))
};
