# Changelog

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/) and
[Keep a CHANGELOG](http://keepachangelog.com).



## 2.1.0 - 2025-04-09

Elixir versions < 1.14 and OTP version < 24 are no longer supported.

Also, compatibility with decimal < v2.0 is dropped.

### Added

- `RDF.JSON` datatype
- `RDF.IRI.merge!/2` which validates that the base and the result of the merge
  is a valid IRI or fails otherwise
- `RDF.Test.Assertions.assert_rdf_isomorphic/2` ExUnit test helper 

### Changed

- `RDF.IRI.valid?/1` now performs a proper RFC 3987 conformance validation.
  Note: This makes various places where the previous very sloppy implementation 
  was used stricter, e.g. the Turtle decoder or `~I` sigil. 
- The `RDF.EarlFormatter` module was renamed to `RDF.Test.EarlFormatter`.
- The `RDF.Test.EarlFormatter` no longer marks excluded tests as `earl:untested`, 
  but simply ignores them.

### Fixed

- Fixed compilation error when defining `RDF.Vocabulary.Namespace`s for large 
  vocabularies (like Schema.org) caused by exceeding implementation limits.
- The case violation check during `RDF.Vocabulary.Namespace` creation didn't
  always recognize properties correctly. 
- Namespace delegator modules defined with `RDF.Namespace.act_as_namespace/1`
  were not properly recompiled on changes of the underlying vocabulary file. 


[Compare v2.0.1...v2.1.0](https://github.com/rdf-elixir/rdf-ex/compare/v2.0.1...v2.1.0)



## 2.0.1 - 2024-10-07

### Fixed

- The Turtle/TriG encoder didn't escape strings properly when using the long
  literal form, i.e. when the encoded string contains newlines, which could 
  result in invalid output in edge-cases.


[Compare v2.0.0...v2.0.1](https://github.com/rdf-elixir/rdf-ex/compare/v2.0.0...v2.0.1)



## 2.0.0 - 2024-08-07

Elixir versions < 1.13 and OTP version < 23 are no longer supported

An update to the recent more extensive Turtle test suite revealed that a bug in  
Elixir's `URI.merge/2` function affects the relative URI handling in the Turtle decoder. 
It is therefore strongly recommended to use the Turtle decoder with 
Elixir v1.15 or later, where this issue has been resolved.

### Added

- `RDF.TriG` with an implementation of the TriG serialization language. 
- Several new options on the Turtle/TriG encoders for more customizations and 
  performance optimizations:
  - Capability to add custom content on the Turtle/TriG encoders with the `:content` option.
  - `:line_prefix` for a function defining custom line prefixes
  - `:indent_width` to customize the indentation width
  - `:pn_local_validation` for controlling IRI validation when encoding prefixed names
  - `:rdf_star` allowing to skip an RDF-star related preprocessing step
- `RDF.Dataset.named_graphs/1` to get a list of all named graphs of a dataset.
- `RDF.Dataset.graph_names/1` to get a list of all graph names of a dataset.
- `RDF.Dataset.update_all_graphs/2` to apply a function on all graphs of a dataset.
- `RDF.Graph.update_all_descriptions/2` to apply a function on all descriptions of a graph.
- `RDF.Description.update_all_predicates/2` and `RDF.Description.update_all_objects/2`
  to apply a function on all predications resp. objects of a description.
- `RDF.Graph.rename_resource/2` and `RDF.Description.rename_resource/2` to replace all 
  occurrences of an id.
- `RDF.turtle_prefixes/1` and `RDF.sparql_prefixes/1` for creating respective prefix headers
- `RDF.Graph.prefixes/2` which allows to specify a custom return value when the prefixes 
  are empty.
- `RDF.PrefixMap.empty?/1` to check of a `RDF.PrefixMap` is empty.
- `RDF.PrefixMap.limit/2` to limit a `RDF.PrefixMap` to a subset of some given prefixes.
- `RDF.BlankNode.Generator.UUID` and `RDF.BlankNode.Generator.Random` implementations
  of `RDF.BlankNode.Generator.Algorithm`
- `:bnode_gen` option on the Turtle/TriG decoders, allowing customization of blank node 
  generation and a `turtle_trig_decoder_bnode_gen` application config for setting the 
  default blank node generator globally.
- Performance improvements of N-Triples and N-Quads encoders.

### Changed

- Default blank node generation in Turtle decoder now generates UUID blank node 
  identifiers instead of the previous deterministic incremented identifiers. 
  This change ensures unique blank nodes across multiple parsing operations.
  You can opt back to the previous behaviour with the new `turtle_trig_decoder_bnode_gen` 
  application config using the `:increment` value.
- Aliases defined within `RDF.Graph.build` blocks are no longer supported due to changes  
  in Elixir 1.17. Aliases from the caller context are still available and automatically  
  re-aliased in the build block. However, instead of using aliases for vocabulary namespaces, 
  use `@prefix` declarations inside the build block, as it provides additional benefits. 
  Please refer to the [user guide](https://rdf-elixir.dev/rdf-ex/description-and-graph-dsl.html#graph-builder) for more information.
- The `prefixes` of an `RDF.Graph` are now always a `RDF.PrefixMap` and no longer `nil`
  initially, since this had the confusing consequence that an `RDF.Graph` where all 
  prefixes were deleted was not equal to same graph where the deleted were never set,
  e.g. `RDF.graph() |> Graph.add_prefixes(ex: EX) |> Graph.delete_prefixes(:ex) == RDF.graph()`
  did not hold previously. This behaviour was used before to differentiate graphs which
  should use the `RDF.default_prefixes/0` (in case `prefixes` was `nil`) from those which
  should not use any prefixes (empty `PrefixMap`) when serialized to Turtle. 
  You'll now have to add the `prefixes: []` on Turtle serialization explicitly. 
  The old behaviour of getting `nil` on empty prefixes can be achieved with the new 
  `RDF.Graph.prefixes/2` function.
- Update to change in N-Triples and N-Quads specs disallowing colons in bnode labels.
- Rename `:only` option of `RDF.Turtle.Encoder` to `:content` to reflect the enhanced 
  capabilities.
- The `RDF.BlankNode.Generator` and `RDF.BlankNode.Generator.Algorithm` behaviour 
  used internally at various places was redesigned.
- Deprecated `RDF.Diff.merge/2` was removed. Use `RDF.Diff.union/2` instead.
- Replacement of `elixir_uuid` with `uniq` dependency for UUID generation and
  make it no longer optional

### Fixed

- The `RDF.Turtle.Encoder` was not falling back to using `RDF.default_prefixes/0` when
  the encoded graph had prefixes which were removed afterwards.
- Fixed the `RDF.Turtle.Encoder` validation to ensure IRIs with permissible characters, 
  such as hyphens, can be correctly encoded as prefixed names. Previously, the validation 
  was overly strict, preventing some valid IRIs from being encoded as prefixed names.
- `RDF.NTriples.Encoder` and `RDF.NQuads.Encoder` could not stream quoted RDF-star 
  triples could as iodata.


[Compare v1.2.0...v2.0.0](https://github.com/rdf-elixir/rdf-ex/compare/v1.2.0...v2.0.0)



## 1.2.0 - 2024-03-18

Elixir versions < 1.12 are no longer supported

### Added 

- `RDF.Namespace.act_as_namespace/1` macro which can be used to let a module act 
  as a specified `RDF.Namespace` or `RDF.Vocabulary.Namespace`.
- `canonical_hash/2` function on `RDF.Dataset`, `RDF.Graph` and `RDF.Description` which
  computes a hash value for the data based on the `RDF.Canonicalization` algorithm
- `intersection/2` function on `RDF.Dataset`, `RDF.Graph` and `RDF.Description` which
  create respective graph data intersections. Since this feature relies on `Map.intersect/3` 
  that was added in Elixir v1.15, it is only available with a respective Elixir version.  
- `RDF.Dataset.put_graph/3` adds new graphs overwriting any existing graphs
- `RDF.Dataset.update/4` to update graphs in a `RDF.Dataset`
- `RDF.Graph.delete_predications/3` to delete all statements in a `RDF.Graph` with 
  the given subjects and predicates
- `RDF.PrefixMap.to_header/3`, `RDF.PrefixMap.to_turtle/1` and `RDF.PrefixMap.to_sparql/1`
  to get header string representations of a `RDF.PrefixMap` in the respective style
- `RDF.PrefixMap.to_sorted_list/1` which returns the prefix map as keyword list 
  sorted by prefix (this should become useful with OTP 26)
- `RDF.PropertyMap.to_sorted_list/1` which returns the property map as keyword list
  sorted by property  
- The Turtle encoder now sorts the prefixes (based on `RDF.PrefixMap.to_sorted_list/1`), 
  which has become necessary, since OTP 26 maps are now unordered even in smaller cases 
  (previously only larger maps were unordered).
- The N-Triples and N-Quads encoders now support a flag option `:sort` which, when  
  activated, encodes the statements sorted in Unicode code point order.
- The hash algorithm to be used for RDF canonicalization can be configured either
  with the `:hash_algorithm` keyword option or the `:canon_hash_algorithm` application 
  runtime configuration.
- Add Hash N-Degree Quads algorithm call limit to canonicalization as a countermeasure
  against [poison dataset attacks](https://www.w3.org/TR/rdf-canon/#dataset-poisoning)
- Compile-time application configuration `:optimize_regexes` that allows to switch 
  internal usage to the faster Erlang `:re.run/2` function for regex pattern matching
  ([@jkrueger](https://github.com/jkrueger))
- Some optimizations on `RDF.IRI` ([@jkrueger](https://github.com/jkrueger))
- `RDF.EarlFormatter` as an `ExUnit.Formatter` implementation that generates EARL reports

### Changed

- `RDF.Canonicalization.canonicalize/2` now returns the canonicalized dataset in a 
  tuple along with final state containing the _input blank node identifier map_ and
  the _issued identifiers map_ as required by the RDF dataset canonicalization 
  specification
- `RDF.Diff.merge/2` was deprecated and will be replaced in future versions with a 
  different merge algorithm. Use `RDF.Diff.union/2` now for the current algorithm.
- Statements as lists (instead of tuples) in the `Collectable` implementations of
  `RDF.Description`, `RDF.Graph` and `RDF.Dataset` were deprecated.
  Support of those will be removed in RDF.ex v2.0. 
- The following deprecated types were removed:
  - `RDF.Statement.coercible_t` (new type: `RDF.Statement.coercible`)
  - `RDF.Star.Statement.coercible_t` (new type: `RDF.Star.Statement.coercible`)
  - `RDF.Triple.t_values` (new type: `RDF.Triple.mapping_value`)
  - `RDF.Quad.t_values` (new type: `RDF.Quad.mapping_value`)


### Fixed

- `RDF.Dataset.put/3` with a `RDF.Dataset` input didn't respect the `:graph` option to 
  aggregate everything into single target graph


[Compare v1.1.1...v1.2.0](https://github.com/rdf-elixir/rdf-ex/compare/v1.1.1...v1.2.0)



## 1.1.1 - 2023-03-31

### Added

- a custom option `:content_only` on the `Inspect` implementation of `RDF.Graph` 
  which returns only the (possibly abbreviated) Turtle representation of the graph;
  this can be used in other `Inspect` implementations that want to include 
  this `RDF.Graph` representation
- `RDF.prefixes/1` as another alias for the creation of a `RDF.PrefixMap` 

### Fixed

- `RDF.Graph.new/2` didn't respect the `:init` opt when the first argument was a `RDF.Graph` 


[Compare v1.1.0...v1.1.1](https://github.com/rdf-elixir/rdf-ex/compare/v1.1.0...v1.1.1)



## 1.1.0 - 2022-12-19

### Added

- implementation of the [Standard RDF Dataset Canonicalization Algorithm](https://www.w3.org/TR/rdf-canon/)
  which can be used with `RDF.Graph.canonicalize/1` and `RDF.Dataset.canonicalize/1` functions
- `RDF.Graph.isomorphic?/2` and `RDF.Dataset.isomorphic?/2` to compare if two
  graphs or datasets are the same, regardless of the concrete names of the 
  blank nodes they contain
- `RDF.Statement.bnodes/1`, `RDF.Triple.bnodes/1`, `RDF.Quad.bnodes/1` to get a list
  of all blank nodes within a statement
- `RDF.Statement.include_value?/2`, `RDF.Triple.include_value?/2`, `RDF.Quad.include_value?/2` 
  to check whether a given value is a component of a statement
- performance improvements of the `RDF.Turtle.Encoder`

### Changed

- `RDF.XSD.Double` and `RDF.XSD.Float` literals created from Elixir floats and integers
  are now interpreted to be in the canonical lexical form
- `RDF.BlankNode.new/1` ignores the prefix `"_:"` in a given blank node name

### Fixed

- the N-Triples, N-Quads and Turtle encoder were creating too many backslashes,
  when escaping a backslash in a string;  
  BEWARE: You'll have to fix the generated Turtle files you've produced with earlier versions!
- the N-Triples, N-Quads and Turtle encoder didn't apply proper escaping in typed literals 
  of unknown type in general
- the Turtle encoder didn't encode the descriptions of blank nodes which occurred in
  a blank node cycle, e.g. in `_:b1 :p1 _:b2 . _:b2 :p2 _:b1 .` neither the description 
  of `_:b1` nor of `_:b2` were rendered
- the Turtle encoder now preserves the lexical form of a literal instead of always  
  encoding the canonical form
- a regression in `defvocab` prevented its use with fully qualified vocabulary 
  namespace module names (i.e. which include a dot)
- the `term_to_iri/1` macro didn't work properly in all types of pattern matches
- the `Inspect` protocol implementation for decimal literals wasn't using the lexical
  in case of an uncanonical lexical form of a decimal literal 


[Compare v1.0.0...v1.1.0](https://github.com/rdf-elixir/rdf-ex/compare/v1.0.0...v1.1.0)



## 1.0.0 - 2022-11-03

In this version `RDF.Namespace` and `RDF.Vocabulary.Namespace` were completely rewritten.
The generated namespaces are much more flexible now and compile faster.

For more details on how to migrate from an earlier version read [this wiki page](https://github.com/rdf-elixir/rdf-ex/wiki/Upgrading-to-RDF.ex-1.0).

Elixir versions < 1.11 are no longer supported


### Added

- `RDF.Vocabulary.Namespace.create/5` for dynamic creation of `RDF.Vocabulary.Namespace`s
- `RDF.Namespace` builders `defnamespace/3` and `create/4`
  inside of pattern matches
- `RDF.Vocabulary.Namespace` modules now have a `__file__/0` function which returns
  the path to the vocabulary file they were generated from
- `RDF.Vocabulary.path/1` returning the path to the vocabulary directory of an
  application and `RDF.Vocabulary.path/2` returning the path to the files within it
- The property functions on the `RDF.Namespace` and `RDF.Vocabulary.Namespace` modules
  now also have a single argument variant, which allows to query the objects for the
  respective property from a `RDF.Description`
- Aliases on a `RDF.Vocabulary.Namespace` can now be specified directly in the
  `:terms` list.
- The `:terms` option can now also be used in conjunction with the `:file` and
  `:data` options to restrict the terms loaded from the vocabulary data with a
  list of the terms or a restriction function. 
- The `case_violations` option of `defvocab` now supports an `:auto_fix` option 
  which adapts the first letter of violating term accordingly. It also supports
  custom handler functions, either as an inline function or as a function on a 
  separate module.
- New option `allow_lowercase_resource_terms` option which can be set to `true`
  to no longer complain about lowercased terms for non-property resources.
- `RDF.Graph.build/2` now supports the creation of ad-hoc vocabulary namespaces
  with a `@prefix` declaration providing the URI of the namespace as a string
- `RDF.Namespace.IRI.term_to_iri/1` macro which allows to resolve `RDF.Namespace` terms
- a lot of new `RDF.Guards`: `is_rdf_iri/1`, `is_rdf_bnode/1`, `is_rdf_literal/1`,
  `is_rdf_literal/2`, `is_plain_rdf_literal/1`, `is_typed_rdf_literal/1`,
  `is_rdf_resource/1`, `is_rdf_term/1`, `is_rdf_triple/1`, `is_rdf_quad/1` and
  `is_rdf_statement/1`
- an implementation of `__using__` on the top-level `RDF` module, which allows to
  add basic imports and aliases with a simple `use RDF` 
- `RDF.IRI.starts_with?/2` and `RDF.IRI.ends_with?/2`
- `RDF.Graph.quads/2` and `RDF.Dataset.quads/2` to get all statements of a 
  `RDF.Graph` and `RDF.Dataset` as quads
- `RDF.Dataset.triples/2` to get all statements of a `RDF.Dataset` as triples
- `RDF.PrefixMap.to_list/1`
- `RDF.PropertyMap.to_list/1`
- support for Elixir 1.14
- support for Decimal v2


### Changed

#### Breaking

- Support for passing multiple objects as separate arguments to the property
  functions of the description DSL on the vocabulary namespaces was removed
  to create space for further arguments for other purposes in the future.
  Multiple objects must be given now in a list instead.
- All errors found during the compilation of `RDF.Vocabulary.Namespace` are 
  now collectively reported under a single `RDF.Vocabulary.Namespace.CompileError`.
- An `ignore` term in a `defvocab` definition which actually is not a term of
  the vocabulary namespace is now considered an error.
- When defining an alias for a term of vocabulary which would be invalid as an
  Elixir term, the original term is now implicitly ignored and won't any longer
  be returned by the `__terms__/0` function of a `RDF.Vocabulary.Namespace`.
- `RDF.Graph.build/2` blocks are now wrapped in a function, so the aliases and
  import no longer affect the caller context. `alias`es in the caller context are
  still available in the build block, but `import`s not and must be reimported in
  the build block. Variables in the caller context are also no longer available
  in a `build` block but must be passed explicitly as bindings in a keyword list
  on the new optional first argument of `RDF.Graph.build/3`.
- `RDF.BlankNode.Increment` was renamed to `RDF.BlankNode.Generator.Increment`
- `RDF.XSD.Datatype.Mismatch` exception was renamed to
  `RDF.XSD.Datatype.MismatchError` for consistency reasons

#### Non-breaking

- The `defvocab` macro can now be safely used in any module and guarantees cleanliness
  of the base module. So, a surrounding namespace (like `NS`) is no longer necessary.
  Although still useful for foreign vocabularies, this can be useful eg. to define a
  `MyApplication.Vocab` module directly under the root module of the application.
- The `:base_iri` specified in `defvocab` can now be given in any form supported
  by `RDF.IRI.new/1`. There are also no longer restrictions on the expression 
  of this value. While previously the value had to be provided as a literal value,
  now any expression returning a value accepted by `RDF.IRI.new/1` can be given 
  (e.g. function calls, module attributes etc.).
  The `:base_iri` also no longer has to end with a `/` or `#`.
- `RDF.Data.merge/2` and `RDF.Data.equal?/2` are now commutative, i.e. structs
  which implement the `RDF.Data` protocol can be given also as the second argument
  (previously custom structs with `RDF.Data` protocol implementations always
  had to be given as the first argument).
- the `Inspect` implementation for the `RDF.Literal`, `RDF.PrefixMap` and  
  `RDF.PropertyMap` structs now return a string with a valid Elixir expression
  that recreates the struct when evaluated
- several performance improvements


### Fixed

- The RDF vocabulary namespaces used in `@prefix` and `@base` declarations in a
  `RDF.Graph.build` block no longer have to be written out, which had to be done
  previously even when parts of the module were available as an alias.
- No warning on lowercased non-property resources in vocabularies


[Compare v0.12.0...v1.0.0](https://github.com/rdf-elixir/rdf-ex/compare/v0.12.0...v1.0.0)



## 0.12.0 - 2022-04-11

This version introduces a new graph builder DSL. See the [new guide](https://rdf-elixir.dev/rdf-ex/description-and-graph-dsl.html)
for an introduction.

### Added

- a `RDF.Graph` builder DSL available under the `RDF.Graph.build/2` function
- new `RDF.Sigils` `~i`, `~b` and `~l` as variants of the `~I`, `~B` and `~L`
  sigils, which support string interpolation   
- `RDF.Graph.new/2` and `RDF.Graph.add/2` support the addition of `RDF.Dataset`s
- `RDF.Description.empty?/1`, `RDF.Graph.empty?/1`, `RDF.Dataset.empty?/1` and
  `RDF.Data.empty?/1` which are significantly faster than `Enum.empty?/1`
  - By replacing all `Enum.empty?/1` uses over the RDF data structures with these
    new `empty?/1` functions throughout the code base, several functions benefit
    from this performance improvement.
- `RDF.Description.first/2` now has a `RDF.Description.first/3` variant which
  supports a default value
- new guards in `RDF.Guards`: `is_statement/1` and `is_quad/1`
- `RDF.PropertyMap.terms/1` and `RDF.PropertyMap.iris/1`

### Changed

- `RDF.Graph.description/2` is no longer an alias for `RDF.Graph.get/2`, but
  has a different behaviour now: it will return an empty description when no
  description for the requested subject exists in the graph
- The inspect string of `RDF.Description` now includes the subject separately, so 
  it can be seen also when the description is empty.

### Fixed

- When triples with an empty object list where added to an `RDF.Graph`, it 
  included empty descriptions, which lead to inconsistent behaviour 
  (for example it would be counted in `RDF.Graph.subject_count/1`).
- When an `RDF.Graph` contained empty descriptions these were rendered by 
  the `RDF.Turtle.Encoder` to a subject without predicates and objects, i.e.
  invalid Turtle. This actually shouldn't happen and is either caused by 
  misuse or a bug. So instead, a `RDF.Graph.EmptyDescriptionError` with a 
  detailed message will be raised now when this case is detected.


[Compare v0.11.0...v0.12.0](https://github.com/rdf-elixir/rdf-ex/compare/v0.11.0...v0.12.0)



## 0.11.0 - 2022-03-22

The main feature of this version are the `RDF.Resource.Generator`s.
For an introduction see [this guide](https://rdf-elixir.dev/rdf-ex/resource-generators.html).

### Added

- `RDF.Resource.Generator`s which can be used to generate configurable ids
- `:implicit_base` option on the `RDF.Turtle.Encoder`
- `:base_description` option on the `RDF.Turtle.Encoder`
- several new types: 
  - `RDF.Resource.t` for all node identifiers, i.e. `RDF.IRI`s and `RDF.BlankNode`s 
  - `RDF.Triple.coercible`, `RDF.Quad.coercible`, `RDF.Star.Triple.coercible`
    and `RDF.Star.Quad.coercible` for tuples which can be coerced to the
    respective statements

### Changed

- some types were renamed for consistency reasons; the old types were deprecated
  and will be removed
  - `RDF.Statement.coercible_t` -> `RDF.Statement.coercible`
  - `RDF.Star.Statement.coercible_t` -> `RDF.Star.Statement.coercible`
  - `RDF.Triple.t_values` -> `RDF.Triple.mapping_value`
  - `RDF.Quad.t_values` -> `RDF.Quad.mapping_value`

### Fixed

- the interface of `RDF.BlankNode.Generator.start_link/1` was fixed, so that
  generators can be started supervised


[Compare v0.10.0...v0.11.0](https://github.com/rdf-elixir/rdf-ex/compare/v0.10.0...v0.11.0)



## 0.10.0 - 2021-12-13

This release adds RDF-star support on the RDF data structures, the N-Triples, N-Quads, 
Turtle encoders and decoders and the BGP query engine. 
For an introduction read the new [page on the RDF.ex guide](https://rdf-elixir.dev/rdf-ex/rdf-star.html).
For more details on how to migrate from an earlier version read [this wiki page](https://github.com/rdf-elixir/rdf-ex/wiki/Upgrading-to-RDF.ex-0.10).

Elixir versions < 1.10 are no longer supported

### Added

- Support for `RDF.PropertyMap` on `RDF.Statement.new/2` and `RDF.Statement.coerce/2`.
- `RDF.Dataset.graph_count/1`
- The `RDF.NQuads.Encoder` now supports a `:default_graph_name` option, which
  allows to specify the graph name to be used as the default for triples
  from a `RDF.Graph` or `RDF.Description`.

### Changed

- The `RDF.Turtle.Encoder` no longer supports the encoding of `RDF.Dataset`s.   
  You'll have to aggregate a `RDF.Dataset` to a `RDF.Graph` on your own now.
- The `RDF.NQuads.Encoder` now uses the `RDF.Graph.name/1` as the graph name for  
  the triples of a `RDF.Graph`.
  Previously the triples of an `RDF.Graph` were always encoded as part of default 
  graph. You can use the new `:default_graph_name` option and set it to `nil` to get
  the old behaviour.

  
[Compare v0.9.4...v0.10.0](https://github.com/rdf-elixir/rdf-ex/compare/v0.9.4...v0.10.0)



## 0.9.4 - 2021-05-26

### Added

- `RDF.statement/1`, `RDF.statement/3` and `RDF.statement/4` constructor functions
- the `:default_prefixes` configuration option now allows to set a `{mod, fun}`
  tuple, with a function which should be called to determine the default prefixes
- the `:default_base_iri` configuration option now allows to set a `{mod, fun}`
  tuple, with a function which should be called to determine the default base IRI
- support for Elixir 1.12 and OTP 24

### Fixed

- the Turtle encoder was encoding IRIs as prefixed names even when they were
  resulting in non-conform prefixed names
- the Turtle encoder didn't properly escape special characters in language-tagged 
  literals
- the N-Triples and N-Quads encoders didn't properly escape special characters in 
  both language-tagged and plain literals
- the `Inspect` protocol implementation for `RDF.Diff` was causing an error when
  both graphs had prefixes defined
  
Note: In the canonical form of -0.0 in XSD doubles and floats the sign is removed
in OTP versions < 24 although this is not standard conform. This has the
consequence that the sign of -0.0 is also removed when casting these doubles and
floats to decimals. These bugs won't be fixed. If you rely on the correct behavior
in these cases, you'll have to upgrade to OTP 24 and a respective Elixir version.


[Compare v0.9.3...v0.9.4](https://github.com/rdf-elixir/rdf-ex/compare/v0.9.3...v0.9.4)



## 0.9.3 - 2021-03-09

### Added

- `:indent` option on `RDF.Turtle.Encoder`, which allows to specify the number
  of spaces the output should be indented

### Changed

- the performance of the `Enumerable` protocol implementations of the RDF data 
  structures was significantly improved (for graphs almost 10x), which in turn
  increases the performance of all functions built on top of that, eg. 
  the N-Triples and N-Quads encoders
- improvement of the Inspect forms of the RDF data structures: the content is
  now enclosed in angle brackets and indented 

### Fixed

- strings of the form `".0"` and `"0."` weren't recognized as valid XSD float  
  and double literals
- the Turtle encoder handles base URIs without a trailing slash or hash properly  
  (no longer raising a warning and ignoring them) 
 

[Compare v0.9.2...v0.9.3](https://github.com/rdf-elixir/rdf-ex/compare/v0.9.2...v0.9.3)



## 0.9.2 - 2021-01-06

### Added

- `RDF.XSD.Base64Binary` datatype ([@pukkamustard](https://github.com/pukkamustard))

### Changed

- a new option `:as_value` to enforce interpretation of an input string as a value
  instead of a lexical, which is needed on datatypes where the lexical space and
  the value space both consist of strings
- `RDF.XSD.Date` and `RDF.XSD.Time` both can now be initialized with tuples of an
  Elixir `Date` resp. `Time` value and a timezone string (previously XSD date and 
  time values with time zones could only be created from strings)


[Compare v0.9.1...v0.9.2](https://github.com/rdf-elixir/rdf-ex/compare/v0.9.1...v0.9.2)



## 0.9.1 - 2020-11-16

Elixir versions < 1.9 are no longer supported

### Added

- general serialization functions for reading from and writing to streams
  and implementations for N-Triples and N-Quads (Turtle still to come)
- a `:gzip` option flag on all `read_file/3` and `write_file/3` functions
  allows to read and write all supported serialization formats from and to
  gzipped files (works also with the new possibility to read and write files via streams)
- `RDF.Dataset.prefixes/1` for getting an aggregated `RDF.PrefixMap` over all graphs
- `RDF.PrefixMap.put/3` for adding a prefix mapping and overwrite an existing one
- `RDF.BlankNode.value/1` for getting the internal string representation of a blank node
- `RDF.IRI.in_namespace?/2` for determining whether an IRI lies in a namespace
 
### Changed

- all `read_file/3` and `write_file/3` functions on `RDF.Serialization` and the
  modules of RDF serialization formats can use streaming via the `:stream` flag
  option; for `read_file/3` and `write_file/3` it defaults to `false`, while for
  `read_file!/3` and `write_file!/3` it defaults to `true` when the respective
  format supports streams
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
- `RDF.Vocabulary.Namespace`s couldn't contain terms conflicting with functions
  from Elixirs Kernel module; most of them are supported now, while for the  
  remaining unsupported ones a proper error message is produced during compilation 


[Compare v0.9.0...v0.9.1](https://github.com/rdf-elixir/rdf-ex/compare/v0.9.0...v0.9.1)



## 0.9.0 - 2020-10-13

The API of the all three RDF datastructures `RDF.Dataset`, `RDF.Graph` and 
`RDF.Description` were changed, so that the functions taking input data consist only
of one field in order to open the possibility of introducing options on these 
functions. The supported ways with which RDF statements can be passed to the 
RDF data structures were extended and unified to be supported across all functions 
accepting input data. This includes also the way in which patterns for BGP queries
are specified. Also, the performance for adding data has been improved.

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
  vocabularies which use dots in the IRIs for further structuring (e.g. CIM-based formats like CGMES)
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

Elixir versions < 1.8 are no longer supported

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

Elixir versions < 1.6 are no longer supported

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
	for all numeric literals, e.g. arithmetic functions
- Various new `RDF.Datatype` function 
	- `RDF.Datatype.cast/1` for casting between `RDF.Literal`s  as specified in the 
		XSD spec on all `RDF.Datatype`s 
	- logical operators and the Effective Boolean Value (EBV) coercion algorithm 
		from the XPath and SPARQL specs on `RDF.Boolean`
	- various functions on the `RDF.DateTime` and `RDF.Time` datatypes
	- `RDF.LangString.match_language?/2`
- Many new convenience functions on the top-level `RDF` module 
	- constructors for all the supported `RDF.Datatype`s
	- constant functions `RDF.true` and `RDF.false` for the two boolean `RDF.Literal` values
- `RDF.Literal.Guards` which allow pattern matching of common literal datatypes
- `RDF.BlankNode.Generator`
- Possibility to configure an application-specific default base IRI; for now it 
  is used only on reading of RDF serializations (when no `base` specified)


### Changed

- `RDF.String.new/2` and `RDF.String.new!/2` produce a `rdf:langString` when 
  given a language tag
- Some of the defined structs now enforce keys at compile-time (via Elixirs 
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

- `Collectable` implementations for all `RDF.Data` structures, so they can be 
  used as destinations of `Enum.into` and `for` comprehensions
- `RDF.Quad` can be created from triple and `RDF.Triple` can be created from quad
- `RDF.Statement.map/2` which creates a statement with mapped nodes from another statement
- `RDF.Statement` functions to get the coerced components of a statement

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

Elixir versions < 1.4 are no longer supported

### Added

- full Turtle support
- `RDF.List` structure for the representation of RDF lists
- `describes?/1` on `RDF.Data` protocol and all RDF data structures which checks  
  if statements about a given resource exist
- `RDF.Data.descriptions/1` which returns all descriptions within an RDF data structure 
- `RDF.Description.first/2` which returns a single object to a predicate of a `RDF.Description`
- `RDF.Description.objects/2` now supports a custom filter function
- `RDF.bnode?/1` which checks if the given value is a blank node

### Changed

- Rename `RDF.Statement.convert*` functions to `RDF.Statement.coerce*`

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
