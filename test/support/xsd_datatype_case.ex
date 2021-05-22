defmodule RDF.XSD.Datatype.Test.Case do
  use ExUnit.CaseTemplate

  alias RDF.XSD

  using(opts) do
    datatype = Keyword.fetch!(opts, :datatype)
    datatype_name = Keyword.fetch!(opts, :name)

    datatype_iri = Keyword.get(opts, :iri, RDF.NS.XSD.__base_iri__() <> datatype_name)

    valid = Keyword.get(opts, :valid)
    invalid = Keyword.get(opts, :invalid)
    primitive = Keyword.get(opts, :primitive)
    base = unless primitive, do: Keyword.fetch!(opts, :base)
    base_primitive = unless primitive, do: Keyword.fetch!(opts, :base_primitive)
    applicable_facets = Keyword.get(opts, :applicable_facets, [])
    facets = Keyword.get(opts, :facets)

    quote do
      alias RDF.XSD
      alias RDF.XSD.Datatype
      alias RDF.TestDatatypes.{Age, DecimalUnitInterval, DoubleUnitInterval, FloatUnitInterval}
      alias unquote(datatype)
      import unquote(__MODULE__)

      doctest unquote(datatype)

      @moduletag datatype: unquote(datatype)

      if unquote(valid) do
        @valid unquote(valid)
        @invalid unquote(invalid)

        test "registration" do
          assert unquote(datatype) in RDF.Literal.Datatype.Registry.builtin_datatypes()
          assert unquote(datatype) in RDF.Literal.Datatype.Registry.builtin_xsd_datatypes()

          assert unquote(datatype) |> RDF.Literal.Datatype.Registry.builtin_datatype?()
          assert unquote(datatype) |> RDF.Literal.Datatype.Registry.builtin_xsd_datatype?()

          assert RDF.Literal.Datatype.get(unquote(datatype_iri)) == unquote(datatype)
          assert XSD.Datatype.get(unquote(datatype_iri)) == unquote(datatype)
        end

        test "primitive/0" do
          assert unquote(datatype).primitive?() == unquote(!!primitive)
        end

        test "base/0" do
          if unquote(primitive) do
            assert unquote(datatype).base == nil
          else
            assert unquote(datatype).base == unquote(base)
          end
        end

        test "base_primitive/0" do
          if unquote(primitive) do
            assert unquote(datatype).base_primitive == unquote(datatype)
          else
            assert unquote(datatype).base_primitive == unquote(base_primitive)
          end
        end

        test "derived_from?/1" do
          assert unquote(datatype).derived_from?(unquote(datatype)) == false

          unless unquote(primitive) do
            assert unquote(datatype).derived_from?(unquote(base)) == true
            assert unquote(datatype).derived_from?(unquote(base_primitive)) == true
          end
        end

        describe "datatype?/1" do
          test "with itself" do
            assert unquote(datatype).datatype?(unquote(datatype)) == true
          end

          test "with non-RDF values" do
            assert unquote(datatype).datatype?(self()) == false
            assert unquote(datatype).datatype?(Elixir.Enum) == false
            assert unquote(datatype).datatype?(:foo) == false
          end

          unless unquote(primitive) do
            test "on a base datatype" do
              # We're using apply here to suppress "nil.datatype?/1 is undefined" warnings caused by the primitives
              assert apply(unquote(base), :datatype?, [unquote(datatype)]) == true
              assert apply(unquote(base_primitive), :datatype?, [unquote(datatype)]) == true
            end
          end
        end

        test "applicable_facets/0" do
          assert MapSet.new(unquote(datatype).applicable_facets()) ==
                   MapSet.new(unquote(applicable_facets))
        end

        if unquote(facets) do
          test "facets" do
            Enum.each(unquote(facets), fn {facet, value} ->
              assert apply(unquote(datatype), facet, []) == value
            end)
          end
        end

        test "name/0" do
          assert unquote(datatype).name() == unquote(datatype_name)
        end

        test "id/0" do
          assert unquote(datatype).id() == RDF.iri(unquote(datatype_iri))
        end

        describe "general datatype?/1" do
          test "on the exact same datatype" do
            assert unquote(datatype).datatype?(unquote(datatype)) == true

            Enum.each(@valid, fn {input, _} ->
              literal = unquote(datatype).new(input)
              assert unquote(datatype).datatype?(literal) == true
              assert unquote(datatype).datatype?(literal.literal) == true
            end)
          end

          unless unquote(primitive) do
            test "on the base datatype" do
              assert unquote(base).datatype?(unquote(datatype)) == true

              Enum.each(@valid, fn {input, _} ->
                literal = unquote(datatype).new(input)
                assert unquote(base).datatype?(literal) == true
                assert unquote(base).datatype?(literal.literal) == true
              end)
            end

            test "on the base primitive datatype" do
              assert unquote(base_primitive).datatype?(unquote(datatype)) == true

              Enum.each(@valid, fn {input, _} ->
                literal = unquote(datatype).new(input)
                assert unquote(base_primitive).datatype?(literal) == true
                assert unquote(base_primitive).datatype?(literal.literal) == true
              end)
            end
          end
        end

        test "datatype_id/1" do
          Enum.each(@valid, fn {input, _} ->
            assert unquote(datatype).new(input) |> unquote(datatype).datatype_id() ==
                     RDF.iri(unquote(datatype_iri))
          end)
        end

        test "language/1" do
          Enum.each(@valid, fn {input, _} ->
            assert unquote(datatype).new(input) |> unquote(datatype).language() == nil
          end)
        end

        describe "general new" do
          Enum.each(@valid, fn {input, {value, lexical, _}} ->
            expected = %RDF.Literal{
              literal: %unquote(datatype){value: value, uncanonical_lexical: lexical}
            }

            @tag example: %{input: input, output: expected}
            test "valid: #{unquote(datatype)}.new(#{inspect(input)})", %{example: example} do
              assert unquote(datatype).new(example.input) == example.output
            end
          end)

          Enum.each(@invalid, fn value ->
            expected = %RDF.Literal{
              literal: %unquote(datatype){
                uncanonical_lexical: unquote(datatype).init_invalid_lexical(value, [])
              }
            }

            @tag example: %{input: value, output: expected}
            test "invalid: #{unquote(datatype)}.new(#{inspect(value)})",
                 %{example: example} do
              assert unquote(datatype).new(example.input) == example.output
            end
          end)

          test "canonicalize option" do
            Enum.each(@valid, fn {input, _} ->
              assert unquote(datatype).new(input, canonicalize: true) ==
                       unquote(datatype).new(input) |> unquote(datatype).canonical()
            end)

            Enum.each(@invalid, fn input ->
              assert unquote(datatype).new(input, canonicalize: true) ==
                       unquote(datatype).new(input) |> unquote(datatype).canonical()
            end)
          end
        end

        describe "general new!" do
          test "with valid values, it behaves the same as new" do
            Enum.each(@valid, fn {input, _} ->
              assert unquote(datatype).new!(input) == unquote(datatype).new(input)

              assert unquote(datatype).new!(input) ==
                       unquote(datatype).new(input)

              assert unquote(datatype).new!(input, canonicalize: true) ==
                       unquote(datatype).new(input, canonicalize: true)
            end)
          end

          test "with invalid values, it raises an error" do
            Enum.each(@invalid, fn value ->
              assert_raise ArgumentError, fn -> unquote(datatype).new!(value) end

              assert_raise ArgumentError, fn ->
                unquote(datatype).new!(value, canonicalize: true)
              end
            end)
          end
        end

        describe "general value" do
          Enum.each(@valid, fn {input, {value, _, canonicalized}} ->
            @tag example: %{input: input, value: value}
            test "of valid #{unquote(datatype)}.new(#{inspect(input)})",
                 %{example: example} do
              assert unquote(datatype).new(example.input) |> unquote(datatype).value() ==
                       example.value
            end
          end)

          Enum.each(@invalid, fn value ->
            @tag example: %{input: value, value: value}
            test "of invalid #{unquote(datatype)}.new(#{inspect(value)})", %{example: example} do
              assert unquote(datatype).new(example.input) |> unquote(datatype).value() == nil
            end
          end)
        end

        describe "general lexical" do
          Enum.each(@valid, fn {input, {_, lexical, canonicalized}} ->
            lexical = lexical || canonicalized
            @tag example: %{input: input, lexical: lexical}
            test "of valid #{unquote(datatype)}.new(#{inspect(input)})",
                 %{example: example} do
              assert unquote(datatype).new(example.input) |> unquote(datatype).lexical() ==
                       example.lexical
            end
          end)

          Enum.each(@invalid, fn value ->
            lexical = unquote(datatype).init_invalid_lexical(value, [])
            @tag example: %{input: value, lexical: lexical}
            test "of invalid #{unquote(datatype)}.new(#{inspect(value)}) == #{inspect(lexical)}",
                 %{example: example} do
              assert unquote(datatype).new(example.input) |> unquote(datatype).lexical() ==
                       example.lexical
            end
          end)
        end

        describe "general canonicalization" do
          Enum.each(@valid, fn {input, {value, _, _}} ->
            expected = %RDF.Literal{literal: %unquote(datatype){value: value}}
            @tag example: %{input: input, output: expected}
            test "#{unquote(datatype)} #{inspect(input)}", %{example: example} do
              assert unquote(datatype).new(example.input) |> unquote(datatype).canonical() ==
                       example.output
            end
          end)

          Enum.each(@valid, fn {input, {_, _, canonicalized}} ->
            @tag example: %{input: input, canonicalized: canonicalized}
            test "lexical of canonicalized #{unquote(datatype)} #{inspect(input, limit: 4)} is #{inspect(canonicalized, limit: 4)}",
                 %{example: example} do
              assert unquote(datatype).new(example.input)
                     |> unquote(datatype).canonical()
                     |> unquote(datatype).lexical() ==
                       example.canonicalized
            end
          end)

          Enum.each(@valid, fn {input, {_, _, canonicalized}} ->
            @tag example: %{input: input, canonicalized: canonicalized}
            test "canonical? for #{unquote(datatype)} #{inspect(input)}", %{example: example} do
              literal = unquote(datatype).new(example.input)

              assert unquote(datatype).canonical?(literal) ==
                       (unquote(datatype).lexical(literal) == example.canonicalized)
            end
          end)

          test "does not change the XSD datatype value when it is invalid" do
            Enum.each(@invalid, fn value ->
              assert unquote(datatype).new(value) |> unquote(datatype).canonical() ==
                       unquote(datatype).new(value)
            end)
          end

          test "canonical_lexical with valid literals" do
            Enum.each(@valid, fn {input, {_, _, canonicalized}} ->
              assert unquote(datatype).new(input) |> unquote(datatype).canonical_lexical() ==
                       canonicalized
            end)
          end

          test "canonical_lexical with invalid literals" do
            Enum.each(@invalid, fn value ->
              assert unquote(datatype).new(value) |> unquote(datatype).canonical_lexical() ==
                       nil
            end)
          end
        end

        describe "general validation" do
          Enum.each(Map.keys(@valid), fn value ->
            @tag value: value
            test "#{inspect(value)} as a #{unquote(datatype)} is valid", %{value: value} do
              assert unquote(datatype).valid?(unquote(datatype).new(value))
            end
          end)

          Enum.each(@invalid, fn value ->
            @tag value: value
            test "#{inspect(value)} as a #{unquote(datatype)} is invalid", %{value: value} do
              refute unquote(datatype).valid?(unquote(datatype).new(value))
            end
          end)
        end
      end

      test "String.Chars protocol implementation" do
        Enum.each(@valid, fn {input, _} ->
          assert unquote(datatype).new(input) |> to_string() ==
                   unquote(datatype).new(input) |> unquote(datatype).lexical()
        end)
      end
    end
  end

  def dt(value) do
    {:ok, date, _} = DateTime.from_iso8601(value)
    date
  end
end
