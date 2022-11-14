defmodule RDF.XSD.Short do
  @moduledoc """
  `RDF.XSD.Datatype` for `xsd:short`.

  See: <https://www.w3.org/TR/xmlschema11-2/#short>
  """

  use RDF.XSD.Datatype.Restriction,
    name: "short",
    id: RDF.Utils.Bootstrapping.xsd_iri("short"),
    base: RDF.XSD.Int

  def_facet_constraint RDF.XSD.Facets.MinInclusive, -32_768
  def_facet_constraint RDF.XSD.Facets.MaxInclusive, 32_767
end
