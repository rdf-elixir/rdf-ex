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

    defvocab ExampleFromTurtleFile,
      base_uri: "http://example.com/from_turtle/",
      file: "test/data/vocab_ns_example.ttl"

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


  test "defvocab with special terms" do
    defmodule NSofEdgeCases do
      use RDF.Vocabulary.Namespace

      defvocab Example,
        base_uri: "http://example.com/ex#",
        terms: ~w[
          nil
          true
          false
          do
          end
          else
          try
          rescue
          catch
          after
          not
          cond
          inbits
          inlist
          receive
          __block__
          __info__
          __MODULE__
          __FILE__
          __DIR__
          __ENV__
          __CALLER__
        ]
    end
    alias NSofEdgeCases.Example
    alias TestNS.EX

    assert Example.nil     == ~I<http://example.com/ex#nil>
    assert Example.true    == ~I<http://example.com/ex#true>
    assert Example.false   == ~I<http://example.com/ex#false>
    assert Example.do      == ~I<http://example.com/ex#do>
    assert Example.end     == ~I<http://example.com/ex#end>
    assert Example.else    == ~I<http://example.com/ex#else>
    assert Example.try     == ~I<http://example.com/ex#try>
    assert Example.rescue  == ~I<http://example.com/ex#rescue>
    assert Example.catch   == ~I<http://example.com/ex#catch>
    assert Example.after   == ~I<http://example.com/ex#after>
    assert Example.not     == ~I<http://example.com/ex#not>
    assert Example.cond    == ~I<http://example.com/ex#cond>
    assert Example.inbits  == ~I<http://example.com/ex#inbits>
    assert Example.inlist  == ~I<http://example.com/ex#inlist>
    assert Example.receive == ~I<http://example.com/ex#receive>
    assert Example.__block__   == ~I<http://example.com/ex#__block__>
    assert Example.__info__    == ~I<http://example.com/ex#__info__>
    assert Example.__MODULE__  == ~I<http://example.com/ex#__MODULE__>
    assert Example.__FILE__    == ~I<http://example.com/ex#__FILE__>
    assert Example.__DIR__     == ~I<http://example.com/ex#__DIR__>
    assert Example.__ENV__     == ~I<http://example.com/ex#__ENV__>
    assert Example.__CALLER__  == ~I<http://example.com/ex#__CALLER__>

    assert Example.nil(    EX.S, 1) == RDF.description(EX.S, Example.nil     , 1)
    assert Example.true(   EX.S, 1) == RDF.description(EX.S, Example.true    , 1)
    assert Example.false(  EX.S, 1) == RDF.description(EX.S, Example.false   , 1)
    assert Example.do(     EX.S, 1) == RDF.description(EX.S, Example.do      , 1)
    assert Example.end(    EX.S, 1) == RDF.description(EX.S, Example.end     , 1)
    assert Example.else(   EX.S, 1) == RDF.description(EX.S, Example.else    , 1)
    assert Example.try(    EX.S, 1) == RDF.description(EX.S, Example.try     , 1)
    assert Example.rescue( EX.S, 1) == RDF.description(EX.S, Example.rescue  , 1)
    assert Example.catch(  EX.S, 1) == RDF.description(EX.S, Example.catch   , 1)
    assert Example.after(  EX.S, 1) == RDF.description(EX.S, Example.after   , 1)
    assert Example.not(    EX.S, 1) == RDF.description(EX.S, Example.not     , 1)
    assert Example.cond(   EX.S, 1) == RDF.description(EX.S, Example.cond    , 1)
    assert Example.inbits( EX.S, 1) == RDF.description(EX.S, Example.inbits  , 1)
    assert Example.inlist( EX.S, 1) == RDF.description(EX.S, Example.inlist  , 1)
    assert Example.receive(EX.S, 1) == RDF.description(EX.S, Example.receive , 1)
  end


  describe "defvocab with invalid terms" do
    test "terms with a special meaning for Elixir cause a failure" do
      assert_raise RDF.Namespace.InvalidTermError, ~r/unquote_splicing/s, fn ->
        defmodule NSWithElixirTerms do
          use RDF.Vocabulary.Namespace
          defvocab Example,
            base_uri: "http://example.com/example#",
            terms: RDF.Vocabulary.Namespace.invalid_terms
        end
      end
    end

    test "alias terms with a special meaning for Elixir cause a failure" do
      assert_raise RDF.Namespace.InvalidTermError, ~r/unquote_splicing/s, fn ->
        defmodule NSWithElixirAliasTerms do
          use RDF.Vocabulary.Namespace
          defvocab Example,
            base_uri: "http://example.com/example#",
             terms: ~w[foo],
              alias: [
                      and:              "foo",
                      or:               "foo",
                      xor:              "foo",
                      in:               "foo",
                      fn:               "foo",
                      def:              "foo",
                      when:             "foo",
                      if:               "foo",
                      for:              "foo",
                      case:             "foo",
                      with:             "foo",
                      quote:            "foo",
                      unquote:          "foo",
                      unquote_splicing: "foo",
                      alias:            "foo",
                      import:           "foo",
                      require:          "foo",
                      super:            "foo",
                      __aliases__:      "foo",
                    ]
        end
      end
    end

    test "terms with a special meaning for Elixir don't cause a failure when they are ignored" do
      defmodule NSWithIgnoredElixirTerms do
        use RDF.Vocabulary.Namespace
        defvocab Example,
          base_uri: "http://example.com/example#",
          terms: RDF.Vocabulary.Namespace.invalid_terms,
          ignore: RDF.Vocabulary.Namespace.invalid_terms
      end
    end

    test "terms with a special meaning for Elixir don't cause a failure when an alias is defined" do
      defmodule NSWithAliasesForElixirTerms do
        use RDF.Vocabulary.Namespace
        defvocab Example,
          base_uri: "http://example.com/example#",
          terms: RDF.Vocabulary.Namespace.invalid_terms,
          alias: [
                   and_:              "and",
                   or_:               "or",
                   xor_:              "xor",
                   in_:               "in",
                   fn_:               "fn",
                   def_:              "def",
                   when_:             "when",
                   if_:               "if",
                   for_:              "for",
                   case_:             "case",
                   with_:             "with",
                   quote_:            "quote",
                   unquote_:          "unquote",
                   unquote_splicing_: "unquote_splicing",
                   alias_:            "alias",
                   import_:           "import",
                   require_:          "require",
                   super_:            "super",
                   _aliases_:         "__aliases__"
                 ]
      end
      alias NSWithAliasesForElixirTerms.Example

      assert Example.and_              == ~I<http://example.com/example#and>
      assert Example.or_               == ~I<http://example.com/example#or>
      assert Example.xor_              == ~I<http://example.com/example#xor>
      assert Example.in_               == ~I<http://example.com/example#in>
      assert Example.fn_               == ~I<http://example.com/example#fn>
      assert Example.def_              == ~I<http://example.com/example#def>
      assert Example.when_             == ~I<http://example.com/example#when>
      assert Example.if_               == ~I<http://example.com/example#if>
      assert Example.for_              == ~I<http://example.com/example#for>
      assert Example.case_             == ~I<http://example.com/example#case>
      assert Example.with_             == ~I<http://example.com/example#with>
      assert Example.quote_            == ~I<http://example.com/example#quote>
      assert Example.unquote_          == ~I<http://example.com/example#unquote>
      assert Example.unquote_splicing_ == ~I<http://example.com/example#unquote_splicing>
      assert Example.alias_            == ~I<http://example.com/example#alias>
      assert Example.import_           == ~I<http://example.com/example#import>
      assert Example.require_          == ~I<http://example.com/example#require>
      assert Example.super_            == ~I<http://example.com/example#super>
      assert Example._aliases_         == ~I<http://example.com/example#__aliases__>
    end
  end

  describe "defvocab invalid character handling" do
    test "when a term contains unallowed characters and no alias defined, it fails when invalid_characters = :fail" do
      assert_raise RDF.Namespace.InvalidTermError, ~r/Foo-bar.*foo-bar/s, fn ->
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

    test "terms starting with an underscore are not checked" do
      defmodule NSWithUnderscoreTerms do
        use RDF.Vocabulary.Namespace

        defvocab Example,
          base_uri: "http://example.com/ex#",
          case_violations: :fail,
          data: RDF.Graph.new([
            {~I<http://example.com/ex#_Foo>, ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>, ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#Property>},
            {~I<http://example.com/ex#_bar>, ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>, ~I<http://www.w3.org/2000/01/rdf-schema#Resource>}
          ])
      end
    end
  end


  describe "defvocab ignore terms" do
    defmodule NSWithIgnoredTerms do
      use RDF.Vocabulary.Namespace

      defvocab ExampleIgnoredLowercasedTerm,
        base_uri: "http://example.com/",
        data: RDF.Graph.new([
          {~I<http://example.com/foo>, ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>, ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#Property>},
          {~I<http://example.com/Bar>, ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>, ~I<http://www.w3.org/2000/01/rdf-schema#Resource>}
        ]),
        ignore: ["foo"]

      defvocab ExampleIgnoredCapitalizedTerm,
        base_uri: "http://example.com/",
        data: RDF.Dataset.new([
          {~I<http://example.com/foo>, ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>, ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#Property>},
          {~I<http://example.com/Bar>, ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>, ~I<http://www.w3.org/2000/01/rdf-schema#Resource>, ~I<http://example.com/from_dataset#Graph>}
        ]),
        ignore: ~w[Bar]

      defvocab ExampleIgnoredLowercasedTermWithAlias,
        base_uri: "http://example.com/",
        terms:    ~w[foo Bar],
        alias:    [Foo: "foo"],
        ignore:   ~w[foo]a

      defvocab ExampleIgnoredCapitalizedTermWithAlias,
        base_uri: "http://example.com/",
        terms:    ~w[foo Bar],
        alias:    [bar: "Bar"],
        ignore:   ~w[Bar]a

      defvocab ExampleIgnoredLowercasedAlias,
        base_uri: "http://example.com/",
        terms:    ~w[foo Bar],
        alias:    [bar: "Bar"],
        ignore:   ~w[bar]a

      defvocab ExampleIgnoredCapitalizedAlias,
        base_uri: "http://example.com/",
        terms:    ~w[foo Bar],
        alias:    [Foo: "foo"],
        ignore:   ~w[Foo]a

      defvocab ExampleIgnoredNonStrictLowercasedTerm,
        base_uri: "http://example.com/",
        terms:    ~w[],
        strict:   false,
        ignore:   ~w[foo]a

      defvocab ExampleIgnoredNonStrictCapitalizedTerm,
        base_uri: "http://example.com/",
        terms:    ~w[],
        strict:   false,
        ignore:   ~w[Bar]a

    end

    test "resolution of ignored lowercased term on a strict vocab fails" do
      alias NSWithIgnoredTerms.ExampleIgnoredLowercasedTerm
      assert ExampleIgnoredLowercasedTerm.__terms__ == [:Bar]
      assert_raise UndefinedFunctionError, fn -> ExampleIgnoredLowercasedTerm.foo end
    end

    test "resolution of ignored capitalized term on a strict vocab fails" do
      alias NSWithIgnoredTerms.ExampleIgnoredCapitalizedTerm
      assert ExampleIgnoredCapitalizedTerm.__terms__ == [:foo]
      assert_raise RDF.Namespace.UndefinedTermError, fn ->
        RDF.uri(ExampleIgnoredCapitalizedTerm.Bar)
      end
    end

    test "resolution of ignored lowercased term with alias on a strict vocab fails" do
      alias NSWithIgnoredTerms.ExampleIgnoredLowercasedTermWithAlias
      assert ExampleIgnoredLowercasedTermWithAlias.__terms__ == [:Bar, :Foo]
      assert_raise UndefinedFunctionError, fn -> ExampleIgnoredLowercasedTermWithAlias.foo end
      assert RDF.uri(ExampleIgnoredLowercasedTermWithAlias.Foo) == ~I<http://example.com/foo>
    end

    test "resolution of ignored capitalized term with alias on a strict vocab fails" do
      alias NSWithIgnoredTerms.ExampleIgnoredCapitalizedTermWithAlias
      assert ExampleIgnoredCapitalizedTermWithAlias.__terms__ == [:bar, :foo]
      assert_raise RDF.Namespace.UndefinedTermError, fn ->
        RDF.uri(ExampleIgnoredCapitalizedTermWithAlias.Bar)
      end
      assert RDF.uri(ExampleIgnoredCapitalizedTermWithAlias.bar) == ~I<http://example.com/Bar>
    end

    test "resolution of ignored lowercased alias on a strict vocab fails" do
      alias NSWithIgnoredTerms.ExampleIgnoredLowercasedAlias
      assert ExampleIgnoredLowercasedAlias.__terms__ == [:Bar, :foo]
      assert RDF.uri(ExampleIgnoredLowercasedAlias.Bar) == ~I<http://example.com/Bar>
      assert_raise UndefinedFunctionError, fn ->
        RDF.uri(ExampleIgnoredLowercasedAlias.bar)
      end
    end

    test "resolution of ignored capitalized alias on a strict vocab fails" do
      alias NSWithIgnoredTerms.ExampleIgnoredCapitalizedAlias
      assert ExampleIgnoredCapitalizedAlias.__terms__ == [:Bar, :foo]
      assert RDF.uri(ExampleIgnoredCapitalizedAlias.foo) == ~I<http://example.com/foo>
      assert_raise RDF.Namespace.UndefinedTermError, fn ->
        RDF.uri(ExampleIgnoredCapitalizedAlias.Foo)
      end
    end

    test "resolution of ignored lowercased term on a non-strict vocab fails" do
      alias NSWithIgnoredTerms.ExampleIgnoredNonStrictLowercasedTerm
      assert_raise UndefinedFunctionError, fn ->
        ExampleIgnoredNonStrictLowercasedTerm.foo
      end
    end

    test "resolution of ignored capitalized term on a non-strict vocab fails" do
      alias NSWithIgnoredTerms.ExampleIgnoredNonStrictCapitalizedTerm
      assert_raise RDF.Namespace.UndefinedTermError, fn ->
        RDF.uri(ExampleIgnoredNonStrictCapitalizedTerm.Bar)
      end
    end

    test "ignored terms with invalid characters do not raise anything" do
      defmodule IgnoredTermWithInvalidCharacters do
        use RDF.Vocabulary.Namespace
        defvocab Example,
          base_uri: "http://example.com/",
          terms:    ~w[foo-bar],
          ignore:   ~w[foo-bar]a
      end
    end

    test "ignored terms with case violations do not raise anything" do
      defmodule IgnoredTermWithCaseViolations do
        use RDF.Vocabulary.Namespace
        defvocab Example,
          base_uri: "http://example.com/",
          data: RDF.Dataset.new([
            {~I<http://example.com/Foo>, ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>, ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#Property>},
            {~I<http://example.com/bar>, ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>, ~I<http://www.w3.org/2000/01/rdf-schema#Resource>, ~I<http://example.com/from_dataset#Graph>}
          ]),
          case_violations: :fail,
          ignore:   ~w[Foo bar]a
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

    alias TestNS.ExampleFromTurtleFile, as: Example4
    assert length(Example4.__uris__) == 2
    assert RDF.uri(Example4.foo) in Example4.__uris__
    assert RDF.uri(Example4.Bar) in Example4.__uris__

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

    test "capitalized terms" do
      assert RDF.uri(ExampleFromGraph.Bar) == URI.parse("http://example.com/from_graph#Bar")
      assert RDF.uri(ExampleFromNTriplesFile.Bar) == URI.parse("http://example.com/from_ntriples/Bar")
      assert RDF.uri(StrictExampleFromTerms.Bar) == URI.parse("http://example.com/strict_from_terms#Bar")
    end

    test "terms starting with an underscore" do
      defmodule NSwithUnderscoreTerms do
        use RDF.Vocabulary.Namespace

        defvocab Example,
          base_uri: "http://example.com/ex#",
          terms: ~w[_foo]
      end
      alias NSwithUnderscoreTerms.Example
      alias TestNS.EX

      assert Example._foo == ~I<http://example.com/ex#_foo>
      assert Example._foo(EX.S, 1) == RDF.description(EX.S, Example._foo, 1)
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

    test "undefined terms starting with an underscore" do
      assert NonStrictExampleFromTerms._random == URI.parse("http://example.com/non_strict_from_terms#_random")
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


  describe "term resolution on the top-level RDF module" do
    test "capitalized terms" do
      assert RDF.uri(RDF.Property)     == URI.parse("http://www.w3.org/1999/02/22-rdf-syntax-ns#Property")
      assert RDF.uri(RDF.Statement)    == URI.parse("http://www.w3.org/1999/02/22-rdf-syntax-ns#Statement")
      assert RDF.uri(RDF.List)         == URI.parse("http://www.w3.org/1999/02/22-rdf-syntax-ns#List")
      assert RDF.uri(RDF.Nil)          == URI.parse("http://www.w3.org/1999/02/22-rdf-syntax-ns#nil")
      assert RDF.uri(RDF.Seq)          == URI.parse("http://www.w3.org/1999/02/22-rdf-syntax-ns#Seq")
      assert RDF.uri(RDF.Bag)          == URI.parse("http://www.w3.org/1999/02/22-rdf-syntax-ns#Bag")
      assert RDF.uri(RDF.Alt)          == URI.parse("http://www.w3.org/1999/02/22-rdf-syntax-ns#Alt")
      assert RDF.uri(RDF.LangString)   == URI.parse("http://www.w3.org/1999/02/22-rdf-syntax-ns#langString")
      assert RDF.uri(RDF.PlainLiteral) == URI.parse("http://www.w3.org/1999/02/22-rdf-syntax-ns#PlainLiteral")
      assert RDF.uri(RDF.XMLLiteral)   == URI.parse("http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral")
      assert RDF.uri(RDF.HTML)         == URI.parse("http://www.w3.org/1999/02/22-rdf-syntax-ns#HTML")
      assert RDF.uri(RDF.Property)     == URI.parse("http://www.w3.org/1999/02/22-rdf-syntax-ns#Property")
    end

    test "lowercase terms" do
      assert RDF.type      == URI.parse("http://www.w3.org/1999/02/22-rdf-syntax-ns#type")
      assert RDF.subject   == URI.parse("http://www.w3.org/1999/02/22-rdf-syntax-ns#subject")
      assert RDF.predicate == URI.parse("http://www.w3.org/1999/02/22-rdf-syntax-ns#predicate")
      assert RDF.object    == URI.parse("http://www.w3.org/1999/02/22-rdf-syntax-ns#object")
      assert RDF.first     == URI.parse("http://www.w3.org/1999/02/22-rdf-syntax-ns#first")
      assert RDF.rest      == URI.parse("http://www.w3.org/1999/02/22-rdf-syntax-ns#rest")
      assert RDF.value     == URI.parse("http://www.w3.org/1999/02/22-rdf-syntax-ns#value")

      assert RDF.langString == URI.parse("http://www.w3.org/1999/02/22-rdf-syntax-ns#langString")
      assert RDF.nil        == URI.parse("http://www.w3.org/1999/02/22-rdf-syntax-ns#nil")
    end

    test "description DSL" do
      alias TestNS.EX
      assert RDF.type(     EX.S, 1)                     == RDF.NS.RDF.type(     EX.S, 1)
      assert RDF.subject(  EX.S, 1, 2)                  == RDF.NS.RDF.subject(  EX.S, 1, 2)
      assert RDF.predicate(EX.S, 1, 2, 3)               == RDF.NS.RDF.predicate(EX.S, 1, 2, 3)
      assert RDF.object(   EX.S, 1, 2, 3, 4)            == RDF.NS.RDF.object(   EX.S, 1, 2, 3, 4)
      assert RDF.first(    EX.S, 1, 2, 3, 4, 5)         == RDF.NS.RDF.first(    EX.S, 1, 2, 3, 4, 5)
      assert RDF.rest(     EX.S, [1, 2, 3, 4, 5, 6])    == RDF.NS.RDF.rest(     EX.S, [1, 2, 3, 4, 5, 6])
      assert RDF.value(    EX.S, [1, 2, 3, 4, 5, 6, 7]) == RDF.NS.RDF.value(    EX.S, [1, 2, 3, 4, 5, 6, 7])
    end
  end

end
