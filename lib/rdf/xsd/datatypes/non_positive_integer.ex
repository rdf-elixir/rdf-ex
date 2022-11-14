defmodule RDF.XSD.NonPositiveInteger do
  @moduledoc """
  `RDF.XSD.Datatype` for `xsd:nonPositiveInteger`.

  See: <https://www.w3.org/TR/xmlschema11-2/#nonPositiveInteger>
  """

  use RDF.XSD.Datatype.Restriction,
    name: "nonPositiveInteger",
    id: RDF.Utils.Bootstrapping.xsd_iri("nonPositiveInteger"),
    base: RDF.XSD.Integer

  def_facet_constraint RDF.XSD.Facets.MaxInclusive, 0
end
