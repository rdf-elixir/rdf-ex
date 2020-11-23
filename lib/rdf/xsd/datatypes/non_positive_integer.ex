defmodule RDF.XSD.NonPositiveInteger do
  use RDF.XSD.Datatype.Restriction,
    name: "nonPositiveInteger",
    id: RDF.Utils.Bootstrapping.xsd_iri("nonPositiveInteger"),
    base: RDF.XSD.Integer

  def_facet_constraint RDF.XSD.Facets.MaxInclusive, 0
end
