defmodule RDF.VocabularyTest do
  use ExUnit.Case

  doctest RDF.Vocabulary


  defmodule StrictVocab, do:
    use RDF.Vocabulary, base_uri: "http://example.com/strict_vocab/", strict: true

  defmodule NonStrictVocab, do:
    use RDF.Vocabulary, base_uri: "http://example.com/non_strict_vocab/"

  defmodule HashVocab, do:
    use RDF.Vocabulary, base_uri: "http://example.com/hash_vocab#"

  defmodule SlashVocab, do:
    use RDF.Vocabulary, base_uri: "http://example.com/slash_vocab/"


  describe "base_uri" do
    test "__base_uri__ returns the base_uri" do
      assert SlashVocab.__base_uri__ == "http://example.com/slash_vocab/"
      assert HashVocab.__base_uri__  == "http://example.com/hash_vocab#"
    end

    test "a Vocabulary can't be defined without a base_uri" do
      assert_raise RDF.Vocabulary.InvalidBaseURIError, fn ->
        defmodule TestBaseURIVocab3, do: use RDF.Vocabulary
      end
    end

    test "it is not valid, when it doesn't end with '/' or '#'" do
      assert_raise RDF.Vocabulary.InvalidBaseURIError, fn ->
        defmodule TestBaseURIVocab4, do:
          use RDF.Vocabulary, base_uri: "http://example.com/base_uri4"
      end
    end

    @tag skip: "TODO: implement proper URI validation"
    test "it is not valid, when it isn't a valid URI according to RFC 3986" do
      assert_raise RDF.Vocabulary.InvalidBaseURIError, fn ->
        defmodule TestBaseURIVocab5, do: use RDF.Vocabulary, base_uri: "foo/"
      end
      assert_raise RDF.Vocabulary.InvalidBaseURIError, fn ->
        defmodule TestBaseURIVocab6, do: use RDF.Vocabulary, base_uri: :foo
      end
    end
  end

  test "__terms__ returns a list of all defined terms" do
    defmodule VocabWithSomeTerms do
      use RDF.Vocabulary, base_uri: "http://example.com/test5/"
      defuri :prop
      defuri :Foo
    end

    assert length(VocabWithSomeTerms.__terms__) == 2
    assert :prop in VocabWithSomeTerms.__terms__
    assert :Foo in VocabWithSomeTerms.__terms__
  end

  @tag skip: "TODO: Can we make RDF.uri(:foo) an undefined function call with guards or in another way?"
  test "resolving an unqualified term raises an error" do
    assert_raise UndefinedFunctionError, fn -> RDF.uri(:foo) end
    # or: assert_raise InvalidTermError, fn -> RDF.uri(:foo) end
  end

  test "resolving undefined terms of a non-strict vocabulary" do
    assert NonStrictVocab.foo ==
            URI.parse("http://example.com/non_strict_vocab/foo")
    assert RDF.uri(NonStrictVocab.Bar) ==
            URI.parse("http://example.com/non_strict_vocab/Bar")
  end

  test "resolving undefined terms of a strict vocabulary" do
    assert_raise UndefinedFunctionError, fn -> StrictVocab.foo end
    assert_raise RDF.Vocabulary.UndefinedTermError, fn ->
      RDF.uri(StrictVocab.Foo) end
  end

  test "resolving manually defined lowercase terms on a non-strict vocabulary" do
    defmodule TestManualVocab1 do
      use RDF.Vocabulary, base_uri: "http://example.com/manual_vocab1/"
      defuri :prop
    end

    assert TestManualVocab1.prop ==
            URI.parse("http://example.com/manual_vocab1/prop")
    assert RDF.uri(TestManualVocab1.prop) ==
            URI.parse("http://example.com/manual_vocab1/prop")
  end

  test "resolving manually defined uppercase terms on a non-strict vocabulary" do
    defmodule TestManualVocab2 do
      use RDF.Vocabulary, base_uri: "http://example.com/manual_vocab2/"
      defuri :Foo
    end

    assert RDF.uri(TestManualVocab2.Foo) ==
            URI.parse("http://example.com/manual_vocab2/Foo")
  end

  test "resolving manually defined lowercase terms on a strict vocabulary" do
    defmodule TestManualStrictVocab1 do
      use RDF.Vocabulary,
        base_uri: "http://example.com/manual_strict_vocab1/", strict: true
      defuri :prop
    end

    assert TestManualStrictVocab1.prop ==
            URI.parse("http://example.com/manual_strict_vocab1/prop")
    assert RDF.uri(TestManualStrictVocab1.prop) ==
            URI.parse("http://example.com/manual_strict_vocab1/prop")
  end

  test "resolving manually defined uppercase terms on a strict vocabulary" do
    defmodule TestManualStrictVocab2 do
      use RDF.Vocabulary,
        base_uri: "http://example.com/manual_strict_vocab2/", strict: true
      defuri :Foo
    end

    assert RDF.uri(TestManualStrictVocab2.Foo) ==
            URI.parse("http://example.com/manual_strict_vocab2/Foo")
  end

end
