defmodule RDF.XSD.UnsignedByte do
  @moduledoc """
  `RDF.XSD.Datatype` for `xsd:unsignedByte`.

  See: <https://www.w3.org/TR/xmlschema11-2/#unsignedByte>
  """

  use RDF.XSD.Datatype.Restriction,
    name: "unsignedByte",
    id: RDF.Utils.Bootstrapping.xsd_iri("unsignedByte"),
    base: RDF.XSD.UnsignedShort

  def_facet_constraint RDF.XSD.Facets.MinInclusive, 0
  def_facet_constraint RDF.XSD.Facets.MaxInclusive, 255
end
