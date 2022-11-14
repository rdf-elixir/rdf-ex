defmodule RDF.XSD.PositiveInteger do
  @moduledoc """
  `RDF.XSD.Datatype` for `xsd:positiveInteger`.

  See: <https://www.w3.org/TR/xmlschema11-2/#positiveInteger>
  """

  use RDF.XSD.Datatype.Restriction,
    name: "positiveInteger",
    id: RDF.Utils.Bootstrapping.xsd_iri("positiveInteger"),
    base: RDF.XSD.NonNegativeInteger

  def_facet_constraint RDF.XSD.Facets.MinInclusive, 1
end
