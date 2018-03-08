# Change Log

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/) and
[Keep a CHANGELOG](http://keepachangelog.com).


## Unreleased

### Changed

- rename `RDF.Serialization` behaviour to `RDF.Serialization.Format`; the new
  `RDF.Serialization` module contains just simple RDF serialization related functions 


### Added

- `RDF.Serialization.Format`s define a `name` atom
- The following functions to access available `RDF.Serialization.Format`s:
  - `RDF.Serialization.formats/0`
  - `RDF.Serialization.available_formats/0`
  - `RDF.Serialization.format/1`
  - `RDF.Serialization.format_by_content_type/1`
  - `RDF.Serialization.format_by_extension/1`


[Compare v0.3.1...HEAD](https://github.com/marcelotto/rdf-ex/compare/v0.3.1...HEAD)



## 0.3.1 - 2018-01-19

### Added

- `Collectable` implementations for all `RDF.Data` structures so they can be 
  used as destinations of `Enum.into` and `for` comprehensions

### Fixed

- Fix `unescape_map` in `parse_helper` for Elixir 1.6 ([@ajkeys](https://github.com/ajkeys))


[Compare v0.3.0...v0.3.1](https://github.com/marcelotto/rdf-ex/compare/v0.3.0...v0.3.1)



## 0.3.0 - 2017-08-24

### Added

- `RDF.IRI` as a more suitable URI/IRI representation for RDF, bringing enormous
  performance and memory consumption benefits (see [here](https://github.com/marcelotto/rdf-ex/issues/1) 
  for the details about the improvements)

### Changed

- use `RDF.IRI` instead of Elixirs `URI` everywhere
- use the term _iri_ instead of _uri_ consistently, leading to the following 
  function renamings:
    - `base_iri` instead of `base_uri` for the definition of `RDF.Vocabulary.Namespace`s
    - `__base_iri__` instead of `__base_uri__` in all `RDF.Vocabulary.Namespace`s
    - `__iris__` instead of `__uris__` in all `RDF.Vocabulary.Namespace`s
    - `RDF.IRI.InvalidError` instead of `RDF.InvalidURIError`
    - `RDF.Literal.InvalidError` instead of `RDF.InvalidLiteralError`
    - `RDF.Namespace.InvalidVocabBaseIRIError` instead of `RDF.Namespace.InvalidVocabBaseURIError`
- show compilation message of vocabulary namespaces always to be able to relate
  resp. errors and warnings

### Fixed

- when trying to resolve a term from an undefined module a `RDF.Namespace.UndefinedTermError`
  exception


[Compare v0.2.0...v0.3.0](https://github.com/marcelotto/rdf-ex/compare/v0.2.0...v0.3.0)



## 0.2.0 - 2017-08-12

### Added

- full Turtle support
- `RDF.List` structure for the representation of RDF lists
- `describes?/1` on `RDF.Data` protocol and all RDF data structures which checks  
  if statements about a given resource exist
- `RDF.Data.descriptions/1` which returns all descriptions within a RDF data structure 
- `RDF.Description.first/2` which returns a single object to a predicate of a `RDF.Description`
- `RDF.Description.objects/2` now supports a custom filter function
- `RDF.bnode?/1` which checks if the given value is a blank node

### Changed

- Rename `RDF.Statement.convert*` functions to `RDF.Statement.coerce*`
- Don't support Elixir versions < 1.4

### Fixed

- `RDF.uri/1` and URI parsing of N-Triples and N-Quads decoders preserve empty fragments   
- booleans weren't recognized as coercible literals on object positions
- N-Triples and N-Quads decoder didn't handle escaping properly


[Compare v0.1.1...v0.2.0](https://github.com/marcelotto/rdf-ex/compare/v0.1.1...v0.2.0)



## 0.1.1 - 2017-06-25

### Fixed

- Add `src` directory to package files.

[Compare v0.1.0...v0.1.1](https://github.com/marcelotto/rdf-ex/compare/v0.1.0...v0.1.1)



## 0.1.0 - 2017-06-25

Initial release

Note: This version is not usable, since the `src` directory is not part of the 
package, which has been immediately fixed on version 0.1.1.
