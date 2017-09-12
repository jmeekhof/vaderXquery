# vadarXquery
This is an XQuery implementation of [vaderSentiment](https://github.com/cjhutto/vaderSentiment)

## Why?
Good question. The Python implementation works well. My particular problem involved a large dataset already existing on a MarkLogic server. Given the time I had to work on the project and the number of items that needed analysis porting this library to XQuery made sense.

# Installation
This XQuery library is intended to be installed as a submodule within your project. I would suggest something along the lines of:
```bash
$ git submodule add <repo-url>
```
## Supporting Resources
### XRAY
Unit tests are written using the [xray](https://github.com/robwhitby/xray) library. I recommend installing this as a submodule to the _parent_ project.

### vader-lexicon.txt
vaderSentiment contains a lexicon that it uses to determine a word's valence score. I've created a transform that will ingest the vader-lexicon and transform it into an xml document that this library uses.
