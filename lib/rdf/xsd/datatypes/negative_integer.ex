defmodule RDF.XSD.NegativeInteger do
  use RDF.XSD.Datatype.Restriction,
    name: "negativeInteger",
    id: RDF.Utils.Bootstrapping.xsd_iri("negativeInteger"),
    base: RDF.XSD.NonPositiveInteger,
    register: false # core datatypes don't need to be registered

  def_facet_constraint RDF.XSD.Facets.MaxInclusive, -1
end
