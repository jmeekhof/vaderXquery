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

  let $line-handler := function ( $item as item(), $items as item()* ) as item()* {
    $lex-builder($item),$items
  }

  let $doc :=
    element v:lexicon {
      fn:fold-right($line-handler(?,?), (), $lines)
    }

  return
    xdmp:document-insert(
      map:get($content, "uri"),
      $doc,
      xdmp:default-permissions(),
      (map:get($context,"collections"),"vader-lexicon")
    ),
    map:map()
};
