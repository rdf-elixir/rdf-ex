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

  import RDF.Sigils

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

  describe "ebv/1" do
    import RDF.Boolean, only: [ebv: 1]

    test "if the argument is a xsd:boolean typed literal and it has a valid lexical form, the EBV is the value of that argument" do
      [
        RDF.true,
        RDF.false,
        RDF.boolean(1),
        RDF.boolean("0"),
      ]
      |> Enum.each(fn value ->
           assert ebv(value) == value
         end)
    end

    test "any literal whose type is xsd:boolean or numeric is false if the lexical form is not valid for that datatype" do
      [
        RDF.boolean(42),
        RDF.integer(3.14),
        RDF.double("Foo"),
      ]
      |> Enum.each(fn value ->
           assert ebv(value) == RDF.false
         end)
    end

    test "if the argument is a plain or xsd:string typed literal, the EBV is false if the operand value has zero length" do
      assert ebv(~L"")   == RDF.false
      assert ebv(~L""de) == RDF.false
    end

    test "if the argument is a plain or xsd:string typed literal, the EBV is true if the operand value has length greater zero" do
      assert ebv(~L"bar")   == RDF.true
      assert ebv(~L"baz"de) == RDF.true
    end

    test "if the argument is a numeric type with a valid lexical form having the value NaN or being numerically equal to zero, the EBV is false" do
      [
        RDF.integer(0),
        RDF.integer("0"),
        RDF.double("0"),
        RDF.double("0.0"),
        RDF.double(:nan),
        RDF.double("NaN"),
      ]
      |> Enum.each(fn value ->
           assert ebv(value) == RDF.false
         end)
    end

    test "if the argument is a numeric type with a valid lexical form being numerically unequal to zero, the EBV is true" do
      assert ebv(RDF.integer(42))    == RDF.true
      assert ebv(RDF.integer("42"))  == RDF.true
      assert ebv(RDF.double("3.14")) == RDF.true
    end

    test "Elixirs booleans are treated as RDF.Booleans" do
      assert ebv(true)  == RDF.true
      assert ebv(false) == RDF.false
    end

    test "Elixirs strings are treated as RDF.Strings" do
      assert ebv("")    == RDF.false
      assert ebv("foo") == RDF.true
      assert ebv("0")   == RDF.true
    end

    test "Elixirs numbers are treated as RDF.Numerics" do
      assert ebv(0)   == RDF.false
      assert ebv(0.0) == RDF.false

      assert ebv(42)   == RDF.true
      assert ebv(3.14) == RDF.true
    end

    test "all other arguments, produce nil" do
      [
        RDF.date("2010-01-01"),
        RDF.time("00:00:00"),
        nil,
        self(),
        [true],
        {true},
        %{foo: :bar},
      ]
      |> Enum.each(fn value ->
           assert ebv(value) == nil
         end)
    end
  end

  test "truth-table of logical_and" do
    [
      {RDF.true,  RDF.true,  RDF.true},
      {RDF.true,  RDF.false, RDF.false},
      {RDF.false, RDF.true,  RDF.false},
      {RDF.false, RDF.false, RDF.false},
      {RDF.true,  nil,       nil},
      {nil,       RDF.true,  nil},
      {RDF.false, nil,       RDF.false},
      {nil,       RDF.false, RDF.false},
      {nil,       nil,       nil},
    ]
    |> Enum.each(fn {left, right, result} ->
         assert RDF.Boolean.logical_and(left, right) == result,
            "expected logical_and(#{inspect left}, #{inspect right}) to be #{inspect result}, but got #{inspect RDF.Boolean.logical_and(left, right)}"
       end)
  end

  test "truth-table of logical_or" do
    [
      {RDF.true,  RDF.true,  RDF.true},
      {RDF.true,  RDF.false, RDF.true},
      {RDF.false, RDF.true,  RDF.true},
      {RDF.false, RDF.false, RDF.false},
      {RDF.true,  nil,       RDF.true},
      {nil,       RDF.true,  RDF.true},
      {RDF.false, nil,       nil},
      {nil,       RDF.false, nil},
      {nil,       nil,       nil},
    ]
    |> Enum.each(fn {left, right, result} ->
         assert RDF.Boolean.logical_or(left, right) == result,
            "expected logical_or(#{inspect left}, #{inspect right}) to be #{inspect result}, but got #{inspect RDF.Boolean.logical_and(left, right)}"
       end)
  end

end
