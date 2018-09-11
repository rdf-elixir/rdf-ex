defmodule RDF.DateTimeTest do
  import RDF.Datatype.Test.Case, only: [dt: 1]

  use RDF.Datatype.Test.Case, datatype: RDF.DateTime, id: RDF.NS.XSD.dateTime,
    valid: %{
    # input                              => { value                              , lexical                    , canonicalized }
      dt("2010-01-01T00:00:00Z")         => { dt( "2010-01-01T00:00:00Z")        , nil                        , "2010-01-01T00:00:00Z" },
      ~N[2010-01-01T00:00:00]            => { dt( "2010-01-01T00:00:00")         , nil                        , "2010-01-01T00:00:00"  },
      ~N[2010-01-01T00:00:00.00]         => { dt( "2010-01-01T00:00:00.00")      , nil                        , "2010-01-01T00:00:00.00"  },
      ~N[2010-01-01T00:00:00.1234]       => { dt( "2010-01-01T00:00:00.1234")    , nil                        , "2010-01-01T00:00:00.1234"  },
      dt("2010-01-01T00:00:00+00:00")    => { dt( "2010-01-01T00:00:00Z")        , nil                        , "2010-01-01T00:00:00Z" },
      dt("2010-01-01T01:00:00+01:00")    => { dt( "2010-01-01T00:00:00Z")        , nil                        , "2010-01-01T00:00:00Z" },
      dt("2009-12-31T23:00:00-01:00")    => { dt( "2010-01-01T00:00:00Z")        , nil                        , "2010-01-01T00:00:00Z" },
      dt("2009-12-31T23:00:00.00-01:00") => { dt( "2010-01-01T00:00:00.00Z")     , nil                        , "2010-01-01T00:00:00.00Z" },
      "2010-01-01T00:00:00Z"             => { dt( "2010-01-01T00:00:00Z")        , nil                        , "2010-01-01T00:00:00Z" },
      "2010-01-01T00:00:00.0000Z"        => { dt( "2010-01-01T00:00:00.0000Z")   , nil, "2010-01-01T00:00:00.0000Z" },
      "2010-01-01T00:00:00.123456Z"      => { dt( "2010-01-01T00:00:00.123456Z") , nil, "2010-01-01T00:00:00.123456Z" },
      "2010-01-01T00:00:00"              => { dt( "2010-01-01T00:00:00")         , nil                        , "2010-01-01T00:00:00"  },
      "2010-01-01T00:00:00+00:00"        => { dt( "2010-01-01T00:00:00Z")        , "2010-01-01T00:00:00+00:00", "2010-01-01T00:00:00Z" },
      "2010-01-01T01:00:00+01:00"        => { dt( "2010-01-01T00:00:00Z")        , "2010-01-01T01:00:00+01:00", "2010-01-01T00:00:00Z" },
      "2009-12-31T23:00:00.42-01:00"     => { dt( "2010-01-01T00:00:00.42Z")     , "2009-12-31T23:00:00.42-01:00", "2010-01-01T00:00:00.42Z" },
      "2009-12-31T23:00:00-01:00"        => { dt( "2010-01-01T00:00:00Z")        , "2009-12-31T23:00:00-01:00", "2010-01-01T00:00:00Z" },
      "2009-12-31T24:00:00"              => { dt( "2010-01-01T00:00:00")         , "2009-12-31T24:00:00"      , "2010-01-01T00:00:00"  },
      "2009-12-31T24:00:00+00:00"        => { dt( "2010-01-01T00:00:00Z")        , "2009-12-31T24:00:00+00:00", "2010-01-01T00:00:00Z" },
# TODO: DateTimes on Elixir versions < 1.7.2 don't handle negative years correctly, so we test this conditionally below
#      "-2010-01-01T00:00:00Z"            => { dt("-2010-01-01T00:00:00Z")        , nil, "-2010-01-01T00:00:00Z" },
    },
    invalid: ~w(
        foo
        +2010-01-01T00:00:00Z
        2010-01-01T00:00:00FOO
        02010-01-01T00:00:00
        2010-01-01
        2010-1-1T00:00:00
        0000-01-01T00:00:00
        2010-07
        2010_
      ) ++ [true, false, 2010, 3.14, "2010-01-01T00:00:00Z foo", "foo 2010-01-01T00:00:00Z"]

  unless Version.compare(System.version(), "1.7.2") == :lt do
    test "negative years" do
      assert DateTime.new("-2010-01-01T00:00:00Z") ==
               %Literal{value: dt("-2010-01-01T00:00:00Z"), uncanonical_lexical: nil, datatype: RDF.NS.XSD.dateTime, language: nil}
      assert (DateTime.new("-2010-01-01T00:00:00Z") |> Literal.lexical) == "-2010-01-01T00:00:00Z"
      assert (DateTime.new("-2010-01-01T00:00:00Z") |> Literal.canonical) ==
               DateTime.new("-2010-01-01T00:00:00Z")
      assert Literal.valid? DateTime.new("-2010-01-01T00:00:00Z")

      assert DateTime.new("-2010-01-01T00:00:00+00:00") ==
               %Literal{value: dt("-2010-01-01T00:00:00Z"), uncanonical_lexical: "-2010-01-01T00:00:00+00:00", datatype: RDF.NS.XSD.dateTime, language: nil}
      assert (DateTime.new("-2010-01-01T00:00:00+00:00") |> Literal.lexical) == "-2010-01-01T00:00:00+00:00"
      assert (DateTime.new("-2010-01-01T00:00:00+00:00") |> Literal.canonical) ==
               DateTime.new("-2010-01-01T00:00:00Z")
      assert Literal.valid? DateTime.new("-2010-01-01T00:00:00+00:00")
    end
  end

  describe "equality" do
    test "two literals are equal when they have the same datatype and lexical form" do
      [
        {"2010-01-01T00:00:00Z" , dt("2010-01-01T00:00:00Z")},
        {"2010-01-01T00:00:00"  , ~N[2010-01-01T00:00:00]},
      ]
      |> Enum.each(fn {l, r} ->
           assert DateTime.new(l) == DateTime.new(r)
         end)
    end

    test "two literals with same value but different lexical form are not equal" do
      [
        {"2010-01-01T00:00:00Z"     , "2010-01-01T00:00:00" },
        {"2010-01-01T00:00:00+00:00", "2010-01-01T00:00:00Z"},
        {"2010-01-01T00:00:00.0000Z", "2010-01-01T00:00:00Z"},
      ]
      |> Enum.each(fn {l, r} ->
           assert DateTime.new(l) != DateTime.new(r)
         end)
    end
  end

  describe "tz/1" do
    test "with timezone" do
      [
        {"2010-01-01T00:00:00-23:00", "-23:00"},
        {"2010-01-01T00:00:00+23:00", "+23:00"},
        {"2010-01-01T00:00:00+00:00", "+00:00"},
      ]
      |> Enum.each(fn {dt, tz} ->
           assert dt |> DateTime.new() |> DateTime.tz() == tz
         end)

    end

    test "without any specific timezone" do
      [
        "2010-01-01T00:00:00Z",
        "2010-01-01T00:00:00.0000Z",
      ]
      |> Enum.each(fn dt ->
           assert dt |> DateTime.new() |> DateTime.tz() == "Z"
         end)
    end

    test "without any timezone" do
      [
        "2010-01-01T00:00:00",
        "2010-01-01T00:00:00.0000",
      ]
      |> Enum.each(fn dt ->
           assert dt |> DateTime.new() |> DateTime.tz() == ""
         end)
    end

    test "with invalid timezone literals" do
      [
        DateTime.new("2010-01-01T00:0"),
        "2010-01-01T00:00:00.0000",
      ]
      |> Enum.each(fn dt ->
           assert DateTime.tz(dt) == nil
         end)

    end
  end

  describe "cast/1" do
    test "casting a datetime returns the input as it is" do
      assert RDF.date_time("2010-01-01T12:34:56") |> RDF.DateTime.cast() ==
             RDF.date_time("2010-01-01T12:34:56")
    end

    test "casting a string" do
      assert RDF.string("2010-01-01T12:34:56") |> RDF.DateTime.cast() ==
               RDF.date_time("2010-01-01T12:34:56")
      assert RDF.string("2010-01-01T12:34:56Z") |> RDF.DateTime.cast() ==
               RDF.date_time("2010-01-01T12:34:56Z")
      assert RDF.string("2010-01-01T12:34:56+01:00") |> RDF.DateTime.cast() ==
               RDF.date_time("2010-01-01T12:34:56+01:00")
    end

    test "casting a date" do
      assert RDF.date("2010-01-01") |> RDF.DateTime.cast() ==
               RDF.date_time("2010-01-01T00:00:00")
      assert RDF.date("2010-01-01Z") |> RDF.DateTime.cast() ==
               RDF.date_time("2010-01-01T00:00:00Z")
      assert RDF.date("2010-01-01+00:00") |> RDF.DateTime.cast() ==
               RDF.date_time("2010-01-01T00:00:00Z")
      assert RDF.date("2010-01-01+01:00") |> RDF.DateTime.cast() ==
               RDF.date_time("2010-01-01T00:00:00+01:00")
    end

    test "with invalid literals" do
      assert RDF.date_time("02010-01-01T00:00:00") |> RDF.DateTime.cast() == nil
    end

    test "with literals of unsupported datatypes" do
      assert RDF.false |> RDF.DateTime.cast() == nil
      assert RDF.integer(1) |> RDF.DateTime.cast() == nil
      assert RDF.decimal(3.14) |> RDF.DateTime.cast() == nil
    end
  end


  test "canonical_lexical_with_zone/1" do
    assert RDF.date_time(~N[2010-01-01T12:34:56])     |> DateTime.canonical_lexical_with_zone() == "2010-01-01T12:34:56"
    assert RDF.date_time("2010-01-01T12:34:56")       |> DateTime.canonical_lexical_with_zone() == "2010-01-01T12:34:56"
    assert RDF.date_time("2010-01-01T00:00:00+00:00") |> DateTime.canonical_lexical_with_zone() == "2010-01-01T00:00:00Z"
    assert RDF.date_time("2010-01-01T01:00:00+01:00") |> DateTime.canonical_lexical_with_zone() == "2010-01-01T01:00:00+01:00"
    assert RDF.date_time("2010-01-01 01:00:00+01:00") |> DateTime.canonical_lexical_with_zone() == "2010-01-01T01:00:00+01:00"
  end

end
