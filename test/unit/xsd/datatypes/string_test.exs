defmodule RDF.XSD.StringTest do
  use RDF.XSD.Datatype.Test.Case,
    datatype: RDF.XSD.String,
    name: "string",
    primitive: true,
    applicable_facets: [
      RDF.XSD.Facets.MinLength,
      RDF.XSD.Facets.MaxLength,
      RDF.XSD.Facets.Length,
    ],
    facets: %{
      max_length: nil,
      min_length: nil,
      length: nil
    },
    valid: %{
      # input => { value, lexical, canonicalized }
      "foo" => {"foo", nil, "foo"},
      0 => {"0", nil, "0"},
      42 => {"42", nil, "42"},
      3.14 => {"3.14", nil, "3.14"},
      true => {"true", nil, "true"},
      false => {"false", nil, "false"}
    },
    invalid: []

  describe "cast/1" do
    test "casting a string returns the input as it is" do
      assert XSD.string("foo") |> XSD.String.cast() == XSD.string("foo")
    end

    test "casting an integer" do
      assert XSD.integer(0) |> XSD.String.cast() == XSD.string("0")
      assert XSD.integer(1) |> XSD.String.cast() == XSD.string("1")
    end

    test "casting a boolean" do
      assert XSD.false() |> XSD.String.cast() == XSD.string("false")
      assert XSD.true() |> XSD.String.cast() == XSD.string("true")
    end

    test "casting a decimal" do
      assert XSD.decimal(0) |> XSD.String.cast() == XSD.string("0")
      assert XSD.decimal(1.0) |> XSD.String.cast() == XSD.string("1")
      assert XSD.decimal(3.14) |> XSD.String.cast() == XSD.string("3.14")
    end

    test "casting a double" do
      assert XSD.double(0) |> XSD.String.cast() == XSD.string("0")
      assert XSD.double(0.0) |> XSD.String.cast() == XSD.string("0")
      assert XSD.double("+0") |> XSD.String.cast() == XSD.string("0")
      assert XSD.double("-0") |> XSD.String.cast() == XSD.string("-0")
      assert XSD.double(0.1) |> XSD.String.cast() == XSD.string("0.1")
      assert XSD.double(3.14) |> XSD.String.cast() == XSD.string("3.14")
      assert XSD.double(0.000_001) |> XSD.String.cast() == XSD.string("0.000001")
      assert XSD.double(123_456) |> XSD.String.cast() == XSD.string("123456")
      assert XSD.double(1_234_567) |> XSD.String.cast() == XSD.string("1.234567E6")
      assert XSD.double(0.0000001) |> XSD.String.cast() == XSD.string("1.0E-7")
      assert XSD.double(1.0e-10) |> XSD.String.cast() == XSD.string("1.0E-10")
      assert XSD.double("1.0e-10") |> XSD.String.cast() == XSD.string("1.0E-10")
      assert XSD.double(1.26743223e15) |> XSD.String.cast() == XSD.string("1.26743223E15")

      assert XSD.double(:nan) |> XSD.String.cast() == XSD.string("NaN")
      assert XSD.double(:positive_infinity) |> XSD.String.cast() == XSD.string("INF")
      assert XSD.double(:negative_infinity) |> XSD.String.cast() == XSD.string("-INF")
    end

    test "casting a float" do
      assert XSD.float(0) |> XSD.String.cast() == XSD.string("0")
      assert XSD.float(0.0) |> XSD.String.cast() == XSD.string("0")
      assert XSD.float("+0") |> XSD.String.cast() == XSD.string("0")
      assert XSD.float("-0") |> XSD.String.cast() == XSD.string("-0")
      assert XSD.float(0.1) |> XSD.String.cast() == XSD.string("0.1")
      assert XSD.float(3.14) |> XSD.String.cast() == XSD.string("3.14")
      assert XSD.float(0.000_001) |> XSD.String.cast() == XSD.string("0.000001")
      assert XSD.float(123_456) |> XSD.String.cast() == XSD.string("123456")
      assert XSD.float(1_234_567) |> XSD.String.cast() == XSD.string("1.234567E6")
      assert XSD.float(0.0000001) |> XSD.String.cast() == XSD.string("1.0E-7")
      assert XSD.float(1.0e-10) |> XSD.String.cast() == XSD.string("1.0E-10")
      assert XSD.float("1.0e-10") |> XSD.String.cast() == XSD.string("1.0E-10")
      assert XSD.float(1.26743223e15) |> XSD.String.cast() == XSD.string("1.26743223E15")

      assert XSD.float(:nan) |> XSD.String.cast() == XSD.string("NaN")
      assert XSD.float(:positive_infinity) |> XSD.String.cast() == XSD.string("INF")
      assert XSD.float(:negative_infinity) |> XSD.String.cast() == XSD.string("-INF")
    end

    test "casting a datetime" do
      assert XSD.datetime(~N[2010-01-01T12:34:56]) |> XSD.String.cast() ==
               XSD.string("2010-01-01T12:34:56")

      assert XSD.datetime("2010-01-01T00:00:00+00:00") |> XSD.String.cast() ==
               XSD.string("2010-01-01T00:00:00Z")

      assert XSD.datetime("2010-01-01T01:00:00+01:00") |> XSD.String.cast() ==
               XSD.string("2010-01-01T01:00:00+01:00")

      assert XSD.datetime("2010-01-01 01:00:00+01:00") |> XSD.String.cast() ==
               XSD.string("2010-01-01T01:00:00+01:00")
    end

    test "casting a date" do
      assert XSD.date(~D[2000-01-01]) |> XSD.String.cast() == XSD.string("2000-01-01")
      assert XSD.date("2000-01-01") |> XSD.String.cast() == XSD.string("2000-01-01")
      assert XSD.date("2000-01-01+00:00") |> XSD.String.cast() == XSD.string("2000-01-01Z")
      assert XSD.date("2000-01-01+01:00") |> XSD.String.cast() == XSD.string("2000-01-01+01:00")
      assert XSD.date("0001-01-01") |> XSD.String.cast() == XSD.string("0001-01-01")

      assert XSD.date("-0001-01-01") |> XSD.String.cast() == XSD.string("-0001-01-01")
    end

    test "casting a time" do
      assert XSD.time(~T[00:00:00]) |> XSD.String.cast() == XSD.string("00:00:00")
      assert XSD.time("00:00:00") |> XSD.String.cast() == XSD.string("00:00:00")
      assert XSD.time("00:00:00Z") |> XSD.String.cast() == XSD.string("00:00:00Z")
      assert XSD.time("00:00:00+00:00") |> XSD.String.cast() == XSD.string("00:00:00Z")
      assert XSD.time("00:00:00+01:00") |> XSD.String.cast() == XSD.string("00:00:00+01:00")
    end

    test "casting an IRI" do
      assert RDF.iri("http://example.com") |> XSD.String.cast() == XSD.string("http://example.com")
    end

    test "with invalid literals" do
      assert XSD.integer(3.14) |> XSD.String.cast() == nil
      assert XSD.decimal("NAN") |> XSD.String.cast() == nil
      assert XSD.double(true) |> XSD.String.cast() == nil
    end

    test "with coercible value" do
      assert XSD.String.cast(42) == XSD.string("42")
      assert XSD.String.cast(3.14) == XSD.string("3.14")
      assert XSD.String.cast(true) == XSD.string("true")
      assert XSD.String.cast(false) == XSD.string("false")
    end

    test "with non-coercible value" do
      assert XSD.String.cast(:foo) == nil
      assert XSD.String.cast(make_ref()) == nil
    end
  end
end
