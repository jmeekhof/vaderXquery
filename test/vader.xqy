xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";
import module namespace vader = "http://vaderSentiment/vader" at "../vader.xqy";
import module namespace func = "http://snelson.org.uk/functions/functional" at "../functionalxq/functional.xq";

declare option xdmp:mapping "false";

declare %test:case function  negated-test ()
{

  let $string1 := "I do not like this"
  let $string2 := "I didn't like this, didn't you?"
  let $string4 := "This doesn't contain another ain't"
  let $string5 := "this is positive"

  return (
    assert:true(vader:negated(fn:tokenize($string1, " "))),
    assert:true(vader:negated(fn:tokenize($string2, " "))),
    assert:true(vader:negated(fn:tokenize($string4, " "))),
    assert:false(vader:negated(fn:tokenize($string5, " ")))
  )


};

declare %test:case function  negated-test-least ()
{
  let $string3 := "At least I look good least"
  return assert:false(vader:negated(fn:tokenize($string3, " ")))
};

declare %test:case function  negated-test-least-again ()
{
  let $string3 := "I like you the least yet the least"
  let $string1 := "at least your are good "
  return (
    assert:false(vader:negated(fn:tokenize($string3, " "))),
    assert:true(vader:negated(fn:tokenize($string1, " ")))
    )
};

declare %test:case function normalize () {
  let $score := xs:decimal(0)
  let $score-pos := xs:decimal(1000)
  let $score-neg := xs:decimal(-1000)

  return (
    assert:equal(vader:normalize($score), 0 ),
    assert:true(vader:normalize($score-pos) > 0),
    assert:true(vader:normalize($score-neg) < 0)
  )
};

declare %test:case function allcap_differential() {
  let $small := "this is is in all small case"
  let $sentence := "This is a normal sentence"
  let $yell := "THIS IS SOMEONE YELLING"
  let $emph := "This is SOMEONE attempting to EMPHASIZE something"

  return
    (
    assert:false( vader:allcap_differential(fn:tokenize($small, " "))),
    assert:false( vader:allcap_differential(fn:tokenize($sentence, ' '))),
    assert:false( vader:allcap_differential(fn:tokenize($yell, ' ') )),
    assert:true( vader:allcap_differential(fn:tokenize($emph, ' ') ))
    )

};

declare %test:case function scalar_inc_dec() {
  let $neutral-word := "him"
  let $pos-word := "absolutely"
  let $neg-word := "barely"

  return (
    assert:equal( vader:scalar_inc_dec($neutral-word, 0, fn:true()), 0 ),
    assert:true( vader:scalar_inc_dec($pos-word, 0, fn:true()) gt 0 ),
    assert:true( vader:scalar_inc_dec($neg-word, 0, fn:true()) lt 0 )
  )
};

declare %test:case function remove-punctuation() {
  let $sentence := "This is a sentence, with punctuation."
  let $clean := "This is a sentence with punctuation"

  return
    assert:equal(vader:remove-punctuation($sentence), $clean)
};

declare %test:case function remove-singeltons() {
  let $sentence := "This is a sentence, with punctuation."
  let $clean := "This is sentence, with punctuation."

  return
    assert:equal(string-join(vader:remove-singeltons($sentence), ' '), $clean)
};

declare %test:case function product() {
  let $f := function($a,$b) {
    map:new( ( map:entry('seq', ($a,$b)) ) )
  }
  let $f1 := function($a,$b) {
    $a || "," || $b
  }
  let $seq-a := ("a","b","c")
  let $seq-1 := ("1","2","3")

  let $expected := (
    map:new (( map:entry('seq', ("a","1") ) )),
    map:new (( map:entry('seq', ("a","2") ) )),
    map:new (( map:entry('seq', ("a","3") ) )),
    map:new (( map:entry('seq', ("b","1") ) )),
    map:new (( map:entry('seq', ("b","2") ) )),
    map:new (( map:entry('seq', ("b","3") ) )),
    map:new (( map:entry('seq', ("c","1") ) )),
    map:new (( map:entry('seq', ("c","2") ) )),
    map:new (( map:entry('seq', ("c","3") ) ))
  )

  let $expected1 := (
    "a,1", "a,2", "a,3",
    "b,1", "b,2", "b,3",
    "c,1", "c,2", "c,3"
  )

  return
  (
    assert:equal(<debug>{vader:product($seq-a, $seq-1, $f)}</debug>, <debug>{$expected}</debug>),
    assert:equal(<debug>{vader:product($seq-a, $seq-1, $f1)}</debug>, <debug>{$expected1}</debug>)
  )
};

declare %test:case function _words_plus_punc() {
  let $sentence := "This is a sentence, with a dumb; and a dumber"

  let $map := vader:_words_plus_punc($sentence)

  return
  (
    assert:true(map:contains($map, "sentence,")),
    assert:not-empty($map)
  )
};

declare %test:case function _words_and_emoticons() {
  let $emot := "This is funny :-)"
  let $sad := "I'm not a fun of this :-("
  let $non := "This contains no emotion."
  let $trailing := "This, by the way, contains trailing punctuation."

  return (
    assert:equal(fn:string-join(vader:_words_and_emoticons($emot)/word, " "), $emot),
    assert:not-equal(fn:string-join(vader:_words_and_emoticons($non)/word, " "), $non),
    assert:not-equal(fn:string-join(vader:_words_and_emoticons($trailing)/word, " "), $trailing)
  )

};

declare %test:case  function exists-in-lexicon() {
  let $x := "Accident" (:in the lexicon, therfore true:)
  let $y := "there" (:not in the lexicon, therefore false :)

  return (
    assert:false(vader:exists-in-lexicon($y)),
    assert:true(vader:exists-in-lexicon($x)),
    ()
  )
};

declare %test:case function _least_check() {
  let $x := vader:_words_and_emoticons("This is a sentence.")

  let $emot := vader:_words_and_emoticons(
  "My least favorite thing is Microsoft Word.")
  let $f := vader:_least_check(2.5, $emot, ?)
  return (
    assert:not-empty(
    fn:map($f(?), (1 to fn:count($emot))), ""),
    assert:true( $f(3) lt 2.5, "The third word should be lowered because it's preceded by 'least'")
  )
};

declare %test:case function get-valence-measure() {
  let $word := "((-:"

  return (
    assert:not-empty(vader:get-valence-measure($word)),
    assert:empty(vader:get-valence-measure(""))
  )
};

declare %test:case function determine-valence-cap() {
  let $word := "((-:"
  let $cap := "STOP"
  let $wow := "WOW"

  return (
    assert:not-empty(vader:determine-valence-cap($word, fn:false()), ""),
    assert:not-empty(vader:determine-valence-cap($wow, fn:true()), ""),
    assert:not-empty(vader:determine-valence-cap($wow, fn:false()), ""),
    assert:not-empty(vader:determine-valence-cap($cap, fn:true()), ""),
    assert:not-empty(vader:determine-valence-cap($cap, fn:false()), "")
  )
};

declare %test:case function create-word-structure() {
  let $s := ("one","two","three","four")
  let $xml := vader:create-word-structure($s)

  return (
    fn:map(function($x) {
      assert:equal($xml/word[. = $x]/string(),$x)
    },
    $s
    )
  )
};

declare %test:case function determine-word-position() {
  let $s := ("one","two","three","four")
  let $ws := vader:create-word-structure($s)

  let $one := "one"
  let $four := "four"

  let $dwp := vader:determine-word-position(?, $ws)

  return (
    assert:equal($dwp($one), 1),
    assert:equal($dwp($four), 4)
  )
};

declare %test:case function sentiment_valence() {
  let $t := "this is some awesome text"

  return (
    assert:equal(vader:sentiment_valence((), $t, (), (), () ), "" )
  )
};

declare %test:case function _but_check() {
  let $sentence := vader:_words_and_emoticons("This is good, but that is better")
  let $sentiments := (2,2,2,1,2,2)

  let $modified := vader:_but_check($sentence, $sentiments)

  return assert:not-equal($modified, $sentiments)
};

declare %test:case %test:ignore function _idioms_check(){
  ()
};

declare %test:case function _never_check() {
  let $v := 10.0
  let $wae1 :=
    "this should be neutral"
  let $wae2 :=
    "this should never work"

  return (
    (:assert:equal(vader:_never_check($v, $wae1,  1, 3), ""),
    assert:equal(vader:_never_check($v, $wae2,  1, 3), ""),:)
    fn:map(function($sentence) {
      let $s := vader:_words_and_emoticons($sentence)
      return
      fn:map(function($start_i){
        fn:map(function($i){
          assert:not-empty(
            vader:_never_check($v,$s, $start_i, $i),
            string-join((xs:string($v),$s,xs:string($start_i),xs:string($i)),":"))
        },(1 to fn:count($s)) )
      },
      (1 to 3))},
    ($wae1,$wae2))
  )
};

declare %test:case function _amplify_ep() {
  let $s := "This is totally awesome!!!"

  return assert:not-empty(vader:_amplify_ep($s), "")
};

declare %test:case function _amplify_qm() {
  let $s := "This is totally awesome???"

  return assert:not-empty(vader:_amplify_qm($s), "")
};

declare %test:case function _sift_sentiment_scores() {
  let $scores := (-1.0, -1.5, 0, 1,  1.5)

  return (
    assert:not-empty(vader:_sift_sentiment_scores($scores) )
  )
};
