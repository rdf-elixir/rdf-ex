defmodule RDF.XSD.DoubleTest do
  use RDF.XSD.Datatype.Test.Case,
    datatype: RDF.XSD.Double,
    name: "double",
    primitive: true,
    comparable_datatypes: [RDF.XSD.Integer, RDF.XSD.Decimal],
    applicable_facets: [
      RDF.XSD.Facets.MinInclusive,
      RDF.XSD.Facets.MaxInclusive,
      RDF.XSD.Facets.MinExclusive,
      RDF.XSD.Facets.MaxExclusive,
    ],
    facets: %{
      min_inclusive: nil,
      max_inclusive: nil,
      min_exclusive: nil,
      max_exclusive: nil
    },
    valid: RDF.XSD.TestData.valid_floats(),
    invalid: RDF.XSD.TestData.invalid_floats()

  describe "cast/1" do
    test "casting a double returns the input as it is" do
      assert XSD.double(3.14) |> XSD.Double.cast() == XSD.double(3.14)
      assert XSD.double("NAN") |> XSD.Double.cast() == XSD.double("NAN")
      assert XSD.double("-INF") |> XSD.Double.cast() == XSD.double("-INF")
    end

    test "casting a boolean" do
      assert XSD.true() |> XSD.Double.cast() == XSD.double(1.0)
      assert XSD.false() |> XSD.Double.cast() == XSD.double(0.0)
    end

    test "casting a string with a value from the lexical value space of xsd:double" do
      assert XSD.string("1.0") |> XSD.Double.cast() == XSD.double("1.0E0")
      assert XSD.string("3.14") |> XSD.Double.cast() == XSD.double("3.14E0")
      assert XSD.string("3.14E0") |> XSD.Double.cast() == XSD.double("3.14E0")
    end

    test "casting a string with a value not in the lexical value space of xsd:double" do
      assert XSD.string("foo") |> XSD.Double.cast() == nil
    end

    test "casting an integer" do
      assert XSD.integer(0) |> XSD.Double.cast() == XSD.double(0.0)
      assert XSD.integer(42) |> XSD.Double.cast() == XSD.double(42.0)
    end

    test "casting a decimal" do
      assert XSD.decimal(0) |> XSD.Double.cast() == XSD.double(0)
      assert XSD.decimal(1) |> XSD.Double.cast() == XSD.double(1)
      assert XSD.decimal(3.14) |> XSD.Double.cast() == XSD.double(3.14)
    end

    test "casting a float" do
      assert XSD.float(0) |> XSD.Double.cast() == XSD.double(0)
      assert XSD.float(1) |> XSD.Double.cast() == XSD.double(1)
      assert XSD.float(3.14) |> XSD.Double.cast() == XSD.double(3.14)
    end

    test "from derived types of xsd:double" do
      assert DoubleUnitInterval.new(0.14) |> XSD.Double.cast() == XSD.double(0.14)
      assert FloatUnitInterval.new(1.0) |> XSD.Double.cast() == XSD.double(1.0)
    end

    test "from derived types of the castable datatypes" do
      assert DecimalUnitInterval.new(0.14) |> XSD.Double.cast() == XSD.double(0.14)
      assert Age.new(42) |> XSD.Double.cast() == XSD.double(42)
    end

    test "with invalid literals" do
      assert XSD.boolean("42") |> XSD.Double.cast() == nil
      assert XSD.integer(3.14) |> XSD.Double.cast() == nil
      assert XSD.decimal("NAN") |> XSD.Double.cast() == nil
      assert XSD.double(true) |> XSD.Double.cast() == nil
    end

    test "with literals of unsupported datatypes" do
      assert XSD.date("2020-01-01") |> XSD.Double.cast() == nil
    end
  end
end
