defmodule RDF.Vocabulary.NamespaceTest do
  use ExUnit.Case

  doctest RDF.Vocabulary.Namespace

  import RDF.Sigils

  alias RDF.Description


  defmodule TestNS do
    use RDF.Vocabulary.Namespace

    defvocab EX,
      base_uri: "http://example.com/",
      terms: ~w[], strict: false

    defvocab EXS,
      base_uri: "http://example.com/strict#",
      terms: ~w[foo bar]

    defvocab ExampleFromGraph,
      base_uri: "http://example.com/from_graph#",
      data: RDF.Graph.new([
        {~I<http://example.com/from_graph#foo>, ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>, ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#Property>},
        {~I<http://example.com/from_graph#Bar>, ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>, ~I<http://www.w3.org/2000/01/rdf-schema#Resource>}
      ])

    defvocab ExampleFromDataset,
      base_uri: "http://example.com/from_dataset#",
      data: RDF.Dataset.new([
        {~I<http://example.com/from_dataset#foo>, ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>, ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#Property>},
        {~I<http://example.com/from_dataset#Bar>, ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>, ~I<http://www.w3.org/2000/01/rdf-schema#Resource>, ~I<http://example.com/from_dataset#Graph>}
      ])

    defvocab ExampleFromNTriplesFile,
      base_uri: "http://example.com/from_ntriples/",
      file: "test/data/vocab_ns_example.nt"

    defvocab ExampleFromNQuadsFile,
      base_uri: "http://example.com/from_nquads/",
      file: "test/data/vocab_ns_example.nq"

    defvocab StrictExampleFromTerms,
      base_uri: "http://example.com/strict_from_terms#",
      terms:    ~w[foo Bar]

    defvocab NonStrictExampleFromTerms,
      base_uri: "http://example.com/non_strict_from_terms#",
      terms:    ~w[foo Bar],
      strict: false

    defvocab StrictExampleFromAliasedTerms,
      base_uri: "http://example.com/strict_from_aliased_terms#",
      terms: ~w[term1 Term2 Term-3 term-4],
      alias: [
                Term1: "term1",
                term2: "Term2",
                Term3: "Term-3",
                term4: "term-4",
              ]

    defvocab NonStrictExampleFromAliasedTerms,
      base_uri: "http://example.com/non_strict_from_aliased_terms#",
      terms: ~w[],
      alias: [
                Term1: "term1",
                term2: "Term2",
                Term3: "Term-3",
                term4: "term-4",
              ],
      strict: false

    defvocab ExampleWithSynonymAliases,
      base_uri: "http://example.com/ex#",
      terms:    ~w[bar Bar],
      alias:    [foo: "bar", baz: "bar",
                 Foo: "Bar", Baz: "Bar"]

  end


  describe "defvocab with bad base uri" do
    test "without a base_uri, an error is raised" do
      assert_raise KeyError, fn ->
        defmodule NSWithoutBaseURI do
          use RDF.Vocabulary.Namespace

          defvocab Example, terms: []
        end
      end
    end

    test "when the base_uri doesn't end with '/' or '#', an error is raised" do
      assert_raise RDF.Namespace.InvalidVocabBaseURIError, fn ->
        defmodule NSWithInvalidBaseURI1 do
          use RDF.Vocabulary.Namespace

          defvocab Example,
            base_uri: "http://example.com/base_uri4",
            terms: []
        end
      end
    end

    test "when the base_uri isn't a valid URI, an error is raised" do
      assert_raise RDF.Namespace.InvalidVocabBaseURIError, fn ->
        defmodule NSWithInvalidBaseURI2 do
          use RDF.Vocabulary.Namespace

          defvocab Example,
            base_uri: "invalid",
            terms: []
        end
      end
      assert_raise RDF.Namespace.InvalidVocabBaseURIError, fn ->
        defmodule NSWithInvalidBaseURI3 do
          use RDF.Vocabulary.Namespace

          defvocab Example,
            base_uri: :foo,
            terms: []
        end
      end
    end
  end


  describe "defvocab with bad terms" do
    test "when the given file not found, an error is raised" do
      assert_raise File.Error, fn ->
        defmodule NSWithMissingVocabFile do
          use RDF.Vocabulary.Namespace

          defvocab Example,
            base_uri: "http://example.com/ex#",
            file: "something.nt"
        end
      end
    end
  end


  test "defvocab with special terms" do
    defmodule NSofEdgeCases do
      use RDF.Vocabulary.Namespace

      defvocab Example,
        base_uri: "http://example.com/ex#",
        terms: ~w[nil true false]
    end
    alias NSofEdgeCases.Example

    assert Example.nil == ~I<http://example.com/ex#nil>
    assert Example.true == ~I<http://example.com/ex#true>
    assert Example.false == ~I<http://example.com/ex#false>
  end


  describe "defvocab with bad aliases" do
    test "when an alias contains invalid characters, an error is raised" do
      assert_raise RDF.Namespace.InvalidAliasError, fn ->
        defmodule NSWithInvalidTerms do
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
        defmodule NSWithInvalidAliases1 do
          use RDF.Vocabulary.Namespace

          defvocab Example,
            base_uri: "http://example.com/ex#",
            terms:    ~w[foo bar],
            alias:    [foo: "bar"]
        end
      end
    end

    test "when strict and trying to map to a term not in the vocabulary, an error is raised" do
      assert_raise RDF.Namespace.InvalidAliasError, fn ->
        defmodule NSWithInvalidAliases2 do
          use RDF.Vocabulary.Namespace

          defvocab Example,
            base_uri: "http://example.com/ex#",
            terms:    ~w[],
            alias:    [foo: "bar"]
        end
      end
    end

    test "when defining an alias for an alias, an error is raised" do
      assert_raise RDF.Namespace.InvalidAliasError, fn ->
        defmodule NSWithInvalidAliases3 do
          use RDF.Vocabulary.Namespace

          defvocab Example,
            base_uri: "http://example.com/ex#",
            terms:    ~w[bar],
            alias:    [foo: "bar", baz: "foo"]
        end
      end
    end
  end


  describe "defvocab invalid character handling" do
    test "when a term contains unallowed characters and no alias defined, it fails when invalid_characters = :fail" do
      assert_raise RDF.Namespace.InvalidTermError, ~r/Foo-bar.*foo-bar/s,
        fn ->
          defmodule NSWithInvalidTerms1 do
            use RDF.Vocabulary.Namespace
            defvocab Example,
              base_uri: "http://example.com/example#",
              terms:    ~w[Foo-bar foo-bar]
          end
        end
    end

    test "when a term contains unallowed characters it does not fail when invalid_characters = :ignore" do
      defmodule NSWithInvalidTerms2 do
        use RDF.Vocabulary.Namespace
        defvocab Example,
          base_uri: "http://example.com/example#",
          terms:    ~w[Foo-bar foo-bar],
          invalid_characters: :ignore
      end
    end
  end


  describe "defvocab case violation handling" do
    test "aliases can fix case violations" do
      defmodule NSWithBadCasedTerms1 do
        use RDF.Vocabulary.Namespace

        defvocab Example,
          base_uri: "http://example.com/ex#",
          case_violations: :fail,
          data: RDF.Graph.new([
            {~I<http://example.com/ex#Foo>, ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>, ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#Property>},
            {~I<http://example.com/ex#bar>, ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>, ~I<http://www.w3.org/2000/01/rdf-schema#Resource>}
          ]),
          alias: [
            foo: "Foo",
            Bar: "bar",
          ]
      end
    end

    test "when case_violations == :ignore is set, case violations are ignored" do
      defmodule NSWithBadCasedTerms2 do
        use RDF.Vocabulary.Namespace

        defvocab Example,
          base_uri: "http://example.com/ex#",
          case_violations: :ignore,
          data: RDF.Graph.new([
            {~I<http://example.com/ex#Foo>, ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>, ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#Property>},
            {~I<http://example.com/ex#bar>, ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>, ~I<http://www.w3.org/2000/01/rdf-schema#Resource>}
          ]),
          alias: [
            foo: "Foo",
            Bar: "bar",
          ]
      end
    end


    test "a capitalized property without an alias and :case_violations == :fail, raises an error" do
      assert_raise RDF.Namespace.InvalidTermError, ~r<http://example\.com/ex#Foo>s, fn ->
        defmodule NSWithBadCasedTerms3 do
          use RDF.Vocabulary.Namespace

          defvocab Example,
            base_uri: "http://example.com/ex#",
            case_violations: :fail,
            data: RDF.Graph.new([
              {~I<http://example.com/ex#Foo>, ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>, ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#Property>},
            ])
        end
      end
    end

    test "a lowercased non-property without an alias and :case_violations == :fail, raises an error" do
      assert_raise RDF.Namespace.InvalidTermError, ~r<http://example\.com/ex#bar>s, fn ->
        defmodule NSWithBadCasedTerms4 do
          use RDF.Vocabulary.Namespace

          defvocab Example,
            base_uri: "http://example.com/ex#",
            case_violations: :fail,
            data: RDF.Graph.new([
              {~I<http://example.com/ex#bar>, ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>, ~I<http://www.w3.org/2000/01/rdf-schema#Resource>}
            ])
        end
      end
    end


    test "a capitalized alias for a property and :case_violations == :fail, raises an error" do
      assert_raise RDF.Namespace.InvalidTermError, fn ->
        defmodule NSWithBadCasedTerms5 do
          use RDF.Vocabulary.Namespace

          defvocab Example,
            base_uri: "http://example.com/ex#",
            case_violations: :fail,
            data: RDF.Graph.new([
              {~I<http://example.com/ex#foo>, ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>, ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#Property>},
            ]),
            alias: [Foo: "foo"]
        end
      end
    end

    test "a lowercased alias for a non-property and :case_violations == :fail, raises an error" do
      assert_raise RDF.Namespace.InvalidTermError, fn ->
        defmodule NSWithBadCasedTerms6 do
          use RDF.Vocabulary.Namespace

          defvocab Example,
            base_uri: "http://example.com/ex#",
            case_violations: :fail,
            data: RDF.Graph.new([
              {~I<http://example.com/ex#Bar>, ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>, ~I<http://www.w3.org/2000/01/rdf-schema#Resource>}
            ]),
            alias: [bar: "Bar"]
        end
      end
    end
  end


  test "__base_uri__ returns the base_uri" do
    alias TestNS.ExampleFromGraph, as: HashVocab
    alias TestNS.ExampleFromNTriplesFile, as: SlashVocab

    assert HashVocab.__base_uri__  == "http://example.com/from_graph#"
    assert SlashVocab.__base_uri__ == "http://example.com/from_ntriples/"
  end


  test "__uris__ returns all URIs of the vocabulary" do
    alias TestNS.ExampleFromGraph, as: Example1
    assert length(Example1.__uris__) == 2
    assert RDF.uri(Example1.foo) in Example1.__uris__
    assert RDF.uri(Example1.Bar) in Example1.__uris__

    alias TestNS.ExampleFromNTriplesFile, as: Example2
    assert length(Example2.__uris__) == 2
    assert RDF.uri(Example2.foo) in Example2.__uris__
    assert RDF.uri(Example2.Bar) in Example2.__uris__

    alias TestNS.ExampleFromNQuadsFile, as: Example3
    assert length(Example3.__uris__) == 2
    assert RDF.uri(Example3.foo) in Example3.__uris__
    assert RDF.uri(Example3.Bar) in Example3.__uris__

    alias TestNS.StrictExampleFromAliasedTerms, as: Example4
    assert length(Example4.__uris__) == 4
    assert RDF.uri(Example4.Term1) in Example4.__uris__
    assert RDF.uri(Example4.term2) in Example4.__uris__
    assert RDF.uri(Example4.Term3) in Example4.__uris__
    assert RDF.uri(Example4.term4) in Example4.__uris__
  end


  describe "__terms__" do
    alias TestNS.{ExampleFromGraph, ExampleFromDataset, StrictExampleFromAliasedTerms}

    test "includes all defined terms" do
      assert length(ExampleFromGraph.__terms__) == 2
      for term <- ~w[foo Bar]a do
        assert term in ExampleFromGraph.__terms__
      end

      assert length(ExampleFromDataset.__terms__) == 2
      for term <- ~w[foo Bar]a do
        assert term in ExampleFromDataset.__terms__
      end
    end

    test "includes aliases" do
      assert length(StrictExampleFromAliasedTerms.__terms__) == 8
      for term <- ~w[term1 Term1 term2 Term2 Term3 term4 Term-3 term-4]a do
        assert term in StrictExampleFromAliasedTerms.__terms__
      end
    end
  end


  test "resolving an unqualified term raises an error" do
    assert_raise RDF.Namespace.UndefinedTermError, fn -> RDF.uri(:foo) end
  end

  test "resolving an non-RDF.Namespace module" do
    assert_raise RDF.Namespace.UndefinedTermError, fn -> RDF.uri(ExUnit.Test) end
  end


  describe "term resolution in a strict vocab namespace" do
    alias TestNS.{ExampleFromGraph, ExampleFromNTriplesFile, StrictExampleFromTerms}

    test "undefined terms" do
      assert_raise UndefinedFunctionError, fn ->
        ExampleFromGraph.undefined
      end
      assert_raise UndefinedFunctionError, fn ->
        ExampleFromNTriplesFile.undefined
      end
      assert_raise UndefinedFunctionError, fn ->
        StrictExampleFromTerms.undefined
      end

      assert_raise RDF.Namespace.UndefinedTermError, fn ->
        RDF.Namespace.resolve_term(TestNS.ExampleFromGraph.Undefined)
      end
      assert_raise RDF.Namespace.UndefinedTermError, fn ->
        RDF.Namespace.resolve_term(ExampleFromNTriplesFile.Undefined)
      end
      assert_raise RDF.Namespace.UndefinedTermError, fn ->
        RDF.Namespace.resolve_term(StrictExampleFromTerms.Undefined)
      end
    end

    test "lowercased terms" do
      assert ExampleFromGraph.foo == URI.parse("http://example.com/from_graph#foo")
      assert RDF.uri(ExampleFromGraph.foo) == URI.parse("http://example.com/from_graph#foo")

      assert ExampleFromNTriplesFile.foo == URI.parse("http://example.com/from_ntriples/foo")
      assert RDF.uri(ExampleFromNTriplesFile.foo) == URI.parse("http://example.com/from_ntriples/foo")

      assert StrictExampleFromTerms.foo == URI.parse("http://example.com/strict_from_terms#foo")
      assert RDF.uri(StrictExampleFromTerms.foo) == URI.parse("http://example.com/strict_from_terms#foo")
    end

    test "captitalized terms" do
      assert RDF.uri(ExampleFromGraph.Bar) == URI.parse("http://example.com/from_graph#Bar")
      assert RDF.uri(ExampleFromNTriplesFile.Bar) == URI.parse("http://example.com/from_ntriples/Bar")
      assert RDF.uri(StrictExampleFromTerms.Bar) == URI.parse("http://example.com/strict_from_terms#Bar")
    end
  end


  describe "term resolution in a non-strict vocab namespace" do
    alias TestNS.NonStrictExampleFromTerms
    test "undefined lowercased terms" do
      assert NonStrictExampleFromTerms.random == URI.parse("http://example.com/non_strict_from_terms#random")
    end

    test "undefined capitalized terms" do
      assert RDF.uri(NonStrictExampleFromTerms.Random) == URI.parse("http://example.com/non_strict_from_terms#Random")
    end

    test "defined lowercase terms" do
      assert NonStrictExampleFromTerms.foo == URI.parse("http://example.com/non_strict_from_terms#foo")
    end

    test "defined capitalized terms" do
      assert RDF.uri(NonStrictExampleFromTerms.Bar) == URI.parse("http://example.com/non_strict_from_terms#Bar")
    end
  end


  describe "term resolution of aliases on a strict vocabulary" do
    alias TestNS.StrictExampleFromAliasedTerms, as: Example

    test "the alias resolves to the correct URI" do
      assert RDF.uri(Example.Term1) == URI.parse("http://example.com/strict_from_aliased_terms#term1")
      assert RDF.uri(Example.term2) == URI.parse("http://example.com/strict_from_aliased_terms#Term2")
      assert RDF.uri(Example.Term3) == URI.parse("http://example.com/strict_from_aliased_terms#Term-3")
      assert RDF.uri(Example.term4) == URI.parse("http://example.com/strict_from_aliased_terms#term-4")
    end

    test "the old term remains resolvable" do
      assert RDF.uri(Example.term1) == URI.parse("http://example.com/strict_from_aliased_terms#term1")
      assert RDF.uri(Example.Term2) == URI.parse("http://example.com/strict_from_aliased_terms#Term2")
    end

    test "defining multiple aliases for a term" do
      alias TestNS.ExampleWithSynonymAliases, as: Example
      assert Example.foo == Example.baz
      assert RDF.uri(Example.foo) == RDF.uri(Example.baz)
    end
  end

  describe "term resolution of aliases on a non-strict vocabulary" do
    alias TestNS.NonStrictExampleFromAliasedTerms, as: Example

    test "the alias resolves to the correct URI" do
      assert RDF.uri(Example.Term1) == URI.parse("http://example.com/non_strict_from_aliased_terms#term1")
      assert RDF.uri(Example.term2) == URI.parse("http://example.com/non_strict_from_aliased_terms#Term2")
      assert RDF.uri(Example.Term3) == URI.parse("http://example.com/non_strict_from_aliased_terms#Term-3")
      assert RDF.uri(Example.term4) == URI.parse("http://example.com/non_strict_from_aliased_terms#term-4")
    end

    test "the old term remains resolvable" do
      assert RDF.uri(Example.term1) == URI.parse("http://example.com/non_strict_from_aliased_terms#term1")
      assert RDF.uri(Example.Term2) == URI.parse("http://example.com/non_strict_from_aliased_terms#Term2")
    end
  end


  describe "description DSL" do
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
