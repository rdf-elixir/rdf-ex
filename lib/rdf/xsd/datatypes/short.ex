defmodule RDF.XSD.Short do
  use RDF.XSD.Datatype.Restriction,
    name: "short",
    id: RDF.Utils.Bootstrapping.xsd_iri("short"),
    base: RDF.XSD.Int,
    register: false # core datatypes don't need to be registered

  def_facet_constraint RDF.XSD.Facets.MinInclusive, -32768
  def_facet_constraint RDF.XSD.Facets.MaxInclusive, 32767
end
