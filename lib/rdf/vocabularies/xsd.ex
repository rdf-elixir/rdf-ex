defmodule RDF.XSD do
  @moduledoc """
  The XML Schema datatypes vocabulary.

  See <https://www.w3.org/TR/xmlschema11-2/>
  """

  # TODO: This should be a strict vocabulary and loaded from a file.
  use RDF.Vocabulary, base_uri: "http://www.w3.org/2001/XMLSchema#"

  defuri :string
    defuri :normalizedString
      defuri :token
        defuri :language
        defuri :Name
          defuri :NCName
            defuri :ID
            defuri :IDREF
              defuri :IDREFS
            defuri :ENTITY
              defuri :ENTITIES
        defuri :NMTOKEN
          defuri :NMTOKENS
  defuri :boolean
  defuri :float
  defuri :double
  defuri :decimal
    defuri :integer
      defuri :long
        defuri :int
          defuri :short
            defuri :byte
      defuri :nonPositiveInteger
        defuri :negativeInteger
      defuri :nonNegativeInteger
        defuri :positiveInteger
        defuri :unsignedLong
          defuri :unsignedInt
            defuri :unsignedShort
              defuri :unsignedByte
  defuri :duration
  defuri :dateTime
  defuri :time
  defuri :date
  defuri :gYearMonth
  defuri :gYear
  defuri :gMonthDay
  defuri :gDay
  defuri :gMonth
  defuri :base64Binary
  defuri :hexBinary
  defuri :anyURI
  defuri :QName
  defuri :NOTATION
end
