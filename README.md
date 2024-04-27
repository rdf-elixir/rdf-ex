<img src="rdf-logo.png" align="right" />

# RDF.ex

[![Hex.pm](https://img.shields.io/hexpm/v/rdf.svg?style=flat-square)](https://hex.pm/packages/rdf)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/rdf/)
[![Total Download](https://img.shields.io/hexpm/dt/rdf.svg)](https://hex.pm/packages/rdf)
[![License](https://img.shields.io/hexpm/l/rdf.svg)](https://github.com/rdf-elixir/rdf-ex/blob/master/LICENSE.md)

[![ExUnit Tests](https://github.com/rdf-elixir/rdf-ex/actions/workflows/elixir-build-and-test.yml/badge.svg)](https://github.com/rdf-elixir/rdf-ex/actions/workflows/elixir-build-and-test.yml)
[![Dialyzer](https://github.com/rdf-elixir/rdf-ex/actions/workflows/elixir-dialyzer.yml/badge.svg)](https://github.com/rdf-elixir/rdf-ex/actions/workflows/elixir-dialyzer.yml)
[![Quality Checks](https://github.com/rdf-elixir/rdf-ex/actions/workflows/elixir-quality-checks.yml/badge.svg)](https://github.com/rdf-elixir/rdf-ex/actions/workflows/elixir-quality-checks.yml)


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
- a DSL resembling Turtle to build RDF descriptions or full RDF graphs in Elixir
- implementations for the [N-Triples], [N-Quads], [Turtle] and [TriG] serialization formats (including the respective RDF-star extensions); [JSON-LD] and [RDF-XML] are available with the separate [JSON-LD.ex] and [RDF-XML.ex] packages
- implementation of the [RDF Dataset Canonicalization] algorithm  
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

<table style="border: 0;">
<tr>
<td><a href="https://www.netze-bw.de/"><img src="https://iconape.com/wp-content/png_logo_vector/netze-bw-logo.png" alt="NetzeBW Logo" height="150"></a></td>
<td><a href="https://nlnet.nl/"><img src="https://nlnet.nl/logo/banner.svg" alt="NLnet Foundation Logo" width="150"></a></td>
<td><a href="https://www.jetbrains.com/?from=RDF.ex"><img src="https://resources.jetbrains.com/storage/products/company/brand/logos/jb_beam.svg" alt="JetBrains Logo" height="150"></a></td>
</tr>
</table>

The development of this project was partly sponsored by [NetzeBW](https://www.netze-bw.de/) for [NETZlive](https://www.netze-bw.de/unsernetz/netzinnovationen/digitalisierung/netzlive) and the [NLnet foundation](https://nlnet.nl/) as part of the funding of [K-Gen](https://nlnet.nl/project/K-Gen/).

[JetBrains](https://www.jetbrains.com/?from=RDF.ex) supports the project with complimentary access to its development environments.


## License and Copyright

(c) 2016-present Marcel Otto. MIT Licensed, see [LICENSE](LICENSE.md) for details.


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
[TriG]:                 https://www.w3.org/TR/trig/
[N3]:                   https://www.w3.org/TeamSubmission/n3/
[JSON-LD]:              https://www.w3.org/TR/json-ld/
[RDFa]:                 https://www.w3.org/TR/rdfa-syntax/
[RDF-XML]:              https://www.w3.org/TR/rdf-syntax-grammar/
[CSVW]:                 https://www.w3.org/TR/tabular-data-model/
[HDT]:                  http://www.rdfhdt.org/
[SPARQL]:               https://www.w3.org/TR/sparql11-overview/
[ShEx]:                 https://shex.io/
[RDF Dataset Canonicalization]: https://www.w3.org/TR/rdf-canon/
