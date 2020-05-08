defmodule RDF.XSD.UnsignedShort do
  use RDF.XSD.Datatype.Restriction,
    name: "unsignedShort",
    id: RDF.Utils.Bootstrapping.xsd_iri("unsignedShort"),
    base: RDF.XSD.UnsignedInt

  def_facet_constraint RDF.XSD.Facets.MinInclusive, 0
  def_facet_constraint RDF.XSD.Facets.MaxInclusive, 65535
end
