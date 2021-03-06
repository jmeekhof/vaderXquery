xquery version "1.0-ml";

module namespace vc = "http://vaderSentiment/vader/constants";

(:Increase decrease based upon booster words:)
declare variable $vc:B_INCR as xs:double := 0.293;
declare variable $vc:B_DECR as xs:double := -0.293;
(:Intensity increase do to CAPITALIZED words:)
declare variable $vc:C_INCR as xs:double := 0.733;
declare variable $vc:N_SCALAR as xs:double := -0.74;

declare variable $vc:PUNC_DICT as map:map :=  map:new( (
  map:entry(".", 1),
  map:entry("!", 1),
  map:entry("?", 1),
  map:entry(",", 1),
  map:entry(";", 1),
  map:entry(":", 1),
  map:entry("-", 1),
  map:entry("'", 1),
  map:entry('"', 1),
  map:entry("!!", 1),
  map:entry("!!!", 1),
  map:entry("??", 1),
  map:entry("???", 1),
  map:entry("?!?", 1),
  map:entry("!?!", 1),
  map:entry("?!?!", 1),
  map:entry("!?!?", 1)
) );

declare variable $vc:NEGATE_DICT as map:map := map:new( (
map:entry("aint", 1),
map:entry( "arent", 1),
map:entry( "cannot", 1),
map:entry( "cant", 1),
map:entry( "couldnt", 1),
map:entry( "darent", 1),
map:entry( "didnt", 1),
map:entry( "doesnt", 1),
map:entry( "ain't", 1),
map:entry( "aren't", 1),
map:entry( "can't", 1),
map:entry( "couldn't", 1),
map:entry( "daren't", 1),
map:entry( "didn't", 1),
map:entry( "doesn't", 1),
map:entry( "dont", 1),
map:entry( "hadnt", 1),
map:entry( "hasnt", 1),
map:entry( "havent", 1),
map:entry( "isnt", 1),
map:entry( "mightnt", 1),
map:entry( "mustnt", 1),
map:entry( "neither", 1),
map:entry( "don't", 1),
map:entry( "hadn't", 1),
map:entry( "hasn't", 1),
map:entry( "haven't", 1),
map:entry( "isn't", 1),
map:entry( "mightn't", 1),
map:entry( "mustn't", 1),
map:entry( "neednt", 1),
map:entry( "needn't", 1),
map:entry( "never", 1),
map:entry( "none", 1),
map:entry( "nope", 1),
map:entry( "nor", 1),
map:entry( "not", 1),
map:entry( "nothing", 1),
map:entry( "nowhere", 1),
map:entry( "oughtnt", 1),
map:entry( "shant", 1),
map:entry( "shouldnt", 1),
map:entry( "uhuh", 1),
map:entry( "wasnt", 1),
map:entry( "werent", 1),
map:entry( "oughtn't", 1),
map:entry( "shan't", 1),
map:entry( "shouldn't", 1),
map:entry( "uh-uh", 1),
map:entry( "wasn't", 1),
map:entry( "weren't", 1),
map:entry( "without", 1),
map:entry( "wont", 1),
map:entry( "wouldnt", 1),
map:entry( "won't", 1),
map:entry( "wouldn't", 1),
map:entry( "rarely", 1),
map:entry( "seldom", 1),
map:entry( "despite", 1)
) );

declare variable $vc:BOOSTER_DICT as map:map := map:new( (
  map:entry("absolutely", $vc:B_INCR),
  map:entry("amazingly", $vc:B_INCR),
  map:entry("awfully", $vc:B_INCR),
  map:entry("completely", $vc:B_INCR),
  map:entry("considerably", $vc:B_INCR),
  map:entry("decidedly", $vc:B_INCR),
  map:entry("deeply", $vc:B_INCR),
  map:entry("effing", $vc:B_INCR),
  map:entry("enormously", $vc:B_INCR),
  map:entry("entirely", $vc:B_INCR),
  map:entry("especially", $vc:B_INCR),
  map:entry("exceptionally", $vc:B_INCR),
  map:entry("extremely", $vc:B_INCR),
  map:entry("fabulously", $vc:B_INCR),
  map:entry("flipping", $vc:B_INCR),
  map:entry("flippin", $vc:B_INCR),
  map:entry("fricking", $vc:B_INCR),
  map:entry("frickin", $vc:B_INCR),
  map:entry("frigging", $vc:B_INCR),
  map:entry("friggin", $vc:B_INCR),
  map:entry("fully", $vc:B_INCR),
  map:entry("fucking", $vc:B_INCR),
  map:entry("greatly", $vc:B_INCR),
  map:entry("hella", $vc:B_INCR),
  map:entry("highly", $vc:B_INCR),
  map:entry("hugely", $vc:B_INCR),
  map:entry("incredibly", $vc:B_INCR),
  map:entry("intensely", $vc:B_INCR),
  map:entry("majorly", $vc:B_INCR),
  map:entry("more", $vc:B_INCR),
  map:entry("most", $vc:B_INCR),
  map:entry("particularly", $vc:B_INCR),
  map:entry("purely", $vc:B_INCR),
  map:entry("quite", $vc:B_INCR),
  map:entry("really", $vc:B_INCR),
  map:entry("remarkably", $vc:B_INCR),
  map:entry("so", $vc:B_INCR),
  map:entry("substantially", $vc:B_INCR),
  map:entry("thoroughly", $vc:B_INCR),
  map:entry("totally", $vc:B_INCR),
  map:entry("tremendously", $vc:B_INCR),
  map:entry("uber", $vc:B_INCR),
  map:entry("unbelievably", $vc:B_INCR),
  map:entry("unusually", $vc:B_INCR),
  map:entry("utterly", $vc:B_INCR),
  map:entry("very", $vc:B_INCR),
  map:entry("almost", $vc:B_DECR),
  map:entry("barely", $vc:B_DECR),
  map:entry("hardly", $vc:B_DECR),
  map:entry("just enough", $vc:B_DECR),
  map:entry("kind of", $vc:B_DECR),
  map:entry("kinda", $vc:B_DECR),
  map:entry("kindof", $vc:B_DECR),
  map:entry("kind-of", $vc:B_DECR),
  map:entry("less", $vc:B_DECR),
  map:entry("little", $vc:B_DECR),
  map:entry("marginally", $vc:B_DECR),
  map:entry("occasionally", $vc:B_DECR),
  map:entry("partly", $vc:B_DECR),
  map:entry("scarcely", $vc:B_DECR),
  map:entry("slightly", $vc:B_DECR),
  map:entry("somewhat", $vc:B_DECR),
  map:entry("sort of", $vc:B_DECR),
  map:entry("sorta", $vc:B_DECR),
  map:entry("sortof", $vc:B_DECR),
  map:entry("sort-of", $vc:B_DECR)
) );

declare variable $vc:SPECIAL_CASE_IDIOMS as map:map := map:new ((
  map:entry("the shit", 3),
  map:entry("the bomb", 3),
  map:entry("bad ass", 1.5),
  map:entry("yeah right", -2),
  map:entry("cut the mustard", 2),
  map:entry("kiss of death", -1.5),
  map:entry("hand to mouth", -2)
) );
