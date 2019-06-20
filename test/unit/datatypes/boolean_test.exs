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
      "0"     => { false , "0"     , "false" },
      "1"     => { true  , "1"     , "true"  },
    },
    invalid: ~w(foo 10) ++ [42, 3.14, "tRuE", "FaLsE", "true false", "true foo"]

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


  describe "cast/1" do
    test "casting a boolean returns the input as it is" do
      assert RDF.true  |> RDF.Boolean.cast() == RDF.true
      assert RDF.false |> RDF.Boolean.cast() == RDF.false
    end

    test "casting a string with a value from the lexical value space of xsd:boolean" do
      assert RDF.string("true")  |> RDF.Boolean.cast() == RDF.true
      assert RDF.string("1")     |> RDF.Boolean.cast() == RDF.true

      assert RDF.string("false") |> RDF.Boolean.cast() == RDF.false
      assert RDF.string("0")     |> RDF.Boolean.cast() == RDF.false
    end

    test "casting a string with a value not in the lexical value space of xsd:boolean" do
      assert RDF.string("foo") |> RDF.Boolean.cast() == nil
    end

    test "casting an integer" do
      assert RDF.integer(0)  |> RDF.Boolean.cast() == RDF.false
      assert RDF.integer(1)  |> RDF.Boolean.cast() == RDF.true
      assert RDF.integer(42) |> RDF.Boolean.cast() == RDF.true
    end

    test "casting a decimal" do
      assert RDF.decimal(0)       |> RDF.Boolean.cast() == RDF.false
      assert RDF.decimal(0.0)     |> RDF.Boolean.cast() == RDF.false
      assert RDF.decimal("+0")    |> RDF.Boolean.cast() == RDF.false
      assert RDF.decimal("-0")    |> RDF.Boolean.cast() == RDF.false
      assert RDF.decimal("+0.0")  |> RDF.Boolean.cast() == RDF.false
      assert RDF.decimal("-0.0")  |> RDF.Boolean.cast() == RDF.false
      assert RDF.decimal(0.0e0)   |> RDF.Boolean.cast() == RDF.false

      assert RDF.decimal(1)       |> RDF.Boolean.cast() == RDF.true
      assert RDF.decimal(0.1)     |> RDF.Boolean.cast() == RDF.true
    end

    test "casting a double" do
      assert RDF.double(0)       |> RDF.Boolean.cast() == RDF.false
      assert RDF.double(0.0)     |> RDF.Boolean.cast() == RDF.false
      assert RDF.double("+0")    |> RDF.Boolean.cast() == RDF.false
      assert RDF.double("-0")    |> RDF.Boolean.cast() == RDF.false
      assert RDF.double("+0.0")  |> RDF.Boolean.cast() == RDF.false
      assert RDF.double("-0.0")  |> RDF.Boolean.cast() == RDF.false
      assert RDF.double("0.0E0") |> RDF.Boolean.cast() == RDF.false
      assert RDF.double("NAN")   |> RDF.Boolean.cast() == RDF.false

      assert RDF.double(1)       |> RDF.Boolean.cast() == RDF.true
      assert RDF.double(0.1)     |> RDF.Boolean.cast() == RDF.true
      assert RDF.double("-INF")  |> RDF.Boolean.cast() == RDF.true
    end

    @tag skip: "TODO: RDF.Float datatype"
    test "casting a float"

    test "with invalid literals" do
      assert RDF.boolean("42")  |> RDF.Boolean.cast() == nil
      assert RDF.integer(3.14)  |> RDF.Boolean.cast() == nil
      assert RDF.decimal("NAN") |> RDF.Boolean.cast() == nil
      assert RDF.double(true)   |> RDF.Boolean.cast() == nil
    end

    test "with literals of unsupported datatypes" do
      assert RDF.DateTime.now() |> RDF.Boolean.cast() == nil
    end

    test "with non-RDF terms" do
      assert RDF.Boolean.cast(:foo) == nil
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
