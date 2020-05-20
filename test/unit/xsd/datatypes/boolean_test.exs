defmodule RDF.XSD.BooleanTest do
  use RDF.XSD.Datatype.Test.Case,
    datatype: RDF.XSD.Boolean,
    name: "boolean",
    primitive: true,
    valid: %{
      # input => { value, lexical, canonicalized }
      true => {true, nil, "true"},
      false => {false, nil, "false"},
      0 => {false, nil, "false"},
      1 => {true, nil, "true"},
      "true" => {true, nil, "true"},
      "false" => {false, nil, "false"},
      "0" => {false, "0", "false"},
      "1" => {true, "1", "true"}
    },
    invalid: ["foo", "10", 42, 3.14, "tRuE", "FaLsE", "true false", "true foo"]

  describe "cast/1" do
    test "casting a boolean returns the input as it is" do
      assert XSD.true() |> XSD.Boolean.cast() == XSD.true()
      assert XSD.false() |> XSD.Boolean.cast() == XSD.false()
    end

    test "casting a string with a value from the lexical value space of xsd:boolean" do
      assert XSD.string("true") |> XSD.Boolean.cast() == XSD.true()
      assert XSD.string("1") |> XSD.Boolean.cast() == XSD.true()

      assert XSD.string("false") |> XSD.Boolean.cast() == XSD.false()
      assert XSD.string("0") |> XSD.Boolean.cast() == XSD.false()
    end

    test "casting a string with a value not in the lexical value space of xsd:boolean" do
      assert XSD.string("foo") |> XSD.Boolean.cast() == nil
    end

    test "casting an integer" do
      assert XSD.integer(0) |> XSD.Boolean.cast() == XSD.false()
      assert XSD.integer(1) |> XSD.Boolean.cast() == XSD.true()
      assert XSD.integer(42) |> XSD.Boolean.cast() == XSD.true()
    end

    test "casting a decimal" do
      assert XSD.decimal(0) |> XSD.Boolean.cast() == XSD.false()
      assert XSD.decimal(0.0) |> XSD.Boolean.cast() == XSD.false()
      assert XSD.decimal("+0") |> XSD.Boolean.cast() == XSD.false()
      assert XSD.decimal("-0") |> XSD.Boolean.cast() == XSD.false()
      assert XSD.decimal("+0.0") |> XSD.Boolean.cast() == XSD.false()
      assert XSD.decimal("-0.0") |> XSD.Boolean.cast() == XSD.false()
      assert XSD.decimal(0.0e0) |> XSD.Boolean.cast() == XSD.false()

      assert XSD.decimal(1) |> XSD.Boolean.cast() == XSD.true()
      assert XSD.decimal(0.1) |> XSD.Boolean.cast() == XSD.true()
    end

    test "casting a double" do
      assert XSD.double(0) |> XSD.Boolean.cast() == XSD.false()
      assert XSD.double(0.0) |> XSD.Boolean.cast() == XSD.false()
      assert XSD.double("+0") |> XSD.Boolean.cast() == XSD.false()
      assert XSD.double("-0") |> XSD.Boolean.cast() == XSD.false()
      assert XSD.double("+0.0") |> XSD.Boolean.cast() == XSD.false()
      assert XSD.double("-0.0") |> XSD.Boolean.cast() == XSD.false()
      assert XSD.double("0.0E0") |> XSD.Boolean.cast() == XSD.false()
      assert XSD.double("NAN") |> XSD.Boolean.cast() == XSD.false()

      assert XSD.double(1) |> XSD.Boolean.cast() == XSD.true()
      assert XSD.double(0.1) |> XSD.Boolean.cast() == XSD.true()
      assert XSD.double("-INF") |> XSD.Boolean.cast() == XSD.true()
    end

    test "casting a float" do
      assert XSD.float(0) |> XSD.Boolean.cast() == XSD.false()
      assert XSD.float(0.0) |> XSD.Boolean.cast() == XSD.false()
      assert XSD.float("+0") |> XSD.Boolean.cast() == XSD.false()
      assert XSD.float("-0.0") |> XSD.Boolean.cast() == XSD.false()
      assert XSD.float("0.0E0") |> XSD.Boolean.cast() == XSD.false()
      assert XSD.float("NAN") |> XSD.Boolean.cast() == XSD.false()

      assert XSD.float(1) |> XSD.Boolean.cast() == XSD.true()
      assert XSD.float(0.1) |> XSD.Boolean.cast() == XSD.true()
      assert XSD.float("-INF") |> XSD.Boolean.cast() == XSD.true()
    end

    test "with invalid literals" do
      assert XSD.boolean("42") |> XSD.Boolean.cast() == nil
      assert XSD.integer(3.14) |> XSD.Boolean.cast() == nil
      assert XSD.decimal("NAN") |> XSD.Boolean.cast() == nil
      assert XSD.double(true) |> XSD.Boolean.cast() == nil
    end

    test "with values of unsupported datatypes" do
      assert XSD.date("2020-01-01") |> XSD.Boolean.cast() == nil
    end
  end

  describe "ebv/1" do
    import XSD.Boolean, only: [ebv: 1]

    test "if the argument is a xsd:boolean typed literal and it has a valid lexical form, the EBV is the value of that argument" do
      [
        XSD.true(),
        XSD.false(),
        XSD.boolean(1),
        XSD.boolean("0")
      ]
      |> Enum.each(fn literal ->
        assert ebv(literal) == literal
      end)
    end

    test "any literal whose type is xsd:boolean or numeric is false if the lexical form is not valid for that datatype" do
      [
        XSD.boolean(42),
        XSD.integer(3.14),
        XSD.double("Foo")
      ]
      |> Enum.each(fn literal ->
        assert ebv(literal) == XSD.false()
      end)
    end

    test "if the argument is a xsd:string, the EBV is false if the operand value has zero length" do
      assert ebv(XSD.string("")) == XSD.false()
    end

    test "if the argument is a xsd:string, the EBV is true if the operand value has length greater zero" do
      assert ebv(XSD.string("bar")) == XSD.true()
    end

    test "if the argument is a numeric literal with a valid lexical form having the value NaN or being numerically equal to zero, the EBV is false" do
      [
        XSD.integer(0),
        XSD.integer("0"),
        XSD.double("0"),
        XSD.double("0.0"),
        XSD.double(:nan),
        XSD.double("NaN")
      ]
      |> Enum.each(fn literal ->
        assert ebv(literal) == XSD.false()
      end)
    end

    test "if the argument is a numeric type with a valid lexical form being numerically unequal to zero, the EBV is true" do
      assert ebv(XSD.integer(42)) == XSD.true()
      assert ebv(XSD.integer("42")) == XSD.true()
      assert ebv(XSD.double("3.14")) == XSD.true()
    end

    test "Elixirs booleans are treated as XSD.Booleans" do
      assert ebv(true) == XSD.true()
      assert ebv(false) == XSD.false()
    end

    test "Elixirs strings are treated as XSD.strings" do
      assert ebv("") == XSD.false()
      assert ebv("foo") == XSD.true()
      assert ebv("0") == XSD.true()
    end

    test "Elixirs numbers are treated as XSD.Numerics" do
      assert ebv(0) == XSD.false()
      assert ebv(0.0) == XSD.false()

      assert ebv(42) == XSD.true()
      assert ebv(3.14) == XSD.true()
    end

    test "all other arguments, produce nil" do
      [
        XSD.date("2010-01-01"),
        XSD.time("00:00:00"),
        nil,
        self(),
        [true],
        {true},
        %{foo: :bar}
      ]
      |> Enum.each(fn value ->
        assert ebv(value) == nil
      end)
    end
  end

  test "truth-table of logical_and" do
    [
      {XSD.true(), XSD.true(), XSD.true()},
      {XSD.true(), XSD.false(), XSD.false()},
      {XSD.false(), XSD.true(), XSD.false()},
      {XSD.false(), XSD.false(), XSD.false()},
      {XSD.true(), nil, nil},
      {nil, XSD.true(), nil},
      {XSD.false(), nil, XSD.false()},
      {nil, XSD.false(), XSD.false()},
      {nil, nil, nil}
    ]
    |> Enum.each(fn {left, right, result} ->
      assert XSD.Boolean.logical_and(left, right) == result,
             "expected logical_and(#{inspect(left)}, #{inspect(right)}) to be #{inspect(result)}, but got #{
               inspect(XSD.Boolean.logical_and(left, right))
             }"
    end)
  end

  test "truth-table of logical_or" do
    [
      {XSD.true(), XSD.true(), XSD.true()},
      {XSD.true(), XSD.false(), XSD.true()},
      {XSD.false(), XSD.true(), XSD.true()},
      {XSD.false(), XSD.false(), XSD.false()},
      {XSD.true(), nil, XSD.true()},
      {nil, XSD.true(), XSD.true()},
      {XSD.false(), nil, nil},
      {nil, XSD.false(), nil},
      {nil, nil, nil}
    ]
    |> Enum.each(fn {left, right, result} ->
      assert XSD.Boolean.logical_or(left, right) == result,
             "expected logical_or(#{inspect(left)}, #{inspect(right)}) to be #{inspect(result)}, but got #{
               inspect(XSD.Boolean.logical_and(left, right))
             }"
    end)
  end
end
