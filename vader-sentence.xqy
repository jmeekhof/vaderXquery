xquery version "1.0-ml";

module namespace vs = "http://vaderSentiment/vader-sentence";

declare option xdmp:mapping "false";

declare function vs:paragraph($paragraph as xs:string) as xs:string+ {
  fn:tokenize($paragraph, "[!\?\.&#10;]+\s+")
};
