defmodule RDF.TestDatatypes do
  defmodule Age do
    use RDF.XSD.Datatype.Restriction,
        name: "age",
        id: "http://example.com/Age",
        base: RDF.XSD.PositiveInteger

    def_facet_constraint RDF.XSD.Facets.MaxInclusive, 150
  end
end
