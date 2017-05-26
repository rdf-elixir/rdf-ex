defmodule RDF.Vocabulary.NamespaceTest do
  use ExUnit.Case

  doctest RDF.Vocabulary.Namespace

  alias RDF.Description


  defmodule TestNS do
    use RDF.Vocabulary.Namespace

    defvocab EX,
      base_uri: "http://example.com/",
      terms: ~w[], strict: false

    defvocab EXS,
      base_uri: "http://example.com/strict#",
      terms: ~w[foo bar]

    defvocab Example1,
      base_uri: "http://example.com/example1#",
      data: RDF.Graph.new([
        {"http://example.com/example1#foo", "http://www.w3.org/1999/02/22-rdf-syntax-ns#type", "http://www.w3.org/1999/02/22-rdf-syntax-ns#Property"},
        {"http://example.com/example1#Bar", "http://www.w3.org/1999/02/22-rdf-syntax-ns#type", "http://www.w3.org/2000/01/rdf-schema#Resource"}
      ])

    defvocab Example2,
      base_uri: "http://example.com/example2/",
      file: "test/data/vocab_ns_example2.nt"

    defvocab Example3,
      base_uri: "http://example.com/example3#",
      terms:    ~w[foo Bar]

    defvocab Example4,
      base_uri: "http://example.com/example4#",
      terms:    ~w[foo Bar],
      strict: false

    defvocab Example5,
      base_uri: "http://example.com/example5#",
      terms: ~w[term1 Term2 Term-3 term-4],
      alias: [
                Term1: "term1",
                term2: "Term2",
                Term3: "Term-3",
                term4: "term-4",
              ]

    defvocab Example6,
      base_uri: "http://example.com/example6#",
      terms: ~w[],
      alias: [
                Term1: "term1",
                term2: "Term2",
                Term3: "Term-3",
                term4: "term-4",
              ],
      strict: false
  end


  describe "defvocab" do
    test "without a base_uri, an error is raised" do
      assert_raise KeyError, fn ->
        defmodule BadNS1 do
          use RDF.Vocabulary.Namespace

          defvocab Example, terms: []
        end
      end
    end

    test "when the base_uri doesn't end with '/' or '#', an error is raised" do
      assert_raise RDF.Namespace.InvalidVocabBaseURIError, fn ->
        defmodule BadNS2 do
          use RDF.Vocabulary.Namespace

          defvocab Example,
            base_uri: "http://example.com/base_uri4",
            terms: []
        end
      end
    end

    test "when the base_uri isn't a valid URI, an error is raised" do
      assert_raise RDF.Namespace.InvalidVocabBaseURIError, fn ->
        defmodule BadNS3 do
          use RDF.Vocabulary.Namespace

          defvocab Example,
            base_uri: "invalid",
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

    test "when the given file not found, an error is raised" do
      assert_raise File.Error, fn ->
        defmodule BadNS5 do
          use RDF.Vocabulary.Namespace

          defvocab Example,
            base_uri: "http://example.com/ex5#",
            file: "something.nt"
        end
      end
    end

    test "when the alias contains invalid characters term, an error is raised" do
      assert_raise RDF.Namespace.InvalidAliasError, fn ->
        defmodule BadNS12 do
          use RDF.Vocabulary.Namespace

          defvocab Example,
            base_uri: "http://example.com/ex#",
            terms:    ~w[foo],
            alias:    ["foo-bar": "foo"]
        end
      end
    end


    test "when trying to map an already existing term, an error is raised" do
      assert_raise RDF.Namespace.InvalidAliasError, fn ->
        defmodule BadNS6 do
          use RDF.Vocabulary.Namespace

          defvocab Example,
            base_uri: "http://example.com/ex6#",
            terms:    ~w[foo bar],
            alias:    [foo: "bar"]
        end
      end
    end

    test "when strict and trying to map to a term not in the vocabulary, an error is raised" do
      assert_raise RDF.Namespace.InvalidAliasError, fn ->
        defmodule BadNS7 do
          use RDF.Vocabulary.Namespace

          defvocab Example,
            base_uri: "http://example.com/ex7#",
            terms:    ~w[],
            alias:    [foo: "bar"]
        end
      end
    end

    test "when defining an alias for an alias, an error is raised" do
      assert_raise RDF.Namespace.InvalidAliasError, fn ->
        defmodule BadNS8 do
          use RDF.Vocabulary.Namespace

          defvocab Example,
            base_uri: "http://example.com/ex8#",
            terms:    ~w[bar],
            alias:    [foo: "bar", baz: "foo"]
        end
      end
    end

    test "defining multiple aliases for a term" do
      defmodule BadNS9 do
        use RDF.Vocabulary.Namespace

        defvocab Example,
          base_uri: "http://example.com/ex8#",
          terms:    ~w[bar Bar],
          alias:    [foo: "bar", baz: "bar",
                     Foo: "Bar", Baz: "Bar"]
      end
      alias BadNS9.Example
      assert Example.foo == Example.baz
      assert RDF.uri(Example.foo) == RDF.uri(Example.baz)
    end

  end

  test "__base_uri__ returns the base_uri" do
    alias TestNS.Example1, as: HashVocab
    alias TestNS.Example2, as: SlashVocab

    assert HashVocab.__base_uri__  == "http://example.com/example1#"
    assert SlashVocab.__base_uri__ == "http://example.com/example2/"
  end


  describe "__terms__" do
    alias TestNS.{Example1, Example5}

    test "includes all defined terms" do
      assert length(Example1.__terms__) == 2
      assert :foo in Example1.__terms__
      assert :Bar in Example1.__terms__
    end

    test "includes aliases" do
      assert length(Example5.__terms__) == 8
      assert :term1 in Example5.__terms__
      assert :Term1 in Example5.__terms__
      assert :term2 in Example5.__terms__
      assert :Term2 in Example5.__terms__
      assert :Term3 in Example5.__terms__
      assert :term4 in Example5.__terms__
      assert :"Term-3" in Example5.__terms__
      assert :"term-4" in Example5.__terms__
    end
  end

  test "__uris__ returns all URIs of the vocabulary" do
    alias TestNS.{Example1, Example5}
    assert length(Example1.__uris__) == 2
    assert RDF.uri(Example1.foo) in Example1.__uris__
    assert RDF.uri(Example1.Bar) in Example1.__uris__

    assert length(Example5.__uris__) == 4
    assert RDF.uri(Example5.Term1) in Example5.__uris__
    assert RDF.uri(Example5.term2) in Example5.__uris__
    assert RDF.uri(Example5.Term3) in Example5.__uris__
    assert RDF.uri(Example5.term4) in Example5.__uris__
  end


  describe "invalid character handling" do
    test "when a term contains unallowed characters and no alias defined, it fails when invalid_characters = :fail" do
      assert_raise RDF.Namespace.InvalidTermError, ~r/Foo-bar.*foo-bar/s,
        fn ->
          defmodule BadNS10 do
            use RDF.Vocabulary.Namespace
            defvocab Example,
              base_uri: "http://example.com/example#",
              terms:    ~w[Foo-bar foo-bar]
          end
        end
    end

    test "when a term contains unallowed characters it does not fail when invalid_characters = :ignore" do
        defmodule BadNS11 do
          use RDF.Vocabulary.Namespace
          defvocab Example,
            base_uri: "http://example.com/example#",
            terms:    ~w[Foo-bar foo-bar],
            invalid_characters: :ignore
        end
    end
  end


  @tag skip: "TODO: Can we make RDF.uri(:foo) an undefined function call with guards or in another way?"
  test "resolving an unqualified term raises an error" do
    assert_raise RDF.Namespace.UndefinedTermError, fn -> RDF.uri(:foo) end
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


  describe "term resolution of aliases on a strict vocabulary" do
    alias TestNS.Example5

    test "the alias resolves to the correct URI" do
      assert RDF.uri(Example5.Term1) == URI.parse("http://example.com/example5#term1")
      assert RDF.uri(Example5.term2) == URI.parse("http://example.com/example5#Term2")
      assert RDF.uri(Example5.Term3) == URI.parse("http://example.com/example5#Term-3")
      assert RDF.uri(Example5.term4) == URI.parse("http://example.com/example5#term-4")
    end

    test "the old term remains resolvable" do
      assert RDF.uri(Example5.term1) == URI.parse("http://example.com/example5#term1")
      assert RDF.uri(Example5.Term2) == URI.parse("http://example.com/example5#Term2")
    end
  end

  describe "term resolution of aliases on a non-strict vocabulary" do
    alias TestNS.Example6

    test "the alias resolves to the correct URI" do
      assert RDF.uri(Example6.Term1) == URI.parse("http://example.com/example6#term1")
      assert RDF.uri(Example6.term2) == URI.parse("http://example.com/example6#Term2")
      assert RDF.uri(Example6.Term3) == URI.parse("http://example.com/example6#Term-3")
      assert RDF.uri(Example6.term4) == URI.parse("http://example.com/example6#term-4")
    end

    test "the old term remains resolvable" do
      assert RDF.uri(Example6.term1) == URI.parse("http://example.com/example6#term1")
      assert RDF.uri(Example6.Term2) == URI.parse("http://example.com/example6#Term2")
    end
  end


  describe "Description DSL" do
    alias TestNS.{EX, EXS}
    
    test "one statement with a strict property term" do
      assert EXS.foo(EX.S, EX.O) == Description.new(EX.S, EXS.foo, EX.O)
    end

    test "multiple statements with strict property terms and one object" do
      description =
        EX.S
        |> EXS.foo(EX.O1)
        |> EXS.bar(EX.O2)
      assert description == Description.new(EX.S, [{EXS.foo, EX.O1}, {EXS.bar, EX.O2}])
    end

    test "multiple statements with strict property terms and multiple objects in a list" do
      description =
        EX.S
        |> EXS.foo([EX.O1, EX.O2])
        |> EXS.bar([EX.O3, EX.O4])
      assert description == Description.new(EX.S, [
              {EXS.foo, EX.O1},
              {EXS.foo, EX.O2},
              {EXS.bar, EX.O3},
              {EXS.bar, EX.O4}
             ])
    end

    test "multiple statements with strict property terms and multiple objects as arguments" do
      description =
        EX.S
        |> EXS.foo(EX.O1, EX.O2)
        |> EXS.bar(EX.O3, EX.O4, EX.O5)
      assert description == Description.new(EX.S, [
              {EXS.foo, EX.O1},
              {EXS.foo, EX.O2},
              {EXS.bar, EX.O3},
              {EXS.bar, EX.O4},
              {EXS.bar, EX.O5}
             ])
    end


    test "one statement with a non-strict property term" do
      assert EX.p(EX.S, EX.O) == Description.new(EX.S, EX.p, EX.O)
    end

    test "multiple statements with non-strict property terms and one object" do
      description =
        EX.S
        |> EX.p1(EX.O1)
        |> EX.p2(EX.O2)
      assert description == Description.new(EX.S, [{EX.p1, EX.O1}, {EX.p2, EX.O2}])
    end

    test "multiple statements with non-strict property terms and multiple objects in a list" do
      description =
        EX.S
        |> EX.p1([EX.O1, EX.O2])
        |> EX.p2([EX.O3, EX.O4])
      assert description == Description.new(EX.S, [
              {EX.p1, EX.O1},
              {EX.p1, EX.O2},
              {EX.p2, EX.O3},
              {EX.p2, EX.O4}
             ])
    end

    test "multiple statements with non-strict property terms and multiple objects as arguments" do
      description =
        EX.S
        |> EX.p1(EX.O1, EX.O2)
        |> EX.p2(EX.O3, EX.O4)
      assert description == Description.new(EX.S, [
              {EX.p1, EX.O1},
              {EX.p1, EX.O2},
              {EX.p2, EX.O3},
              {EX.p2, EX.O4}
             ])
    end
  end

end
