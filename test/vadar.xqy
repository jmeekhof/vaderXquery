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
