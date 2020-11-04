# Changelog

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/) and
[Keep a CHANGELOG](http://keepachangelog.com).


## Unreleased

### Added

- general serialization functions for reading from and writing to streams
  and implementations for N-Triples and N-Quads (Turtle still to come)
- `RDF.Dataset.prefixes/1` for getting an aggregated `RDF.PrefixMap` over all graphs
- `RDF.PrefixMap.put/3` for adding a prefix mapping and overwrite an existing one
- `RDF.BlankNode.value/1` for getting the internal string representation of a blank node
 
### Changed

- the Inspect form of the RDF data structures are now Turtle-based and respect
  the usual `:limit` behaviour
- more compact Inspect form for `RDF.PrefixMap`
- the `RDF.Turtle.Encoder` accepts `RDF.Vocabulary.Namespace` modules as `base`
- the performance of the `RDF.Turtle.Encoder` was improved (by using a for most 
  use cases more efficient method for resolving IRIs to prefixed names)
- `RDF.BlankNode.new/0` creates integer-based blank nodes, which is much more
  efficient in terms of performance and memory consumption than the previous
  ref-based blank nodes
  

### Fixed

- `RDF.BlankNode`s based on refs weren't serializable to Turtle


[Compare v0.9.0...HEAD](https://github.com/rdf-elixir/rdf-ex/compare/v0.9.0...HEAD)



## 0.9.0 - 2020-10-13

The API of the all three RDF datastructures `RDF.Dataset`, `RDF.Graph` and 
`RDF.Description` were changed, so that the functions taking input data consist only
of one field in order to open the possibility of introducing options on these 
functions. The supported ways with which RDF statements can be passed to the 
RDF data structures were extended and unified to be supported across all functions 
accepting input data. This includes also the way in which patterns for BGP queries
are specified. Also the performance for adding data has been improved.

For an introduction on the new data structure API and the commonly supported input formats
read the updated [page on the RDF data structures in the guide](https://rdf-elixir.dev/rdf-ex/data-structures.html). 
For more details on how to migrate from an earlier version read [this wiki page](https://github.com/rdf-elixir/rdf-ex/wiki/Upgrading-to-RDF.ex-0.9).


### Added

- `RDF.PropertyMap` which allow definition of atoms for RDF properties. 
  Such property maps can be provided to all RDF data structure functions 
  accepting input data and BGP query patterns with the `:context` opt, 
  allowing the use of the atoms from the property map in the input data. 
- on `RDF.Description`
    - `RDF.Description.subject/1` 
    - `RDF.Description.change_subject/2`
- on `RDF.Graph`
    - `RDF.Graph.name/1` 
    - `RDF.Graph.change_name/2`
    - `RDF.Graph.base_iri/1` 
    - `RDF.Graph.prefixes/1`
    - `RDF.Graph.put_properties/3`
- on `RDF.Dataset`
    - `RDF.Dataset.name/1` 
    - `RDF.Dataset.change_name/2`
    - `RDF.Dataset.put_properties/3`
- `RDF.IRI.append/2`

### Changed

- the format for the specification of BGP queries with `RDF.Graph.query/2`, 
  `RDF.Graph.query_stream/2` and `RDF.Query.bgp/1` has been changed to be consistent   
  with the supported formats for input data in the rest of the library   
- `RDF.Description.new` now requires the `subject` to be passed always as first argument;
  if you want to add some initial data this must be done with the `:init` option
- The `put/3` functions on `RDF.Graph` and `RDF.Dataset` now overwrite all 
  statements with same subject. Previously only statements with the same subject 
  AND predicate were overwritten, which was probably not the expected behaviour, 
  since it's not inline with the common `put` semantics in Elixir. 
  A function with the previous behaviour was added on `RDF.Graph` and `RDF.Dataset` 
  with the `put_properties/3` function.
    - **CAUTION: This means the `RDF.Graph.put/2` and `RDF.Dataset.put/2` function have become more destructive now when not specified otherwise.**
    - Note: Although one could argue, that following this route `RDF.Dataset.put/3`
      would consequently have to overwrite whole graphs, this was not implemented
      for practical reasons. It's probably not what's wanted in most cases.
- The `Access` protocol implementation of `get_and_update/3` on `RDF.Graph` and
  `RDF.Dataset` previously relied on the `put/2` functions with the old behaviour
  of overwriting only statements with the same subject and predicate, which was
  almost never the expected behaviour. This is fixed now by relying on the new
  `put/2` behaviour.
- the `values/2` functions of `RDF.Statement`, `RDF.Triple`, `RDF.Quad`, `RDF.Description`,
  `RDF.Graph` and `RDF.Dataset` now accept on their second argument an optional 
  `RDF.PropertyMap`which will be used to map predicates accordingly; the variant of 
  these `values/2` functions to provide a custom mapping function was extracted into 
  a new function `map/2` on all of these modules 
- for consistency reasons the internal `:id` struct field of `RDF.BlankNode` was renamed
  to `:value`
- allow the `base_iri` of `RDF.Vocabulary.Namespace`s to end with a `.` to support
  vocabularies which use dots in the IRIs for further structuring (eg. CIM-based formats like CGMES)
- `RDF.Triple.new/1` now also accepts four-element tuples and simple ignores fourth element   
- `RDF.Quad.new/1` now also accepts three-element tuples and simple assumes the fourth 
  element to be `nil`    

### Fixed

- the `put` functions on `RDF.Description`, `RDF.Graph` and `RDF.Dataset` didn't add all
  statements properly under certain circumstances
- `RDF.Graph.put/2` ignores empty descriptions; this should be the final piece to ensure
  that `RDF.Graph`s never contain empty descriptions, which would distort results of 
  functions like `RDF.Graph.subjects/1`, `RDF.Graph.subject_count/1`, `RDF.Graph.descriptions/1`   


[Compare v0.8.2...v0.9.0](https://github.com/rdf-elixir/rdf-ex/compare/v0.8.2...v0.9.0)



## 0.8.2 - 2020-09-21

### Added

- the Turtle encoder can now produce partial Turtle documents with the `:only` option
  and any combination of the following values: `:triples`, `:directives`, `:base`, `:prefixes`  
- the style of the Turtle directives produced by the Turtle encoder can be
  switched to SPARQL style with the option `:directive_style` and the value `:sparql`
- the most common conflict resolution strategies on `RDF.PrefixMap.merge/3` can now
  be chosen directly with the atoms `:ignore` and `:overwrite` 
- `RDF.PrefixMap.prefixed_name/2` to convert an IRI to a prefixed name
- `RDF.PrefixMap.prefixed_name_to_iri/2` to convert a prefixed name to an IRI

### Changed

- when serializing a `RDF.Dataset` with the Turtle encoder the prefixes of all of its graphs 
  are used now

### Fixed

- adding an empty `RDF.Description` with a subject to an empty `RDF.Graph` resulted in 
  an invalid non-empty graph ([@pukkamustard](https://github.com/pukkamustard))


[Compare v0.8.1...v0.8.2](https://github.com/rdf-elixir/rdf-ex/compare/v0.8.1...v0.8.2)



## 0.8.1 - 2020-06-16

### Added

- query functions for basic graph pattern matching (incl. streaming-support)


[Compare v0.8.0...v0.8.1](https://github.com/rdf-elixir/rdf-ex/compare/v0.8.0...v0.8.1)



## 0.8.0 - 2020-06-01

RDF literals and their datatypes were completely redesigned to support derived XSD datatypes and
allow for defining custom datatypes. 
For an introduction on how literals work now read the updated [page on literals in the guide](https://rdf-elixir.dev/rdf-ex/literals.html). 
For more details on how to migrate from an earlier version read [this wiki page](https://github.com/rdf-elixir/rdf-ex/wiki/Upgrading-to-RDF.ex-0.8).

### Added

- a lot of new datatypes like `xsd:float`, `xsd:byte` or `xsd:anyURI` -- all numeric XSD datatypes 
  are now available; see [this page of the API documentation](https://hexdocs.pm/rdf/RDF.XSD.Datatype.html#module-builtin-xsd-datatypes)
  for an up-to-date list of all supported and missing XSD datatypes
- an implementation of XSD facet system now makes it easy to define own custom datatypes via 
  restriction of the existing XSD datatypes
- `RDF.Literal.update/2` updates the value of a `RDF.Literal` without changing anything else, 
  eg. the language or datatype

### Changed

- the `RDF.Literal` struct now consists entirely of a datatype-specific structs in the `literal` field, 
  which besides being more memory-efficient (since literals no longer consist of all possible fields a literal might have),
  allows pattern matching now on the datatype of literals.
- RDF XSD datatypes are now defined in the `RDF.XSD` namespace
- alias constructor functions for the XSD datatypes are now defined on `RDF.XSD`
- `matches?`, `less_than?`, `greater_than` as higher level functions were removed from the 
  `RDF.Literal.Datatype` modules 
- `less_than?`, `greater_than?` now always return a boolean and no longer `nil` when incomparable;
  you can still determine if two terms are comparable by checking if `compare/2` returns `nil`
- the `language` option is not supported on the `RDF.XSD.String.new/2` constructor  
- the `language` option on `RDF.Literal.new/2` is no longer ignored if it's empty (`nil` or `""`), 
  so this either produces an invalid `RDF.LangString` now or, if another `datatype` is provided will 
  fail with an `ArgumentError`
- `canonical` now performs implicit coercions when passed plain Elixir values
- the inspect format for literals was changed and is now much more informative and uniform, since
  you now always see the value, the lexical form and if the literal is valid
- `RDF.Namespace.resolve_term/1` now returns ok or error tuples, but a new function 
  `RDF.Namespace.resolve_term!/1` with the old behaviour was added
- Elixir versions < 1.8 are no longer supported

### Fixed

- numeric operations on invalid numeric literals no longer fail, but return `nil` instead    
- Datetimes preserve the original lexical form of the timezone when casting from a date
- BEAM error warnings when trying to use top-level modules as vocabulary terms 


[Compare v0.7.1...v0.8.0](https://github.com/rdf-elixir/rdf-ex/compare/v0.7.1...v0.8.0)



## 0.7.1 - 2020-03-11

### Added

- proper typespecs so that Dialyzer passes without warnings ([@rustra](https://github.com/rustra))


### Fixed

- `RDF.XSD.Time` didn't handle 24h overflows with an offset correctly


[Compare v0.7.0...v0.7.1](https://github.com/rdf-elixir/rdf-ex/compare/v0.7.0...v0.7.1)



## 0.7.0 - 2019-11-22

### Added

- `RDF.Diff` data structure for diffs between RDF graphs and descriptions 
- `RDF.Description.update/4` updates the objects of a predicate in a description 
  with a custom update function
- `RDF.Graph.update/4` updates the descriptions of a subject in a graph 
  with a custom update function
- `RDF.Description.take/2` creates a description from another one by limiting 
  its statements to a set of predicates
- `RDF.Graph.take/3` creates a graph from another one by limiting 
  its statements to a set of subjects and optionally also a set of predicates
- `RDF.Graph.clear/1` removes the triples from a graph
- Mix formatter configuration for using `defvocab` without parens 


### Changed

- `RDF.Serialization.Writer.write_file/4` which is the basis used by all the
  `write_file/3` and `write_file!/3` functions of all serialization format modules
  like `RDF.NTriples`, `RDF.Turtle`, `JSON.LD` etc. now opens file in a different 
  mode: it no longer opens them with the [`:utf8` option](https://hexdocs.pm/elixir/File.html#open/2).
  First, this by default slowed down the writing, but more importantly could lead
  to unexpected encoding issues.
  This is a **breaking change**: If your code relied on this file mode, you can
  get the old behaviour, by specifying the `file_mode` on these functions
  accordingly as `[:utf8, :write, :exclusive]`. For example, to write a Turtle
  file with the old behaviour, you can do it like this:
  
```elixir
RDF.Turtle.write_file!(some_data, some_path, file_mode: ~w[utf8 write exclusive]a)
``` 


[Compare v0.6.2...v0.7.0](https://github.com/rdf-elixir/rdf-ex/compare/v0.6.2...v0.7.0)



## 0.6.2 - 2019-09-08

### Added

- field `base_iri` on `RDF.Graph` structure which can be set via new `base_iri` 
  option on `RDF.Graph.new` or the new functions `RDF.Graph.set_base_iri/2` 
  and `RDF.Graph.clear_base_iri/1`
- `RDF.Graph.clear_metadata/1` which clears the base IRI and the prefixes
- `RDF.IRI.coerce_base/1` which coerces base IRIs; as opposed to `RDF.IRI.new/1`
  it also accepts bare `RDF.Vocabulary.Namespace` modules


### Changed

- `RDF.Turtle.Decoder` saves the base IRI in the `RDF.Graph` now
- `RDF.Turtle.Encoder` now takes the base IRI to be used during serialization in  
  the following order of precedence:
	- from the `base` option or its new alias `base_iri`
	- from the `base_iri` field of the given graph
	- from the `RDF.default_base_iri` returning the one from the application 
	  configuration
- `RDF.PrefixMap.new` and `RDF.PrefixMap.add` now also accepts terms from 
  `RDF.Vocabulary.Namespace`s as namespaces


### Fixed

- Vocabulary namespace modules weren't always detected properly


[Compare v0.6.1...v0.6.2](https://github.com/rdf-elixir/rdf-ex/compare/v0.6.1...v0.6.2)



## 0.6.1 - 2019-07-15

### Added

- `RDF.IRI.to_string/1` returns the string representation of an `RDF.IRI`  
  (implicitly resolving vocabulary namespace terms)
- `RDF.Literal.matches?/3` for XQuery regex pattern matching
- `RDF.Decimal.digit_count/1` and `RDF.Decimal.fraction_digit_count/1` for  
  determining the number of digits of decimal literals


### Fixed

- language literals were not properly unescaped during Turtle parsing
- `RDF.Literal.new/1` can take decimals and infers the datatype `xsd:decimal` 
  correctly
- `true` and `false` with capital letters are no longer valid `RDF.Boolean`s 
  following the XSD specification; the same applies for booleans in Turtle
- `+INF` is no longer a valid `RDF.Double` (positive infinity doesn't expect a sign)
- slightly improve output of errors during parsing of Turtle, N-Triples and N-Quads  


[Compare v0.6.0...v0.6.1](https://github.com/rdf-elixir/rdf-ex/compare/v0.6.0...v0.6.1)



## 0.6.0 - 2019-04-06

see [here](https://github.com/rdf-elixir/rdf-ex/wiki/Upgrading-to-RDF.ex-0.6) for
upgrading notes to RDF.ex 0.6 

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


[Compare v0.5.4...v0.6.0](https://github.com/rdf-elixir/rdf-ex/compare/v0.5.4...v0.6.0)



## 0.5.4 - 2019-01-17

### Fixed

- issue with Elixir 1.8
- `RDF.write_file` and `RDF.write_file!` delegators had wrong signatures


[Compare v0.5.3...v0.5.4](https://github.com/rdf-elixir/rdf-ex/compare/v0.5.3...v0.5.4)



## 0.5.3 - 2018-11-11

### Added

- `RDF.Triple.valid?/1`, `RDF.Quad.valid?/1` and `RDF.Statement.valid?/1`, which
  validate if a tuple is a valid RDF triple or RDF quad


[Compare v0.5.2...v0.5.3](https://github.com/rdf-elixir/rdf-ex/compare/v0.5.2...v0.5.3)



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


[Compare v0.5.1...v0.5.2](https://github.com/rdf-elixir/rdf-ex/compare/v0.5.1...v0.5.2)



## 0.5.1 - 2018-09-17

### Fixed

- generated Erlang output files of Leex and Yecc are excluded from Hex package


[Compare v0.5.0...v0.5.1](https://github.com/rdf-elixir/rdf-ex/compare/v0.5.0...v0.5.1)



## 0.5.0 - 2018-09-17

### Added

- Possibility to execute simple SPARQL queries against `RDF.Graph`s with 
  [SPARQL 0.2](https://github.com/rdf-elixir/sparql-ex/blob/master/CHANGELOG.md)
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


[Compare v0.4.1...v0.5.0](https://github.com/rdf-elixir/rdf-ex/compare/v0.4.1...v0.5.0)



## 0.4.1 - 2018-03-19

### Added

- `RDF.Literal.new!/2` which fails when creating an invalid literal 


### Changed

- `RDF.Literal.new/2` can create `rdf:langString` literals without failing, they  
  are simply invalid; if you want to fail without a language tag use the new 
  `RDF.Literal.new!/2` function


[Compare v0.4.0...v0.4.1](https://github.com/rdf-elixir/rdf-ex/compare/v0.4.0...v0.4.1)



## 0.4.0 - 2018-03-10

### Changed

- renamed `RDF.Serialization` behaviour to `RDF.Serialization.Format`; the new
  `RDF.Serialization` module contains just simple RDF serialization related functions 
- renamed `RDF.Serialization.Format` function `content_type/0` to `media_type/0`
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


[Compare v0.3.1...v0.4.0](https://github.com/rdf-elixir/rdf-ex/compare/v0.3.1...v0.4.0)



## 0.3.1 - 2018-01-19

### Added

- `Collectable` implementations for all `RDF.Data` structures so they can be 
  used as destinations of `Enum.into` and `for` comprehensions

### Fixed

- Fix `unescape_map` in `parse_helper` for Elixir 1.6 ([@ajkeys](https://github.com/ajkeys))


[Compare v0.3.0...v0.3.1](https://github.com/rdf-elixir/rdf-ex/compare/v0.3.0...v0.3.1)



## 0.3.0 - 2017-08-24

### Added

- `RDF.IRI` as a more suitable URI/IRI representation for RDF, bringing enormous
  performance and memory consumption benefits (see [here](https://github.com/rdf-elixir/rdf-ex/issues/1) 
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


[Compare v0.2.0...v0.3.0](https://github.com/rdf-elixir/rdf-ex/compare/v0.2.0...v0.3.0)



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


[Compare v0.1.1...v0.2.0](https://github.com/rdf-elixir/rdf-ex/compare/v0.1.1...v0.2.0)



## 0.1.1 - 2017-06-25

### Fixed

- Add `src` directory to package files.

[Compare v0.1.0...v0.1.1](https://github.com/rdf-elixir/rdf-ex/compare/v0.1.0...v0.1.1)



## 0.1.0 - 2017-06-25

Initial release

Note: This version is not usable, since the `src` directory is not part of the 
package, which has been immediately fixed on version 0.1.1.
