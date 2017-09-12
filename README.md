# vadarXquery
This is an XQuery implementation of [vaderSentiment](https://github.com/cjhutto/vaderSentiment).

## Why?
Good question. The Python implementation works well. My particular problem involved a large dataset already existing on a MarkLogic server. Given the time I had to work on the project and the number of items that needed analysis porting, this library to XQuery made sense.

# Installation
This XQuery library is intended to be installed as a submodule within your project. I would suggest something along the lines of:
```bash
$ git submodule add <repo-url>
```
## Supporting Resources
### XRAY
Unit tests are written using the [xray](https://github.com/robwhitby/xray) library. I recommend installing this as a submodule to the _parent_ project.

### vader-lexicon.txt
[vaderSentiment](https://github.com/cjhutto/vaderSentiment) contains a lexicon that it uses to determine a word's valence score. I've created a transform that will ingest the vader-lexicon and transform it into an xml document that this library uses.

This transform is intended to be called by [MLCP](https://developer.marklogic.com/products/mlcp). If you're using [mlGradle](https://github.com/marklogic-community/ml-gradle), add a task like:
```groovy
task importLexicon(type: com.marklogic.gradle.task.MlcpTask){
    classpath = configurations.mlcp
    command = "IMPORT"
    port = Integer.parseInt(mlXccPort)
    database = mlAppConfig.contentDatabaseName
    input_file_path = "src/main/ml-modules/root/modules/vaderXquery/*.txt"
    output_uri_replace = ".*vader, '/vader'"
    output_uri_suffix = ".xml"
    document_type = "text"
    input_file_type = "documents"
    transform_module = "/modules/vaderXquery/transform-lexicon.xqy"
    transform_namespace = "http://vaderSentiment/vader/transform"
}
```
You'll need to adjust accordingly if you placed this submodule elsewhere.

# General Use
The general entry point for this module is `polarity_scores()`. This function expects a sentence, and returns a map of scores. The score you most likely care about is the `compound` score. Please see [vaderSentiment](https://github.com/cjhutto/vaderSentiment) for a full description of what this means.

## Repsonse Format
`polarity_scores` returns a map that looks like:
```
map:new((
    map:entry("neg", xs:decimal()),
    map:entry("pos", xs:decimal()),
    map:entry("neu", xs:decimal()),
    map:entry("compound", xs:decimal())
))
```

In general, the `compound` score is what you care about. This is a value that ranges from -1 to +1. A negative score indicates a negative sentiment, a positive score a positive sentiment.

