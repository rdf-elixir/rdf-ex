defmodule RDF.BooleanTest do
  use RDF.Datatype.Test.Case, datatype: RDF.Boolean, id: RDF.NS.XSD.boolean,
    valid: %{
    # input   => { value , lexical , canonicalized }
      true    => { true  , nil     , "true"  },
      false   => { false , nil     , "false" },
      0       => { false , nil     , "false" },
      1       => { true  , nil     , "true"  },
      "true"  => { true  , nil     , "true"  },
      "false" => { false , nil     , "false" },
      "tRuE"  => { true  , "tRuE"  , "true"  },
      "FaLsE" => { false , "FaLsE" , "false" },
      "0"     => { false , "0"     , "false" },
      "1"     => { true  , "1"     , "true"  },
    },
    invalid: ~w(foo 10) ++ [42, 3.14, "true false", "true foo"]


  describe "equality" do
    test "two literals are equal when they have the same datatype and lexical form" do
      [
        {true   , "true" },
        {false  , "false"},
        {1      , "true" },
        {0      , "false"},
      ]
      |> Enum.each(fn {l, r} ->
           assert Boolean.new(l) == Boolean.new(r)
         end)
    end

    test "two literals with same value but different lexical form are not equal" do
      [
        {"True"  , "true" },
        {"FALSE" , "false"},
        {"1"     , "true" },
        {"0"     , "false"},
      ]
      |> Enum.each(fn {l, r} ->
           assert Boolean.new(l) != Boolean.new(r)
         end)
    end
  end

end
