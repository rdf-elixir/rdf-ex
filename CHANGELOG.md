# Change Log

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/) and
[Keep a CHANGELOG](http://keepachangelog.com).


## Unreleased

### Added

- top-level alias functions for constructors of the basic datatypes
- top-level constant functions `RDF.true` and `RDF.false` for the two boolean 
  RDF.Literal values


[Compare v0.4.1...HEAD](https://github.com/marcelotto/rdf-ex/compare/v0.4.1...HEAD)



## 0.4.1 - 2018-03-19

### Added

- `RDF.Literal.new!/2` which fails when creating an invalid literal 


### Changed

- `RDF.Literal.new/2` can create `rdf:langString` literals without failing, they  
  are simply invalid; if you want to fail without a language tag use the new 
  `RDF.Literal.new!/2` function


[Compare v0.4.0...v0.4.1](https://github.com/marcelotto/rdf-ex/compare/v0.4.0...v0.4.1)



## 0.4.0 - 2018-03-10

### Changed

- renamed `RDF.Serialization` behaviour to `RDF.Serialization.Format`; the new
  `RDF.Serialization` module contains just simple RDF serialization related functions 
- renamed `RDF.Serialization.Format.content_type/0` to `RDF.Serialization.Format.media_type/0`
- moved `RDF.Reader` and `RDF.Writer` into `RDF.Serialization` module 
- removed the limitation to serialization formats defined in the core RDF.ex package
  for use as a source of `RDF.Vocabulary.Namespace`s; so you can now also define
  vocabulary namespaces from JSON-LD files for example, provided that the corresponding 
  Hex package is defined as a dependency  


### Added

- `RDF.Serialization.Format`s define a `name` atom
- all `RDF.Serialization.Reader` and `RDF.Serialization.Writer` functions are now
  available on the `RDF.Serialization` module (or aliased on the top-level `RDF` 
  module) and the format can be specified instead of a `RDF.Serialization.Format` 
  argument, via the `format` or `media_type` option or in case of `*_file` 
  functions, without explicit specification of the format, but inferred from file
  name extension instead; see the updated README section about RDF serializations
- the following functions to access available `RDF.Serialization.Format`s:
  - `RDF.Serialization.formats/0`
  - `RDF.Serialization.available_formats/0`
  - `RDF.Serialization.format/1`
  - `RDF.Serialization.format_by_media_type/1`
  - `RDF.Serialization.format_by_extension/1`


[Compare v0.3.1...v0.4.0](https://github.com/marcelotto/rdf-ex/compare/v0.3.1...v0.4.0)



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
