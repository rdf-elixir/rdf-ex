if String.to_integer(System.otp_release()) >= 25 do
  defmodule RDF.JSONTest do
    use ExUnit.Case

    doctest RDF.JSON

    alias RDF.{Literal, XSD}

    @valid_values [
      true,
      false,
      nil,
      0,
      42,
      3.14,
      %{},
      %{"a" => 42},
      %{"a" => [1, 2, 3]},
      %{"a" => %{"b" => 1}},
      [],
      [1, "foo", true],
      [%{"a" => 1}, %{"b" => 2}]
    ]

    @canonical_json [
      ~s(42),
      ~s(3.14),
      ~s(true),
      ~s(false),
      ~s(null),
      ~s("null"),
      ~s("a string"),
      ~s({"a":1}),
      ~s([1,2,3])
    ]

    @non_canonical_json [
      ~s([1, 2, 3]),
      ~s({"a": 1}),
      ~s( {"a":1} ),
      ~s({"b":2, "a":1}),
      """
      {
        "a": 1,
        "b": 2
      }
      """
    ]

    @valid_json @canonical_json ++ @non_canonical_json

    @invalid_json [
      ~s(invalid JSON),
      ~s([1, 2, 3),
      ~s([1, 2, 3),
      ~s({"a": 1)
    ]

    @invalid_values [
      "\xFF",
      %{%{a: 1} => 2}
    ]

    @invalid_typed [
      :atom,
      {"tuple"}
    ]

    @all_valid @valid_values ++ @valid_json
    @all_invalid @invalid_json ++ @invalid_typed ++ @invalid_values
    @all @all_valid ++ @all_invalid

    describe "new/2" do
      test "with non-string JSON-compatible values" do
        Enum.each(@valid_values, fn value ->
          assert %Literal{} = RDF.JSON.new(value)
        end)
      end

      test "with JSON-encoded strings (default behavior)" do
        Enum.each(@valid_json, fn json ->
          assert %Literal{} = literal = RDF.JSON.new(json)
          assert RDF.JSON.valid?(literal)
          assert RDF.JSON.value(literal) == Jason.decode!(json)
          assert RDF.JSON.lexical(literal) == json
        end)
      end

      test "with strings as values (using as_value: true)" do
        string = "a string"
        literal = RDF.JSON.new(string, as_value: true)
        assert RDF.JSON.valid?(literal)
        assert RDF.JSON.value(literal) == string
      end

      test "with invalid values" do
        Enum.each(@invalid_values ++ @invalid_json, fn value ->
          assert %Literal{} = RDF.JSON.new(value)
        end)
      end

      test ":pretty option" do
        value = %{"a" => 1, "nested" => %{"b" => 2}}
        literal = RDF.JSON.new(value, pretty: true)
        assert RDF.JSON.lexical(literal) == Jason.encode!(value, pretty: true)
        assert RDF.JSON.value(literal) == value

        literal = value |> Jcs.encode() |> RDF.JSON.new(pretty: true)
        assert RDF.JSON.lexical(literal) == Jason.encode!(value, pretty: true)
        assert RDF.JSON.value(literal) == value
      end

      test ":jason_encode option" do
        value = %CustomJSON{value: "test"}

        assert RDF.JSON.new(value) |> RDF.JSON.valid?() == false

        literal = RDF.JSON.new(value, jason_encode: true)
        assert RDF.JSON.valid?(literal)
        assert RDF.JSON.lexical(literal) == ~s({"custom":"test"})
      end

      test ":pretty and :jason_encode options combined" do
        value = %CustomJSON{value: "test"}

        literal = RDF.JSON.new(value, pretty: true, jason_encode: true)
        assert RDF.JSON.valid?(literal)

        assert RDF.JSON.lexical(literal) ==
                 """
                 {
                   "custom": "test"
                 }
                 """
                 |> String.trim()
      end

      test ":canonicalize option" do
        Enum.each(@valid_values, fn value ->
          assert RDF.JSON.new(value, canonicalize: true) ==
                   value |> RDF.JSON.new() |> RDF.JSON.canonical()
        end)

        Enum.each(@non_canonical_json, fn value ->
          assert RDF.JSON.new(value, canonicalize: true) ==
                   value |> RDF.JSON.new() |> RDF.JSON.canonical()

          assert RDF.JSON.new(value, as_value: true, canonicalize: true) ==
                   value |> RDF.JSON.new(as_value: true) |> RDF.JSON.canonical()
        end)
      end

      test ":jason_encode and :canonicalize options combined" do
        value = %CustomJSON{value: 1.0}

        literal = RDF.JSON.new(value, jason_encode: true, canonicalize: true)
        assert RDF.JSON.valid?(literal)

        assert RDF.JSON.lexical(literal) == ~s({"custom":1})
      end

      test ":pretty and :canonicalize options combined" do
        assert_raise ArgumentError, fn ->
          RDF.JSON.new(1, pretty: true, canonicalize: true)
        end
      end
    end

    describe "new!/2" do
      test "with valid values, it behaves the same as new" do
        Enum.each(@all_valid, fn value ->
          assert RDF.JSON.new!(value) ==
                   RDF.JSON.new(value)

          assert RDF.JSON.new!(value, canonicalize: true) ==
                   RDF.JSON.new(value, canonicalize: true)
        end)

        string = "some string"

        assert RDF.JSON.new!(string, as_value: true) ==
                 RDF.JSON.new(string, as_value: true)

        assert RDF.JSON.new!("null") == RDF.JSON.new("null")
      end

      test "with invalid values" do
        Enum.each(@all_invalid, fn value ->
          assert_raise ArgumentError, fn -> RDF.JSON.new!(value) end
        end)
      end
    end

    describe "value/2" do
      test "with valid literals" do
        Enum.each(@valid_values, fn value ->
          assert RDF.JSON.new!(value) |> RDF.JSON.value() == value
        end)

        string = "some string"
        assert RDF.JSON.new(string, as_value: true) |> RDF.JSON.value() == string

        Enum.each(@valid_json, fn json ->
          assert RDF.JSON.new!(json) |> RDF.JSON.value() == Jason.decode!(json)
          assert RDF.JSON.new!(json, as_value: true) |> RDF.JSON.value() == json
        end)
      end

      test "with invalid literals" do
        Enum.each(@all_invalid, fn value ->
          assert RDF.JSON.new(value) |> RDF.JSON.value() == :invalid
        end)
      end

      test "special case: null" do
        assert RDF.JSON.new(nil) |> RDF.JSON.value() == nil
        assert RDF.JSON.new("null") |> RDF.JSON.value() == nil
        assert RDF.JSON.new("null", as_value: true) |> RDF.JSON.value() == "null"
      end

      test "with Jason decode options" do
        assert ~s({"foo": 1}) |> RDF.JSON.new!() |> RDF.JSON.value(keys: :atoms) ==
                 %{foo: 1}
      end
    end

    describe "lexical/1" do
      test "with valid literals from values" do
        Enum.each(@valid_values, fn value ->
          assert RDF.JSON.new(value) |> RDF.JSON.lexical() == Jcs.encode(value)
        end)
      end

      test "with string values (as_value: true)" do
        string = "some string"
        assert RDF.JSON.new(string, as_value: true) |> RDF.JSON.lexical() == Jcs.encode(string)

        Enum.each(@valid_json, fn json ->
          assert RDF.JSON.new(json, as_value: true) |> RDF.JSON.lexical() == Jcs.encode(json)
        end)
      end

      test "with valid literals from JSON strings" do
        Enum.each(@valid_json, fn json ->
          assert RDF.JSON.new(json) |> RDF.JSON.lexical() == json
        end)
      end

      test "with invalid literals" do
        Enum.each(@all_invalid, fn
          value when is_binary(value) ->
            assert RDF.JSON.new(value) |> RDF.JSON.lexical() == value

          value ->
            assert RDF.JSON.new(value) |> RDF.JSON.lexical() == inspect(value)
        end)
      end

      test "special case: null" do
        assert RDF.JSON.new(nil) |> RDF.JSON.lexical() == "null"
        assert RDF.JSON.new("null") |> RDF.JSON.lexical() == "null"
        assert RDF.JSON.new("null", as_value: true) |> RDF.JSON.lexical() == ~s("null")
      end
    end

    describe "canonical/1" do
      test "with valid literals from values" do
        Enum.each(@valid_values, fn value ->
          assert %Literal{} = canonical = RDF.JSON.new(value) |> RDF.JSON.canonical()
          assert RDF.JSON.lexical(canonical) == Jcs.encode(value)
          assert RDF.JSON.value(canonical) == value
        end)
      end

      test "with string values (as_value: true)" do
        string = "some string"

        assert %Literal{} =
                 canonical = RDF.JSON.new(string, as_value: true) |> RDF.JSON.canonical()

        assert RDF.JSON.lexical(canonical) == Jcs.encode(string)
        assert RDF.JSON.value(canonical) == string

        Enum.each(@valid_json, fn json ->
          assert %Literal{} =
                   canonical = RDF.JSON.new(json, as_value: true) |> RDF.JSON.canonical()

          assert RDF.JSON.lexical(canonical) == Jcs.encode(json)
          assert RDF.JSON.value(canonical) == json
        end)
      end

      test "with valid literals from JSON strings" do
        Enum.each(@canonical_json, fn json ->
          assert RDF.JSON.new(json) |> RDF.JSON.canonical() == RDF.JSON.new(json)
        end)

        Enum.each(@non_canonical_json, fn json ->
          value = Jason.decode!(json)
          assert %Literal{} = canonical = RDF.JSON.new(json) |> RDF.JSON.canonical()
          assert RDF.JSON.lexical(canonical) == Jcs.encode(value)
          assert RDF.JSON.value(canonical) == value
        end)
      end

      test "with invalid literals" do
        Enum.each(@all_invalid, fn value ->
          assert RDF.JSON.new(value) |> RDF.JSON.canonical() == RDF.JSON.new(value)
        end)
      end

      test "special case: null" do
        assert %Literal{} = canonical = RDF.JSON.new(nil) |> RDF.JSON.canonical()
        assert RDF.JSON.lexical(canonical) == "null"
        assert RDF.JSON.value(canonical) == nil

        assert %Literal{} = canonical = RDF.JSON.new("null") |> RDF.JSON.canonical()
        assert RDF.JSON.lexical(canonical) == "null"
        assert RDF.JSON.value(canonical) == nil

        assert %Literal{} =
                 canonical = RDF.JSON.new("null", as_value: true) |> RDF.JSON.canonical()

        assert RDF.JSON.lexical(canonical) == ~s("null")
        assert RDF.JSON.value(canonical) == "null"
      end
    end

    describe "canonical?/1" do
      test "with valid literals from values" do
        Enum.each(@valid_values, fn value ->
          assert RDF.JSON.new(value) |> RDF.JSON.canonical?() == true
        end)
      end

      test "with string values (as_value: true)" do
        string = "some string"
        assert RDF.JSON.new(string, as_value: true) |> RDF.JSON.canonical?() == true

        Enum.each(@valid_json, fn json ->
          assert RDF.JSON.new(json, as_value: true) |> RDF.JSON.canonical?() == true
        end)
      end

      test "with canonical literals from JSON strings" do
        Enum.each(@canonical_json, fn json ->
          assert RDF.JSON.new(json) |> RDF.JSON.canonical?() == true
        end)
      end

      test "with non-canonical literals from JSON strings" do
        Enum.each(@non_canonical_json, fn json ->
          assert RDF.JSON.new(json) |> RDF.JSON.canonical?() == false
        end)
      end

      test "with invalid literals" do
        Enum.each(@all_invalid, fn value ->
          refute RDF.JSON.new(value) |> RDF.JSON.canonical?()
        end)
      end

      test "special case: null" do
        assert RDF.JSON.new(nil) |> RDF.JSON.canonical?() == true
        assert RDF.JSON.new("null") |> RDF.JSON.canonical?() == true
        assert RDF.JSON.new("null", as_value: true) |> RDF.JSON.canonical?() == true
      end
    end

    describe "valid?/1" do
      test "with valid values" do
        Enum.each(@all_valid, fn value ->
          assert RDF.JSON.new(value) |> RDF.JSON.valid?() == true
        end)

        Enum.each(@all_valid, fn value ->
          assert RDF.JSON.new(value, as_value: true) |> RDF.JSON.valid?() == true
        end)
      end

      test "with invalid_values" do
        Enum.each(@all_invalid, fn value ->
          assert RDF.JSON.new(value) |> RDF.JSON.valid?() == false
        end)
      end
    end

    test "datatype?/1" do
      assert RDF.JSON.datatype?(RDF.JSON) == true

      Enum.each(@all, fn value ->
        literal = RDF.JSON.new(value)
        assert RDF.JSON.datatype?(literal) == true
        assert RDF.JSON.datatype?(literal.literal) == true
      end)
    end

    test "datatype_id/1" do
      Enum.each(@all, fn value ->
        assert RDF.JSON.new(value) |> RDF.JSON.datatype_id() ==
                 RDF.iri(RDF.JSON.id())
      end)
    end

    test "language/1" do
      Enum.each(@all, fn value ->
        assert RDF.JSON.new(value) |> RDF.JSON.language() == nil
      end)
    end

    describe "cast/1" do
      test "when given a valid RDF.JSON literal" do
        Enum.each(@all_valid, fn value ->
          assert RDF.JSON.new(value) |> RDF.JSON.cast() ==
                   RDF.JSON.new(value)
        end)
      end

      test "when given a literal with a datatype which is not castable" do
        assert XSD.String.new("foo") |> RDF.JSON.cast() == nil
        assert XSD.Integer.new(12_345) |> RDF.JSON.cast() == nil
      end

      test "with invalid literals" do
        assert XSD.Integer.new(3.14) |> RDF.JSON.cast() == nil
      end

      test "with non-coercible value" do
        assert RDF.JSON.cast(:foo) == nil
        assert RDF.JSON.cast(make_ref()) == nil
      end
    end

    describe "equal_value?/2" do
      test "with valid equal values" do
        Enum.each(@all_valid, fn value ->
          literal = RDF.JSON.new(value)
          assert RDF.JSON.equal_value?(literal, literal) == true
        end)
      end

      test "with valid unequal values" do
        assert RDF.JSON.equal_value?(RDF.JSON.new("a"), RDF.JSON.new("b")) == false
        assert RDF.JSON.equal_value?(RDF.JSON.new(1), RDF.JSON.new(2)) == false
      end

      test "with different lexical forms but same value" do
        assert RDF.JSON.equal_value?(
                 RDF.JSON.new(~s({"a": 1})),
                 RDF.JSON.new(%{"a" => 1})
               ) == true

        assert RDF.JSON.equal_value?(
                 RDF.JSON.new(~s({"x": {"a": 1, "b": 2}})),
                 RDF.JSON.new(~s({"x": {"b": 2, "a": 1}}))
               ) == true

        assert RDF.JSON.equal_value?(RDF.JSON.new(1), RDF.JSON.new(1.0)) == true

        assert RDF.JSON.equal_value?(
                 RDF.JSON.new("1.23456789"),
                 RDF.JSON.new("1.234567890000")
               ) == true

        # not actually different lexical forms, but different forms of initialization
        assert RDF.JSON.equal_value?(
                 RDF.JSON.new("42"),
                 RDF.JSON.new(42)
               ) == true
      end

      test "with invalid values" do
        Enum.each(@all_invalid, fn value ->
          literal = RDF.JSON.new(value)
          assert RDF.JSON.equal_value?(literal, literal) == true
        end)
      end
    end

    describe "compare/2" do
      test "with equal values" do
        Enum.each(@all_valid, fn value ->
          assert RDF.JSON.compare(
                   RDF.JSON.new(value),
                   RDF.JSON.new(value)
                 ) == :eq
        end)
      end

      test "ordering based on JCS representation" do
        ordered = [
          ~s("a string"),
          -1,
          42,
          [1, 2, 3],
          false,
          nil,
          true,
          %{"a" => 1}
        ]

        ordered_literals = Enum.map(ordered, &RDF.JSON.new/1)

        Enum.chunk_every(ordered_literals, 2, 1, :discard)
        |> Enum.each(fn [a, b] ->
          assert RDF.JSON.compare(a, b) == :lt, "expected #{inspect(a)} < #{inspect(b)}"
          assert RDF.JSON.compare(b, a) == :gt, "expected #{inspect(b)} > #{inspect(a)}"
        end)
      end

      test "different values with same JCS representation" do
        examples = [
          {1, 1.0},
          {~s({"a": 1}), ~s({"a":1})}
        ]

        Enum.each(examples, fn {value1, value2} ->
          assert RDF.JSON.compare(RDF.JSON.new(value1), RDF.JSON.new(value2)) == :eq
        end)
      end

      test "comparing same type values" do
        assert RDF.JSON.compare(
                 RDF.JSON.new("a", as_value: true),
                 RDF.JSON.new("b", as_value: true)
               ) == :lt

        assert RDF.JSON.compare(RDF.JSON.new(1), RDF.JSON.new(2)) == :lt

        assert RDF.JSON.compare(RDF.JSON.new([1]), RDF.JSON.new([2])) == :lt

        assert RDF.JSON.compare(
                 RDF.JSON.new(%{"a" => 1}),
                 RDF.JSON.new(%{"b" => 1})
               ) == :lt
      end

      test "with invalid values" do
        Enum.each(@all_invalid, fn value ->
          literal1 = RDF.JSON.new(value)
          literal2 = RDF.JSON.new(value)
          assert RDF.JSON.compare(literal1, literal2) == nil

          Enum.each(@valid_values, fn valid ->
            assert RDF.JSON.compare(literal1, RDF.JSON.new(valid)) == nil
            assert RDF.JSON.compare(RDF.JSON.new(valid), literal1) == nil
          end)
        end)
      end

      test "special cases" do
        assert RDF.JSON.compare(RDF.JSON.new("null", as_value: true), RDF.JSON.new(nil)) == :lt
        assert RDF.JSON.compare(RDF.JSON.new(nil), RDF.JSON.new(nil)) == :eq
        assert RDF.JSON.compare(RDF.JSON.new("null"), RDF.JSON.new(nil)) == :eq
      end
    end

    describe "update/2" do
      test "with map" do
        assert %{a: 1}
               |> RDF.JSON.new()
               |> Literal.update(fn map ->
                 Map.put(map, :b, 2)
               end) == RDF.JSON.new(%{a: 1, b: 2})
      end

      test "result is interpreted as value" do
        assert RDF.JSON.new(1) |> Literal.update(fn _ -> "foo" end) ==
                 RDF.JSON.new("foo", as_value: true)
      end
    end
  end
end
