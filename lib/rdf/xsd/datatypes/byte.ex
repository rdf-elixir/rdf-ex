defmodule RDF.XSD.Byte do
  use RDF.XSD.Datatype.Restriction,
    name: "byte",
    id: RDF.Utils.Bootstrapping.xsd_iri("byte"),
    base: RDF.XSD.Short

  def_facet_constraint RDF.XSD.Facets.MinInclusive, -128
  def_facet_constraint RDF.XSD.Facets.MaxInclusive, 127
end
