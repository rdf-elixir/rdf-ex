import RDF.Sigils
import RDF.Guards

require RDF.Graph

alias RDF.NS
alias RDF.NS.{RDFS, OWL, SKOS}

alias RDF.{
  Term,
  IRI,
  BlankNode,
  Literal,
  XSD,

  Triple,
  Quad,
  Statement,

  Description,
  Graph,
  Dataset,

  PrefixMap,
  PropertyMap
}

alias RDF.BlankNode, as: BNode

alias RDF.{NTriples, NQuads, Turtle}

alias Decimal, as: D

defmodule Test do
  use RDF.Vocabulary.Namespace
  defvocab EX, base_iri: "http://example.com/", terms: [], strict: false
end

alias Test.EX
