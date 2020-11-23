defmodule RDF.XSD.PositiveIntegerTest do
  use RDF.XSD.Datatype.Test.Case,
    datatype: RDF.XSD.PositiveInteger,
    name: "positiveInteger",
    base: RDF.XSD.NonNegativeInteger,
    base_primitive: RDF.XSD.Integer,
    comparable_datatypes: [RDF.XSD.Decimal, RDF.XSD.Double],
    applicable_facets: [
      RDF.XSD.Facets.MinInclusive,
      RDF.XSD.Facets.MaxInclusive,
      RDF.XSD.Facets.MinExclusive,
      RDF.XSD.Facets.MaxExclusive,
      RDF.XSD.Facets.TotalDigits,
      RDF.XSD.Facets.Pattern
    ],
    facets: %{
      min_inclusive: 1,
      max_inclusive: nil,
      min_exclusive: nil,
      max_exclusive: nil,
      total_digits: nil,
      pattern: nil
    },
    valid: RDF.XSD.TestData.valid_positive_integers(),
    invalid: RDF.XSD.TestData.invalid_positive_integers()

  describe "cast/1" do
    test "casting a positive_integer returns the input as it is" do
      assert XSD.positive_integer(1) |> XSD.PositiveInteger.cast() ==
               XSD.positive_integer(1)

      assert XSD.positive_integer(1) |> XSD.PositiveInteger.cast() ==
               XSD.positive_integer(1)
    end

    test "casting an integer with a value from the value space of positive_integer" do
      assert XSD.integer(1) |> XSD.PositiveInteger.cast() ==
               XSD.positive_integer(1)
    end

    test "casting an integer with a value not from the value space of positive_integer" do
      assert XSD.integer(-1) |> XSD.PositiveInteger.cast() == nil
      assert XSD.non_negative_integer(0) |> XSD.PositiveInteger.cast() == nil
    end

    test "casting a positive_integer" do
      assert XSD.positive_integer(1) |> XSD.PositiveInteger.cast() ==
               XSD.positive_integer(1)
    end

    test "casting a boolean" do
      assert XSD.true() |> XSD.PositiveInteger.cast() == XSD.positive_integer(1)
    end

    test "casting a string with a value from the lexical value space of xsd:integer" do
      assert XSD.string("1") |> XSD.PositiveInteger.cast() == XSD.positive_integer(1)
      assert XSD.string("042") |> XSD.PositiveInteger.cast() == XSD.positive_integer(42)
      assert XSD.string("0") |> XSD.PositiveInteger.cast() == nil
    end

    test "casting a string with a value not in the lexical value space of xsd:integer" do
      assert XSD.string("foo") |> XSD.PositiveInteger.cast() == nil
      assert XSD.string("3.14") |> XSD.PositiveInteger.cast() == nil
    end

    test "casting an decimal" do
      assert XSD.decimal(1.0) |> XSD.PositiveInteger.cast() == XSD.positive_integer(1)
      assert XSD.decimal(3.14) |> XSD.PositiveInteger.cast() == XSD.positive_integer(3)
      assert XSD.decimal(0) |> XSD.PositiveInteger.cast() == nil
    end

    test "casting a double" do
      assert XSD.double(1) |> XSD.PositiveInteger.cast() == XSD.positive_integer(1)
      assert XSD.double(1.0) |> XSD.PositiveInteger.cast() == XSD.positive_integer(1)
      assert XSD.double(1.1) |> XSD.PositiveInteger.cast() == XSD.positive_integer(1)
      assert XSD.double("+1") |> XSD.PositiveInteger.cast() == XSD.positive_integer(1)
      assert XSD.double("+1.0") |> XSD.PositiveInteger.cast() == XSD.positive_integer(1)
      assert XSD.double("1.0E0") |> XSD.PositiveInteger.cast() == XSD.positive_integer(1)
      assert XSD.double(3.14) |> XSD.PositiveInteger.cast() == XSD.positive_integer(3)

      assert XSD.double("NAN") |> XSD.PositiveInteger.cast() == nil
      assert XSD.double("+INF") |> XSD.PositiveInteger.cast() == nil
      assert XSD.double(0) |> XSD.PositiveInteger.cast() == nil
      assert XSD.double(0.0) |> XSD.PositiveInteger.cast() == nil
      assert XSD.double(0.1) |> XSD.PositiveInteger.cast() == nil
      assert XSD.double("+0") |> XSD.PositiveInteger.cast() == nil
      assert XSD.double("+0.0") |> XSD.PositiveInteger.cast() == nil
      assert XSD.double("-0.0") |> XSD.PositiveInteger.cast() == nil
      assert XSD.double("0.0E0") |> XSD.PositiveInteger.cast() == nil
      assert XSD.double("-1.0") |> XSD.PositiveInteger.cast() == nil
    end

    test "casting a float" do
      assert XSD.float(1) |> XSD.PositiveInteger.cast() == XSD.positive_integer(1)
      assert XSD.float(1.0) |> XSD.PositiveInteger.cast() == XSD.positive_integer(1)
      assert XSD.float(1.1) |> XSD.PositiveInteger.cast() == XSD.positive_integer(1)
      assert XSD.float("+1") |> XSD.PositiveInteger.cast() == XSD.positive_integer(1)
      assert XSD.float("+1.0") |> XSD.PositiveInteger.cast() == XSD.positive_integer(1)
      assert XSD.float("1.0E0") |> XSD.PositiveInteger.cast() == XSD.positive_integer(1)
      assert XSD.float(3.14) |> XSD.PositiveInteger.cast() == XSD.positive_integer(3)

      assert XSD.float("NAN") |> XSD.PositiveInteger.cast() == nil
      assert XSD.float("+INF") |> XSD.PositiveInteger.cast() == nil
      assert XSD.float(0) |> XSD.PositiveInteger.cast() == nil
      assert XSD.float(0.0) |> XSD.PositiveInteger.cast() == nil
      assert XSD.float(0.1) |> XSD.PositiveInteger.cast() == nil
      assert XSD.float("+0") |> XSD.PositiveInteger.cast() == nil
      assert XSD.float("+0.0") |> XSD.PositiveInteger.cast() == nil
      assert XSD.float("-0.0") |> XSD.PositiveInteger.cast() == nil
      assert XSD.float("0.0E0") |> XSD.PositiveInteger.cast() == nil
      assert XSD.float("-1.0") |> XSD.PositiveInteger.cast() == nil
    end

    test "with invalid literals" do
      assert XSD.positive_integer(3.14) |> XSD.PositiveInteger.cast() == nil
      assert XSD.positive_integer(0) |> XSD.PositiveInteger.cast() == nil
      assert XSD.decimal("NAN") |> XSD.PositiveInteger.cast() == nil
      assert XSD.double(true) |> XSD.PositiveInteger.cast() == nil
    end

    test "with literals of unsupported datatypes" do
      assert XSD.date("2020-01-01") |> XSD.PositiveInteger.cast() == nil
    end
  end
end
