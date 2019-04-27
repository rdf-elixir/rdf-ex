# Changelog

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/) and
[Keep a CHANGELOG](http://keepachangelog.com).


## Unreleased

### Added

- `RDF.Literal.matches?/3` for XQuery regex pattern matching
- `RDF.Decimal.digit_count/1` and `RDF.Decimal.fraction_digit_count/1` for  
  determining the number of digits of decimal literals


### Fixed

- language literals were not properly unescaped during Turtle parsing 


[Compare v0.6.0...HEAD](https://github.com/marcelotto/rdf-ex/compare/v0.6.0...HEAD)



## 0.6.0 - 2019-04-06

### Added

- `RDF.PrefixMap`
- prefix management of `RDF.Graph`s:
	- the structure now has a `prefixes` field with an optional `RDF.PrefixMap`
	- new functions `add_prefixes/2`, `delete_prefixes/2` and `clear_prefixes/1` 
- configurable `RDF.default_prefixes`
- `RDF.Description.equal?/2`, `RDF.Graph.equal?/2`, `RDF.Dataset.equal?/2` and 
  `RDF.Data.equal?/2` 


### Changed

- the constructor functions for `RDF.Graph`s and `RDF.Dataset`s now take the 
  graph name resp. dataset name through a `name` option, instead of the first
  argument
- `RDF.Graph.new` supports an additional `prefixes` argument to initialize the 
	`prefixes` field
- when `RDF.Graph.add` and `RDF.Graph.put` are called with another graph, its
  prefixes are merged 
- `RDF.Turtle.Decoder` saves the prefixes now
- `RDF.Turtle.Encoder` now takes the prefixes to be serialized in the following 
  order of precedence:
	- from the `prefixes` option (as before)
	- from the `prefixes` field of the given graph
	- from the `RDF.default_prefixes`
- drop support for OTP < 20, since prefixes can consist of UTF characters which
  are not supported in atoms on these versions  	


[Compare v0.5.4...v0.6.0](https://github.com/marcelotto/rdf-ex/compare/v0.5.4...v0.6.0)



## 0.5.4 - 2019-01-17

### Fixed

- issue with Elixir 1.8
- `RDF.write_file` and `RDF.write_file!` delegators had wrong signatures


[Compare v0.5.3...v0.5.4](https://github.com/marcelotto/rdf-ex/compare/v0.5.3...v0.5.4)



## 0.5.3 - 2018-11-11

### Added

- `RDF.Triple.valid?/1`, `RDF.Quad.valid?/1` and `RDF.Statement.valid?/1`, which
  validate if a tuple is a valid RDF triple or RDF quad


[Compare v0.5.2...v0.5.3](https://github.com/marcelotto/rdf-ex/compare/v0.5.2...v0.5.3)



## 0.5.2 - 2018-11-04

### Added

- `RDF.Term.value/1` returning the native Elixir value of a RDF term
- `RDF.Statement.values/1`, `RDF.Triple.values/1` and `RDF.Quad.values/1` 
  returning a tuple of `RDF.Term.value/1` converted native Elixir values from a 
  tuple of RDF terms
- `RDF.Description.values/1`, `RDF.Graph.values/1`, `RDF.Dataset.values/1` and
	`RDF.Data.values/1` returning a map of `RDF.Term.value/1` converted native 
	Elixir values from the respective structure of RDF terms
- for all of aforementioned `values/1` functions a variant `values/2` which 
  allows to specify custom mapping function to be applied when creating the resp.
  structure
- `RDF.Literal.compare/2`, `RDF.Literal.less_than?/2` and `RDF.Literal.greater_than?/2`  
  for `RDF.Datatype` aware comparisons of `RDF.Literal`s  


### Fixed

- `RDF.DateTime.equal_value?/2` and `RDF.Date.equal_value?/2` did not handle 
  timezones correctly
- `-00:00` is a valid timezone offset on `RDF.DateTime`


[Compare v0.5.1...v0.5.2](https://github.com/marcelotto/rdf-ex/compare/v0.5.1...v0.5.2)



## 0.5.1 - 2018-09-17

### Fixed

- generated Erlang output files of Leex and Yecc are excluded from Hex package


[Compare v0.5.0...v0.5.1](https://github.com/marcelotto/rdf-ex/compare/v0.5.0...v0.5.1)



## 0.5.0 - 2018-09-17

### Added

- Possibility to execute simple SPARQL queries against `RDF.Graph`s with 
  [SPARQL 0.2](https://github.com/marcelotto/sparql-ex/blob/master/CHANGELOG.md)
- New `RDF.Term` protocol implemented for all structs representing RDF nodes and  
  all native Elixir datatypes which are coercible to those modules. For now, it  
  mainly offers, besides the coercion, just the function `RDF.Term.equal?/2` and 
  `RDF.Term.equal_value?/2` for term- and value comparisons.
- New `RDF.Decimal` datatype for `xsd:decimal` literals and support for decimal 
	literals in Turtle encoder
- `RDF.Numeric` module with a list of all numeric datatypes and shared functions
	for all numeric literals, eg. arithmetic functions
- Various new `RDF.Datatype` function 
	- `RDF.Datatype.cast/1` for casting between `RDF.Literal`s  as specified in the 
		XSD spec on all `RDF.Datatype`s 
	- logical operators and the Effective Boolean Value (EBV) coercion algorithm 
		from the XPath and SPARQL specs on `RDF.Boolean`
	- various functions on the `RDF.DateTime` and `RDF.Time` datatypes
	- `RDF.LangString.match_language?/2`
- Many new convenience functions on the top-level `RDF` module 
	- constructors for all of the supported `RDF.Datatype`s
	- constant functions `RDF.true` and `RDF.false` for the two boolean `RDF.Literal` values
- `RDF.Literal.Guards` which allow pattern matching of common literal datatypes
- `RDF.BlankNode.Generator`
- Possibility to configure an application-specific default base IRI; for now it 
  is used only on reading of RDF serializations (when no `base` specified)


### Changed

- Elixir versions < 1.6 are no longer supported
- `RDF.String.new/2` and `RDF.String.new!/2` produce a `rdf:langString` when 
  given a language tag
- Some of the defined structs now enforce keys on compile-time (via Elixirs 
  `@enforce_keys` feature) when not setting the corresponding fields would lead 
  to invalid structs, namely the following fields: 
  - `RDF.IRI.value`
  - `RDF.BlankNode.id`
  - `RDF.Description.subject`
  - `RDF.List.head`


### Fixed

- `RDF.resource?/1` does not fail anymore when called with unresolvable atoms 
  but returns `false` instead
- `RDF.IRI.absolute/2` does not fail with a `FunctionClauseError` when the given 
  base is not absolute, but returns `nil` instead 
- `RDF.DateTime` and `RDF.Time` store microseconds
- `RDF.DateTime`: '24:00:00' is a valid time in a xsd:dateTime; the dateTime 
  value so represented is the first instant of the following day
- `RDF.LangString`: non-strings or the empty string as language produce invalid
  literals


[Compare v0.4.1...v0.5.0](https://github.com/marcelotto/rdf-ex/compare/v0.4.1...v0.5.0)



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
