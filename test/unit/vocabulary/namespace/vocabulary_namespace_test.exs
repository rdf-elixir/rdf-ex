defmodule RDF.Vocabulary.NamespaceTest do
  use ExUnit.Case

  doctest RDF.Vocabulary.Namespace

  import RDF.Sigils

  alias RDF.Description
  alias RDF.NS.RDFS

  @compile {:no_warn_undefined, RDF.Vocabulary.NamespaceTest.TestNS.EX}
  @compile {:no_warn_undefined, RDF.Vocabulary.NamespaceTest.TestNS.ExampleFromGraph}
  @compile {:no_warn_undefined, RDF.Vocabulary.NamespaceTest.TestNS.ExampleFromNTriplesFile}
  @compile {:no_warn_undefined, RDF.Vocabulary.NamespaceTest.TestNS.NonStrictExampleFromTerms}
  @compile {:no_warn_undefined,
            RDF.Vocabulary.NamespaceTest.TestNS.NonStrictExampleFromAliasedTerms}
  @compile {:no_warn_undefined, RDF.Vocabulary.NamespaceTest.TestNS.StrictExampleFromTerms}
  @compile {:no_warn_undefined, RDF.Vocabulary.NamespaceTest.NSofEdgeCases.Example}
  @compile {:no_warn_undefined, RDF.Vocabulary.NamespaceTest.NSwithKernelConflicts.Example}
  @compile {:no_warn_undefined, RDF.Vocabulary.NamespaceTest.NSWithAliasesForElixirTerms.Example}
  @compile {:no_warn_undefined, RDF.Vocabulary.NamespaceTest.NSwithUnderscoreTerms.Example}
  @compile {:no_warn_undefined,
            RDF.Vocabulary.NamespaceTest.NSWithIgnoredTerms.ExampleIgnoredLowercasedTerm}
  @compile {:no_warn_undefined,
            RDF.Vocabulary.NamespaceTest.NSWithIgnoredTerms.ExampleIgnoredNonStrictLowercasedTerm}
  @compile {:no_warn_undefined,
            RDF.Vocabulary.NamespaceTest.NSWithIgnoredTerms.ExampleIgnoredLowercasedTermWithAlias}
  @compile {:no_warn_undefined,
            RDF.Vocabulary.NamespaceTest.NSWithIgnoredTerms.ExampleIgnoredLowercasedAlias}
  @compile {:no_warn_undefined,
            RDF.Vocabulary.NamespaceTest.NSWithExplicitlyIgnoredElixirTerms.Example}
  @compile {:no_warn_undefined,
            RDF.Vocabulary.NamespaceTest.IgnoredAliasTest.ExampleIgnoredLowercasedAlias}
  @compile {:no_warn_undefined,
            RDF.Vocabulary.NamespaceTest.IgnoredAliasTest.ExampleIgnoredCapitalizedAlias}

  defmodule ExampleCaseViolationHandler do
    def fix(_, "baazTest"), do: :ignore
    def fix(:property, term), do: {:ok, String.downcase(term)}
    def fix(:resource, term), do: {:ok, String.upcase(term)}

    def fix(_, "baazTest", _), do: raise("this should not happen since we have an alias defined")
    def fix(:property, term, arg), do: {:ok, String.downcase(term) <> arg}
    def fix(:resource, term, arg), do: {:ok, String.upcase(term) <> arg}
  end

  defmodule TestNS do
    use RDF.Vocabulary.Namespace

    defvocab EX, base_iri: "http://example.com/", terms: ~w[], strict: false

    defvocab EXS,
      base_iri: "http://example.com/strict#",
      terms: ~w[foo bar]

    @base_iri "http://example.com/"
    defvocab ExampleWithBaseFromModuleAttribute,
      base_iri: @base_iri,
      terms: ~w[foo Bar]a

    defvocab ExampleWithBaseFromIRI,
      base_iri: ~I<http://example.com/>,
      terms: ~w[foo Bar]a

    defvocab ExampleFromGraph,
      base_iri: "http://example.com/from_graph#",
      data:
        RDF.Graph.new([
          {~I<http://example.com/from_graph#foo>, RDF.type(), RDF.Property},
          {~I<http://example.com/from_graph#Bar>, RDF.type(), RDFS.Resource}
        ])

    defvocab ExampleFromDataset,
      base_iri: "http://example.com/from_dataset#",
      data:
        RDF.Dataset.new([
          {~I<http://example.com/from_dataset#foo>, RDF.type(), RDF.Property},
          {~I<http://example.com/from_dataset#Bar>, RDF.type(), RDFS.Resource,
           ~I<http://example.com/from_dataset#Graph>}
        ])

    defvocab ExampleFromNTriplesFile,
      base_iri: "http://example.com/from_ntriples/",
      file: "test/data/vocab_ns_example.nt"

    defvocab ExampleFromNQuadsFile,
      base_iri: "http://example.com/from_nquads/",
      file: "test/data/vocab_ns_example.nq"

    defvocab ExampleFromTurtleFile,
      base_iri: "http://example.com/from_turtle/",
      file: "test/data/vocab_ns_example.ttl"

    defvocab StrictExampleFromTerms,
      base_iri: "http://example.com/strict_from_terms#",
      terms: ~w[foo Bar]

    defvocab NonStrictExampleFromTerms,
      base_iri: "http://example.com/non_strict_from_terms#",
      terms: ~w[foo Bar],
      strict: false

    defvocab StrictExampleFromAliasedTerms,
      base_iri: "http://example.com/strict_from_aliased_terms#",
      terms: ~w[term1 Term2 Term-3 term-4],
      alias: [
        Term1: "term1",
        term2: "Term2",
        Term3: "Term-3",
        term4: "term-4"
      ]

    defvocab StrictExampleFromImplicitAliasedTerms,
      base_iri: "http://example.com/strict_from_aliased_terms#",
      terms: [
        :term5,
        :term6,
        Term1: "term1",
        term2: "Term2",
        Term3: "Term-3",
        term4: "term-4"
      ]

    defvocab NonStrictExampleFromAliasedTerms,
      base_iri: "http://example.com/non_strict_from_aliased_terms#",
      terms: ~w[],
      alias: [
        Term1: "term1",
        term2: "Term2",
        Term3: "Term-3",
        term4: "term-4"
      ],
      strict: false

    defvocab ExampleWithSynonymAliases,
      base_iri: "http://example.com/ex#",
      terms: ~w[bar Bar],
      alias: [foo: "bar", baz: "bar", Foo: "Bar", Baz: "Bar"]

    defvocab ExampleWithSynonymImplicitAliases,
      base_iri: "http://example.com/ex#",
      terms: [foo: "bar", baz: "bar", Foo: "Bar", Baz: "Bar"]

    defvocab ExampleWithAutoFixedCaseViolations,
      base_iri: "http://example.com/ex#",
      case_violations: :auto_fix,
      data:
        RDF.Graph.new([
          {~I<http://example.com/ex#FooTest>, RDF.type(), RDF.Property},
          {~I<http://example.com/ex#barTest>, RDF.type(), RDF.Property},
          {~I<http://example.com/ex#bazTest>, RDF.type(), RDFS.Resource},
          {~I<http://example.com/ex#baazTest>, RDF.type(), RDFS.Resource}
        ]),
      alias: [BaazAlias: :baazTest]

    defvocab ExampleWithAutoFixedCaseViolationsAllowLowercaseResource,
      base_iri: "http://example.com/ex#",
      case_violations: :auto_fix,
      allow_lowercase_resource_terms: true,
      data:
        RDF.Graph.new([
          {~I<http://example.com/ex#FooTest>, RDF.type(), RDF.Property},
          {~I<http://example.com/ex#barTest>, RDF.type(), RDF.Property},
          {~I<http://example.com/ex#bazTest>, RDF.type(), RDFS.Resource},
          {~I<http://example.com/ex#baazTest>, RDF.type(), RDFS.Resource}
        ]),
      alias: [BaazAlias: :baazTest]

    defvocab ExampleWithCustomInlineCaseViolationFunction,
      base_iri: "http://example.com/ex#",
      case_violations: fn
        _, "baazTest" -> :ignore
        :property, term -> {:ok, Macro.underscore(term)}
        :resource, term -> {:ok, Macro.camelize(term)}
      end,
      data:
        RDF.Graph.new([
          {~I<http://example.com/ex#FooTest>, RDF.type(), RDF.Property},
          {~I<http://example.com/ex#barTest>, RDF.type(), RDF.Property},
          {~I<http://example.com/ex#bazTest>, RDF.type(), RDFS.Resource},
          {~I<http://example.com/ex#baazTest>, RDF.type(), RDFS.Resource}
        ])

    defvocab ExampleWithCustomExternalCaseViolationFunction,
      base_iri: "http://example.com/ex#",
      case_violations: {ExampleCaseViolationHandler, :fix},
      data:
        RDF.Graph.new([
          {~I<http://example.com/ex#FooTest>, RDF.type(), RDF.Property},
          {~I<http://example.com/ex#barTest>, RDF.type(), RDF.Property},
          {~I<http://example.com/ex#bazTest>, RDF.type(), RDFS.Resource},
          {~I<http://example.com/ex#baazTest>, RDF.type(), RDFS.Resource}
        ])

    defvocab ExampleWithCustomExternalCaseViolationFunctionWithArgs,
      base_iri: "http://example.com/ex#",
      case_violations: {ExampleCaseViolationHandler, :fix, ["arg"]},
      data:
        RDF.Graph.new([
          {~I<http://example.com/ex#FooTest>, RDF.type(), RDF.Property},
          {~I<http://example.com/ex#barTest>, RDF.type(), RDF.Property},
          {~I<http://example.com/ex#bazTest>, RDF.type(), RDFS.Resource},
          {~I<http://example.com/ex#baazTest>, RDF.type(), RDFS.Resource}
        ]),
      alias: [BaazTest: :baazTest]
  end

  describe "defvocab with bad base iri" do
    test "without a base_iri, an error is raised" do
      assert_raise RDF.Vocabulary.Namespace.CompileError,
                   ~r/invalid base IRI: nil/,
                   fn ->
                     defmodule NSWithoutBaseIRI do
                       use RDF.Vocabulary.Namespace

                       defvocab Example, terms: []
                     end
                   end
    end

    test "when the base_iri isn't a valid IRI, an error is raised" do
      assert_raise RDF.Vocabulary.Namespace.CompileError,
                   ~r/invalid base IRI: "invalid"/,
                   fn ->
                     defmodule NSWithInvalidBaseIRI2 do
                       use RDF.Vocabulary.Namespace

                       defvocab Example,
                         base_iri: "invalid",
                         terms: []
                     end
                   end

      assert_raise RDF.Vocabulary.Namespace.CompileError,
                   ~r/invalid base IRI: :foo/,
                   fn ->
                     defmodule NSWithInvalidBaseIRI3 do
                       use RDF.Vocabulary.Namespace

                       defvocab Example,
                         base_iri: :foo,
                         terms: []
                     end
                   end
    end
  end

  describe "defvocab with bad file" do
    test "when the given file not found, an error is raised" do
      assert_raise File.Error, fn ->
        defmodule NSWithMissingVocabFile do
          use RDF.Vocabulary.Namespace

          defvocab Example,
            base_iri: "http://example.com/ex#",
            file: "something.nt"
        end
      end
    end
  end

  describe "defvocab with bad aliases" do
    test "when an alias uses invalid types, an error is raised" do
      assert_raise RDF.Vocabulary.Namespace.CompileError,
                   ~r/invalid term type: 42/,
                   fn ->
                     defmodule NSWithInvalidTypesInAliases do
                       use RDF.Vocabulary.Namespace

                       defvocab Example,
                         base_iri: "http://example.com/ex#",
                         terms: [:foo],
                         alias: [foo: 42]
                     end
                   end
    end

    test "when an alias contains invalid characters, an error is raised" do
      assert_raise RDF.Vocabulary.Namespace.CompileError,
                   ~r/alias 'foo-bar' contains invalid characters/,
                   fn ->
                     defmodule NSWithInvalidTerms do
                       use RDF.Vocabulary.Namespace

                       defvocab Example,
                         base_iri: "http://example.com/ex#",
                         terms: ~w[foo],
                         alias: ["foo-bar": "foo"]
                     end
                   end
    end

    test "when trying to map an already existing term, an error is raised" do
      assert_raise RDF.Vocabulary.Namespace.CompileError,
                   ~r/alias 'foo' conflicts with an existing term/,
                   fn ->
                     defmodule NSWithInvalidAliases1 do
                       use RDF.Vocabulary.Namespace

                       defvocab Example,
                         base_iri: "http://example.com/ex#",
                         terms: ~w[foo bar],
                         alias: [foo: "bar"]
                     end
                   end
    end

    test "when strict and trying to map to a term not in the vocabulary, an error is raised" do
      assert_raise RDF.Vocabulary.Namespace.CompileError,
                   ~r/term 'bar' is not a term in this namespace/,
                   fn ->
                     defmodule NSWithInvalidAliases2 do
                       use RDF.Vocabulary.Namespace

                       defvocab Example,
                         base_iri: "http://example.com/ex#",
                         terms: ~w[],
                         alias: [foo: "bar"]
                     end
                   end
    end

    test "when defining an alias for an alias, an error is raised" do
      assert_raise RDF.Vocabulary.Namespace.CompileError,
                   ~r/alias 'baz' is referring to alias 'foo'/,
                   fn ->
                     defmodule NSWithInvalidAliases3 do
                       use RDF.Vocabulary.Namespace

                       defvocab Example,
                         base_iri: "http://example.com/ex#",
                         terms: ~w[bar],
                         alias: [foo: "bar", baz: "foo"]
                     end
                   end
    end
  end

  test "defvocab with special terms" do
    defmodule NSofEdgeCases do
      use RDF.Vocabulary.Namespace

      defvocab Example,
        base_iri: "http://example.com/ex#",
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
          __MODULE__
          __FILE__
          __DIR__
          __ENV__
          __CALLER__
        ]

      # This one also passes the tests, but causes some warnings:
      # __block__
    end

    alias NSofEdgeCases.Example
    alias TestNS.EX

    assert Example.nil() == ~I<http://example.com/ex#nil>
    assert Example.true() == ~I<http://example.com/ex#true>
    assert Example.false() == ~I<http://example.com/ex#false>
    assert Example.do() == ~I<http://example.com/ex#do>
    assert Example.end() == ~I<http://example.com/ex#end>
    assert Example.else() == ~I<http://example.com/ex#else>
    assert Example.try() == ~I<http://example.com/ex#try>
    assert Example.rescue() == ~I<http://example.com/ex#rescue>
    assert Example.catch() == ~I<http://example.com/ex#catch>
    assert Example.after() == ~I<http://example.com/ex#after>
    assert Example.not() == ~I<http://example.com/ex#not>
    assert Example.cond() == ~I<http://example.com/ex#cond>
    assert Example.inbits() == ~I<http://example.com/ex#inbits>
    assert Example.inlist() == ~I<http://example.com/ex#inlist>
    assert Example.receive() == ~I<http://example.com/ex#receive>
    #    assert Example.__block__   == ~I<http://example.com/ex#__block__>
    assert Example.__MODULE__() == ~I<http://example.com/ex#__MODULE__>
    assert Example.__FILE__() == ~I<http://example.com/ex#__FILE__>
    assert Example.__DIR__() == ~I<http://example.com/ex#__DIR__>
    assert Example.__ENV__() == ~I<http://example.com/ex#__ENV__>
    assert Example.__CALLER__() == ~I<http://example.com/ex#__CALLER__>

    assert Example.nil(EX.S, 1) == RDF.description(EX.S, init: {EX.S, Example.nil(), 1})
    assert Example.true(EX.S, 1) == RDF.description(EX.S, init: {EX.S, Example.true(), 1})
    assert Example.false(EX.S, 1) == RDF.description(EX.S, init: {EX.S, Example.false(), 1})
    assert Example.do(EX.S, 1) == RDF.description(EX.S, init: {EX.S, Example.do(), 1})
    assert Example.end(EX.S, 1) == RDF.description(EX.S, init: {EX.S, Example.end(), 1})
    assert Example.else(EX.S, 1) == RDF.description(EX.S, init: {EX.S, Example.else(), 1})
    assert Example.try(EX.S, 1) == RDF.description(EX.S, init: {EX.S, Example.try(), 1})
    assert Example.rescue(EX.S, 1) == RDF.description(EX.S, init: {EX.S, Example.rescue(), 1})
    assert Example.catch(EX.S, 1) == RDF.description(EX.S, init: {EX.S, Example.catch(), 1})
    assert Example.after(EX.S, 1) == RDF.description(EX.S, init: {EX.S, Example.after(), 1})
    assert Example.not(EX.S, 1) == RDF.description(EX.S, init: {EX.S, Example.not(), 1})
    assert Example.cond(EX.S, 1) == RDF.description(EX.S, init: {EX.S, Example.cond(), 1})
    assert Example.inbits(EX.S, 1) == RDF.description(EX.S, init: {EX.S, Example.inbits(), 1})
    assert Example.inlist(EX.S, 1) == RDF.description(EX.S, init: {EX.S, Example.inlist(), 1})
    assert Example.receive(EX.S, 1) == RDF.description(EX.S, init: {EX.S, Example.receive(), 1})
  end

  test "defvocab with terms in conflict with Kernel functions" do
    defmodule NSwithKernelConflicts do
      use RDF.Vocabulary.Namespace

      defvocab Example,
        base_iri: "http://example.com/ex#",
        terms: ~w[
          abs
          apply
          binary_part
          binding
          bit_size
          byte_size
          ceil
          destructure
          div
          elem
          exit
          floor
          get_and_update_in
          get_in
          hd
          inspect
          is_atom
          is_tuple
          length
          make_ref
          map_size
          max
          min
          node
          not
          pop_in
          put_elem
          put_in
          raise
          rem
          reraise
          round
          self
          send
          spawn
          spawn_link
          spawn_monitor
          struct
          throw
          tl
          to_charlist
          to_string
          trunc
          tuple_size
          update_in
          use
      ]
    end

    alias NSwithKernelConflicts.Example
    alias TestNS.EX

    assert Example.abs() == ~I<http://example.com/ex#abs>
    assert Example.apply() == ~I<http://example.com/ex#apply>
    assert Example.binary_part() == ~I<http://example.com/ex#binary_part>
    assert Example.binding() == ~I<http://example.com/ex#binding>
    assert Example.bit_size() == ~I<http://example.com/ex#bit_size>
    assert Example.byte_size() == ~I<http://example.com/ex#byte_size>
    assert Example.ceil() == ~I<http://example.com/ex#ceil>
    assert Example.destructure() == ~I<http://example.com/ex#destructure>
    assert Example.div() == ~I<http://example.com/ex#div>
    assert Example.elem() == ~I<http://example.com/ex#elem>
    assert Example.exit() == ~I<http://example.com/ex#exit>
    assert Example.floor() == ~I<http://example.com/ex#floor>
    assert Example.get_and_update_in() == ~I<http://example.com/ex#get_and_update_in>
    assert Example.get_in() == ~I<http://example.com/ex#get_in>
    assert Example.hd() == ~I<http://example.com/ex#hd>
    assert Example.inspect() == ~I<http://example.com/ex#inspect>
    assert Example.is_atom() == ~I<http://example.com/ex#is_atom>
    assert Example.is_tuple() == ~I<http://example.com/ex#is_tuple>
    assert Example.length() == ~I<http://example.com/ex#length>
    assert Example.make_ref() == ~I<http://example.com/ex#make_ref>
    assert Example.map_size() == ~I<http://example.com/ex#map_size>
    assert Example.max() == ~I<http://example.com/ex#max>
    assert Example.min() == ~I<http://example.com/ex#min>
    assert Example.node() == ~I<http://example.com/ex#node>
    assert Example.not() == ~I<http://example.com/ex#not>
    assert Example.pop_in() == ~I<http://example.com/ex#pop_in>
    assert Example.put_elem() == ~I<http://example.com/ex#put_elem>
    assert Example.put_in() == ~I<http://example.com/ex#put_in>
    assert Example.raise() == ~I<http://example.com/ex#raise>
    assert Example.rem() == ~I<http://example.com/ex#rem>
    assert Example.reraise() == ~I<http://example.com/ex#reraise>
    assert Example.round() == ~I<http://example.com/ex#round>
    assert Example.self() == ~I<http://example.com/ex#self>
    assert Example.send() == ~I<http://example.com/ex#send>
    assert Example.spawn() == ~I<http://example.com/ex#spawn>
    assert Example.spawn_link() == ~I<http://example.com/ex#spawn_link>
    assert Example.spawn_monitor() == ~I<http://example.com/ex#spawn_monitor>
    assert Example.struct() == ~I<http://example.com/ex#struct>
    assert Example.throw() == ~I<http://example.com/ex#throw>
    assert Example.tl() == ~I<http://example.com/ex#tl>
    assert Example.to_charlist() == ~I<http://example.com/ex#to_charlist>
    assert Example.to_string() == ~I<http://example.com/ex#to_string>
    assert Example.trunc() == ~I<http://example.com/ex#trunc>
    assert Example.tuple_size() == ~I<http://example.com/ex#tuple_size>
    assert Example.update_in() == ~I<http://example.com/ex#update_in>
    assert Example.use() == ~I<http://example.com/ex#use>

    assert %Description{} = EX.S |> Example.update_in(EX.O)
  end

  describe "defvocab with reserved terms" do
    test "terms with a special meaning for Elixir cause a failure" do
      assert_raise RDF.Vocabulary.Namespace.CompileError,
                   ~r/The following terms can not be used, because they conflict with reserved Elixir terms:.*unquote_splicing/s,
                   fn ->
                     defmodule NSWithElixirTerms do
                       use RDF.Vocabulary.Namespace

                       defvocab Example,
                         base_iri: "http://example.com/example#",
                         terms: RDF.Namespace.Builder.reserved_terms()
                     end
                   end
    end

    test "alias terms with a special meaning for Elixir cause a failure" do
      assert_raise RDF.Vocabulary.Namespace.CompileError,
                   ~r/alias 'and' is a reserved term and can't be used as an alias/s,
                   fn ->
                     defmodule NSWithElixirAliasTerms do
                       use RDF.Vocabulary.Namespace

                       defvocab Example,
                         base_iri: "http://example.com/example#",
                         terms: ~w[foo],
                         alias: [
                           and: "foo",
                           or: "foo",
                           xor: "foo",
                           in: "foo",
                           fn: "foo",
                           def: "foo",
                           when: "foo",
                           if: "foo",
                           for: "foo",
                           case: "foo",
                           with: "foo",
                           quote: "foo",
                           unquote: "foo",
                           unquote_splicing: "foo",
                           alias: "foo",
                           import: "foo",
                           require: "foo",
                           super: "foo",
                           __aliases__: "foo"
                         ]
                     end
                   end
    end

    test "terms with a special meaning for Elixir don't cause a failure when they are ignored via invalid_terms: :ignore" do
      defmodule NSWithIgnoredElixirTerms do
        use RDF.Vocabulary.Namespace

        defvocab Example,
          base_iri: "http://example.com/example#",
          terms: RDF.Namespace.Builder.reserved_terms() ++ [:foo],
          invalid_terms: :ignore

        assert NSWithIgnoredElixirTerms.Example.__terms__() == [:foo]
      end
    end

    test "terms with a special meaning for Elixir don't cause a failure when they are ignored explicitly" do
      defmodule NSWithExplicitlyIgnoredElixirTerms do
        use RDF.Vocabulary.Namespace

        defvocab Example,
          base_iri: "http://example.com/example#",
          terms: RDF.Namespace.Builder.reserved_terms(),
          ignore: RDF.Namespace.Builder.reserved_terms()
      end

      assert NSWithExplicitlyIgnoredElixirTerms.Example.__terms__() == []
    end

    test "terms with a special meaning for Elixir don't cause a failure when an alias is defined" do
      defmodule NSWithAliasesForElixirTerms do
        use RDF.Vocabulary.Namespace

        defvocab Example,
          base_iri: "http://example.com/example#",
          terms: RDF.Namespace.Builder.reserved_terms(),
          alias: [
            and_: "and",
            or_: "or",
            xor_: "xor",
            in_: "in",
            fn_: "fn",
            when_: "when",
            if_: "if",
            unless_: "unless",
            for_: "for",
            case_: "case",
            with_: "with",
            quote_: "quote",
            unquote_: "unquote",
            unquote_splicing_: "unquote_splicing",
            alias_: "alias",
            import_: "import",
            require_: "require",
            super_: "super",
            _aliases_: "__aliases__",
            _info_: "__info__",
            def_: "def",
            defp_: "defp",
            defoverridable_: "defoverridable",
            defguardp_: "defguardp",
            defimpl_: "defimpl",
            defstruct_: "defstruct",
            defmodule_: "defmodule",
            defguard_: "defguard",
            defmacro_: "defmacro",
            defprotocol_: "defprotocol",
            defdelegate_: "defdelegate",
            defexception_: "defexception",
            defmacrop_: "defmacrop",
            function_exported: "function_exported?",
            macro_exported: "macro_exported?"
          ]
      end

      alias NSWithAliasesForElixirTerms.Example

      assert Example.and_() == ~I<http://example.com/example#and>
      assert Example.or_() == ~I<http://example.com/example#or>
      assert Example.xor_() == ~I<http://example.com/example#xor>
      assert Example.in_() == ~I<http://example.com/example#in>
      assert Example.fn_() == ~I<http://example.com/example#fn>
      assert Example.when_() == ~I<http://example.com/example#when>
      assert Example.if_() == ~I<http://example.com/example#if>
      assert Example.unless_() == ~I<http://example.com/example#unless>
      assert Example.for_() == ~I<http://example.com/example#for>
      assert Example.case_() == ~I<http://example.com/example#case>
      assert Example.with_() == ~I<http://example.com/example#with>
      assert Example.quote_() == ~I<http://example.com/example#quote>
      assert Example.unquote_() == ~I<http://example.com/example#unquote>
      assert Example.unquote_splicing_() == ~I<http://example.com/example#unquote_splicing>
      assert Example.alias_() == ~I<http://example.com/example#alias>
      assert Example.import_() == ~I<http://example.com/example#import>
      assert Example.require_() == ~I<http://example.com/example#require>
      assert Example.super_() == ~I<http://example.com/example#super>
      assert Example._aliases_() == ~I<http://example.com/example#__aliases__>
      assert Example.def_() == ~I<http://example.com/example#def>
      assert Example.defp_() == ~I<http://example.com/example#defp>
      assert Example.defoverridable_() == ~I<http://example.com/example#defoverridable>
      assert Example.defguardp_() == ~I<http://example.com/example#defguardp>
      assert Example.defimpl_() == ~I<http://example.com/example#defimpl>
      assert Example.defstruct_() == ~I<http://example.com/example#defstruct>
      assert Example.defmodule_() == ~I<http://example.com/example#defmodule>
      assert Example.defguard_() == ~I<http://example.com/example#defguard>
      assert Example.defmacro_() == ~I<http://example.com/example#defmacro>
      assert Example.defprotocol_() == ~I<http://example.com/example#defprotocol>
      assert Example.defdelegate_() == ~I<http://example.com/example#defdelegate>
      assert Example.defexception_() == ~I<http://example.com/example#defexception>
      assert Example.defmacrop_() == ~I<http://example.com/example#defmacrop>
      assert Example.function_exported() == ~I<http://example.com/example#function_exported?>
      assert Example.macro_exported() == ~I<http://example.com/example#macro_exported?>
    end

    test "failures for reserved terms as aliases can't be ignored" do
      assert_raise RDF.Vocabulary.Namespace.CompileError,
                   ~r/alias 'super' is a reserved term and can't be used as an alias/s,
                   fn ->
                     defmodule NSWithElixirAliasTerms do
                       use RDF.Vocabulary.Namespace

                       defvocab Example,
                         base_iri: "http://example.com/example#",
                         terms: ~w[foo],
                         alias: [super: "foo"],
                         invalid_terms: :ignore
                     end
                   end
    end
  end

  describe "defvocab invalid character handling" do
    test "when a term contains disallowed characters and no alias defined, it fails when invalid_characters: :fail" do
      assert_raise RDF.Vocabulary.Namespace.CompileError,
                   ~r/The following terms contain invalid characters:.*foo-bar.*Foo-bar/s,
                   fn ->
                     defmodule NSWithInvalidTerms1 do
                       use RDF.Vocabulary.Namespace

                       defvocab Example,
                         base_iri: "http://example.com/example#",
                         terms: ~w[Foo-bar foo-bar]
                     end
                   end
    end

    test "when a term contains disallowed characters it does not fail when invalid_characters: :ignore" do
      defmodule NSWithInvalidTerms2 do
        use RDF.Vocabulary.Namespace

        defvocab Example,
          base_iri: "http://example.com/example#",
          terms: ~w[Foo-bar foo-bar],
          invalid_characters: :ignore
      end
    end

    test "when a term contains disallowed characters it does not fail when invalid_characters: :warn" do
      err =
        ExUnit.CaptureIO.capture_io(:stderr, fn ->
          defmodule NSWithInvalidTerms3 do
            use RDF.Vocabulary.Namespace

            defvocab Example,
              base_iri: "http://example.com/example#",
              terms: ~w[Foo-bar foo-bar],
              invalid_characters: :warn
          end
        end)

      assert err =~ "ignoring term 'foo-bar', since it contains invalid characters"
    end
  end

  describe "defvocab case violation handling" do
    test "aliases can fix case violations" do
      defmodule NSWithBadCasedTerms1 do
        use RDF.Vocabulary.Namespace

        defvocab Example,
          base_iri: "http://example.com/ex#",
          case_violations: :fail,
          data:
            RDF.Graph.new([
              {~I<http://example.com/ex#Foo>, RDF.type(), RDF.Property},
              {~I<http://example.com/ex#bar>, RDF.type(), RDFS.Resource}
            ]),
          alias: [
            foo: "Foo",
            Bar: "bar"
          ]
      end
    end

    test "when case_violations == :ignore is set, case violations are ignored" do
      defmodule NSWithBadCasedTerms2 do
        use RDF.Vocabulary.Namespace

        defvocab Example,
          base_iri: "http://example.com/ex#",
          case_violations: :ignore,
          data:
            RDF.Graph.new([
              {~I<http://example.com/ex#Foo>, RDF.type(), RDF.Property},
              {~I<http://example.com/ex#bar>, RDF.type(), RDFS.Resource}
            ]),
          alias: [
            foo: "Foo",
            Bar: "bar"
          ]
      end
    end

    test "a capitalized property without an alias and :case_violations == :fail, raises an error" do
      assert_raise RDF.Vocabulary.Namespace.CompileError,
                   ~r<Case violations.*http://example\.com/ex#Foo>s,
                   fn ->
                     defmodule NSWithBadCasedTerms3 do
                       use RDF.Vocabulary.Namespace

                       defvocab Example,
                         base_iri: "http://example.com/ex#",
                         case_violations: :fail,
                         data:
                           RDF.Graph.new([
                             {~I<http://example.com/ex#Foo>, RDF.type(), RDF.Property}
                           ])
                     end
                   end
    end

    test "a lowercased non-property without an alias and :case_violations == :fail, raises an error" do
      assert_raise RDF.Vocabulary.Namespace.CompileError,
                   ~r<Case violations.*http://example\.com/ex#bar>s,
                   fn ->
                     defmodule NSWithBadCasedTerms4 do
                       use RDF.Vocabulary.Namespace

                       defvocab Example,
                         base_iri: "http://example.com/ex#",
                         case_violations: :fail,
                         data:
                           RDF.Graph.new([
                             {~I<http://example.com/ex#bar>, RDF.type(), RDFS.Resource}
                           ])
                     end
                   end
    end

    test "a lowercased non-property term is allowed with allow_lowercase_resource_terms: true" do
      defmodule NSWithAllowedLowercaseResourceTerm do
        use RDF.Vocabulary.Namespace

        defvocab Example,
          base_iri: "http://example.com/ex#",
          case_violations: :fail,
          allow_lowercase_resource_terms: true,
          data:
            RDF.Graph.new([
              {~I<http://example.com/ex#bar>, RDF.type(), RDFS.Resource}
            ])
      end
    end

    test "a capitalized alias for a property and :case_violations == :fail, raises an error" do
      assert_raise RDF.Vocabulary.Namespace.CompileError,
                   ~r<Case violations.*http://example\.com/ex#foo>s,
                   fn ->
                     defmodule NSWithBadCasedTerms5 do
                       use RDF.Vocabulary.Namespace

                       defvocab Example,
                         base_iri: "http://example.com/ex#",
                         case_violations: :fail,
                         data:
                           RDF.Graph.new([
                             {~I<http://example.com/ex#foo>, RDF.type(), RDF.Property}
                           ]),
                         alias: [Foo: "foo"]
                     end
                   end
    end

    test "a lowercased alias for a non-property and :case_violations == :fail, raises an error" do
      assert_raise RDF.Vocabulary.Namespace.CompileError,
                   ~r<Case violations.*http://example\.com/ex#Bar>s,
                   fn ->
                     defmodule NSWithBadCasedTerms6 do
                       use RDF.Vocabulary.Namespace

                       defvocab Example,
                         base_iri: "http://example.com/ex#",
                         case_violations: :fail,
                         data:
                           RDF.Graph.new([
                             {~I<http://example.com/ex#Bar>, RDF.type(), RDFS.Resource}
                           ]),
                         alias: [bar: "Bar"]
                     end
                   end
    end

    test "a lowercased alias for a non-property term is allowed with allow_lowercase_resource_terms: true" do
      defmodule NSWithAllowedLowercaseResourceAlias do
        use RDF.Vocabulary.Namespace

        defvocab Example,
          base_iri: "http://example.com/ex#",
          case_violations: :fail,
          allow_lowercase_resource_terms: true,
          data:
            RDF.Graph.new([
              {~I<http://example.com/ex#Bar>, RDF.type(), RDFS.Resource}
            ]),
          alias: [bar: "Bar"]
      end
    end

    test "terms starting with an underscore are not checked" do
      defmodule NSWithUnderscoreTerms do
        use RDF.Vocabulary.Namespace

        defvocab Example,
          base_iri: "http://example.com/ex#",
          case_violations: :fail,
          data:
            RDF.Graph.new([
              {~I<http://example.com/ex#_Foo>, RDF.type(), RDF.Property},
              {~I<http://example.com/ex#_bar>, RDF.type(), RDFS.Resource}
            ])
      end
    end

    test "auto_fix case violations" do
      alias TestNS.ExampleWithAutoFixedCaseViolations, as: Example

      assert Example.fooTest() == RDF.iri(Example.__base_iri__() <> "FooTest")
      assert Example.barTest() == RDF.iri(Example.__base_iri__() <> "barTest")
      assert RDF.iri(Example.BazTest) == RDF.iri(Example.__base_iri__() <> "bazTest")
      assert RDF.iri(Example.BaazAlias) == RDF.iri(Example.__base_iri__() <> "baazTest")
    end

    test "auto_fix case violations with allow_lowercase_resource_terms: true" do
      alias TestNS.ExampleWithAutoFixedCaseViolationsAllowLowercaseResource, as: Example

      assert Example.fooTest() == RDF.iri(Example.__base_iri__() <> "FooTest")
      assert Example.barTest() == RDF.iri(Example.__base_iri__() <> "barTest")
      assert RDF.iri(Example.BaazAlias) == RDF.iri(Example.__base_iri__() <> "baazTest")
      assert_raise RDF.Namespace.UndefinedTermError, fn -> RDF.iri(Example.BazTest) end
    end

    test "case violation function (inline)" do
      alias TestNS.ExampleWithCustomInlineCaseViolationFunction, as: Example

      assert Example.foo_test() == RDF.iri(Example.__base_iri__() <> "FooTest")
      assert Example.barTest() == RDF.iri(Example.__base_iri__() <> "barTest")
      assert RDF.iri(Example.BazTest) == RDF.iri(Example.__base_iri__() <> "bazTest")

      refute :baazTest in Example.__terms__()
    end

    test "case violation function (external)" do
      alias TestNS.ExampleWithCustomExternalCaseViolationFunction, as: Example

      assert Example.footest() == RDF.iri(Example.__base_iri__() <> "FooTest")
      assert Example.barTest() == RDF.iri(Example.__base_iri__() <> "barTest")
      assert RDF.iri(Example.BAZTEST) == RDF.iri(Example.__base_iri__() <> "bazTest")

      refute :baazTest in Example.__terms__()
    end

    test "case violation function (external; with args)" do
      alias TestNS.ExampleWithCustomExternalCaseViolationFunctionWithArgs, as: Example

      assert Example.footestarg() == RDF.iri(Example.__base_iri__() <> "FooTest")
      assert Example.barTest() == RDF.iri(Example.__base_iri__() <> "barTest")
      assert RDF.iri(Example.BAZTESTarg) == RDF.iri(Example.__base_iri__() <> "bazTest")
      assert RDF.iri(Example.BaazTest) == RDF.iri(Example.__base_iri__() <> "baazTest")
    end

    test "case violation in aliases fail with case violation function" do
      assert_raise RDF.Vocabulary.Namespace.CompileError,
                   ~r<Case violations.*Foo>s,
                   fn ->
                     defmodule NSCaseViolationInAlias do
                       use RDF.Vocabulary.Namespace

                       defvocab ExampleWithCustomCaseViolationFunction,
                         base_iri: "http://example.com/ex#",
                         case_violations: {ExampleCaseViolationHandler, :fix},
                         data:
                           RDF.Graph.new([
                             {~I<http://example.com/ex#FooTest>, RDF.type(), RDF.Property}
                           ]),
                         alias: [Foo: :FooTest]
                     end
                   end
    end
  end

  @compile {:no_warn_undefined,
            RDF.Vocabulary.NamespaceTest.NSTermRestrictionTest.RestrictionByTermList}

  describe "defvocab term restrictions" do
    test "restricting terms from data with a list of filtered and aliased terms" do
      defmodule NSTermRestrictionTest do
        use RDF.Vocabulary.Namespace

        defvocab RestrictionByTermList,
          base_iri: "http://example.com/ex#",
          case_violations: :fail,
          data:
            RDF.Graph.new([
              {~I<http://example.com/ex#Foo>, RDF.type(), RDF.Property},
              {~I<http://example.com/ex#Bar-Bar>, RDF.type(), RDFS.Resource},
              {~I<http://example.com/ex#Baz>, RDF.type(), RDFS.Resource},
              {~I<http://example.com/ex#Baaz>, RDF.type(), RDFS.Resource},
              {~I<http://example.com/ex#qux>, RDF.type(), RDF.Property}
            ]),
          terms: [
            :Baz,
            foo: :Foo,
            Bar: "Bar-Bar"
          ]
      end

      alias NSTermRestrictionTest.RestrictionByTermList
      assert RestrictionByTermList.__terms__() == [:Bar, :Baz, :Foo, :foo]
      assert RestrictionByTermList.foo() == ~I<http://example.com/ex#Foo>
      assert RDF.iri(RestrictionByTermList.Foo) == ~I<http://example.com/ex#Foo>
      assert RDF.iri(RestrictionByTermList.Bar) == ~I<http://example.com/ex#Bar-Bar>
      assert RDF.iri(RestrictionByTermList.Baz) == ~I<http://example.com/ex#Baz>
      assert_raise UndefinedFunctionError, fn -> RestrictionByTermList.qux() end
      assert_raise RDF.Namespace.UndefinedTermError, fn -> RDF.iri(RestrictionByTermList.Baaz) end
    end

    test "when terms are specified which are not in the vocabulary" do
      assert_raise RDF.Vocabulary.Namespace.CompileError,
                   ~r/Unknown terms.*'Baz' is not a term in this vocabulary/s,
                   fn ->
                     defmodule NSTermRestrictionTest do
                       use RDF.Vocabulary.Namespace

                       defvocab RestrictionOfUnknownTerms,
                         base_iri: "http://example.com/ex#",
                         case_violations: :fail,
                         file: "test/data/vocab_ns_example.ttl",
                         terms: ~w[Baz]
                     end
                   end
    end
  end

  test "error report" do
    assert_raise RDF.Vocabulary.Namespace.CompileError,
                 """

                 ================================================================================
                 Errors while compiling vocabulary Elixir.RDF.Vocabulary.NamespaceTest.NSErrorReportTest.ErrorsFromTerms
                 ================================================================================

                 Invalid aliases
                 ---------------

                 - alias 'def' is a reserved term and can't be used as an alias
                 - term 'missing_term' is not a term in this namespace

                 Invalid base URI
                 ----------------

                 - invalid base IRI: "invalid-base-uri"

                 Invalid ignore terms
                 --------------------

                 - 'not_existing' is not a term in this vocabulary namespace

                 Invalid terms
                 -------------

                 The following terms can not be used, because they conflict with reserved Elixir terms:

                 - super

                 You have the following options:

                 - define an alias with the :alias option on defvocab
                 - ignore the resource with the :ignore option on defvocab


                 The following terms contain invalid characters:

                 - invalid-character

                 You have the following options:

                 - if you are in control of the vocabulary, consider renaming the resource
                 - define an alias with the :alias option on defvocab
                 - change the handling of invalid characters with the :invalid_characters option on defvocab
                 - ignore the resource with the :ignore option on defvocab


                 """,
                 fn ->
                   defmodule NSErrorReportTest do
                     use RDF.Vocabulary.Namespace

                     defvocab ErrorsFromTerms,
                       base_iri: "invalid-base-uri",
                       terms: ~w[foo Bar invalid-character super],
                       alias: [def: "foo", dangling_alias: :missing_term],
                       ignore: [:not_existing]
                   end
                 end
  end

  describe "defvocab ignore terms" do
    defmodule NSWithIgnoredTerms do
      use RDF.Vocabulary.Namespace

      defvocab ExampleIgnoredLowercasedTerm,
        base_iri: "http://example.com/",
        data:
          RDF.Graph.new([
            {~I<http://example.com/foo>, RDF.type(), RDF.Property},
            {~I<http://example.com/Bar>, RDF.type(), RDFS.Resource}
          ]),
        ignore: ["foo"]

      defvocab ExampleIgnoredCapitalizedTerm,
        base_iri: "http://example.com/",
        data:
          RDF.Dataset.new([
            {~I<http://example.com/foo>, RDF.type(), RDF.Property},
            {~I<http://example.com/Bar>, RDF.type(), RDFS.Resource,
             ~I<http://example.com/from_dataset#Graph>}
          ]),
        ignore: ~w[Bar]

      defvocab ExampleIgnoredLowercasedTermWithAlias,
        base_iri: "http://example.com/",
        terms: ~w[foo Bar],
        alias: [Foo: "foo"],
        ignore: ~w[foo]a

      defvocab ExampleIgnoredCapitalizedTermWithAlias,
        base_iri: "http://example.com/",
        terms: ~w[foo Bar],
        alias: [bar: "Bar"],
        ignore: ~w[Bar]a

      defvocab ExampleIgnoredNonStrictLowercasedTerm,
        base_iri: "http://example.com/",
        terms: ~w[],
        strict: false,
        ignore: ~w[foo]a

      defvocab ExampleIgnoredNonStrictCapitalizedTerm,
        base_iri: "http://example.com/",
        terms: ~w[],
        strict: false,
        ignore: ~w[Bar]a
    end

    test "resolution of ignored lowercased term on a strict vocab fails" do
      alias NSWithIgnoredTerms.ExampleIgnoredLowercasedTerm
      assert ExampleIgnoredLowercasedTerm.__terms__() == [:Bar]
      assert_raise UndefinedFunctionError, fn -> ExampleIgnoredLowercasedTerm.foo() end
    end

    test "resolution of ignored capitalized term on a strict vocab fails" do
      alias NSWithIgnoredTerms.ExampleIgnoredCapitalizedTerm
      assert ExampleIgnoredCapitalizedTerm.__terms__() == [:foo]

      assert_raise RDF.Namespace.UndefinedTermError, fn ->
        RDF.iri(ExampleIgnoredCapitalizedTerm.Bar)
      end
    end

    test "resolution of ignored lowercased term with alias on a strict vocab fails" do
      alias NSWithIgnoredTerms.ExampleIgnoredLowercasedTermWithAlias
      assert ExampleIgnoredLowercasedTermWithAlias.__terms__() == [:Bar, :Foo]
      assert_raise UndefinedFunctionError, fn -> ExampleIgnoredLowercasedTermWithAlias.foo() end
      assert RDF.iri(ExampleIgnoredLowercasedTermWithAlias.Foo) == ~I<http://example.com/foo>
    end

    test "resolution of ignored capitalized term with alias on a strict vocab fails" do
      alias NSWithIgnoredTerms.ExampleIgnoredCapitalizedTermWithAlias
      assert ExampleIgnoredCapitalizedTermWithAlias.__terms__() == [:bar, :foo]

      assert_raise RDF.Namespace.UndefinedTermError, fn ->
        RDF.iri(ExampleIgnoredCapitalizedTermWithAlias.Bar)
      end

      assert RDF.iri(ExampleIgnoredCapitalizedTermWithAlias.bar()) == ~I<http://example.com/Bar>
    end

    test "resolution of ignored lowercased term on a non-strict vocab fails" do
      alias NSWithIgnoredTerms.ExampleIgnoredNonStrictLowercasedTerm

      assert_raise UndefinedFunctionError, fn ->
        ExampleIgnoredNonStrictLowercasedTerm.foo()
      end
    end

    test "resolution of ignored capitalized term on a non-strict vocab fails" do
      alias NSWithIgnoredTerms.ExampleIgnoredNonStrictCapitalizedTerm

      assert_raise RDF.Namespace.UndefinedTermError, fn ->
        RDF.iri(ExampleIgnoredNonStrictCapitalizedTerm.Bar)
      end
    end

    test "ignored terms with invalid characters do not raise anything" do
      defmodule IgnoredTermWithInvalidCharacters do
        use RDF.Vocabulary.Namespace

        defvocab Example,
          base_iri: "http://example.com/",
          terms: ~w[foo-bar],
          ignore: ~w[foo-bar]a
      end
    end

    test "ignored terms with case violations do not raise anything" do
      defmodule IgnoredTermWithCaseViolations do
        use RDF.Vocabulary.Namespace

        defvocab Example,
          base_iri: "http://example.com/",
          data:
            RDF.Dataset.new([
              {~I<http://example.com/Foo>, RDF.type(), RDF.Property},
              {~I<http://example.com/bar>, RDF.type(), RDFS.Resource,
               ~I<http://example.com/from_dataset#Graph>}
            ]),
          case_violations: :fail,
          ignore: ~w[Foo bar]a
      end
    end

    test "ignoring aliases raises an error" do
      assert_raise RDF.Vocabulary.Namespace.CompileError,
                   ~r/Invalid ignore terms.*'bar' is not a term/s,
                   fn ->
                     defmodule IgnoredAliasTest1 do
                       use RDF.Vocabulary.Namespace

                       defvocab ExampleIgnoredLowercasedAlias,
                         base_iri: "http://example.com/",
                         terms: ~w[foo Bar],
                         alias: [bar: "Bar"],
                         ignore: ~w[bar]a
                     end
                   end
    end
  end

  test "__base_iri__ returns the base_iri" do
    alias TestNS.ExampleFromGraph, as: HashVocab
    alias TestNS.ExampleFromNTriplesFile, as: SlashVocab
    alias TestNS.ExampleWithBaseFromModuleAttribute, as: BaseFromModuleAttribute
    alias TestNS.ExampleWithBaseFromIRI, as: BaseFromIRI

    assert HashVocab.__base_iri__() == "http://example.com/from_graph#"
    assert SlashVocab.__base_iri__() == "http://example.com/from_ntriples/"
    assert BaseFromModuleAttribute.__base_iri__() == "http://example.com/"
    assert BaseFromIRI.__base_iri__() == "http://example.com/"
  end

  test "__iris__ returns all IRIs of the vocabulary" do
    alias TestNS.ExampleFromGraph, as: Example1
    assert length(Example1.__iris__()) == 2
    assert RDF.iri(Example1.foo()) in Example1.__iris__()
    assert RDF.iri(Example1.Bar) in Example1.__iris__()

    alias TestNS.ExampleFromNTriplesFile, as: Example2
    assert length(Example2.__iris__()) == 2
    assert RDF.iri(Example2.foo()) in Example2.__iris__()
    assert RDF.iri(Example2.Bar) in Example2.__iris__()

    alias TestNS.ExampleFromNQuadsFile, as: Example3
    assert length(Example3.__iris__()) == 2
    assert RDF.iri(Example3.foo()) in Example3.__iris__()
    assert RDF.iri(Example3.Bar) in Example3.__iris__()

    alias TestNS.ExampleFromTurtleFile, as: Example4
    assert length(Example4.__iris__()) == 2
    assert RDF.iri(Example4.foo()) in Example4.__iris__()
    assert RDF.iri(Example4.Bar) in Example4.__iris__()

    alias TestNS.StrictExampleFromAliasedTerms, as: Example4
    assert length(Example4.__iris__()) == 4
    assert RDF.iri(Example4.Term1) in Example4.__iris__()
    assert RDF.iri(Example4.term2()) in Example4.__iris__()
    assert RDF.iri(Example4.Term3) in Example4.__iris__()
    assert RDF.iri(Example4.term4()) in Example4.__iris__()
  end

  describe "__terms__" do
    alias TestNS.{ExampleFromGraph, ExampleFromDataset, StrictExampleFromAliasedTerms}

    test "includes all defined terms" do
      assert length(ExampleFromGraph.__terms__()) == 2

      for term <- ~w[foo Bar]a do
        assert term in ExampleFromGraph.__terms__()
      end

      assert length(ExampleFromDataset.__terms__()) == 2

      for term <- ~w[foo Bar]a do
        assert term in ExampleFromDataset.__terms__()
      end
    end

    test "includes aliases" do
      assert length(StrictExampleFromAliasedTerms.__terms__()) == 6

      for term <- ~w[term1 Term1 term2 Term2 Term3 term4]a do
        assert term in StrictExampleFromAliasedTerms.__terms__()
      end
    end
  end

  describe "__file__" do
    test "for manually defined vocabulary namespaces" do
      refute RDF.NS.XSD.__file__()
      refute TestNS.EX.__file__()
      refute TestNS.ExampleFromGraph.__file__()
    end

    test "for vocabulary namespaces from files" do
      assert RDF.NS.RDFS.__file__() == expected_vocab_path("rdfs.ttl")
    end

    test "for vocabulary namespaces created in tests" do
      refute TestNS.ExampleFromNTriplesFile.__file__()
    end

    def expected_vocab_path(file) do
      Path.join([:code.priv_dir(:rdf), "vocabs", file])
    end
  end

  test "resolving an unqualified term raises an error" do
    assert_raise RDF.Namespace.UndefinedTermError, fn -> RDF.iri(:foo) end
  end

  test "resolving an non-RDF.Namespace module" do
    assert_raise RDF.Namespace.UndefinedTermError, fn -> RDF.iri(ExUnit.Test) end
  end

  test "resolving an top-level module" do
    assert_raise RDF.Namespace.UndefinedTermError,
                 "ExUnit is not a RDF.Namespace; top-level modules can't be RDF.Namespaces",
                 fn -> RDF.iri(ExUnit) end
  end

  test "resolving an non-existing RDF.Namespace module" do
    assert_raise RDF.Namespace.UndefinedTermError, fn -> RDF.iri(NonExisting.Test) end
  end

  describe "term resolution in a strict vocab namespace" do
    alias TestNS.{
      EXS,
      ExampleFromGraph,
      ExampleFromNTriplesFile,
      StrictExampleFromTerms,
      ExampleWithBaseFromIRI,
      ExampleWithBaseFromModuleAttribute
    }

    test "undefined terms" do
      assert_raise UndefinedFunctionError, fn ->
        ExampleFromGraph.undefined()
      end

      assert_raise UndefinedFunctionError, fn ->
        ExampleFromNTriplesFile.undefined()
      end

      assert_raise UndefinedFunctionError, fn ->
        StrictExampleFromTerms.undefined()
      end

      assert {:error, %RDF.Namespace.UndefinedTermError{}} =
               RDF.Namespace.resolve_term(TestNS.ExampleFromGraph.Undefined)

      assert {:error, %RDF.Namespace.UndefinedTermError{}} =
               RDF.Namespace.resolve_term(ExampleFromNTriplesFile.Undefined)

      assert {:error, %RDF.Namespace.UndefinedTermError{}} =
               RDF.Namespace.resolve_term(StrictExampleFromTerms.Undefined)

      assert_raise RDF.Namespace.UndefinedTermError, fn ->
        RDF.Namespace.resolve_term!(TestNS.ExampleFromGraph.Undefined)
      end

      assert_raise RDF.Namespace.UndefinedTermError, fn ->
        RDF.Namespace.resolve_term!(ExampleFromNTriplesFile.Undefined)
      end

      assert_raise RDF.Namespace.UndefinedTermError, fn ->
        RDF.Namespace.resolve_term!(StrictExampleFromTerms.Undefined)
      end
    end

    test "lowercased terms" do
      assert EXS.foo() == ~I<http://example.com/strict#foo>
      assert ExampleFromGraph.foo() == ~I<http://example.com/from_graph#foo>
      assert RDF.iri(ExampleFromGraph.foo()) == ~I<http://example.com/from_graph#foo>

      assert ExampleFromNTriplesFile.foo() == ~I<http://example.com/from_ntriples/foo>
      assert RDF.iri(ExampleFromNTriplesFile.foo()) == ~I<http://example.com/from_ntriples/foo>

      assert StrictExampleFromTerms.foo() == ~I<http://example.com/strict_from_terms#foo>
      assert RDF.iri(StrictExampleFromTerms.foo()) == ~I<http://example.com/strict_from_terms#foo>

      assert ExampleWithBaseFromIRI.foo() == ~I<http://example.com/foo>
      assert ExampleWithBaseFromModuleAttribute.foo() == ~I<http://example.com/foo>
    end

    test "capitalized terms" do
      assert RDF.iri(ExampleFromGraph.Bar) == ~I<http://example.com/from_graph#Bar>
      assert RDF.iri(ExampleFromNTriplesFile.Bar) == ~I<http://example.com/from_ntriples/Bar>
      assert RDF.iri(StrictExampleFromTerms.Bar) == ~I<http://example.com/strict_from_terms#Bar>
      assert RDF.iri(ExampleWithBaseFromIRI.Bar) == ~I<http://example.com/Bar>
      assert RDF.iri(ExampleWithBaseFromModuleAttribute.Bar) == ~I<http://example.com/Bar>
    end

    test "terms starting with an underscore" do
      defmodule NSwithUnderscoreTerms do
        use RDF.Vocabulary.Namespace

        defvocab Example,
          base_iri: "http://example.com/ex#",
          terms: ~w[_foo]
      end

      alias NSwithUnderscoreTerms.Example
      alias TestNS.EX

      assert Example._foo() == ~I<http://example.com/ex#_foo>
      assert Example._foo(EX.S, 1) == RDF.description(EX.S, init: {EX.S, Example._foo(), 1})
    end
  end

  describe "term resolution in a non-strict vocab namespace" do
    alias TestNS.NonStrictExampleFromTerms

    test "undefined lowercased terms" do
      assert NonStrictExampleFromTerms.random() ==
               ~I<http://example.com/non_strict_from_terms#random>
    end

    test "undefined capitalized terms" do
      assert RDF.iri(NonStrictExampleFromTerms.Random) ==
               ~I<http://example.com/non_strict_from_terms#Random>
    end

    test "undefined terms starting with an underscore" do
      assert NonStrictExampleFromTerms._random() ==
               ~I<http://example.com/non_strict_from_terms#_random>
    end

    test "defined lowercase terms" do
      assert NonStrictExampleFromTerms.foo() == ~I<http://example.com/non_strict_from_terms#foo>
    end

    test "defined capitalized terms" do
      assert RDF.iri(NonStrictExampleFromTerms.Bar) ==
               ~I<http://example.com/non_strict_from_terms#Bar>
    end
  end

  describe "term resolution of aliases on a strict vocabulary" do
    alias TestNS.StrictExampleFromAliasedTerms, as: Ex1
    alias TestNS.StrictExampleFromImplicitAliasedTerms, as: Ex2

    test "the alias resolves to the correct IRI" do
      assert RDF.iri(Ex1.Term1) == ~I<http://example.com/strict_from_aliased_terms#term1>
      assert RDF.iri(Ex1.term2()) == ~I<http://example.com/strict_from_aliased_terms#Term2>
      assert RDF.iri(Ex1.Term3) == ~I<http://example.com/strict_from_aliased_terms#Term-3>
      assert RDF.iri(Ex1.term4()) == ~I<http://example.com/strict_from_aliased_terms#term-4>

      assert RDF.iri(Ex2.Term1) == ~I<http://example.com/strict_from_aliased_terms#term1>
      assert RDF.iri(Ex2.term2()) == ~I<http://example.com/strict_from_aliased_terms#Term2>
      assert RDF.iri(Ex2.Term3) == ~I<http://example.com/strict_from_aliased_terms#Term-3>
      assert RDF.iri(Ex2.term4()) == ~I<http://example.com/strict_from_aliased_terms#term-4>
      assert RDF.iri(Ex2.term5()) == ~I<http://example.com/strict_from_aliased_terms#term5>
      assert RDF.iri(Ex2.term6()) == ~I<http://example.com/strict_from_aliased_terms#term6>
    end

    test "the old term remains resolvable" do
      assert RDF.iri(Ex1.term1()) == ~I<http://example.com/strict_from_aliased_terms#term1>
      assert RDF.iri(Ex1.Term2) == ~I<http://example.com/strict_from_aliased_terms#Term2>

      assert RDF.iri(Ex2.term1()) == ~I<http://example.com/strict_from_aliased_terms#term1>
      assert RDF.iri(Ex2.Term2) == ~I<http://example.com/strict_from_aliased_terms#Term2>
    end

    test "defining multiple aliases for a term" do
      alias TestNS.ExampleWithSynonymAliases, as: Ex1
      alias TestNS.ExampleWithSynonymImplicitAliases, as: Ex2

      assert Ex1.foo() == Ex1.baz()
      assert RDF.iri(Ex1.foo()) == RDF.iri(Ex1.baz())

      assert Ex2.foo() == Ex2.baz()
      assert RDF.iri(Ex2.foo()) == RDF.iri(Ex2.baz())
    end
  end

  describe "term resolution of aliases on a non-strict vocabulary" do
    alias TestNS.NonStrictExampleFromAliasedTerms, as: Example

    test "the alias resolves to the correct IRI" do
      assert RDF.iri(Example.Term1) == ~I<http://example.com/non_strict_from_aliased_terms#term1>

      assert RDF.iri(Example.term2()) ==
               ~I<http://example.com/non_strict_from_aliased_terms#Term2>

      assert RDF.iri(Example.Term3) == ~I<http://example.com/non_strict_from_aliased_terms#Term-3>

      assert RDF.iri(Example.term4()) ==
               ~I<http://example.com/non_strict_from_aliased_terms#term-4>
    end

    test "the old term remains resolvable" do
      assert RDF.iri(Example.term1()) ==
               ~I<http://example.com/non_strict_from_aliased_terms#term1>

      assert RDF.iri(Example.Term2) == ~I<http://example.com/non_strict_from_aliased_terms#Term2>
    end
  end

  describe "description DSL" do
    alias TestNS.{EX, EXS}

    test "one statement with a strict property term" do
      assert EXS.foo(EX.S, EX.O) == Description.new(EX.S, init: {EXS.foo(), EX.O})
    end

    test "description accessor with strict property term" do
      assert Description.new(EX.S, init: {EXS.foo(), EX.O})
             |> EXS.foo() == [RDF.iri(EX.O)]
    end

    test "description accessor with non-strict property term" do
      assert Description.new(EX.S, init: {EX.foo(), EX.O})
             |> EX.foo() == [RDF.iri(EX.O)]
    end

    test "multiple statements with strict property terms and one object" do
      description =
        EX.S
        |> EXS.foo(EX.O1)
        |> EXS.bar(EX.O2)

      assert description ==
               Description.new(EX.S, init: [{EXS.foo(), EX.O1}, {EXS.bar(), EX.O2}])
    end

    test "multiple statements with strict property terms and multiple objects" do
      description =
        EX.S
        |> EXS.foo([EX.O1, EX.O2])
        |> EXS.bar([EX.O3, EX.O4])

      assert description ==
               Description.new(EX.S,
                 init: [
                   {EXS.foo(), EX.O1},
                   {EXS.foo(), EX.O2},
                   {EXS.bar(), EX.O3},
                   {EXS.bar(), EX.O4}
                 ]
               )
    end

    test "one statement with a non-strict property term" do
      assert EX.p(EX.S, EX.O) == Description.new(EX.S, init: {EX.p(), EX.O})
    end

    test "multiple statements with non-strict property terms and one object" do
      description =
        EX.S
        |> EX.p1(EX.O1)
        |> EX.p2(EX.O2)

      assert description ==
               Description.new(EX.S, init: [{EX.p1(), EX.O1}, {EX.p2(), EX.O2}])
    end

    test "multiple statements with non-strict property terms and multiple objects in a list" do
      description =
        EX.S
        |> EX.p1([EX.O1, EX.O2])
        |> EX.p2([EX.O3, EX.O4])

      assert description ==
               Description.new(EX.S,
                 init: [
                   {EX.p1(), EX.O1},
                   {EX.p1(), EX.O2},
                   {EX.p2(), EX.O3},
                   {EX.p2(), EX.O4}
                 ]
               )
    end

    test "multiple statements with non-strict property terms and multiple objects as arguments" do
      description =
        EX.S
        |> EX.p1(EX.O1, EX.O2)
        |> EX.p2(EX.O3, EX.O4)

      assert description ==
               Description.new(EX.S,
                 init: [
                   {EX.p1(), EX.O1},
                   {EX.p1(), EX.O2},
                   {EX.p2(), EX.O3},
                   {EX.p2(), EX.O4}
                 ]
               )
    end

    test "empty object list" do
      assert EX.S |> EX.p1([]) == Description.new(EX.S)
    end
  end

  describe "vocabulary_namespace?/1" do
    test "with RDF.Vocabulary.Namespace modules" do
      alias TestNS.ExampleWithBaseFromIRI, as: Example

      assert RDF.Vocabulary.Namespace.vocabulary_namespace?(TestNS.EX) == true
      assert RDF.Vocabulary.Namespace.vocabulary_namespace?(Example) == true
      assert RDF.Vocabulary.Namespace.vocabulary_namespace?(RDF.NS.RDF) == true
      assert RDF.Vocabulary.Namespace.vocabulary_namespace?(RDF.NS.RDFS) == true
      assert RDF.Vocabulary.Namespace.vocabulary_namespace?(RDF.NS.OWL) == true
      assert RDF.Vocabulary.Namespace.vocabulary_namespace?(RDF.NS.XSD) == true
    end

    test "with the top-level RDF module" do
      assert RDF.Vocabulary.Namespace.vocabulary_namespace?(RDF) == true
    end

    test "with RDF.Namespace modules" do
      assert RDF.Vocabulary.Namespace.vocabulary_namespace?(RDF.TestNamespaces.SimpleNS) == false
    end

    test "with non-RDF.Vocabulary.Namespace modules" do
      assert RDF.Vocabulary.Namespace.vocabulary_namespace?(Enum) == false
      assert RDF.Vocabulary.Namespace.vocabulary_namespace?(__MODULE__) == false
    end
  end

  describe "term resolution on the top-level RDF module" do
    test "capitalized terms" do
      assert RDF.iri(RDF.Property) == ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#Property>
      assert RDF.iri(RDF.Statement) == ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#Statement>
      assert RDF.iri(RDF.List) == ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#List>
      assert RDF.iri(RDF.Nil) == ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#nil>
      assert RDF.iri(RDF.Seq) == ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#Seq>
      assert RDF.iri(RDF.Bag) == ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#Bag>
      assert RDF.iri(RDF.Alt) == ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#Alt>
      assert RDF.iri(RDF.LangString) == ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#langString>

      assert RDF.iri(RDF.PlainLiteral) ==
               ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#PlainLiteral>

      assert RDF.iri(RDF.XMLLiteral) == ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral>
      assert RDF.iri(RDF.HTML) == ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#HTML>
      assert RDF.iri(RDF.Property) == ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#Property>
    end

    test "lowercase terms" do
      assert RDF.type() == ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>
      assert RDF.subject() == ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#subject>
      assert RDF.predicate() == ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#predicate>
      assert RDF.object() == ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#object>
      assert RDF.first() == ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#first>
      assert RDF.rest() == ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#rest>
      assert RDF.value() == ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#value>

      assert RDF.langString() == ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#langString>
      assert RDF.nil() == ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#nil>
    end

    test "description builder" do
      alias TestNS.EX
      assert RDF.type(EX.S, 42) == RDF.NS.RDF.type(EX.S, 42)
      assert RDF.subject(EX.S, 42) == RDF.NS.RDF.subject(EX.S, 42)
      assert RDF.predicate(EX.S, 42) == RDF.NS.RDF.predicate(EX.S, 42)
      assert RDF.object(EX.S, 42) == RDF.NS.RDF.object(EX.S, 42)
      assert RDF.first(EX.S, 42) == RDF.NS.RDF.first(EX.S, 42)
      assert RDF.rest(EX.S, [1, 2, 3, 4, 5, 6]) == RDF.NS.RDF.rest(EX.S, [1, 2, 3, 4, 5, 6])

      assert RDF.value(EX.S, [1, 2, 3, 4, 5, 6, 7]) ==
               RDF.NS.RDF.value(EX.S, [1, 2, 3, 4, 5, 6, 7])
    end

    test "description accessor" do
      alias TestNS.EX

      description =
        EX.S
        |> RDF.type(EX.Class)
        |> RDF.subject(42)
        |> RDF.predicate(42)
        |> RDF.object(42)
        |> RDF.first(42)
        |> RDF.rest([1, 2, 3, 4, 5, 6])

      assert description |> RDF.type() == description |> RDF.NS.RDF.type()
      assert description |> RDF.subject() == description |> RDF.NS.RDF.subject()
      assert description |> RDF.predicate() == description |> RDF.NS.RDF.predicate()
      assert description |> RDF.object() == description |> RDF.NS.RDF.object()
      assert description |> RDF.first() == description |> RDF.NS.RDF.first()
      assert description |> RDF.rest() == description |> RDF.NS.RDF.rest()
      assert description |> RDF.value() == description |> RDF.NS.RDF.value()
    end
  end
end
