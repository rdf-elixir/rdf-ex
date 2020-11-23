defmodule RDF.XSD.NonNegativeInteger do
  use RDF.XSD.Datatype.Restriction,
    name: "nonNegativeInteger",
    id: RDF.Utils.Bootstrapping.xsd_iri("nonNegativeInteger"),
    base: RDF.XSD.Integer

  def_facet_constraint RDF.XSD.Facets.MinInclusive, 0
end
