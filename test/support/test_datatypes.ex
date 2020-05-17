defmodule RDF.TestDatatypes do
  defmodule Age do
    use RDF.XSD.Datatype.Restriction,
        name: "age",
        id: "http://example.com/Age",
        base: RDF.XSD.PositiveInteger

    def_facet_constraint RDF.XSD.Facets.MaxInclusive, 150
  end

  defmodule DecimalUnitInterval do
    use RDF.XSD.Datatype.Restriction,
        name: "decimal_unit_interval",
        id: "http://example.com/decimalUnitInterval",
        base: RDF.XSD.Decimal

    def_facet_constraint RDF.XSD.Facets.MinInclusive, 0
    def_facet_constraint RDF.XSD.Facets.MaxInclusive, 1
  end

  defmodule DoubleUnitInterval do
    use RDF.XSD.Datatype.Restriction,
        name: "double_unit_interval",
        id: "http://example.com/doubleUnitInterval",
        base: RDF.XSD.Double

    def_facet_constraint RDF.XSD.Facets.MinInclusive, 0
    def_facet_constraint RDF.XSD.Facets.MaxInclusive, 1
  end

  defmodule FloatUnitInterval do
    use RDF.XSD.Datatype.Restriction,
        name: "float_unit_interval",
        id: "http://example.com/floatUnitInterval",
        base: RDF.XSD.Float

    def_facet_constraint RDF.XSD.Facets.MinInclusive, 0
    def_facet_constraint RDF.XSD.Facets.MaxInclusive, 1
  end
end
