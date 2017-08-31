xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";
import module namespace vader = "http://vaderSentiment/vader" at "../vader.xqy";

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
    assert:equal(fn:string-join(vader:_words_and_emoticons($emot), " "), $emot),
    assert:not-equal(fn:string-join(vader:_words_and_emoticons($non), " "), $non),
    assert:not-equal(fn:string-join(vader:_words_and_emoticons($trailing), " "), $trailing)
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
