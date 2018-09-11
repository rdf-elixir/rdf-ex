defmodule RDF.DateTest do
  use RDF.Datatype.Test.Case, datatype: RDF.Date, id: RDF.NS.XSD.date,
    valid: %{
    # input              => { value                      , lexical                    , canonicalized }
      ~D[2010-01-01]     => {  ~D[2010-01-01]            , nil                , "2010-01-01"       },
      "2010-01-01"       => {  ~D[2010-01-01]            , nil                , "2010-01-01"       },
      "2010-01-01Z"      => { {~D[2010-01-01], "Z"}      , nil                , "2010-01-01Z"      },
      "2010-01-01+00:00" => { {~D[2010-01-01], "Z"}      , "2010-01-01+00:00" , "2010-01-01Z"      },
      "2010-01-01-00:00" => { {~D[2010-01-01], "-00:00"} , nil                , "2010-01-01-00:00" },
      "2010-01-01+01:00" => { {~D[2010-01-01], "+01:00"} , nil                , "2010-01-01+01:00" },
      "2009-12-31-01:00" => { {~D[2009-12-31], "-01:00"} , nil                , "2009-12-31-01:00" },
      "2014-09-01-08:00" => { {~D[2014-09-01], "-08:00"} , nil                , "2014-09-01-08:00" },
# TODO: Dates on Elixir versions < 1.7.2 don't handle negative years correctly, so we test this conditionally below
#      "-2010-01-01Z"     => { {~D[-2010-01-01], "Z"}     , nil                , "-2010-01-01Z"     },
    },
    invalid: ~w(
        foo
        +2010-01-01Z
        2010-01-01TFOO
        02010-01-01
        2010-1-1
        0000-01-01
        2011-07
        2011
      ) ++ [true, false, 2010, 3.14, "2010-01-01Z foo", "foo 2010-01-01Z"]


  unless Version.compare(System.version(), "1.7.2") == :lt do
    test "negative years" do
      assert Date.new("-2010-01-01Z") ==
               %Literal{value: {~D[-2010-01-01], "Z"}, uncanonical_lexical: nil, datatype: RDF.NS.XSD.date, language: nil}
      assert (Date.new("-2010-01-01Z") |> Literal.lexical) == "-2010-01-01Z"
      assert (Date.new("-2010-01-01Z") |> Literal.canonical) == Date.new("-2010-01-01Z")
      assert Literal.valid? Date.new("-2010-01-01Z")

      assert Date.new("-2010-01-01") ==
               %Literal{value: ~D[-2010-01-01], uncanonical_lexical: nil, datatype: RDF.NS.XSD.date, language: nil}
      assert (Date.new("-2010-01-01") |> Literal.lexical) == "-2010-01-01"
      assert (Date.new("-2010-01-01") |> Literal.canonical) == Date.new("-2010-01-01")
      assert Literal.valid? Date.new("-2010-01-01")

      assert Date.new("-2010-01-01+00:00") ==
               %Literal{value: {~D[-2010-01-01], "Z"}, uncanonical_lexical: "-2010-01-01+00:00", datatype: RDF.NS.XSD.date, language: nil}
      assert (Date.new("-2010-01-01+00:00") |> Literal.lexical) == "-2010-01-01+00:00"
      assert (Date.new("-2010-01-01+00:00") |> Literal.canonical) == Date.new("-2010-01-01Z")
      assert Literal.valid? Date.new("-2010-01-01+00:00")
    end
  end

  describe "equality" do
    test "two literals are equal when they have the same datatype and lexical form" do
      [
        { ~D[2010-01-01] , "2010-01-01" },
      ]
      |> Enum.each(fn {l, r} ->
           assert Date.new(l) == Date.new(r)
         end)
    end

    test "two literals with same value but different lexical form are not equal" do
      [
        { ~D[2010-01-01]     , "2010-01-01Z"      },
        { ~D[2010-01-01]     , "2010-01-01+00:00" },
        { "2010-01-01"       , "00:00:00Z"        },
        { "2010-01-01+00:00" , "00:00:00Z"        },
        { "2010-01-01-00:00" , "00:00:00Z"        },
        { "2010-01-01+00:00" , "00:00:00"         },
        { "2010-01-01-00:00" , "00:00:00"         },
      ]
      |> Enum.each(fn {l, r} ->
           assert Date.new(l) != Date.new(r)
         end)
    end
  end

  describe "cast/1" do
    test "casting a date returns the input as it is" do
      assert RDF.date("2010-01-01") |> RDF.Date.cast() ==
             RDF.date("2010-01-01")
    end

    test "casting a string" do
      assert RDF.string("2010-01-01") |> RDF.Date.cast() ==
               RDF.date("2010-01-01")
      assert RDF.string("2010-01-01Z") |> RDF.Date.cast() ==
               RDF.date("2010-01-01Z")
      assert RDF.string("2010-01-01+01:00") |> RDF.Date.cast() ==
               RDF.date("2010-01-01+01:00")
    end

    test "casting a datetime" do
      assert RDF.date_time("2010-01-01T01:00:00") |> RDF.Date.cast() ==
               RDF.date("2010-01-01")
      assert RDF.date_time("2010-01-01T00:00:00Z") |> RDF.Date.cast() ==
               RDF.date("2010-01-01Z")
      assert RDF.date_time("2010-01-01T00:00:00+00:00") |> RDF.Date.cast() ==
               RDF.date("2010-01-01Z")
      assert RDF.date_time("2010-01-01T23:00:00+01:00") |> RDF.Date.cast() ==
               RDF.date("2010-01-01+01:00")
    end

    test "with invalid literals" do
      assert RDF.date("02010-01-00") |> RDF.Date.cast() == nil
      assert RDF.date_time("02010-01-01T00:00:00") |> RDF.Date.cast() == nil
    end

    test "with literals of unsupported datatypes" do
      assert RDF.false |> RDF.Date.cast() == nil
      assert RDF.integer(1) |> RDF.Date.cast() == nil
      assert RDF.decimal(3.14) |> RDF.Date.cast() == nil
    end
  end

end
