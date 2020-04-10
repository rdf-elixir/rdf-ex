defmodule RDF.Literal.Datatype.NS do
  @moduledoc !"""
  Since the capability of RDF.Vocabulary.Namespaces requires the compilation
  of the RDF.NTriples.Decoder and the RDF.NTriples.Decoder depends on RDF.Literals,
  we can't define the XSD namespace in RDF.NS.

  TODO: This is no longer the case. Why can't we remove it resp. move it to RDF.NS now?
  """

  use RDF.Vocabulary.Namespace

  @vocabdoc false
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
