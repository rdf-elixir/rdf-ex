defmodule RDF.XSD.Facets.ExplicitTimezone do
  @type t :: :required | :prohibited | :optional

  use RDF.XSD.Facet, name: :explicit_timezone, type: t
end
