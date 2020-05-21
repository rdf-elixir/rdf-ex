defmodule RDF.XSD.DecimalTest do
  # TODO: Why can't we use the Decimal alias in the use options? Maybe it's the special ExUnit.CaseTemplate.using/2 macro in XSD.Datatype.Test.Case?
  #  alias Elixir.Decimal, as: D
  use RDF.XSD.Datatype.Test.Case,
    datatype: RDF.XSD.Decimal,
    name: "decimal",
    primitive: true,
    comparable_datatypes: [RDF.XSD.Integer, RDF.XSD.Double],
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
    valid: %{
      # input => {value, lexical, canonicalized}
      0 => {Elixir.Decimal.from_float(0.0), nil, "0.0"},
      1 => {Elixir.Decimal.from_float(1.0), nil, "1.0"},
      -1 => {Elixir.Decimal.from_float(-1.0), nil, "-1.0"},
      1.0 => {Elixir.Decimal.from_float(1.0), nil, "1.0"},
      -3.14 => {Elixir.Decimal.from_float(-3.14), nil, "-3.14"},
      0.0e2 => {Elixir.Decimal.from_float(0.0), nil, "0.0"},
      1.2e3 => {Elixir.Decimal.new("1200.0"), nil, "1200.0"},
      Elixir.Decimal.from_float(1.0) => {Elixir.Decimal.from_float(1.0), nil, "1.0"},
      Elixir.Decimal.new(1) => {Elixir.Decimal.from_float(1.0), nil, "1.0"},
      Elixir.Decimal.from_float(1.2e3) => {Elixir.Decimal.new("1200.0"), nil, "1200.0"},
      "1" => {Elixir.Decimal.from_float(1.0), "1", "1.0"},
      "01" => {Elixir.Decimal.from_float(1.0), "01", "1.0"},
      "0123" => {Elixir.Decimal.from_float(123.0), "0123", "123.0"},
      "-1" => {Elixir.Decimal.from_float(-1.0), "-1", "-1.0"},
      "1." => {Elixir.Decimal.from_float(1.0), "1.", "1.0"},
      "1.0" => {Elixir.Decimal.from_float(1.0), nil, "1.0"},
      "1.000000000" => {Elixir.Decimal.from_float(1.0), "1.000000000", "1.0"},
      "+001.00" => {Elixir.Decimal.from_float(1.0), "+001.00", "1.0"},
      "123.456" => {Elixir.Decimal.from_float(123.456), nil, "123.456"},
      "0123.456" => {Elixir.Decimal.from_float(123.456), "0123.456", "123.456"},
      "010.020" => {Elixir.Decimal.from_float(10.02), "010.020", "10.02"},
      "2.3" => {Elixir.Decimal.from_float(2.3), nil, "2.3"},
      "2.345" => {Elixir.Decimal.from_float(2.345), nil, "2.345"},
      "2.234000005" => {Elixir.Decimal.from_float(2.234000005), nil, "2.234000005"},
      "1.234567890123456789012345789" =>
        {Elixir.Decimal.new("1.234567890123456789012345789"), nil,
         "1.234567890123456789012345789"},
      ".3" => {Elixir.Decimal.from_float(0.3), ".3", "0.3"},
      "-.3" => {Elixir.Decimal.from_float(-0.3), "-.3", "-0.3"}
    },
    invalid: [
      "foo",
      "10.1e1",
      "1.0E0",
      "12.xyz",
      "3,5",
      "NaN",
      "Inf",
      true,
      false,
      "1.0 foo",
      "foo 1.0",
      Elixir.Decimal.new("NaN"),
      Elixir.Decimal.new("Inf")
    ]

  describe "cast/1" do
    test "casting a decimal returns the input as it is" do
      assert XSD.decimal(0) |> XSD.Decimal.cast() == XSD.decimal(0)
      assert XSD.decimal("-0.0") |> XSD.Decimal.cast() == XSD.decimal("-0.0")
      assert XSD.decimal(1) |> XSD.Decimal.cast() == XSD.decimal(1)
      assert XSD.decimal(0.1) |> XSD.Decimal.cast() == XSD.decimal(0.1)
    end

    test "casting a boolean" do
      assert XSD.true() |> XSD.Decimal.cast() == XSD.decimal(1.0)
      assert XSD.false() |> XSD.Decimal.cast() == XSD.decimal(0.0)
    end

    test "casting a string with a value from the lexical value space of xsd:decimal" do
      assert XSD.string("0") |> XSD.Decimal.cast() == XSD.decimal(0)
      assert XSD.string("3.14") |> XSD.Decimal.cast() == XSD.decimal(3.14)
    end

    test "casting a string with a value not in the lexical value space of xsd:decimal" do
      assert XSD.string("foo") |> XSD.Decimal.cast() == nil
    end

    test "casting an integer" do
      assert XSD.integer(0) |> XSD.Decimal.cast() == XSD.decimal(0.0)
      assert XSD.integer(42) |> XSD.Decimal.cast() == XSD.decimal(42.0)
    end

    test "casting a double" do
      assert XSD.double(0.0) |> XSD.Decimal.cast() == XSD.decimal(0.0)
      assert XSD.double("-0.0") |> XSD.Decimal.cast() == XSD.decimal(0.0)
      assert XSD.double(0.1) |> XSD.Decimal.cast() == XSD.decimal(0.1)
      assert XSD.double(1) |> XSD.Decimal.cast() == XSD.decimal(1.0)
      assert XSD.double(3.14) |> XSD.Decimal.cast() == XSD.decimal(3.14)
      assert XSD.double(10.1e1) |> XSD.Decimal.cast() == XSD.decimal(101.0)

      assert XSD.double("NAN") |> XSD.Decimal.cast() == nil
      assert XSD.double("+INF") |> XSD.Decimal.cast() == nil
    end

    test "casting a float" do
      assert XSD.float(0.0) |> XSD.Decimal.cast() == XSD.decimal(0.0)
      assert XSD.float("-0.0") |> XSD.Decimal.cast() == XSD.decimal(0.0)
      assert XSD.float(0.1) |> XSD.Decimal.cast() == XSD.decimal(0.1)
      assert XSD.float(1) |> XSD.Decimal.cast() == XSD.decimal(1.0)
      assert XSD.float(3.14) |> XSD.Decimal.cast() == XSD.decimal(3.14)
      assert XSD.float(10.1e1) |> XSD.Decimal.cast() == XSD.decimal(101.0)

      assert XSD.float("NAN") |> XSD.Decimal.cast() == nil
      assert XSD.float("+INF") |> XSD.Decimal.cast() == nil
    end

    test "from derived types of xsd:decimal" do
      assert DecimalUnitInterval.new(0.1) |> XSD.Decimal.cast() == XSD.decimal(0.1)
    end

    test "from derived types of the castable datatypes" do
      assert DoubleUnitInterval.new(0.14) |> XSD.Decimal.cast() == XSD.decimal(0.14)
      assert FloatUnitInterval.new(1.0) |> XSD.Decimal.cast() == XSD.decimal(1.0)
      assert Age.new(42) |> XSD.Decimal.cast() == XSD.decimal(42)
    end

    test "with invalid literals" do
      assert XSD.boolean("42") |> XSD.Decimal.cast() == nil
      assert XSD.integer(3.14) |> XSD.Decimal.cast() == nil
      assert XSD.decimal("NAN") |> XSD.Decimal.cast() == nil
      assert XSD.double(true) |> XSD.Decimal.cast() == nil
    end

    test "with literals of unsupported datatypes" do
      assert XSD.date("2020-01-01") |> XSD.Decimal.cast() == nil
    end
  end

  test "digit_count/1" do
    assert XSD.Decimal.digit_count(XSD.decimal("1.2345")) == 5
    assert XSD.Decimal.digit_count(XSD.decimal("-1.2345")) == 5
    assert XSD.Decimal.digit_count(XSD.decimal("+1.2345")) == 5
    assert XSD.Decimal.digit_count(XSD.decimal("01.23450")) == 5
    assert XSD.Decimal.digit_count(XSD.decimal("01.23450")) == 5
    assert XSD.Decimal.digit_count(XSD.decimal("NAN")) == nil

    assert XSD.Decimal.digit_count(XSD.integer("2")) == 1
    assert XSD.Decimal.digit_count(XSD.integer("23")) == 2
    assert XSD.Decimal.digit_count(XSD.integer("023")) == 2
  end

  test "fraction_digit_count/1" do
    assert XSD.Decimal.fraction_digit_count(XSD.decimal("1.2345")) == 4
    assert XSD.Decimal.fraction_digit_count(XSD.decimal("-1.2345")) == 4
    assert XSD.Decimal.fraction_digit_count(XSD.decimal("+1.2345")) == 4
    assert XSD.Decimal.fraction_digit_count(XSD.decimal("01.23450")) == 4
    assert XSD.Decimal.fraction_digit_count(XSD.decimal("0.023450")) == 5
    assert XSD.Decimal.fraction_digit_count(XSD.decimal("NAN")) == nil

    assert XSD.Decimal.fraction_digit_count(XSD.integer("2")) == 0
    assert XSD.Decimal.fraction_digit_count(XSD.integer("23")) == 0
    assert XSD.Decimal.fraction_digit_count(XSD.integer("023")) == 0
  end

  defmacrop sigil_d(str, _opts) do
    quote do
      Elixir.Decimal.new(unquote(str))
    end
  end

  test "Decimal.canonical_decimal/1" do
    assert Decimal.canonical_decimal(~d"0") == ~d"0.0"
    assert Decimal.canonical_decimal(~d"0.0") == ~d"0.0"
    assert Decimal.canonical_decimal(~d"0.001") == ~d"0.001"
    assert Decimal.canonical_decimal(~d"-0") == ~d"-0.0"
    assert Decimal.canonical_decimal(~d"-1") == ~d"-1.0"
    assert Decimal.canonical_decimal(~d"-0.00") == ~d"-0.0"
    assert Decimal.canonical_decimal(~d"1.00") == ~d"1.0"
    assert Decimal.canonical_decimal(~d"1000") == ~d"1000.0"
    assert Decimal.canonical_decimal(~d"1000.000000") == ~d"1000.0"
    assert Decimal.canonical_decimal(~d"12345.000") == ~d"12345.0"
    assert Decimal.canonical_decimal(~d"42") == ~d"42.0"
    assert Decimal.canonical_decimal(~d"42.42") == ~d"42.42"
    assert Decimal.canonical_decimal(~d"0.42") == ~d"0.42"
    assert Decimal.canonical_decimal(~d"0.0042") == ~d"0.0042"
    assert Decimal.canonical_decimal(~d"010.020") == ~d"10.02"
    assert Decimal.canonical_decimal(~d"-1.23") == ~d"-1.23"
    assert Decimal.canonical_decimal(~d"-0.0123") == ~d"-0.0123"
    assert Decimal.canonical_decimal(~d"1E+2") == ~d"100.0"
    assert Decimal.canonical_decimal(~d"1.2E3") == ~d"1200.0"
    assert Decimal.canonical_decimal(~d"-42E+3") == ~d"-42000.0"
  end
end
