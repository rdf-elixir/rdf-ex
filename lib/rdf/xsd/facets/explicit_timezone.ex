defmodule RDF.XSD.Facets.ExplicitTimezone do
  @moduledoc """
  `RDF.XSD.Facet` for `explicitTimezone`.

  `explicitTimezone` is a three-valued facet which can can be used to require
  or prohibit the time zone offset in date/time datatypes.

  see <https://www.w3.org/TR/xmlschema11-2/datatypes.html#rf-explicitTimezone>
  """

  @type t :: :required | :prohibited | :optional

  use RDF.XSD.Facet, name: :explicit_timezone, type: t
end
