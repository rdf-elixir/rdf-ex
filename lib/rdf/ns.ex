defmodule RDF.NS do
  @moduledoc """
  `RDF.Namespace`s for fundamental RDF vocabularies.

  Namely:

  - `RDF.NS.RDF`
  - `RDF.NS.RDFS`
  - `RDF.NS.OWL`
  - `RDF.NS.SKOS`
  - `RDF.NS.XSD`
  """

  use RDF.Vocabulary.Namespace

  @vocabdoc """
  The XML Schema datatypes vocabulary.

  See <https://www.w3.org/TR/xmlschema11-2/>
  """
  defvocab XSD,
    base_iri: "http://www.w3.org/2001/XMLSchema#",
    terms:    RDF.Datatype.NS.XSD.__terms__

  @vocabdoc """
  The RDF vocabulary.

  See <https://www.w3.org/TR/rdf11-concepts/>
  """
  defvocab RDF,
    base_iri: "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
    file: "rdf.ttl",
    alias: [
      Nil:        "nil",
      LangString: "langString"
    ]

  @vocabdoc """
  The RDFS vocabulary.

  See <https://www.w3.org/TR/rdf-schema/>
  """
  defvocab RDFS,
    base_iri: "http://www.w3.org/2000/01/rdf-schema#",
    file: "rdfs.ttl"

  @vocabdoc """
  The OWL vocabulary.

  See <https://www.w3.org/TR/owl-overview/>
  """
  defvocab OWL,
    base_iri: "http://www.w3.org/2002/07/owl#",
    file: "owl.ttl"

  @vocabdoc """
  The SKOS vocabulary.

  See <http://www.w3.org/TR/skos-reference/>
  """
  defvocab SKOS,
    base_iri: "http://www.w3.org/2004/02/skos/core#",
    file: "skos.ttl"

end
