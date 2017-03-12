defmodule RDF.Vocabulary.NamespaceTest do
  use ExUnit.Case

  doctest RDF.Vocabulary.Namespace

  defmodule TestNS do
    use RDF.Vocabulary.Namespace

    defvocab Example1,
      base_uri: "http://example.com/example1#",
      data: RDF.Graph.new([
        {"http://example.com/example1#foo", "http://www.w3.org/1999/02/22-rdf-syntax-ns#type", "http://www.w3.org/1999/02/22-rdf-syntax-ns#Property"},
        {"http://example.com/example1#Bar", "http://www.w3.org/1999/02/22-rdf-syntax-ns#type", "http://www.w3.org/2000/01/rdf-schema#Resource"}
      ])

    defvocab Example2,
      base_uri: "http://example.com/example2/",
      file: "test/data/vocab_ns_example2.nt"
#      file: "vocab_ns_example2.nt"

    defvocab Example3,
      base_uri: "http://example.com/example3#",
      terms:    ~w[foo Bar]

    defvocab Example4,
      base_uri: "http://example.com/example4#",
      terms:    ~w[foo Bar],
      strict: false
  end


#  test "__all__ returns a list of all defined namespaces" do
#    assert Enum.count(TestNS.__all__) == 4
#    assert is_map(TestNS.__all__)
#    assert Map.has_key?(TestNS.__all__, :Example1)
#    assert Map.has_key?(TestNS.__all__, :Example2)
#    assert Map.has_key?(TestNS.__all__, :Example3)
#    assert Map.has_key?(TestNS.__all__, :Example4)
#  end

  describe "defvocab" do
    test "fails without a base_uri" do
      assert_raise KeyError, fn ->
        defmodule BadNS1 do
          use RDF.Vocabulary.Namespace

          defvocab Example, terms: []
        end
      end
    end

    test "fails, when the base_uri doesn't end with '/' or '#'" do
      assert_raise RDF.Namespace.InvalidVocabBaseURIError, fn ->
        defmodule BadNS2 do
          use RDF.Vocabulary.Namespace

          defvocab Example,
            base_uri: "http://example.com/base_uri4",
            terms: []
        end
      end
    end

    @tag skip: "TODO: implement proper URI validation"
    test "fails, when the base_uri isn't a valid URI according to RFC 3986" do
      assert_raise RDF.Namespace.InvalidVocabBaseURIError, fn ->
        defmodule BadNS3 do
          use RDF.Vocabulary.Namespace

          defvocab Example,
            base_uri: "foo/",
            terms: []
        end
      end
      assert_raise RDF.Namespace.InvalidVocabBaseURIError, fn ->
        defmodule BadNS4 do
          use RDF.Vocabulary.Namespace

          defvocab Example,
            base_uri: :foo,
            terms: []
        end
      end
    end

    test "fails, when the given file not found" do
      assert_raise File.Error, fn ->
        defmodule BadNS5 do
          use RDF.Vocabulary.Namespace

          defvocab Example,
            base_uri: "http://example.com/ex5#",
            file: "something.nt"
        end
      end
    end

  end

  test "__base_uri__ returns the base_uri" do
    alias TestNS.Example1, as: HashVocab
    alias TestNS.Example2, as: SlashVocab

    assert HashVocab.__base_uri__  == "http://example.com/example1#"
    assert SlashVocab.__base_uri__ == "http://example.com/example2/"
  end

  test "__terms__ returns a list of all defined terms" do
    alias TestNS.Example1
    assert length(Example1.__terms__) == 2
    assert :foo in Example1.__terms__
    assert :Bar in Example1.__terms__
  end

  @tag skip: "TODO: Can we make RDF.uri(:foo) an undefined function call with guards or in another way?"
  test "resolving an unqualified term raises an error" do
    assert_raise UndefinedFunctionError, fn -> RDF.uri(:foo) end
  end

  describe "term resolution in a strict vocab namespace" do
    alias TestNS.{Example1, Example2, Example3}
    test "undefined terms" do
      assert_raise UndefinedFunctionError, fn ->
        Example1.undefined
      end
      assert_raise UndefinedFunctionError, fn ->
        Example2.undefined
      end
      assert_raise UndefinedFunctionError, fn ->
        Example3.undefined
      end

      assert_raise RDF.Namespace.UndefinedTermError, fn ->
        RDF.Namespace.resolve_term(TestNS.Example1.Undefined)
      end
      assert_raise RDF.Namespace.UndefinedTermError, fn ->
        RDF.Namespace.resolve_term(Example2.Undefined)
      end
      assert_raise RDF.Namespace.UndefinedTermError, fn ->
        RDF.Namespace.resolve_term(Example3.Undefined)
      end
    end

    test "lowercased terms" do
      assert Example1.foo == URI.parse("http://example.com/example1#foo")
      assert RDF.uri(Example1.foo) == URI.parse("http://example.com/example1#foo")

      assert Example2.foo == URI.parse("http://example.com/example2/foo")
      assert RDF.uri(Example2.foo) == URI.parse("http://example.com/example2/foo")

      assert Example3.foo == URI.parse("http://example.com/example3#foo")
      assert RDF.uri(Example3.foo) == URI.parse("http://example.com/example3#foo")
    end

    test "captitalized terms" do
      assert RDF.uri(Example1.Bar) == URI.parse("http://example.com/example1#Bar")
      assert RDF.uri(Example2.Bar) == URI.parse("http://example.com/example2/Bar")
      assert RDF.uri(Example3.Bar) == URI.parse("http://example.com/example3#Bar")
    end

  end

  describe "term resolution in a non-strict vocab namespace" do
    alias TestNS.Example4
    test "undefined lowercased terms" do
      assert Example4.random == URI.parse("http://example.com/example4#random")
    end

    test "undefined capitalized terms" do
      assert RDF.uri(Example4.Random) == URI.parse("http://example.com/example4#Random")
    end

    test "defined lowercase terms" do
      assert Example4.foo == URI.parse("http://example.com/example4#foo")
    end

    test "defined capitalized terms" do
      assert RDF.uri(Example4.Bar) == URI.parse("http://example.com/example4#Bar")
    end
  end

end
