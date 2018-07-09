defmodule RDF.Datatype.Test.Case do
  use ExUnit.CaseTemplate

  use RDF.Vocabulary.Namespace
  defvocab EX,
    base_iri: "http://example.com/",
    terms: [], strict: false

  alias RDF.{Literal, Datatype}


  def dt(value) do
    RDF.DateTime.convert(value, %{})
  end


  using(opts) do
    datatype    = Keyword.fetch!(opts, :datatype)
    datatype_id = Keyword.fetch!(opts, :id)
    valid       = Keyword.get(opts, :valid)
    invalid     = Keyword.get(opts, :invalid)

    allow_language = Keyword.get(opts, :allow_language, false)

    quote do
      alias RDF.{Literal, Datatype}
      alias RDF.NS.XSD

      alias unquote(datatype)
      alias unquote(__MODULE__).EX

      import unquote(__MODULE__)

      doctest unquote(datatype)

      @moduletag datatype: unquote(datatype)

      if unquote(valid) do
        @valid   unquote(valid)
        @invalid unquote(invalid)

        test "RDF.Datatype mapping" do
          assert RDF.Datatype.mapping[unquote(datatype_id)] == unquote(datatype)
        end

        describe "general new" do
          Enum.each @valid, fn {input, {value, lexical, _}} ->
            expected_literal =
              %Literal{value: value, uncanonical_lexical: lexical, datatype: unquote(datatype_id), language: nil}
            @tag example: %{input: input, output: expected_literal}
            test "valid: #{unquote(datatype)}.new(#{inspect input})",
                  %{example: example} do
              assert unquote(datatype).new(example.input) == example.output
            end
          end

          Enum.each @invalid, fn value ->
            expected_literal =
              %Literal{uncanonical_lexical: to_string(value), datatype: unquote(datatype_id), language: nil}
            @tag example: %{input: value, output: expected_literal}
            test "invalid: #{unquote(datatype)}.new(#{inspect value})",
                  %{example: example} do
              assert unquote(datatype).new(example.input) == example.output
            end
          end

          test "canonicalize option" do
            Enum.each @valid, fn {input, _} ->
              assert unquote(datatype).new(input, canonicalize: true) ==
                      (unquote(datatype).new(input) |> Literal.canonical)
            end
            Enum.each @invalid, fn input ->
              assert unquote(datatype).new(input, canonicalize: true) ==
                      (unquote(datatype).new(input) |> Literal.canonical)
            end
          end

          test "datatype option is ignored" do
            Enum.each Datatype.ids, fn id ->
              Enum.each @valid, fn {input, _} ->
                assert unquote(datatype).new(input, datatype: id) == unquote(datatype).new(input)
              end
            end
          end

          unless unquote(allow_language) do
            test "language option is ignored" do
              Enum.each @valid, fn {input, _} ->
                assert unquote(datatype).new(input, language: "en") == unquote(datatype).new(input)
              end
            end
          end
        end


        describe "general new!" do
          test "with valid values, it behaves the same as new" do
            Enum.each @valid, fn {input, _} ->
              assert unquote(datatype).new!(input) == unquote(datatype).new(input)
              assert unquote(datatype).new!(input, datatype: unquote(datatype_id)) == unquote(datatype).new(input)
              assert unquote(datatype).new!(input, canonicalize: true) == unquote(datatype).new(input, canonicalize: true)
            end
          end

          test "with invalid values, it raises an error" do
            Enum.each @invalid, fn value ->
              assert_raise ArgumentError, fn -> unquote(datatype).new!(value) end
              assert_raise ArgumentError, fn -> unquote(datatype).new!(value, canonicalize: true) end
            end
          end
        end


        describe "general lexical" do
          Enum.each @valid, fn {input, {_, lexical, canonicalized}} ->
            lexical = lexical || canonicalized
            @tag example: %{input: input, lexical: lexical}
            test "of valid #{unquote(datatype)}.new(#{inspect input})",
                  %{example: example} do
              assert (unquote(datatype).new(example.input) |> Literal.lexical) == example.lexical
            end
          end

          Enum.each @invalid, fn value ->
            lexical = to_string(value)
            @tag example: %{input: value, lexical: lexical}
            test "of invalid #{unquote(datatype)}.new(#{inspect value}) == #{inspect lexical}",
                  %{example: example} do
              assert (unquote(datatype).new(example.input) |> Literal.lexical) == example.lexical
            end
          end
        end


        describe "general canonicalization" do
          Enum.each @valid, fn {input, {value, _, _}} ->
            expected_literal = %Literal{value: value, datatype: unquote(datatype_id)}
            @tag example: %{input: input, output: expected_literal}
            test "#{unquote(datatype)} #{inspect input}",
                  %{example: example} do
              assert (unquote(datatype).new(example.input) |> Literal.canonical) == example.output
            end
          end

          Enum.each @valid, fn {input, {_, _, canonicalized}} ->
            @tag example: %{input: input, canonicalized: canonicalized}
            test "lexical of canonicalized #{unquote(datatype)} #{inspect input, limit: 9} is #{inspect canonicalized}",
                  %{example: example} do
              assert (unquote(datatype).new(example.input) |> Literal.canonical |> Literal.lexical) ==
                      example.canonicalized
            end
          end

          test "does not change the Literal when it is invalid" do
            Enum.each @invalid, fn value ->
              assert (unquote(datatype).new(value) |> Literal.canonical) == unquote(datatype).new(value)
            end
          end

        end


        describe "general validation" do
          Enum.each Map.keys(@valid), fn value ->
            @tag value: value
            test "#{inspect value} as a #{unquote(datatype)} is valid", %{value: value} do
              assert Literal.valid? unquote(datatype).new(value)
            end
          end

          Enum.each @invalid, fn value ->
            @tag value: value
            test "#{inspect value} as a #{unquote(datatype)} is invalid", %{value: value} do
              refute Literal.valid? unquote(datatype).new(value)
            end
          end
        end

      end

    end
  end

end
