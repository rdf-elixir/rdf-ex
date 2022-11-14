defmodule RDF.XSD.UnsignedShort do
  @moduledoc """
  `RDF.XSD.Datatype` for `xsd:unsignedShort`.

  See: <https://www.w3.org/TR/xmlschema11-2/#unsignedShort>
  """

  use RDF.XSD.Datatype.Restriction,
    name: "unsignedShort",
    id: RDF.Utils.Bootstrapping.xsd_iri("unsignedShort"),
    base: RDF.XSD.UnsignedInt

  def_facet_constraint RDF.XSD.Facets.MinInclusive, 0
  def_facet_constraint RDF.XSD.Facets.MaxInclusive, 65_535
end
