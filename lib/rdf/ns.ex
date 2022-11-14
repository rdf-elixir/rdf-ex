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

  # This is needed to ensure that the Turtle compiler is compiled and ready to be used to parse vocabularies.
  # Without this we randomly get "unable to detect serialization format" errors depending on the parallel compilation order.
  require RDF.Turtle

  @vocabdoc """
  The RDF vocabulary.

  Since this module has the same basename as the top-level module, you can't
  alias it. Therefore, the top-level `RDF` module has delegators for all of the
  property functions in this module, so you can use them directly on the
  top-level module without an alias.

  See <https://www.w3.org/TR/rdf11-concepts/>
  """
  defvocab RDF,
    base_iri: "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
    file: "rdf.ttl",
    alias: [
      Nil: "nil",
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

  @vocabdoc """
  The XML Schema datatypes vocabulary.

  See <https://www.w3.org/TR/xmlschema11-2/>
  """
  defvocab XSD,
    base_iri: "http://www.w3.org/2001/XMLSchema#",
    terms: ~w[
      string
        normalizedString
          token
            language
            Name
              NCName
                ID
                IDREF
                  IDREFS
                ENTITY
                  ENTITIES
            NMTOKEN
              NMTOKENS
      boolean
      float
      double
      decimal
        integer
          long
            int
              short
                byte
          nonPositiveInteger
            negativeInteger
          nonNegativeInteger
            positiveInteger
            unsignedLong
              unsignedInt
                unsignedShort
                  unsignedByte
      duration
       dayTimeDuration
       yearMonthDuration
      dateTime
      time
      date
      gYearMonth
      gYear
      gMonthDay
      gDay
      gMonth
      base64Binary
      hexBinary
      anyURI
      QName
      NOTATION
    ]
end
