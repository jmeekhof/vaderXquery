xquery version '1.0-ml';

module namespace vt = "http://vaderSentiment/vader/transform";
declare namespace v = "http://vaderSentiment/vader";
declare option xdmp:mapping "false";

declare function vt:transform(
  $content as map:map, $context as map:map) as map:map* {

  let $lines :=
    map:get($content, 'value') !
    fn:tokenize(.,"\n")
  let $vec := function($x) {
    fn:replace($x, "\[|\]",'') !
    fn:tokenize(., ",") !
    element v:vector {xs:integer(.)}
  }

  let $lex-builder := function ( $x ) {
    let $line := fn:tokenize($x, "&#9;")
    return (
    element v:lex {
      element v:word {$line[1]},
      element v:measure { xs:float($line[2])},
      element v:score { xs:float($line[3])},
      element v:vectors { $vec($line[4]) }
    }
    )
  }

  let $line-handler := function ( $item, $items ) {
    $lex-builder($item),$items
  }

  let $doc :=
    element v:lexicon {
      fn:fold-right($line-handler(?,?), (), $lines)
    }

  let $c := (map:get($context,"collections"),"vader-lexicon")
  let $_ := map:put($context,'collections', $c)

  return
    map:put($content, "value", $doc),
    $content
};
