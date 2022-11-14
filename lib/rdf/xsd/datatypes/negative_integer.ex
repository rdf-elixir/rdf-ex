defmodule RDF.XSD.NegativeInteger do
  @moduledoc """
  `RDF.XSD.Datatype` for `xsd:negativeInteger`.

  See: <https://www.w3.org/TR/xmlschema11-2/#negativeInteger>
  """

  use RDF.XSD.Datatype.Restriction,
    name: "negativeInteger",
    id: RDF.Utils.Bootstrapping.xsd_iri("negativeInteger"),
    base: RDF.XSD.NonPositiveInteger

  def_facet_constraint RDF.XSD.Facets.MaxInclusive, -1
end
