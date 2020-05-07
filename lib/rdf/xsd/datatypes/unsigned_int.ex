defmodule RDF.XSD.UnsignedInt do
  use RDF.XSD.Datatype.Restriction,
    name: "unsignedInt",
    id: RDF.Utils.Bootstrapping.xsd_iri("unsignedInt"),
    base: RDF.XSD.UnsignedLong,
    register: false # core datatypes don't need to be registered

  def_facet_constraint RDF.XSD.Facets.MinInclusive, 0
  def_facet_constraint RDF.XSD.Facets.MaxInclusive, 4_294_967_295
end
