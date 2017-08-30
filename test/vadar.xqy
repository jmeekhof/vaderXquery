xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";
import module namespace vadar = "http://vadarSentiment/vadar" at "../vadar.xqy";

declare option xdmp:mapping "false";

declare %test:case function  negated-test ()
{

  let $string1 := "I do not like this"
  let $string2 := "I didn't like this, didn't you?"
  let $string4 := "This doesn't contain another ain't"
  let $string5 := "this is positive"

  return (
    assert:true(vadar:negated(fn:tokenize($string1, " "))),
    assert:true(vadar:negated(fn:tokenize($string2, " "))),
    assert:true(vadar:negated(fn:tokenize($string4, " "))),
    assert:false(vadar:negated(fn:tokenize($string5, " ")))
  )


};

declare %test:case function  negated-test-least ()
{
  let $string3 := "At least I look good least"
  return assert:false(vadar:negated(fn:tokenize($string3, " ")))
};

declare %test:case function  negated-test-least-again ()
{
  let $string3 := "I like you the least yet the least"
  let $string1 := "at least your are good "
  return (
    assert:false(vadar:negated(fn:tokenize($string3, " "))),
    assert:true(vadar:negated(fn:tokenize($string1, " ")))
    )
};

declare %test:case function normalize () {
  let $score := xs:decimal(0)
  let $score-pos := xs:decimal(1000)
  let $score-neg := xs:decimal(-1000)

  return (
    assert:equal(vadar:normalize($score), 0 ),
    assert:true(vadar:normalize($score-pos) > 0),
    assert:true(vadar:normalize($score-neg) < 0)
  )
};

declare %test:case function allcap_differential() {
  let $small := "this is is in all small case"
  let $sentence := "This is a normal sentence"
  let $yell := "THIS IS SOMEONE YELLING"
  let $emph := "This is SOMEONE attempting to EMPHASIZE something"

  return
    (
    assert:false( vadar:allcap_differential(fn:tokenize($small, " "))),
    assert:false( vadar:allcap_differential(fn:tokenize($sentence, ' '))),
    assert:false( vadar:allcap_differential(fn:tokenize($yell, ' ') )),
    assert:true( vadar:allcap_differential(fn:tokenize($emph, ' ') ))
    )

};

declare %test:case function scalar_inc_dec() {
  let $neutral-word := "him"
  let $pos-word := "absolutely"
  let $neg-word := "barely"

  return (
    assert:equal( vadar:scalar_inc_dec($neutral-word, 0, fn:true()), 0 ),
    assert:true( vadar:scalar_inc_dec($pos-word, 0, fn:true()) gt 0 ),
    assert:true( vadar:scalar_inc_dec($neg-word, 0, fn:true()) lt 0 )
  )
};
