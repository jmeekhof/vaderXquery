xquery version "1.0-ml";

module namespace vadar = "http://vadarSentiment/vadar";

(:Increase decrease based upon booster words:)
declare variable $vadar:B_INCR as xs:double := 0.293;
declare variable $vadar:B_DECR as xs:double := -0.293;
(:Intensity increase do to CAPITALIZED words:)
declare variable $vadar:C_INCR as xs:double := 0.733;
declare variable $vadar:N_SCALAR as xs:double := -0.74;

declare variable $vadar:PUNC_LIST as xs:string+ := (".", "!", "?", ",", ";", ":", "-", "'", '"', "!!", "!!!", "??", "???", "?!?", "!?!", "?!?!", "!?!?");
declare variable $vadar:NEGATE as xs:string+ :=  ("aint", "arent", "cannot", "cant", "couldnt", "darent", "didnt", "doesnt", "ain't", "aren't", "can't", "couldn't", "daren't", "didn't", "doesn't", "dont", "hadnt", "hasnt", "havent", "isnt", "mightnt", "mustnt", "neither", "don't", "hadn't", "hasn't", "haven't", "isn't", "mightn't", "mustn't", "neednt", "needn't", "never", "none", "nope", "nor", "not", "nothing", "nowhere", "oughtnt", "shant", "shouldnt", "uhuh", "wasnt", "werent", "oughtn't", "shan't", "shouldn't", "uh-uh", "wasn't", "weren't", "without", "wont", "wouldnt", "won't", "wouldn't", "rarely", "seldom", "despite");

declare variable $vadar:BOOSTER_DICT as map:map := map:new( (
  map:entry("absolutely", $vadar:B_INCR),
  map:entry("amazingly", $vadar:B_INCR),
  map:entry("awfully", $vadar:B_INCR),
  map:entry("completely", $vadar:B_INCR),
  map:entry("considerably", $vadar:B_INCR),
  map:entry("decidedly", $vadar:B_INCR),
  map:entry("deeply", $vadar:B_INCR),
  map:entry("effing", $vadar:B_INCR),
  map:entry("enormously", $vadar:B_INCR),
  map:entry("entirely", $vadar:B_INCR),
  map:entry("especially", $vadar:B_INCR),
  map:entry("exceptionally", $vadar:B_INCR),
  map:entry("extremely", $vadar:B_INCR),
  map:entry("fabulously", $vadar:B_INCR),
  map:entry("flipping", $vadar:B_INCR),
  map:entry("flippin", $vadar:B_INCR),
  map:entry("fricking", $vadar:B_INCR),
  map:entry("frickin", $vadar:B_INCR),
  map:entry("frigging", $vadar:B_INCR),
  map:entry("friggin", $vadar:B_INCR),
  map:entry("fully", $vadar:B_INCR),
  map:entry("fucking", $vadar:B_INCR),
  map:entry("greatly", $vadar:B_INCR),
  map:entry("hella", $vadar:B_INCR),
  map:entry("highly", $vadar:B_INCR),
  map:entry("hugely", $vadar:B_INCR),
  map:entry("incredibly", $vadar:B_INCR),
  map:entry("intensely", $vadar:B_INCR),
  map:entry("majorly", $vadar:B_INCR),
  map:entry("more", $vadar:B_INCR),
  map:entry("most", $vadar:B_INCR),
  map:entry("particularly", $vadar:B_INCR),
  map:entry("purely", $vadar:B_INCR),
  map:entry("quite", $vadar:B_INCR),
  map:entry("really", $vadar:B_INCR),
  map:entry("remarkably", $vadar:B_INCR),
  map:entry("so", $vadar:B_INCR),
  map:entry("substantially", $vadar:B_INCR),
  map:entry("thoroughly", $vadar:B_INCR),
  map:entry("totally", $vadar:B_INCR),
  map:entry("tremendously", $vadar:B_INCR),
  map:entry("uber", $vadar:B_INCR),
  map:entry("unbelievably", $vadar:B_INCR),
  map:entry("unusually", $vadar:B_INCR),
  map:entry("utterly", $vadar:B_INCR),
  map:entry("very", $vadar:B_INCR),
  map:entry("almost", $vadar:B_DECR),
  map:entry("barely", $vadar:B_DECR),
  map:entry("hardly", $vadar:B_DECR),
  map:entry("just enough", $vadar:B_DECR),
  map:entry("kind of", $vadar:B_DECR),
  map:entry("kinda", $vadar:B_DECR),
  map:entry("kindof", $vadar:B_DECR),
  map:entry("kind-of", $vadar:B_DECR),
  map:entry("less", $vadar:B_DECR),
  map:entry("little", $vadar:B_DECR),
  map:entry("marginally", $vadar:B_DECR),
  map:entry("occasionally", $vadar:B_DECR),
  map:entry("partly", $vadar:B_DECR),
  map:entry("scarcely", $vadar:B_DECR),
  map:entry("slightly", $vadar:B_DECR),
  map:entry("somewhat", $vadar:B_DECR),
  map:entry("sort of", $vadar:B_DECR),
  map:entry("sorta", $vadar:B_DECR),
  map:entry("sortof", $vadar:B_DECR),
  map:entry("sort-of", $vadar:B_DECR)
) );

declare variable $vadar:SPECIAL_CASE_IDIOMS as map:map := map:new ((
  map:entry("the shit", 3),
  map:entry("the bomb", 3),
  map:entry("bad ass", 1.5),
  map:entry("yeah right", -2),
  map:entry("cut the mustard", 2),
  map:entry("kiss of death", -1.5),
  map:entry("hand to mouth", -2)
) );

declare option xdmp:mapping "false";

declare function vadar:negated ( $input-words as xs:string+ )  {
  vadar:negated($input-words, fn:true())
};

declare function vadar:negated ( $input-words as xs:string+, $include-nt as xs:boolean) {
(:~
 : Determine if input words contain negation words
 :)

  let $negated as xs:boolean := $input-words = $vadar:NEGATE
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
  vadar:normalize($score, xs:double(15))
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
