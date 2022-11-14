defmodule RDF.XSD.Int do
  @moduledoc """
  `RDF.XSD.Datatype` for `xsd:int`.

  See: <https://www.w3.org/TR/xmlschema11-2/#int>
  """

  use RDF.XSD.Datatype.Restriction,
    name: "int",
    id: RDF.Utils.Bootstrapping.xsd_iri("int"),
    base: RDF.XSD.Long

  def_facet_constraint RDF.XSD.Facets.MinInclusive, -2_147_483_648
  def_facet_constraint RDF.XSD.Facets.MaxInclusive, 2_147_483_647
end
