defmodule RDF.XSD.UnsignedByte do
  use RDF.XSD.Datatype.Restriction,
    name: "unsignedByte",
    id: RDF.Utils.Bootstrapping.xsd_iri("unsignedByte"),
    base: RDF.XSD.UnsignedShort,
    register: false # core datatypes don't need to be registered

  def_facet_constraint RDF.XSD.Facets.MinInclusive, 0
  def_facet_constraint RDF.XSD.Facets.MaxInclusive, 255
end
