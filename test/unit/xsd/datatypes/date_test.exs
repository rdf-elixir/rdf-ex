defmodule RDF.XSD.DateTest do
  use RDF.XSD.Datatype.Test.Case,
    datatype: RDF.XSD.Date,
    name: "date",
    primitive: true,
    valid: %{
      # input => { value, lexical, canonicalized }
      ~D[2010-01-01] => {~D[2010-01-01], nil, "2010-01-01"},
      "2010-01-01" => {~D[2010-01-01], nil, "2010-01-01"},
      "2010-01-01Z" => {{~D[2010-01-01], "Z"}, nil, "2010-01-01Z"},
      "2010-01-01+00:00" => {{~D[2010-01-01], "Z"}, "2010-01-01+00:00", "2010-01-01Z"},
      "2010-01-01-00:00" => {{~D[2010-01-01], "-00:00"}, nil, "2010-01-01-00:00"},
      "2010-01-01+01:00" => {{~D[2010-01-01], "+01:00"}, nil, "2010-01-01+01:00"},
      "2009-12-31-01:00" => {{~D[2009-12-31], "-01:00"}, nil, "2009-12-31-01:00"},
      "2014-09-01-08:00" => {{~D[2014-09-01], "-08:00"}, nil, "2014-09-01-08:00"},

      # negative years
      "-2010-01-01" => {~D[-2010-01-01], nil, "-2010-01-01"},
      "-2010-01-01Z" => {{~D[-2010-01-01], "Z"}, nil, "-2010-01-01Z"},
      "-2010-01-01+00:00" => {{~D[-2010-01-01], "Z"}, "-2010-01-01+00:00", "-2010-01-01Z"}
    },
    invalid: [
      "foo",
      "+2010-01-01Z",
      "2010-01-01TFOO",
      "02010-01-01",
      "2010-1-1",
      "0000-01-01",
      "2011-07",
      "2011",
      true,
      false,
      2010,
      3.14,
      # this value representation is just internal and not accepted as
      {~D[2010-01-01], "Z"}
    ]

  describe "new/2" do
    test "with date and tz opt" do
      assert XSD.Date.new("2010-01-01", tz: "+01:00") ==
               %RDF.Literal{literal: %XSD.Date{value: {~D[2010-01-01], "+01:00"}}}

      assert XSD.Date.new(~D[2010-01-01], tz: "+01:00") ==
               %RDF.Literal{literal: %XSD.Date{value: {~D[2010-01-01], "+01:00"}}}

      assert XSD.Date.new("2010-01-01", tz: "+00:00") ==
               %RDF.Literal{literal: %XSD.Date{
                 value: {~D[2010-01-01], "Z"},
                 uncanonical_lexical: "2010-01-01+00:00"
               }}

      assert XSD.Date.new(~D[2010-01-01], tz: "+00:00") ==
               %RDF.Literal{literal: %XSD.Date{
                 value: {~D[2010-01-01], "Z"},
                 uncanonical_lexical: "2010-01-01+00:00"
               }}
    end

    test "with date string including a timezone and tz opt" do
      assert XSD.Date.new("2010-01-01+00:00", tz: "+01:00") ==
               %RDF.Literal{literal: %XSD.Date{value: {~D[2010-01-01], "+01:00"}}}

      assert XSD.Date.new("2010-01-01+01:00", tz: "Z") ==
               %RDF.Literal{literal: %XSD.Date{value: {~D[2010-01-01], "Z"}}}

      assert XSD.Date.new("2010-01-01+01:00", tz: "+00:00") ==
               %RDF.Literal{literal: %XSD.Date{
                 value: {~D[2010-01-01], "Z"},
                 uncanonical_lexical: "2010-01-01+00:00"
               }}
    end

    test "with invalid tz opt" do
      assert XSD.Date.new(~D[2020-01-01], tz: "+01:00:42") ==
               %RDF.Literal{literal: %XSD.Date{uncanonical_lexical: "2020-01-01+01:00:42"}}

      assert XSD.Date.new("2020-01-01-01", tz: "+01:00") ==
               %RDF.Literal{literal: %XSD.Date{uncanonical_lexical: "2020-01-01-01"}}

      assert XSD.Date.new("2020-01-01", tz: "+01:00:42") ==
               %RDF.Literal{literal: %XSD.Date{uncanonical_lexical: "2020-01-01"}}

      assert XSD.Date.new("2020-01-01+00:00:", tz: "+01:00:") ==
               %RDF.Literal{literal: %XSD.Date{uncanonical_lexical: "2020-01-01+00:00:"}}
    end
  end

  describe "cast/1" do
    test "casting a date returns the input as it is" do
      assert XSD.date("2010-01-01") |> XSD.Date.cast() ==
               XSD.date("2010-01-01")
    end

    test "casting a string" do
      assert XSD.string("2010-01-01") |> XSD.Date.cast() ==
               XSD.date("2010-01-01")

      assert XSD.string("2010-01-01Z") |> XSD.Date.cast() ==
               XSD.date("2010-01-01Z")

      assert XSD.string("2010-01-01+01:00") |> XSD.Date.cast() ==
               XSD.date("2010-01-01+01:00")
    end

    test "casting a datetime" do
      assert XSD.datetime("2010-01-01T01:00:00") |> XSD.Date.cast() ==
               XSD.date("2010-01-01")

      assert XSD.datetime("2010-01-01T00:00:00Z") |> XSD.Date.cast() ==
               XSD.date("2010-01-01Z")

      assert XSD.datetime("2010-01-01T00:00:00+00:00") |> XSD.Date.cast() ==
               XSD.date("2010-01-01+00:00")

      assert XSD.datetime("2010-01-01T23:00:00+01:00") |> XSD.Date.cast() ==
               XSD.date("2010-01-01+01:00")
    end

    test "with invalid literals" do
      assert XSD.date("02010-01-00") |> XSD.Date.cast() == nil
      assert XSD.datetime("02010-01-01T00:00:00") |> XSD.Date.cast() == nil
    end

    test "with literals of unsupported datatypes" do
      assert XSD.false() |> XSD.Date.cast() == nil
      assert XSD.integer(1) |> XSD.Date.cast() == nil
      assert XSD.decimal(3.14) |> XSD.Date.cast() == nil
    end

    test "with coercible value" do
      assert XSD.Date.cast("2010-01-01") == XSD.date("2010-01-01")
    end

    test "with non-coercible value" do
      assert XSD.Date.cast(:foo) == nil
      assert XSD.Date.cast(make_ref()) == nil
    end
  end
end
