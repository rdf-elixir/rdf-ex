defmodule RDF.XSD.Long do
  use RDF.XSD.Datatype.Restriction,
    name: "long",
    id: RDF.Utils.Bootstrapping.xsd_iri("long"),
    base: RDF.XSD.Integer,
    register: false # core datatypes don't need to be registered

  def_facet_constraint RDF.XSD.Facets.MinInclusive, -9_223_372_036_854_775_808
  def_facet_constraint RDF.XSD.Facets.MaxInclusive, 9_223_372_036_854_775_807
end
