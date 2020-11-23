defmodule RDF.XSD.TimeTest do
  use RDF.XSD.Datatype.Test.Case,
    datatype: RDF.XSD.Time,
    name: "time",
    primitive: true,
    applicable_facets: [
      RDF.XSD.Facets.ExplicitTimezone,
      RDF.XSD.Facets.Pattern
    ],
    facets: %{
      explicit_timezone: nil,
      pattern: nil
    },
    valid: %{
      # input => { value, lexical, canonicalized }
      ~T[00:00:00] => {~T[00:00:00], nil, "00:00:00"},
      ~T[00:00:00.123] => {~T[00:00:00.123], nil, "00:00:00.123"},
      "00:00:00" => {~T[00:00:00], nil, "00:00:00"},
      "00:00:00.123" => {~T[00:00:00.123], nil, "00:00:00.123"},
      "00:00:00Z" => {{~T[00:00:00], true}, nil, "00:00:00Z"},
      "00:00:00.1234Z" => {{~T[00:00:00.1234], true}, nil, "00:00:00.1234Z"},
      "00:00:00.0000Z" => {{~T[00:00:00.0000], true}, nil, "00:00:00.0000Z"},
      "00:00:00+00:00" => {{~T[00:00:00], true}, "00:00:00+00:00", "00:00:00Z"},
      "00:00:00-00:00" => {{~T[00:00:00], true}, "00:00:00-00:00", "00:00:00Z"},
      "01:00:00+01:00" => {{~T[00:00:00], true}, "01:00:00+01:00", "00:00:00Z"},
      "23:00:00-01:00" => {{~T[00:00:00], true}, "23:00:00-01:00", "00:00:00Z"},
      "23:00:00.45-01:00" => {{~T[00:00:00.45], true}, "23:00:00.45-01:00", "00:00:00.45Z"}
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
      "00:00:00Z foo",
      "foo 00:00:00Z",
      # this value representation is just internal and not accepted as
      {~T[00:00:00], true},
      {~T[00:00:00], "Z"}
    ]

  describe "new/2" do
    test "with date and tz opt" do
      assert XSD.Time.new("12:00:00", tz: "+01:00") ==
               %RDF.Literal{
                 literal: %XSD.Time{
                   value: {~T[11:00:00], true},
                   uncanonical_lexical: "12:00:00+01:00"
                 }
               }

      assert XSD.Time.new(~T[12:00:00], tz: "+01:00") ==
               %RDF.Literal{
                 literal: %XSD.Time{
                   value: {~T[11:00:00], true},
                   uncanonical_lexical: "12:00:00+01:00"
                 }
               }

      assert XSD.Time.new("12:00:00", tz: "+00:00") ==
               %RDF.Literal{
                 literal: %XSD.Time{
                   value: {~T[12:00:00], true},
                   uncanonical_lexical: "12:00:00+00:00"
                 }
               }

      assert XSD.Time.new(~T[12:00:00], tz: "+00:00") ==
               %RDF.Literal{
                 literal: %XSD.Time{
                   value: {~T[12:00:00], true},
                   uncanonical_lexical: "12:00:00+00:00"
                 }
               }
    end

    test "with date string including a timezone and tz opt" do
      assert XSD.Time.new("12:00:00+00:00", tz: "+01:00") ==
               %RDF.Literal{
                 literal: %XSD.Time{
                   value: {~T[11:00:00], true},
                   uncanonical_lexical: "12:00:00+01:00"
                 }
               }

      assert XSD.Time.new("12:00:00+01:00", tz: "Z") ==
               %RDF.Literal{literal: %XSD.Time{value: {~T[12:00:00], true}}}

      assert XSD.Time.new("12:00:00+01:00", tz: "+00:00") ==
               %RDF.Literal{
                 literal: %XSD.Time{
                   value: {~T[12:00:00], true},
                   uncanonical_lexical: "12:00:00+00:00"
                 }
               }
    end

    test "with invalid tz opt" do
      assert XSD.Time.new(~T[12:00:00], tz: "+01:00:42") ==
               %RDF.Literal{literal: %XSD.Time{uncanonical_lexical: "12:00:00+01:00:42"}}

      assert XSD.Time.new("12:00:00:foo", tz: "+01:00") ==
               %RDF.Literal{literal: %XSD.Time{uncanonical_lexical: "12:00:00:foo"}}

      assert XSD.Time.new("12:00:00", tz: "+01:00:42") ==
               %RDF.Literal{literal: %XSD.Time{uncanonical_lexical: "12:00:00"}}

      assert XSD.Time.new("12:00:00+00:00:", tz: "+01:00:") ==
               %RDF.Literal{literal: %XSD.Time{uncanonical_lexical: "12:00:00+00:00:"}}
    end
  end

  describe "cast/1" do
    test "casting a time returns the input as it is" do
      assert XSD.time("01:00:00") |> XSD.Time.cast() ==
               XSD.time("01:00:00")
    end

    test "casting a string" do
      assert XSD.string("01:00:00") |> XSD.Time.cast() ==
               XSD.time("01:00:00")

      assert XSD.string("01:00:00Z") |> XSD.Time.cast() ==
               XSD.time("01:00:00Z")

      assert XSD.string("01:00:00+01:00") |> XSD.Time.cast() ==
               XSD.time("01:00:00+01:00")
    end

    test "casting a datetime" do
      assert XSD.datetime("2010-01-01T01:00:00") |> XSD.Time.cast() ==
               XSD.time("01:00:00")

      assert XSD.datetime("2010-01-01T00:00:00Z") |> XSD.Time.cast() ==
               XSD.time("00:00:00Z")

      assert XSD.datetime("2010-01-01T00:00:00+00:00") |> XSD.Time.cast() ==
               XSD.time("00:00:00Z")

      assert XSD.datetime("2010-01-01T23:00:00+01:00") |> XSD.Time.cast() ==
               XSD.time("23:00:00+01:00")
    end

    test "with invalid literals" do
      assert XSD.time("25:00:00") |> XSD.Time.cast() == nil
      assert XSD.datetime("02010-01-01T00:00:00") |> XSD.Time.cast() == nil
    end

    test "with literals of unsupported datatypes" do
      assert XSD.false() |> XSD.Time.cast() == nil
      assert XSD.integer(1) |> XSD.Time.cast() == nil
      assert XSD.decimal(3.14) |> XSD.Time.cast() == nil
    end
  end
end
