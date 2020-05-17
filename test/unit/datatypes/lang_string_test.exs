defmodule RDF.LangStringTest do
  use ExUnit.Case

  alias RDF.{Literal, LangString}
  alias RDF.XSD

  @valid %{
  # input => { value   , language }
    "foo" => { "foo"   , "en"     },
    0     => { "0"     , "en"     },
    42    => { "42"    , "en"     },
    3.14  => { "3.14"  , "en"     },
    true  => { "true"  , "en"     },
    false => { "false" , "en"     },
  }

  describe "new" do
    test "with value and language" do
      Enum.each @valid, fn {input, {value, language}} ->
        assert %Literal{literal: %LangString{value: ^value, language: ^language}} =
                 LangString.new(input, language: language)
        assert %Literal{literal: %LangString{value: ^value, language: ^language}} =
                 LangString.new(input, language: String.to_atom(language))
      end
    end

    test "with language directly" do
      Enum.each @valid, fn {input, {_, language}} ->
        assert LangString.new(input, language) == LangString.new(input, language: language)
        assert LangString.new(input, String.to_atom(language)) ==
                 LangString.new(input, language: String.to_atom(language))
      end
    end

    test "language get normalized to downcase" do
      Enum.each @valid, fn {input, {value, _}} ->
        assert %Literal{literal: %LangString{value: ^value, language: "de"}} =
                 LangString.new(input, language: "DE")
      end
    end

    test "with canonicalize opts" do
      Enum.each @valid, fn {input, {value, language}} ->
        assert %Literal{literal: %LangString{value: ^value, language: ^language}} =
                 LangString.new(input, language: language, canonicalize: true)
      end
    end

    test "without a language it produces an invalid literal" do
      Enum.each @valid, fn {input, {value, _}} ->
        assert %Literal{literal: %LangString{value: ^value, language: nil}} =
                 literal = LangString.new(input, [])
        assert LangString.valid?(literal) == false
      end
    end

    test "with nil as a language it produces an invalid literal" do
      Enum.each @valid, fn {input, {value, _}} ->
        assert %Literal{literal: %LangString{value: ^value, language: nil}} =
                 literal = LangString.new(input, language: nil)
        assert LangString.valid?(literal) == false
      end
    end

    test "with the empty string as a language it produces an invalid literal" do
      Enum.each @valid, fn {input, {value, _}} ->
        assert %Literal{literal: %LangString{value: ^value, language: nil}} =
                 literal = LangString.new(input, language: "")
        assert LangString.valid?(literal) == false
      end
    end
  end

  describe "new!" do
    test "with valid values, it behaves the same as new" do
      Enum.each @valid, fn {input, {_, language}} ->
        assert LangString.new!(input, language: language) ==
                LangString.new(input, language: language)
        assert LangString.new!(input, language: language, canonicalize: true) ==
                LangString.new(input, language: language, canonicalize: true)
      end
    end

    test "without a language it raises an error" do
      Enum.each @valid, fn {input, _} ->
        assert_raise ArgumentError, fn -> LangString.new!(input, []) end
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

  test "datatype?/1" do
    assert LangString.datatype?(LangString) == true
    Enum.each @valid, fn {input, {_, language}} ->
      literal = LangString.new(input, language: language)
      assert LangString.datatype?(literal) == true
      assert LangString.datatype?(literal.literal) == true
    end
  end

  test "datatype_id/1" do
    Enum.each @valid, fn {input, {_, language}} ->
      assert (LangString.new(input, language: language) |> LangString.datatype_id()) == RDF.iri(LangString.id())
    end
  end

  test "language/1" do
    Enum.each @valid, fn {input, {_, language}} ->
      assert (LangString.new(input, language: language) |> LangString.language()) == language
    end

    assert (LangString.new("foo", language: nil) |> LangString.language()) == nil
    assert (LangString.new("foo", language: "") |> LangString.language()) == nil
  end

  test "value/1" do
    Enum.each @valid, fn {input, {value, language}} ->
      assert (LangString.new(input, language: language) |> LangString.value()) == value
    end
  end

  test "lexical/1" do
    Enum.each @valid, fn {input, {value, language}} ->
      assert (LangString.new(input, language: language) |> LangString.lexical()) == value
    end
  end

  test "canonical/1" do
    Enum.each @valid, fn {input, {_, language}} ->
      assert (LangString.new(input, language: language) |> LangString.canonical()) ==
               LangString.new(input, language: language)
    end
  end

  test "canonical?/1" do
    Enum.each @valid, fn {input, {_, language}} ->
      assert (LangString.new(input, language: language) |> LangString.canonical?()) == true
    end
  end

  describe "valid?/1" do
    test "with a language" do
      Enum.each @valid, fn {input, {_, language}} ->
        assert (LangString.new(input, language: language) |> LangString.valid?()) == true
      end
    end

    test "without a language" do
      Enum.each @valid, fn {input, _} ->
        assert (LangString.new(input, language: nil) |> LangString.valid?()) == false
        assert (LangString.new(input, language: "") |> LangString.valid?()) == false
      end
    end
  end

  describe "cast/1" do
    test "when given a valid RDF.LangString literal" do
      Enum.each @valid, fn {input, {_, language}} ->
        assert LangString.new(input, language: language) |> LangString.cast() ==
                 LangString.new(input, language: language)
      end
    end

    test "when given an valid RDF.LangString literal" do
      assert LangString.new("foo", language: nil) |> LangString.cast() == nil
    end

    test "when given a literal with a datatype which is not castable" do
      assert RDF.XSD.String.new("foo") |> LangString.cast() == nil
      assert RDF.XSD.Integer.new(12345) |> LangString.cast() == nil
    end

    test "with invalid literals" do
      assert RDF.XSD.Integer.new(3.14) |> LangString.cast() == nil
    end

    test "with non-coercible value" do
      assert LangString.cast(:foo) == nil
      assert LangString.cast(make_ref()) == nil
    end
  end

  test "equal_value?/2" do
    Enum.each @valid, fn {input, {_, language}} ->
      assert LangString.equal_value?(
               LangString.new(input, language: language),
               LangString.new(input, language: language)) == true
    end

    assert LangString.equal_value?(
             LangString.new("foo", language: "en"),
             LangString.new("foo", language: "de")) == false
    assert LangString.equal_value?(LangString.new("foo", []), LangString.new("foo", [])) == true
    assert LangString.equal_value?(LangString.new("foo", []), LangString.new("bar", [])) == false
    assert LangString.equal_value?(LangString.new("foo", []), RDF.XSD.String.new("foo")) == nil
    assert LangString.equal_value?(RDF.XSD.String.new("foo"), LangString.new("foo", [])) == nil
  end

  test "compare/2" do
    Enum.each @valid, fn {input, {_, language}} ->
      assert LangString.compare(
               LangString.new(input, language: language),
               LangString.new(input, language: language)) == :eq
    end

    assert LangString.compare(LangString.new("foo", language: "en"), LangString.new("bar", language: "en")) == :gt
    assert LangString.compare(LangString.new("bar", language: "en"), LangString.new("baz", language: "en")) == :lt

    assert LangString.compare(
             LangString.new("foo", language: "en"),
             LangString.new("foo", language: "de")) == nil
    assert LangString.compare(LangString.new("foo", []), LangString.new("foo", [])) == nil
    assert LangString.compare(LangString.new("foo", []), RDF.XSD.String.new("foo")) == nil
  end

  describe "match_language?/2" do
    @positive_examples [
      {"de", "de"},
      {"de", "DE"},
      {"de-DE", "de"},
      {"de-CH", "de"},
      {"de-CH", "de-ch"},
      {"de-DE-1996", "de-de"},
    ]

    @negative_examples [
      {"en", "de"},
      {"de", "de-CH"},
      {"de-Deva", "de-de"},
      {"de-Latn-DE", "de-de"},
    ]

    test "with a language tag and a matching non-'*' language range" do
      Enum.each @positive_examples, fn {language_tag, language_range} ->
        assert LangString.match_language?(language_tag, language_range),
          "expected language range #{inspect language_range} to match language tag #{inspect language_tag}, but it didn't"
      end
    end

    test "with a language tag and a non-matching non-'*' language range" do
      Enum.each @negative_examples, fn {language_tag, language_range} ->
        refute LangString.match_language?(language_tag, language_range),
         "expected language range #{inspect language_range} to not match language tag #{inspect language_tag}, but it did"
      end
    end

    test "with a language tag and '*' language range" do
      Enum.each @positive_examples ++ @negative_examples, fn {language_tag, _} ->
        assert LangString.match_language?(language_tag, "*"),
           ~s[expected language range "*" to match language tag #{inspect language_tag}, but it didn't]
      end
    end

    test "with the empty string as language tag" do
      refute LangString.match_language?("", "de")
      refute LangString.match_language?("", "*")
    end

    test "with the empty string as language range" do
      refute LangString.match_language?("de", "")
    end

    test "with a RDF.LangString literal and a language range" do
      Enum.each @positive_examples, fn {language_tag, language_range} ->
        literal = LangString.new("foo", language: language_tag)
        assert LangString.match_language?(literal, language_range),
          "expected language range #{inspect language_range} to match #{inspect literal}, but it didn't"
      end
      Enum.each @negative_examples, fn {language_tag, language_range} ->
        literal = LangString.new("foo", language: language_tag)
        refute LangString.match_language?(literal, language_range),
          "expected language range #{inspect language_range} to not match #{inspect literal}, but it did"
      end
      refute LangString.match_language?(LangString.new("foo", language: ""), "de")
      refute LangString.match_language?(LangString.new("foo", language: ""), "*")
      refute LangString.match_language?(LangString.new("foo", language: nil), "de")
      refute LangString.match_language?(LangString.new("foo", language: nil), "*")
    end

    test "with a non-language-tagged literal" do
      refute XSD.String.new("42") |> LangString.match_language?("de")
      refute XSD.String.new("42") |> LangString.match_language?("")
      refute XSD.String.new("42") |> LangString.match_language?("*")
      refute XSD.Integer.new("42") |> LangString.match_language?("de")
    end
  end
end
