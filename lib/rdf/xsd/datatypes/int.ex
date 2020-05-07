defmodule RDF.XSD.Int do
  use RDF.XSD.Datatype.Restriction,
    name: "int",
    id: RDF.Utils.Bootstrapping.xsd_iri("int"),
    base: RDF.XSD.Long,
    register: false # core datatypes don't need to be registered

  def_facet_constraint RDF.XSD.Facets.MinInclusive, -2_147_483_648
  def_facet_constraint RDF.XSD.Facets.MaxInclusive, 2_147_483_647
end
