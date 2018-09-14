defmodule RDF.DoubleTest do
  use RDF.Datatype.Test.Case, datatype: RDF.Double, id: RDF.NS.XSD.double,
    valid: %{
    # input              => { value              , lexical     , canonicalized }
      0                  => { 0.0                , "0.0"       , "0.0E0"     },
      42                 => { 42.0               , "42.0"      , "4.2E1"     },
      0.0E0              => { 0.0                , "0.0"       , "0.0E0"     },
      1.0E0              => { 1.0                , "1.0"       , "1.0E0"     },
      :positive_infinity => { :positive_infinity , nil         , "INF"       },
      :negative_infinity => { :negative_infinity , nil         , "-INF"      },
      :nan               => { :nan               , nil         , "NaN"       },
      "1.0E0"            => { 1.0E0              , nil         , "1.0E0"     },
      "0.0"              => { 0.0                , "0.0"       , "0.0E0"     },
      "1"                => { 1.0E0              , "1"         , "1.0E0"     },
      "01"               => { 1.0E0              , "01"        , "1.0E0"     },
      "0123"             => { 1.23E2             , "0123"      , "1.23E2"    },
      "-1"               => { -1.0E0             , "-1"        , "-1.0E0"    },
      "+01.000"          => { 1.0E0              , "+01.000"   , "1.0E0"     },
      "1.0"              => { 1.0E0              , "1.0"       , "1.0E0"     },
      "123.456"          => { 1.23456E2          , "123.456"   , "1.23456E2" },
      "1.0e+1"           => { 1.0E1              , "1.0e+1"    , "1.0E1"     },
      "1.0e-10"          => { 1.0E-10            , "1.0e-10"   , "1.0E-10"   },
      "123.456e4"        => { 1.23456E6          , "123.456e4" , "1.23456E6" },
      "1.E-8"            => { 1.0E-8             , "1.E-8"     , "1.0E-8"    },
      "3E1"              => { 3.0E1              , "3E1"       , "3.0E1"     },
      "INF"              => { :positive_infinity , nil         , "INF"       },
      "Inf"              => { :positive_infinity , "Inf"       , "INF"       },
      "+INF"             => { :positive_infinity , "+INF"      , "INF"       },
      "-INF"             => { :negative_infinity , nil         , "-INF"      },
      "NaN"              => { :nan               , nil         , "NaN"       },
    },
    invalid: ~w(foo 12.xyz 1.0ez) ++ [true, false, "1.1e1 foo", "foo 1.1e1"]


  describe "equality" do
    test "two literals are equal when they have the same datatype and lexical form" do
      [
        {"1.0"   , 1.0},
        {"-42.0" , -42.0},
        {"1.0"   , 1.0},
      ]
      |> Enum.each(fn {l, r} ->
           assert Double.new(l) == Double.new(r)
         end)
    end

    test "two literals with same value but different lexical form are not equal" do
      [
        {"1"     , 1.0},
        {"01"    , 1.0},
        {"1.0E0" , 1.0},
        {"1.0E0" , "1.0"},
        {"+42"   , 42.0},
      ]
      |> Enum.each(fn {l, r} ->
           assert Double.new(l) != Double.new(r)
         end)
    end
  end


  describe "cast/1" do
    test "casting a double returns the input as it is" do
      assert RDF.double(3.14)   |> RDF.Double.cast() == RDF.double(3.14)
      assert RDF.double("NAN")  |> RDF.Double.cast() == RDF.double("NAN")
      assert RDF.double("+INF") |> RDF.Double.cast() == RDF.double("+INF")
    end

    test "casting a boolean" do
      assert RDF.true  |> RDF.Double.cast() == RDF.double(1.0)
      assert RDF.false |> RDF.Double.cast() == RDF.double(0.0)
    end

    test "casting a string with a value from the lexical value space of xsd:double" do
      assert RDF.string("1.0")    |> RDF.Double.cast() == RDF.double("1.0E0")
      assert RDF.string("3.14")   |> RDF.Double.cast() == RDF.double("3.14E0")
      assert RDF.string("3.14E0") |> RDF.Double.cast() == RDF.double("3.14E0")
    end

    test "casting a string with a value not in the lexical value space of xsd:double" do
      assert RDF.string("foo") |> RDF.Double.cast() == nil
    end

    test "casting an integer" do
      assert RDF.integer(0)  |> RDF.Double.cast() == RDF.double(0.0)
      assert RDF.integer(42) |> RDF.Double.cast() == RDF.double(42.0)
    end

    test "casting a decimal" do
      assert RDF.decimal(0)    |> RDF.Double.cast() == RDF.double(0)
      assert RDF.decimal(1)    |> RDF.Double.cast() == RDF.double(1)
      assert RDF.decimal(3.14) |> RDF.Double.cast() == RDF.double(3.14)
    end

    @tag skip: "TODO: RDF.Float datatype"
    test "casting a float"

    test "with invalid literals" do
      assert RDF.boolean("42")  |> RDF.Double.cast() == nil
      assert RDF.integer(3.14)  |> RDF.Double.cast() == nil
      assert RDF.decimal("NAN") |> RDF.Double.cast() == nil
      assert RDF.double(true)   |> RDF.Double.cast() == nil
    end

    test "with literals of unsupported datatypes" do
      assert RDF.DateTime.now() |> RDF.Double.cast() == nil
    end
  end

end
