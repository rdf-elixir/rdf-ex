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
