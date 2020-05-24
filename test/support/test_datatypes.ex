defmodule RDF.TestDatatypes do
  defmodule Initials do
    use RDF.XSD.Datatype.Restriction,
        name: "initials",
        id: "http://example.com/initials",
        base: RDF.XSD.String

    def_facet_constraint RDF.XSD.Facets.Length, 2
  end

  defmodule UsZipcode do
    use RDF.XSD.Datatype.Restriction,
        name: "us_zipcode",
        id: "http://example.com/us-zipcode",
        base: RDF.XSD.String

    def_facet_constraint RDF.XSD.Facets.Pattern, "[0-9]{5}(-[0-9]{4})?"
  end

  defmodule AltUsZipcode do
    use RDF.XSD.Datatype.Restriction,
        name: "alt_us_zipcode",
        id: "http://example.com/alt-us-zipcode",
        base: RDF.XSD.String

    def_facet_constraint RDF.XSD.Facets.Pattern, [
      "[0-9]{5}",
      "[0-9]{5}-[0-9]{4}",
    ]
  end

  defmodule Age do
    use RDF.XSD.Datatype.Restriction,
        name: "age",
        id: "http://example.com/Age",
        base: RDF.XSD.PositiveInteger

    def_facet_constraint RDF.XSD.Facets.MaxInclusive, 150

    @impl RDF.XSD.Datatype
    def canonical_mapping(value), do: "#{value} years"
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

  defmodule DateTimeWithTz do
    use RDF.XSD.Datatype.Restriction,
        name: "datetime_with_tz",
        id: "http://example.com/datetime-with-tz",
        base: RDF.XSD.DateTime

    def_facet_constraint RDF.XSD.Facets.ExplicitTimezone, :required
  end

  defmodule DateWithoutTz do
    use RDF.XSD.Datatype.Restriction,
        name: "date_with_tz",
        id: "http://example.com/date-with-tz",
        base: RDF.XSD.Date

    def_facet_constraint RDF.XSD.Facets.ExplicitTimezone, :prohibited
  end

  defmodule CustomTime do
    use RDF.XSD.Datatype.Restriction,
        name: "time_with_tz",
        id: "http://example.com/time-with-tz",
        base: RDF.XSD.Time

    def_facet_constraint RDF.XSD.Facets.ExplicitTimezone, :optional
  end
end
