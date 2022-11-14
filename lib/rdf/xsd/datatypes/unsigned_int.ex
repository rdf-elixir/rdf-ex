defmodule RDF.XSD.UnsignedInt do
  @moduledoc """
  `RDF.XSD.Datatype` for `xsd:unsignedInt`.

  See: <https://www.w3.org/TR/xmlschema11-2/#unsignedInt>
  """

  use RDF.XSD.Datatype.Restriction,
    name: "unsignedInt",
    id: RDF.Utils.Bootstrapping.xsd_iri("unsignedInt"),
    base: RDF.XSD.UnsignedLong

  def_facet_constraint RDF.XSD.Facets.MinInclusive, 0
  def_facet_constraint RDF.XSD.Facets.MaxInclusive, 4_294_967_295
end
