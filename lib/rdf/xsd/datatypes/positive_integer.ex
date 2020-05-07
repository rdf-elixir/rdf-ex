defmodule RDF.XSD.PositiveInteger do
  use RDF.XSD.Datatype.Restriction,
    name: "positiveInteger",
    id: RDF.Utils.Bootstrapping.xsd_iri("positiveInteger"),
    base: RDF.XSD.NonNegativeInteger,
    register: false # core datatypes don't need to be registered

  def_facet_constraint RDF.XSD.Facets.MinInclusive, 1
end
