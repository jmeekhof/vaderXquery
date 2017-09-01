xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";
import module namespace vt = "http://vaderSentiment/vader/transform" at "../transform-lexicon.xqy";
import module namespace vader = "http://vaderSentiment/vader" at "../vader.xqy";

declare option xdmp:mapping "false";

declare %test:case %test:ignore function transform ()
{

  let $doc :=
    "fysa&#9;0.4&#9;0.91652&#9;[0, 0, 0, 1, 0, 3, 0, 0, 0, 0]&#10;" ||
    "g1&#9;1.4&#9;0.4899&#9;[2, 1, 1, 1, 2, 1, 2, 1, 1, 2]&#10;" ||
    "gg&#9;1.2&#9;0.74833&#9;[0, 2, 2, 1, 0, 1, 2, 2, 1, 1]&#10;" ||
    "gga&#9;1.7&#9;0.45826&#9;[2, 2, 1, 2, 2, 1, 2, 2, 1, 2]&#10;"

  let $xform := vt:transform(
      map:new( (
        map:entry('value', $doc)
      ) ),
      map:map()
    )

  let $xml := map:get($xform, "value")

  return assert:equal($xml/vader:lex/vader:word/string()[. = "fysa"],"fysa")

};

