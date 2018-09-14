defmodule RDF.StringTest do
  use RDF.Datatype.Test.Case, datatype: RDF.String, id: RDF.NS.XSD.string,
    valid: %{
    # input => { value   , lexical , canonicalized }
      "foo" => { "foo"   , nil     , "foo"   },
      0     => { "0"     , nil     , "0"     },
      42    => { "42"    , nil     , "42"    },
      3.14  => { "3.14"  , nil     , "3.14"  },
      true  => { "true"  , nil     , "true"  },
      false => { "false" , nil     , "false" },
    },
    invalid: [],
    allow_language: true

  describe "new" do
    test "when given a language tag it produces a rdf:langString" do
      assert RDF.String.new("foo", language: "en") ==
             RDF.LangString.new("foo", language: "en")
    end

    test "nil as language is ignored" do
      assert RDF.String.new("Eule", datatype: XSD.string, language: nil) ==
             RDF.String.new("Eule", datatype: XSD.string)
      assert RDF.String.new("Eule", language: nil) ==
             RDF.String.new("Eule")
    end

  end

  describe "new!" do
    test "when given a language tag it produces a rdf:langString" do
      assert RDF.String.new!("foo", language: "en") ==
             RDF.LangString.new!("foo", language: "en")
    end

    test "nil as language is ignored" do
      assert RDF.String.new!("Eule", datatype: XSD.string, language: nil) ==
             RDF.String.new!("Eule", datatype: XSD.string)
      assert RDF.String.new!("Eule", language: nil) ==
             RDF.String.new!("Eule")
    end

  end


  describe "cast/1" do
    test "casting a string returns the input as it is" do
      assert RDF.string("foo") |> RDF.String.cast() == RDF.string("foo")
    end

    test "casting an integer" do
      assert RDF.integer(0) |> RDF.String.cast() == RDF.string("0")
      assert RDF.integer(1) |> RDF.String.cast() == RDF.string("1")
    end

    test "casting a boolean" do
      assert RDF.false |> RDF.String.cast() == RDF.string("false")
      assert RDF.true  |> RDF.String.cast() == RDF.string("true")
    end

    test "casting a decimal" do
      assert RDF.decimal(0)    |> RDF.String.cast() == RDF.string("0")
      assert RDF.decimal(1.0)  |> RDF.String.cast() == RDF.string("1")
      assert RDF.decimal(3.14) |> RDF.String.cast() == RDF.string("3.14")
    end

    test "casting a double" do
      assert RDF.double(0)         |> RDF.String.cast() == RDF.string("0")
      assert RDF.double(0.0)       |> RDF.String.cast() == RDF.string("0")
      assert RDF.double("+0")      |> RDF.String.cast() == RDF.string("0")
      assert RDF.double("-0")      |> RDF.String.cast() == RDF.string("-0")
      assert RDF.double(0.1)       |> RDF.String.cast() == RDF.string("0.1")
      assert RDF.double(3.14)      |> RDF.String.cast() == RDF.string("3.14")
      assert RDF.double(0.000_001) |> RDF.String.cast() == RDF.string("0.000001")
      assert RDF.double(123_456)   |> RDF.String.cast() == RDF.string("123456")
      assert RDF.double(1_234_567) |> RDF.String.cast() == RDF.string("1.234567E6")
      assert RDF.double(0.0000001) |> RDF.String.cast() == RDF.string("1.0E-7")
      assert RDF.double(1.0e-10)   |> RDF.String.cast() == RDF.string("1.0E-10")
      assert RDF.double("1.0e-10") |> RDF.String.cast() == RDF.string("1.0E-10")
      assert RDF.double(1.26743223e15) |> RDF.String.cast() == RDF.string("1.26743223E15")

      assert RDF.double(:nan)               |> RDF.String.cast() == RDF.string("NaN")
      assert RDF.double(:positive_infinity) |> RDF.String.cast() == RDF.string("INF")
      assert RDF.double(:negative_infinity) |> RDF.String.cast() == RDF.string("-INF")
    end

    @tag skip: "TODO: RDF.Float datatype"
    test "casting a float"

    test "casting a datetime" do
      assert RDF.date_time(~N[2010-01-01T12:34:56])     |> RDF.String.cast() == RDF.string("2010-01-01T12:34:56")
      assert RDF.date_time("2010-01-01T00:00:00+00:00") |> RDF.String.cast() == RDF.string("2010-01-01T00:00:00Z")
      assert RDF.date_time("2010-01-01T01:00:00+01:00") |> RDF.String.cast() == RDF.string("2010-01-01T01:00:00+01:00")
      assert RDF.date_time("2010-01-01 01:00:00+01:00") |> RDF.String.cast() == RDF.string("2010-01-01T01:00:00+01:00")
    end

    test "casting a date" do
      assert RDF.date(~D[2000-01-01])     |> RDF.String.cast() == RDF.string("2000-01-01")
      assert RDF.date("2000-01-01")       |> RDF.String.cast() == RDF.string("2000-01-01")
      assert RDF.date("2000-01-01+00:00") |> RDF.String.cast() == RDF.string("2000-01-01Z")
      assert RDF.date("2000-01-01+01:00") |> RDF.String.cast() == RDF.string("2000-01-01+01:00")
      assert RDF.date("0001-01-01")       |> RDF.String.cast() == RDF.string("0001-01-01")
      unless Version.compare(System.version(), "1.7.2") == :lt do
        assert RDF.date("-0001-01-01")  |> RDF.String.cast() == RDF.string("-0001-01-01")
      end
    end

    test "casting a time" do
      assert RDF.time(~T[00:00:00])     |> RDF.String.cast() == RDF.string("00:00:00")
      assert RDF.time("00:00:00")       |> RDF.String.cast() == RDF.string("00:00:00")
      assert RDF.time("00:00:00Z")      |> RDF.String.cast() == RDF.string("00:00:00Z")
      assert RDF.time("00:00:00+00:00") |> RDF.String.cast() == RDF.string("00:00:00Z")
      assert RDF.time("00:00:00+01:00") |> RDF.String.cast() == RDF.string("00:00:00+01:00")
    end

    test "casting an IRI" do
      assert RDF.iri("http://example.com") |> RDF.String.cast() == RDF.string("http://example.com")
    end

    test "with invalid literals" do
      assert RDF.integer(3.14)  |> RDF.String.cast() == nil
      assert RDF.decimal("NAN") |> RDF.String.cast() == nil
      assert RDF.double(true)   |> RDF.String.cast() == nil
    end
  end

end
