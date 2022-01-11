<img src="rdf-logo.png" align="right" />

# RDF.ex

[![CI](https://github.com/rdf-elixir/rdf-ex/workflows/CI/badge.svg?branch=master)](https://github.com/rdf-elixir/rdf-ex/actions?query=branch%3Amaster+workflow%3ACI)
[![Hex.pm](https://img.shields.io/hexpm/v/rdf.svg?style=flat-square)](https://hex.pm/packages/rdf)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/rdf/)
[![Total Download](https://img.shields.io/hexpm/dt/rdf.svg)](https://hex.pm/packages/rdf)
[![License](https://img.shields.io/hexpm/l/rdf.svg)](https://github.com/rdf-elixir/rdf-ex/blob/master/LICENSE.md)


An implementation of the [RDF](https://www.w3.org/TR/rdf11-primer/) data model in Elixir.

The API documentation can be found [here](https://hexdocs.pm/rdf/). For a guide and more information about RDF.ex and it's related projects, go to <https://rdf-elixir.dev>.

Migration guides for the various versions can be found in the [Wiki](https://github.com/rdf-elixir/rdf-ex/wiki).


## Features

- fully compatible with the RDF 1.1 specification
- support of the [RDF-star] extension
- in-memory data structures for RDF descriptions, RDF graphs and RDF datasets
- basic graph pattern matching against the in-memory data structures with streaming-support
- execution of [SPARQL] queries against the in-memory data structures with the [SPARQL.ex] package or against any SPARQL endpoint with the [SPARQL.Client] package
- RDF vocabularies as Elixir modules for safe, i.e. compile-time checked and concise usage of IRIs
- most of the important XML schema datatypes for RDF literals
- support for custom datatypes for RDF literals, incl. as derivations of XSD datatypes via facets 
- sigils for the most common types of nodes, i.e. IRIs, literals, blank nodes and lists
- a description DSL resembling Turtle in Elixir
- implementations for the [N-Triples], [N-Quads] and [Turtle] serialization formats (including the respective RDF-star extensions); [JSON-LD] and [RDF-XML] are available with the separate [JSON-LD.ex] and [RDF-XML.ex] packages
- validation of RDF data against [ShEx] schemas with the [ShEx.ex] package
- mapping of RDF data structures to Elixir structs and back with [Grax] 


## Contributing

There's still much to do for a complete RDF ecosystem for Elixir, which means there are plenty of opportunities to contribute. Here are some suggestions:

- more serialization formats, like [RDFa], [N3], [CSVW], [HDT] etc.
- more XSD datatypes
- improving the documentation

See [CONTRIBUTING](CONTRIBUTING.md) for details.


## Consulting

If you need help with your Elixir and Linked Data projects, just contact [NinjaConcept](https://www.ninjaconcept.com/) via <contact@ninjaconcept.com>.


## Acknowledgements

The development of this project was partly sponsored by [NetzeBW](https://www.netze-bw.de/) for [NETZlive](https://www.netze-bw.de/unsernetz/netzinnovationen/digitalisierung/netzlive).

[JetBrains](https://www.jetbrains.com/?from=RDF.ex) supports the project with complimentary access to its development environments.


## License and Copyright

(c) 2017-present Marcel Otto. MIT Licensed, see [LICENSE](LICENSE.md) for details.


[RDF.ex]:               https://hex.pm/packages/rdf
[JSON-LD.ex]:           https://hex.pm/packages/json_ld
[RDF-XML.ex]:           https://hex.pm/packages/rdf_xml
[SPARQL.ex]:            https://hex.pm/packages/sparql
[SPARQL.Client]:        https://hex.pm/packages/sparql_client
[ShEx.ex]:              https://hex.pm/packages/shex
[Grax]:                 https://hex.pm/packages/grax
[RDF-star]:             https://w3c.github.io/rdf-star/cg-spec
[N-Triples]:            https://www.w3.org/TR/n-triples/
[N-Quads]:              https://www.w3.org/TR/n-quads/
[Turtle]:               https://www.w3.org/TR/turtle/
[N3]:                   https://www.w3.org/TeamSubmission/n3/
[JSON-LD]:              https://www.w3.org/TR/json-ld/
[RDFa]:                 https://www.w3.org/TR/rdfa-syntax/
[RDF-XML]:              https://www.w3.org/TR/rdf-syntax-grammar/
[CSVW]:                 https://www.w3.org/TR/tabular-data-model/
[HDT]:                  http://www.rdfhdt.org/
[SPARQL]:               https://www.w3.org/TR/sparql11-overview/
[ShEx]:                 https://shex.io/
