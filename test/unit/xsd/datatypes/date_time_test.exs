defmodule RDF.XSD.DateTimeTest do
  import RDF.XSD.Datatype.Test.Case, only: [dt: 1]

  use RDF.XSD.Datatype.Test.Case,
    datatype: RDF.XSD.DateTime,
    name: "dateTime",
    primitive: true,
    applicable_facets: [
      RDF.XSD.Facets.Pattern
    ],
    facets: %{
      pattern: nil
    },
    valid: %{
      # input => { value, lexical, canonicalized }
      dt("2010-01-01T00:00:00Z") => {dt("2010-01-01T00:00:00Z"), nil, "2010-01-01T00:00:00Z"},
      ~N[2010-01-01T00:00:00] => {~N[2010-01-01T00:00:00], nil, "2010-01-01T00:00:00"},
      ~N[2010-01-01T00:00:00.00] => {~N[2010-01-01T00:00:00.00], nil, "2010-01-01T00:00:00.00"},
      ~N[2010-01-01T00:00:00.1234] =>
        {~N[2010-01-01T00:00:00.1234], nil, "2010-01-01T00:00:00.1234"},
      dt("2010-01-01T00:00:00+00:00") =>
        {dt("2010-01-01T00:00:00Z"), nil, "2010-01-01T00:00:00Z"},
      dt("2010-01-01T01:00:00+01:00") =>
        {dt("2010-01-01T00:00:00Z"), nil, "2010-01-01T00:00:00Z"},
      dt("2009-12-31T23:00:00-01:00") =>
        {dt("2010-01-01T00:00:00Z"), nil, "2010-01-01T00:00:00Z"},
      dt("2009-12-31T23:00:00.00-01:00") =>
        {dt("2010-01-01T00:00:00.00Z"), nil, "2010-01-01T00:00:00.00Z"},
      "2010-01-01T00:00:00Z" => {dt("2010-01-01T00:00:00Z"), nil, "2010-01-01T00:00:00Z"},
      "2010-01-01T00:00:00.0000Z" =>
        {dt("2010-01-01T00:00:00.0000Z"), nil, "2010-01-01T00:00:00.0000Z"},
      "2010-01-01T00:00:00.123456Z" =>
        {dt("2010-01-01T00:00:00.123456Z"), nil, "2010-01-01T00:00:00.123456Z"},
      "2010-01-01T00:00:00" => {~N[2010-01-01T00:00:00], nil, "2010-01-01T00:00:00"},
      "2010-01-01T00:00:00+00:00" =>
        {dt("2010-01-01T00:00:00Z"), "2010-01-01T00:00:00+00:00", "2010-01-01T00:00:00Z"},
      "2010-01-01T00:00:00-00:00" =>
        {dt("2010-01-01T00:00:00Z"), "2010-01-01T00:00:00-00:00", "2010-01-01T00:00:00Z"},
      "2010-01-01T01:00:00+01:00" =>
        {dt("2010-01-01T00:00:00Z"), "2010-01-01T01:00:00+01:00", "2010-01-01T00:00:00Z"},
      "2009-12-31T23:00:00.42-01:00" =>
        {dt("2010-01-01T00:00:00.42Z"), "2009-12-31T23:00:00.42-01:00", "2010-01-01T00:00:00.42Z"},
      "2009-12-31T23:00:00-01:00" =>
        {dt("2010-01-01T00:00:00Z"), "2009-12-31T23:00:00-01:00", "2010-01-01T00:00:00Z"},

      # 24:00 is a valid XSD dateTime
      "2009-12-31T24:00:00" =>
        {~N[2010-01-01T00:00:00], "2009-12-31T24:00:00", "2010-01-01T00:00:00"},
      "2009-12-31T24:00:00+00:00" =>
        {dt("2010-01-01T00:00:00Z"), "2009-12-31T24:00:00+00:00", "2010-01-01T00:00:00Z"},
      "2009-12-31T24:00:00-00:00" =>
        {dt("2010-01-01T00:00:00Z"), "2009-12-31T24:00:00-00:00", "2010-01-01T00:00:00Z"},

      # negative years
      dt("-2010-01-01T00:00:00Z") => {dt("-2010-01-01T00:00:00Z"), nil, "-2010-01-01T00:00:00Z"},
      "-2010-01-01T00:00:00+00:00" =>
        {dt("-2010-01-01T00:00:00Z"), "-2010-01-01T00:00:00+00:00", "-2010-01-01T00:00:00Z"}
    },
    invalid: [
      "foo",
      "+2010-01-01T00:00:00Z",
      "2010-01-01T00:00:00FOO",
      "02010-01-01T00:00:00",
      "2010-01-01",
      "2010-1-1T00:00:00",
      "0000-01-01T00:00:00",
      "2010-07",
      "2010_",
      true,
      false,
      2010,
      3.14,
      "2010-01-01T00:00:00Z foo",
      "foo 2010-01-01T00:00:00Z"
    ]

  describe "cast/1" do
    test "casting a datetime returns the input as it is" do
      assert XSD.datetime("2010-01-01T12:34:56") |> XSD.DateTime.cast() ==
               XSD.datetime("2010-01-01T12:34:56")
    end

    test "casting a string with a value from the lexical value space of xsd:dateTime" do
      assert XSD.string("2010-01-01T12:34:56") |> XSD.DateTime.cast() ==
               XSD.datetime("2010-01-01T12:34:56")

      assert XSD.string("2010-01-01T12:34:56Z") |> XSD.DateTime.cast() ==
               XSD.datetime("2010-01-01T12:34:56Z")

      assert XSD.string("2010-01-01T12:34:56+01:00") |> XSD.DateTime.cast() ==
               XSD.datetime("2010-01-01T12:34:56+01:00")
    end

    test "casting a string with a value not in the lexical value space of xsd:dateTime" do
      assert XSD.string("string") |> XSD.DateTime.cast() == nil
      assert XSD.string("02010-01-01T00:00:00") |> XSD.DateTime.cast() == nil
    end

    test "casting a date" do
      assert XSD.date("2010-01-01") |> XSD.DateTime.cast() ==
               XSD.datetime("2010-01-01T00:00:00")

      assert XSD.date("2010-01-01Z") |> XSD.DateTime.cast() ==
               XSD.datetime("2010-01-01T00:00:00Z")

      assert XSD.date("2010-01-01+00:00") |> XSD.DateTime.cast() ==
               XSD.datetime("2010-01-01T00:00:00Z")

      assert XSD.date("2010-01-01+01:00") |> XSD.DateTime.cast() ==
               XSD.datetime("2010-01-01T00:00:00+01:00")
    end

    test "with invalid literals" do
      assert XSD.datetime("02010-01-01T00:00:00") |> XSD.DateTime.cast() == nil
    end

    test "with literals of unsupported datatypes" do
      assert XSD.false() |> XSD.DateTime.cast() == nil
      assert XSD.integer(1) |> XSD.DateTime.cast() == nil
      assert XSD.decimal(3.14) |> XSD.DateTime.cast() == nil
    end
  end

  test "now/0" do
    assert %RDF.Literal{literal: %XSD.DateTime{}} = XSD.DateTime.now()
  end

  describe "tz/1" do
    test "with timezone" do
      [
        {"2010-01-01T00:00:00-23:00", "-23:00"},
        {"2010-01-01T00:00:00+23:00", "+23:00"},
        {"2010-01-01T00:00:00+00:00", "+00:00"}
      ]
      |> Enum.each(fn {dt, tz} ->
        assert dt |> DateTime.new() |> DateTime.tz() == tz
        assert dt |> XSD.DateTime.new() |> DateTime.tz() == tz
      end)
    end

    test "without any specific timezone" do
      [
        "2010-01-01T00:00:00Z",
        "2010-01-01T00:00:00.0000Z"
      ]
      |> Enum.each(fn dt ->
        assert dt |> DateTime.new() |> DateTime.tz() == "Z"
      end)
    end

    test "without any timezone" do
      [
        "2010-01-01T00:00:00",
        "2010-01-01T00:00:00.0000"
      ]
      |> Enum.each(fn dt ->
        assert dt |> DateTime.new() |> DateTime.tz() == ""
      end)
    end

    test "with invalid timezone literals" do
      [
        DateTime.new("2010-01-01T00:0"),
        "2010-01-01T00:00:00.0000"
      ]
      |> Enum.each(fn dt ->
        assert DateTime.tz(dt) == nil
      end)
    end
  end

  test "canonical_lexical_with_zone/1" do
    assert XSD.dateTime(~N[2010-01-01T12:34:56]) |> DateTime.canonical_lexical_with_zone() ==
             "2010-01-01T12:34:56"

    assert XSD.dateTime("2010-01-01T12:34:56") |> DateTime.canonical_lexical_with_zone() ==
             "2010-01-01T12:34:56"

    assert XSD.dateTime("2010-01-01T00:00:00+00:00") |> DateTime.canonical_lexical_with_zone() ==
             "2010-01-01T00:00:00Z"

    assert XSD.dateTime("2010-01-01T00:00:00-00:00") |> DateTime.canonical_lexical_with_zone() ==
             "2010-01-01T00:00:00Z"

    assert XSD.dateTime("2010-01-01T01:00:00+01:00") |> DateTime.canonical_lexical_with_zone() ==
             "2010-01-01T01:00:00+01:00"

    assert XSD.dateTime("2010-01-01 01:00:00+01:00") |> DateTime.canonical_lexical_with_zone() ==
             "2010-01-01T01:00:00+01:00"
  end
end
