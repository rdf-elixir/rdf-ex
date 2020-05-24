defmodule RDF.XSD.IntegerTest do
  use RDF.XSD.Datatype.Test.Case,
    datatype: RDF.XSD.Integer,
    name: "integer",
    primitive: true,
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
      min_inclusive: nil,
      max_inclusive: nil,
      min_exclusive: nil,
      max_exclusive: nil,
      total_digits: nil,
      pattern: nil
    },
    valid: RDF.XSD.TestData.valid_integers(),
    invalid: RDF.XSD.TestData.invalid_integers()

  alias RDF.TestDatatypes.Age

  describe "value/1" do
    test "with a derived datatype" do
      assert XSD.byte(42) |> XSD.Integer.value() == 42
      assert Age.new(42) |> XSD.Integer.value() == 42
    end

    test "with another datatype" do
      assert_raise RDF.XSD.Datatype.Mismatch, "'#{inspect(XSD.decimal(42).literal)}' is not a #{XSD.Integer}", fn ->
        XSD.decimal(42) |> XSD.Integer.value()
      end
    end

    test "with a non-literal" do
      assert_raise RDF.XSD.Datatype.Mismatch, "'42' is not a #{XSD.Integer}", fn ->
         XSD.Integer.value(42)
      end
    end
  end

  describe "valid?/1" do
    test "with a derived datatype" do
      assert XSD.byte(42) |> XSD.Integer.valid?() == true
      assert Age.new(42) |> XSD.Integer.valid?() == true
      assert Age.new(200) |> XSD.Integer.valid?() == false
    end

    test "with another datatype" do
      assert XSD.decimal(42) |> XSD.Integer.valid?() == false
    end

    test "with a non-literal" do
      assert XSD.Integer.valid?(42) == false
    end
  end

  describe "cast/1" do
    test "casting an integer returns the input as it is" do
      assert XSD.integer(0) |> XSD.Integer.cast() == XSD.integer(0)
      assert XSD.integer(1) |> XSD.Integer.cast() == XSD.integer(1)
    end

    test "casting a boolean" do
      assert XSD.false() |> XSD.Integer.cast() == XSD.integer(0)
      assert XSD.true() |> XSD.Integer.cast() == XSD.integer(1)
    end

    test "casting a string with a value from the lexical value space of xsd:integer" do
      assert XSD.string("0") |> XSD.Integer.cast() == XSD.integer(0)
      assert XSD.string("042") |> XSD.Integer.cast() == XSD.integer(42)
    end

    test "casting a string with a value not in the lexical value space of xsd:integer" do
      assert XSD.string("foo") |> XSD.Integer.cast() == nil
      assert XSD.string("3.14") |> XSD.Integer.cast() == nil
    end

    test "casting an decimal" do
      assert XSD.decimal(0) |> XSD.Integer.cast() == XSD.integer(0)
      assert XSD.decimal(1.0) |> XSD.Integer.cast() == XSD.integer(1)
      assert XSD.decimal(3.14) |> XSD.Integer.cast() == XSD.integer(3)
    end

    test "casting a double" do
      assert XSD.double(0) |> XSD.Integer.cast() == XSD.integer(0)
      assert XSD.double(0.0) |> XSD.Integer.cast() == XSD.integer(0)
      assert XSD.double(0.1) |> XSD.Integer.cast() == XSD.integer(0)
      assert XSD.double("+0") |> XSD.Integer.cast() == XSD.integer(0)
      assert XSD.double("+0.0") |> XSD.Integer.cast() == XSD.integer(0)
      assert XSD.double("-0.0") |> XSD.Integer.cast() == XSD.integer(0)
      assert XSD.double("0.0E0") |> XSD.Integer.cast() == XSD.integer(0)
      assert XSD.double(1) |> XSD.Integer.cast() == XSD.integer(1)
      assert XSD.double(3.14) |> XSD.Integer.cast() == XSD.integer(3)

      assert XSD.double("NAN") |> XSD.Integer.cast() == nil
      assert XSD.double("+INF") |> XSD.Integer.cast() == nil
    end

    test "casting a float" do
      assert XSD.float(0) |> XSD.Integer.cast() == XSD.integer(0)
      assert XSD.float(0.0) |> XSD.Integer.cast() == XSD.integer(0)
      assert XSD.float(0.1) |> XSD.Integer.cast() == XSD.integer(0)
      assert XSD.float("+0") |> XSD.Integer.cast() == XSD.integer(0)
      assert XSD.float("+0.0") |> XSD.Integer.cast() == XSD.integer(0)
      assert XSD.float("-0.0") |> XSD.Integer.cast() == XSD.integer(0)
      assert XSD.float("0.0E0") |> XSD.Integer.cast() == XSD.integer(0)
      assert XSD.float(1) |> XSD.Integer.cast() == XSD.integer(1)
      assert XSD.float(3.14) |> XSD.Integer.cast() == XSD.integer(3)

      assert XSD.float("NAN") |> XSD.Integer.cast() == nil
      assert XSD.float("+INF") |> XSD.Integer.cast() == nil
    end

    test "from derived types of xsd:integer" do
      assert XSD.byte(42) |> XSD.Integer.cast() == XSD.integer(42)
      assert Age.new(42) |> XSD.Integer.cast() == XSD.integer(42)
    end

    test "from derived types of the castable datatypes" do
      assert DecimalUnitInterval.new(0.14) |> XSD.Integer.cast() == XSD.integer(0)
      assert DoubleUnitInterval.new(0.14) |> XSD.Integer.cast() == XSD.integer(0)
      assert FloatUnitInterval.new(1.0) |> XSD.Integer.cast() == XSD.integer(1)
    end

    test "with invalid literals" do
      assert XSD.integer(3.14) |> XSD.Integer.cast() == nil
      assert XSD.decimal("NAN") |> XSD.Integer.cast() == nil
      assert XSD.double(true) |> XSD.Integer.cast() == nil
    end

    test "with literals of unsupported datatypes" do
      assert XSD.date("2020-01-01") |> XSD.Integer.cast() == nil
    end
  end

  test "digit_count/1" do
    assert XSD.Integer.digit_count(XSD.integer("2")) == 1
    assert XSD.Integer.digit_count(XSD.integer("23")) == 2
    assert XSD.Integer.digit_count(XSD.integer("023")) == 2
    assert XSD.Integer.digit_count(XSD.integer("+023")) == 2
    assert XSD.Integer.digit_count(XSD.integer("-023")) == 2
    assert XSD.Integer.digit_count(XSD.positive_integer("23")) == 2
    assert XSD.Integer.digit_count(XSD.byte("00023")) == 2
    assert XSD.Integer.digit_count(XSD.integer("NaN")) == nil
    assert XSD.Integer.digit_count(XSD.positive_integer("-023")) == nil
    assert XSD.Integer.digit_count(XSD.byte("12345")) == nil
  end
end
