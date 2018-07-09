defmodule RDF.LangStringTest do
  use RDF.Datatype.Test.Case, datatype: RDF.LangString, id: RDF.langString

  @valid %{
  # input => { language , value   , lexical , canonicalized }
    "foo" => { "en"     , "foo"   , nil     , "foo"   },
    0     => { "en"     , "0"     , nil     , "0"     },
    42    => { "en"     , "42"    , nil     , "42"    },
    3.14  => { "en"     , "3.14"  , nil     , "3.14"  },
    true  => { "en"     , "true"  , nil     , "true"  },
    false => { "en"     , "false" , nil     , "false" },
  }


  describe "new" do
    Enum.each @valid, fn {input, {language, value, lexical, _}} ->
      expected_literal =
        %Literal{value: value, uncanonical_lexical: lexical, datatype: RDF.langString, language: language}
      @tag example: %{input: input, language: language, output: expected_literal}
      test "valid: LangString.new(#{inspect input}) == #{inspect expected_literal}",
            %{example: example} do
        assert LangString.new(example.input, language: example.language) == example.output
      end
    end

    # valid value with canonical option
    Enum.each @valid, fn {input, {language, value, _, _}} ->
      expected_literal =
        %Literal{value: value, datatype: RDF.langString, language: language}
      @tag example: %{input: input, language: language, output: expected_literal}
      test "valid: LangString.new(#{inspect input}, canonicalize: true) == #{inspect expected_literal}",
            %{example: example} do
        assert LangString.new(example.input, language: example.language, canonicalize: true) == example.output
      end
    end

    test "datatype option is ignored" do
      Enum.each Datatype.ids, fn id ->
        Enum.each @valid, fn {input, _} ->
          assert LangString.new(input, language: "en", datatype: id) == LangString.new(input, language: "en")
        end
      end
    end

    test "without a language it produces an invalid literal" do
      Enum.each @valid, fn {input, _} ->
        assert %Literal{} = literal = LangString.new(input)
        refute Literal.valid?(literal)
      end
    end

    test "with nil as a language it produces an invalid literal" do
      Enum.each @valid, fn {input, _} ->
        assert %Literal{} = literal = LangString.new(input, language: nil)
        refute Literal.valid?(literal)
      end
    end

    test "with the empty string as a language it produces an invalid literal" do
      Enum.each @valid, fn {input, _} ->
        assert %Literal{} = literal = LangString.new(input, language: "")
        refute Literal.valid?(literal)
      end
    end
  end


  describe "new!" do
    test "with valid values, it behaves the same as new" do
      Enum.each @valid, fn {input, _} ->
        assert LangString.new!(input, language: "de") ==
                LangString.new(input, language: "de")
        assert LangString.new!(input, language: "de", datatype: RDF.langString) ==
                LangString.new(input, language: "de")
        assert LangString.new!(input, language: "de", canonicalize: true) ==
                LangString.new(input, language: "de", canonicalize: true)
      end
    end

    test "without a language it raises an error" do
      Enum.each @valid, fn {input, _} ->
        assert_raise ArgumentError, fn -> LangString.new!(input) end
      end
    end

    test "with nil as a language it raises an error" do
      Enum.each @valid, fn {input, _} ->
        assert_raise ArgumentError, fn -> LangString.new!(input, language: nil) end
      end
    end

    test "with the empty string as a language it raises an error" do
      Enum.each @valid, fn {input, _} ->
        assert_raise ArgumentError, fn -> LangString.new!(input, language: "") end
      end
    end
  end


  describe "lexical" do
    Enum.each @valid, fn {input, {language, _, lexical, canonicalized}} ->
      lexical = lexical || canonicalized
      @tag example: %{input: input, language: language, lexical: lexical}
      test "of valid LangString.new(#{inspect input}) == #{inspect lexical}",
            %{example: example} do
        assert (LangString.new(example.input, language: example.language) |> Literal.lexical) == example.lexical
      end
    end
  end


  describe "canonicalization" do
    Enum.each @valid, fn {input, {language, value, _, _}} ->
      expected_literal =
        %Literal{value: value, datatype: RDF.langString, language: language}
      @tag example: %{input: input, language: language, output: expected_literal}
      test "LangString #{inspect input} is canonicalized #{inspect expected_literal}",
            %{example: example} do
        assert (LangString.new(example.input, language: example.language) |> Literal.canonical) == example.output
      end
    end

    Enum.each @valid, fn {input, {language, _, _, canonicalized}} ->
      @tag example: %{input: input, language: language, canonicalized: canonicalized}
      test "lexical of canonicalized LangString #{inspect input} is #{inspect canonicalized}",
            %{example: example} do
        assert (LangString.new(example.input, language: example.language) |> Literal.canonical |> Literal.lexical) ==
                example.canonicalized
      end
    end
  end


  describe "validation" do
    Enum.each Map.keys(@valid), fn value ->
      @tag value: value
      test "#{inspect value} as a RDF.LangString is valid", %{value: value} do
        assert Literal.valid? LangString.new(value, language: "es")
      end
    end

    test "a RDF.LangString without a language is invalid" do
      Enum.each @valid, fn {_, {_, value, lexical, _}} ->
        refute Literal.valid?(
          %Literal{value: value, uncanonical_lexical: lexical, datatype: RDF.langString})
      end
    end
  end
  
end
