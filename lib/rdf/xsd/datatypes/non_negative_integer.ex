defmodule RDF.XSD.NonNegativeInteger do
  @moduledoc """
  `RDF.XSD.Datatype` for `xsd:nonNegativeInteger`.

  See: <https://www.w3.org/TR/xmlschema11-2/#nonNegativeInteger>
  """

  use RDF.XSD.Datatype.Restriction,
    name: "nonNegativeInteger",
    id: RDF.Utils.Bootstrapping.xsd_iri("nonNegativeInteger"),
    base: RDF.XSD.Integer

  def_facet_constraint RDF.XSD.Facets.MinInclusive, 0
end
