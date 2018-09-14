defmodule RDF.IntegerTest do
  use RDF.Datatype.Test.Case, datatype: RDF.Integer, id: RDF.NS.XSD.integer,
    valid: %{
    # input   => { value , lexical , canonicalized }
      0       => { 0     , nil     , "0"   },
      1       => { 1     , nil     , "1"   },
      "0"     => { 0     , nil     , "0"   },
      "1"     => { 1     , nil     , "1"   },
      "01"    => { 1     , "01"    , "1"   },
      "0123"  => { 123   , "0123"  , "123" },
      +1      => { 1     , nil     , "1"   },
      -1      => { -1    , nil     , "-1"  },
      "+1"    => { 1     , "+1"    , "1"   },
      "-1"    => { -1    , nil     , "-1"  },
    },
    invalid: ~w(foo 10.1 12xyz) ++ [true, false, 3.14, "1 2", "foo 1", "1 foo"]


  describe "cast/1" do
    test "casting an integer returns the input as it is" do
      assert RDF.integer(0) |> RDF.Integer.cast() == RDF.integer(0)
      assert RDF.integer(1) |> RDF.Integer.cast() == RDF.integer(1)
    end

    test "casting a boolean" do
      assert RDF.false |> RDF.Integer.cast() == RDF.integer(0)
      assert RDF.true  |> RDF.Integer.cast() == RDF.integer(1)
    end

    test "casting a string with a value from the lexical value space of xsd:integer" do
      assert RDF.string("0")    |> RDF.Integer.cast() == RDF.integer(0)
      assert RDF.string("042")  |> RDF.Integer.cast() == RDF.integer(42)
    end

    test "casting a string with a value not in the lexical value space of xsd:integer" do
      assert RDF.string("foo")  |> RDF.Integer.cast() == nil
      assert RDF.string("3.14") |> RDF.Integer.cast() == nil
    end

    test "casting an decimal" do
      assert RDF.decimal(0)    |> RDF.Integer.cast() == RDF.integer(0)
      assert RDF.decimal(1.0)  |> RDF.Integer.cast() == RDF.integer(1)
      assert RDF.decimal(3.14) |> RDF.Integer.cast() == RDF.integer(3)
    end

    test "casting a double" do
      assert RDF.double(0)       |> RDF.Integer.cast() == RDF.integer(0)
      assert RDF.double(0.0)     |> RDF.Integer.cast() == RDF.integer(0)
      assert RDF.double(0.1)     |> RDF.Integer.cast() == RDF.integer(0)
      assert RDF.double("+0")    |> RDF.Integer.cast() == RDF.integer(0)
      assert RDF.double("+0.0")  |> RDF.Integer.cast() == RDF.integer(0)
      assert RDF.double("-0.0")  |> RDF.Integer.cast() == RDF.integer(0)
      assert RDF.double("0.0E0") |> RDF.Integer.cast() == RDF.integer(0)
      assert RDF.double(1)       |> RDF.Integer.cast() == RDF.integer(1)
      assert RDF.double(3.14)    |> RDF.Integer.cast() == RDF.integer(3)

      assert RDF.double("NAN")   |> RDF.Integer.cast() == nil
      assert RDF.double("+INF")  |> RDF.Integer.cast() == nil
    end

    @tag skip: "TODO: RDF.Float datatype"
    test "casting a float"

    test "with invalid literals" do
      assert RDF.integer(3.14)  |> RDF.Integer.cast() == nil
      assert RDF.decimal("NAN") |> RDF.Integer.cast() == nil
      assert RDF.double(true)   |> RDF.Integer.cast() == nil
    end

    test "with literals of unsupported datatypes" do
      assert RDF.DateTime.now() |> RDF.Integer.cast() == nil
    end

    test "with non-RDF terms" do
      assert RDF.Integer.cast(:foo) == nil
    end
  end


  describe "equality" do
    test "two literals are equal when they have the same datatype and lexical form" do
      [
        {"1"   , 1},
        {"-42" , -42},
      ]
      |> Enum.each(fn {l, r} ->
           assert Integer.new(l) == Integer.new(r)
         end)
    end

    test "two literals with same value but different lexical form are not equal" do
      [
        {"01"  , 1},
        {"+42" , 42},
      ]
      |> Enum.each(fn {l, r} ->
           assert Integer.new(l) != Integer.new(r)
         end)
    end
  end

end
