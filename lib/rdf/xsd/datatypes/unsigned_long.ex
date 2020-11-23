defmodule RDF.XSD.UnsignedLong do
  use RDF.XSD.Datatype.Restriction,
    name: "unsignedLong",
    id: RDF.Utils.Bootstrapping.xsd_iri("unsignedLong"),
    base: RDF.XSD.NonNegativeInteger

  def_facet_constraint RDF.XSD.Facets.MinInclusive, 0
  def_facet_constraint RDF.XSD.Facets.MaxInclusive, 18_446_744_073_709_551_615
end
