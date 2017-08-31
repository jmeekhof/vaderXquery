xquery version "1.0-ml";

module namespace vader = "http://vaderSentiment/vader";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";


(:Increase decrease based upon booster words:)
declare variable $vader:B_INCR as xs:double := 0.293;
declare variable $vader:B_DECR as xs:double := -0.293;
(:Intensity increase do to CAPITALIZED words:)
declare variable $vader:C_INCR as xs:double := 0.733;
declare variable $vader:N_SCALAR as xs:double := -0.74;

declare variable $vader:PUNC_LIST as xs:string+ := (".", "!", "?", ",", ";", ":", "-", "'", '"', "!!", "!!!", "??", "???", "?!?", "!?!", "?!?!", "!?!?");
declare variable $vader:NEGATE as xs:string+ :=  ("aint", "arent", "cannot", "cant", "couldnt", "darent", "didnt", "doesnt", "ain't", "aren't", "can't", "couldn't", "daren't", "didn't", "doesn't", "dont", "hadnt", "hasnt", "havent", "isnt", "mightnt", "mustnt", "neither", "don't", "hadn't", "hasn't", "haven't", "isn't", "mightn't", "mustn't", "neednt", "needn't", "never", "none", "nope", "nor", "not", "nothing", "nowhere", "oughtnt", "shant", "shouldnt", "uhuh", "wasnt", "werent", "oughtn't", "shan't", "shouldn't", "uh-uh", "wasn't", "weren't", "without", "wont", "wouldnt", "won't", "wouldn't", "rarely", "seldom", "despite");

declare variable $vader:PUNC as xs:string+ := '!"#$%&#38;()*+,-./:;<=>?@[\\]^_`{|}~' || "'";

declare variable $vader:BOOSTER_DICT as map:map := map:new( (
  map:entry("absolutely", $vader:B_INCR),
  map:entry("amazingly", $vader:B_INCR),
  map:entry("awfully", $vader:B_INCR),
  map:entry("completely", $vader:B_INCR),
  map:entry("considerably", $vader:B_INCR),
  map:entry("decidedly", $vader:B_INCR),
  map:entry("deeply", $vader:B_INCR),
  map:entry("effing", $vader:B_INCR),
  map:entry("enormously", $vader:B_INCR),
  map:entry("entirely", $vader:B_INCR),
  map:entry("especially", $vader:B_INCR),
  map:entry("exceptionally", $vader:B_INCR),
  map:entry("extremely", $vader:B_INCR),
  map:entry("fabulously", $vader:B_INCR),
  map:entry("flipping", $vader:B_INCR),
  map:entry("flippin", $vader:B_INCR),
  map:entry("fricking", $vader:B_INCR),
  map:entry("frickin", $vader:B_INCR),
  map:entry("frigging", $vader:B_INCR),
  map:entry("friggin", $vader:B_INCR),
  map:entry("fully", $vader:B_INCR),
  map:entry("fucking", $vader:B_INCR),
  map:entry("greatly", $vader:B_INCR),
  map:entry("hella", $vader:B_INCR),
  map:entry("highly", $vader:B_INCR),
  map:entry("hugely", $vader:B_INCR),
  map:entry("incredibly", $vader:B_INCR),
  map:entry("intensely", $vader:B_INCR),
  map:entry("majorly", $vader:B_INCR),
  map:entry("more", $vader:B_INCR),
  map:entry("most", $vader:B_INCR),
  map:entry("particularly", $vader:B_INCR),
  map:entry("purely", $vader:B_INCR),
  map:entry("quite", $vader:B_INCR),
  map:entry("really", $vader:B_INCR),
  map:entry("remarkably", $vader:B_INCR),
  map:entry("so", $vader:B_INCR),
  map:entry("substantially", $vader:B_INCR),
  map:entry("thoroughly", $vader:B_INCR),
  map:entry("totally", $vader:B_INCR),
  map:entry("tremendously", $vader:B_INCR),
  map:entry("uber", $vader:B_INCR),
  map:entry("unbelievably", $vader:B_INCR),
  map:entry("unusually", $vader:B_INCR),
  map:entry("utterly", $vader:B_INCR),
  map:entry("very", $vader:B_INCR),
  map:entry("almost", $vader:B_DECR),
  map:entry("barely", $vader:B_DECR),
  map:entry("hardly", $vader:B_DECR),
  map:entry("just enough", $vader:B_DECR),
  map:entry("kind of", $vader:B_DECR),
  map:entry("kinda", $vader:B_DECR),
  map:entry("kindof", $vader:B_DECR),
  map:entry("kind-of", $vader:B_DECR),
  map:entry("less", $vader:B_DECR),
  map:entry("little", $vader:B_DECR),
  map:entry("marginally", $vader:B_DECR),
  map:entry("occasionally", $vader:B_DECR),
  map:entry("partly", $vader:B_DECR),
  map:entry("scarcely", $vader:B_DECR),
  map:entry("slightly", $vader:B_DECR),
  map:entry("somewhat", $vader:B_DECR),
  map:entry("sort of", $vader:B_DECR),
  map:entry("sorta", $vader:B_DECR),
  map:entry("sortof", $vader:B_DECR),
  map:entry("sort-of", $vader:B_DECR)
) );

declare variable $vader:SPECIAL_CASE_IDIOMS as map:map := map:new ((
  map:entry("the shit", 3),
  map:entry("the bomb", 3),
  map:entry("bad ass", 1.5),
  map:entry("yeah right", -2),
  map:entry("cut the mustard", 2),
  map:entry("kiss of death", -1.5),
  map:entry("hand to mouth", -2)
) );

declare option xdmp:mapping "false";

declare function vader:negated ( $input-words as xs:string+ )  {
  vader:negated($input-words, fn:true())
};

declare function vader:negated ( $input-words as xs:string+, $include-nt as xs:boolean) {
(:~
 : Determine if input words contain negation words
 :)

  let $negated as xs:boolean := $input-words = $vader:NEGATE
  return
  if ( $negated ) then
    fn:true()
  else
    if ( $include-nt ) then
      some $word in ($input-words ! fn:matches(.,"n't") ) satisfies ($word = fn:true())

    else
      if ( "least" = $input-words ) then
        let $i := fn:index-of($input-words, "least")
        let $x :=
          $i !
          (
          if ( . > 1 and fn:not($input-words[(.)-1] = "at") ) then
            fn:true()
          else
            fn:false()
          )
        return $x
      else
        fn:false()
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
    if (map:contains($vader:BOOSTER_DICT, $word_lower) ) then
      let $s := map:get($vader:BOOSTER_DICT, $word_lower)
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
        $scalar + $vader:C_INCR
      else
        $scalar - $vader:C_INCR
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
      vader:product($vader:PUNC_LIST, $words_only, $combinator) !
      $entry(., 2, fn:string-join(?)),
      vader:product($words_only, $vader:PUNC_LIST, $combinator) !
      $entry(., 1, fn:string-join(?))
    ))

};

declare function _words_and_emoticons($text as xs:string) as xs:string* {
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
  return fn:map($g(?), $wes)
};

declare function vader:remove-punctuation( $text as xs:string) as xs:string {
  (:~
   : Removes standard punctuation from a string of text.
   :)
  let $f := function($x) {
    fn:not($x = functx:chars($vader:PUNC))
  }

  return
    fn:string-join(
      fn:filter($f(?), functx:chars($text))
    )
};

declare function vader:remove-singeltons( $text as xs:string) as xs:string* {
  (:~
   : Removes singletons from a string
   :
   : Returns a sequence of strings with singletons removed
   :)
  let $f := function ($x) {
    fn:string-length($x) gt 1
  }

  return fn:filter($f(?), fn:tokenize($text, ' '))
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

declare function polarity_scores($text as xs:string)  {
  (:~
   : Return a float for sentiment strength based on the input text.
   : Positive values are positive valence, negative value are negative valence.
   :
   : TODO: Come back after sentiment_valence
   :)
   let $words_and_emoticons := vader:_words_and_emoticons($text)

   let $sentiments := fn:map(
    function ($x) {
      ()
    },
    $words_and_emoticons)

  return ()

};

declare function vader:create-word-structure($text as xs:string*) {
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

(:
declare function sentiment_valence($valence, $text, $item, $i, $sentiments) {
  let $is_cap_diff := vader:allcap_differential($text)
  let $words_and_emoticons := vader:_words_and_emoticons($text)
  (:
  let $item_lowercase := fn:map(fn:lower-case(?), $words_and_emoticons)
  :)
  fn:map(
    function($word) {
      (:determine where $word is in text:)
      ()

    },
    $text
  )

  return ()

};
:)

declare function vader:get-valence-measure($word as xs:string)  {
  (:~
   : Retrieves the valence measure from the vader-lexicon
   :)
  fn:collection('vader-lexicon')/vader:lexicon/
  vader:lex[vader:word =$word]/vader:measure/data() !
  xs:float(.)
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
          $vader:C_INCR
        else
          $vader:C_INCR * -1
      )
    else
      $valence


};
