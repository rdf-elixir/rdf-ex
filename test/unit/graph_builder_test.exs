defmodule RDF.Graph.BuilderTest do
  use ExUnit.Case

  require RDF.Graph

  doctest RDF.Graph.Builder

  alias RDF.Graph.Builder

  import ExUnit.CaptureLog

  defmodule TestNS do
    use RDF.Vocabulary.Namespace
    defvocab EX, base_iri: "http://example.com/", terms: [], strict: false
    defvocab Custom, base_iri: "http://custom.com/foo#", terms: [], strict: false
    defvocab ImportTest, base_iri: "http://import.com/bar#", terms: [:foo, :Bar]
  end

  @compile {:no_warn_undefined, __MODULE__.TestNS.EX}
  @compile {:no_warn_undefined, __MODULE__.TestNS.Custom}

  alias __MODULE__.TestNS.EX
  alias RDF.NS

  defmodule UseTest do
    defmacro __using__(_opts) do
      quote do
        {EX.This, EX.ShouldNotAppearIn, EX.Graph}
      end
    end
  end

  test "single statement" do
    graph =
      RDF.Graph.build do
        EX.S |> EX.p(EX.O)
      end

    assert graph == RDF.graph(EX.S |> EX.p(EX.O))
  end

  test "multiple statements" do
    graph =
      RDF.Graph.build do
        EX.S1 |> EX.p1(EX.O1)
        EX.S2 |> EX.p2(EX.O2)
      end

    assert graph ==
             RDF.graph([
               EX.S1 |> EX.p1(EX.O1),
               EX.S2 |> EX.p2(EX.O2)
             ])
  end

  test "different kinds of description forms" do
    graph =
      RDF.Graph.build do
        EX.S1
        |> EX.p11(EX.O11, EX.O12)
        |> EX.p12(EX.O11, EX.O12)

        EX.S2
        |> EX.p2([EX.O21, EX.O22])

        EX.p3(EX.S3, EX.O3)
      end

    assert graph ==
             RDF.graph([
               EX.S1 |> EX.p11(EX.O11, EX.O12),
               EX.S1 |> EX.p12(EX.O11, EX.O12),
               EX.S2 |> EX.p2([EX.O21, EX.O22]),
               EX.p3(EX.S3, EX.O3)
             ])
  end

  test "triples given as tuples" do
    graph =
      RDF.Graph.build do
        EX.S1 |> EX.p1(EX.O1)

        {EX.S2, EX.p2(), EX.O2}
      end

    assert graph ==
             RDF.graph([
               EX.S1 |> EX.p1(EX.O1),
               EX.S2 |> EX.p2(EX.O2)
             ])
  end

  test "nested statements" do
    graph =
      RDF.Graph.build do
        [
          EX.S1 |> EX.p1([EX.O11, EX.O12]),
          [
            {EX.S2, EX.p2(), EX.O2},
            {EX.S31, EX.p31(), EX.O31}
          ],
          {EX.S32, EX.p32(), EX.O32}
        ]
      end

    assert graph ==
             RDF.graph([
               EX.S1 |> EX.p1([EX.O11, EX.O12]),
               EX.S2 |> EX.p2(EX.O2),
               {EX.S31, EX.p31(), EX.O31},
               {EX.S32, EX.p32(), EX.O32}
             ])
  end

  test "a functions as shortcut for rdf:type" do
    graph =
      RDF.Graph.build do
        EX.S1 |> a(EX.Class1)
        EX.S2 |> a(EX.Class1, EX.Class1)
        EX.S3 |> a(EX.Class1, EX.Class2, EX.Class3)
        EX.S4 |> a(EX.Class1, EX.Class2, EX.Class3)
        EX.S5 |> a(EX.Class1, EX.Class2, EX.Class3, EX.Class4)
        EX.S5 |> a(EX.Class1, EX.Class2, EX.Class3, EX.Class4, EX.Class5)
        {EX.S6, a(), EX.O2}
      end

    assert graph ==
             RDF.graph([
               EX.S1 |> RDF.type(EX.Class1),
               EX.S2 |> RDF.type(EX.Class1, EX.Class1),
               EX.S3 |> RDF.type(EX.Class1, EX.Class2, EX.Class3),
               EX.S4 |> RDF.type(EX.Class1, EX.Class2, EX.Class3),
               EX.S5 |> RDF.type(EX.Class1, EX.Class2, EX.Class3, EX.Class4),
               EX.S5 |> RDF.type(EX.Class1, EX.Class2, EX.Class3, EX.Class4, EX.Class5),
               {EX.S6, RDF.type(), EX.O2}
             ])
  end

  test "non-RDF interpretable data is ignored" do
    assert_raise Builder.Error, "invalid RDF data: 42", fn ->
      RDF.Graph.build do
        EX.S |> EX.p(EX.O)
        42
      end
    end

    assert_raise Builder.Error, "invalid RDF data: \"foo\"", fn ->
      RDF.Graph.build do
        EX.S |> EX.p(EX.O)
        "foo"
      end
    end

    assert_raise Builder.Error, "invalid RDF data: {:ok, \"foo\"}", fn ->
      RDF.Graph.build do
        EX.S |> EX.p(EX.O)
        {:ok, "foo"}
      end
    end
  end

  test "variable assignments" do
    graph =
      RDF.Graph.build do
        EX.S1 |> EX.p1(EX.O1)
        literal = "foo"
        EX.S2 |> EX.p2(literal)
      end

    assert graph ==
             RDF.graph([
               EX.S1 |> EX.p1(EX.O1),
               EX.S2 |> EX.p2("foo")
             ])
  end

  test "function applications" do
    graph =
      RDF.Graph.build do
        Enum.map(1..3, &{EX.S, EX.p(), &1})

        Enum.map(1..2, fn i ->
          RDF.iri("http://example.com/foo#{i}")
          |> EX.bar(RDF.bnode("baz#{i}"))
        end)
      end

    assert graph ==
             RDF.graph([
               {EX.S, EX.p(), 1},
               {EX.S, EX.p(), 2},
               {EX.S, EX.p(), 3},
               {RDF.iri("http://example.com/foo1"), EX.bar(), RDF.bnode("baz1")},
               {RDF.iri("http://example.com/foo2"), EX.bar(), RDF.bnode("baz2")}
             ])
  end

  test "conditionals" do
    graph =
      RDF.Graph.build do
        foo = false

        cond do
          true -> EX.S1 |> EX.p1(EX.O1)
        end

        if foo do
          EX.S2 |> EX.p2(EX.O2)
        end
      end

    assert graph == RDF.graph([EX.S1 |> EX.p1(EX.O1)])
  end

  test "comprehensions" do
    graph =
      RDF.Graph.build do
        range = 1..3

        for i <- range do
          EX.S |> EX.p(i)
        end
      end

    assert graph ==
             RDF.graph([
               {EX.S, EX.p(), 1},
               {EX.S, EX.p(), 2},
               {EX.S, EX.p(), 3}
             ])
  end

  test "RDF.Sigils is imported" do
    # we're wrapping this in a function to isolate the import
    graph =
      (fn ->
         RDF.Graph.build do
           ~I"http://test/iri" |> EX.p(~B"foo")
         end
       end).()

    assert graph == RDF.graph(RDF.iri("http://test/iri") |> EX.p(RDF.bnode("foo")))
  end

  test "RDF.XSD is aliased" do
    # we're wrapping this in a function to isolate the alias
    graph =
      (fn ->
         RDF.Graph.build do
           EX.S |> EX.p(XSD.byte(42))
         end
       end).()

    assert graph == RDF.graph(EX.S |> EX.p(RDF.XSD.byte(42)))
  end

  test "default aliases" do
    # we're wrapping this in a function to isolate the alias
    graph =
      (fn ->
         RDF.Graph.build do
           OWL.Class |> RDFS.subClassOf(RDFS.Class)
         end
       end).()

    assert graph == RDF.graph(NS.OWL.Class |> NS.RDFS.subClassOf(NS.RDFS.Class))
  end

  test "alias" do
    # we're wrapping this in a function to isolate the alias
    graph =
      (fn ->
         RDF.Graph.build do
           alias TestNS.Custom
           #          alias RDF.Graph.BuilderTest.TestNS.Custom
           Custom.S |> Custom.p(Custom.O)
         end
       end).()

    assert graph == RDF.graph(TestNS.Custom.S |> TestNS.Custom.p(TestNS.Custom.O))
  end

  test "import" do
    # we're wrapping this in a function to isolate the import
    graph =
      (fn ->
         RDF.Graph.build do
           import RDF.Graph.BuilderTest.TestNS.ImportTest
           EX.S |> foo(RDF.Graph.BuilderTest.TestNS.ImportTest.Bar)
         end
       end).()

    assert graph == RDF.graph(EX.S |> TestNS.ImportTest.foo(TestNS.ImportTest.Bar))
  end

  test "require" do
    {graph, log} =
      with_log(fn ->
        RDF.Graph.build do
          require Logger
          Logger.info("logged successfully")
          EX.S |> EX.p(EX.O)
        end
      end)

    assert graph == RDF.graph(EX.S |> EX.p(EX.O))
    assert log =~ "logged successfully"
  end

  test "use" do
    graph =
      RDF.Graph.build do
        use UseTest
        EX.S |> EX.p(EX.O)
      end

    assert graph == RDF.graph(EX.S |> EX.p(EX.O))
  end

  describe "@prefix" do
    test "for vocabulary namespace with explicit prefix" do
      # we're wrapping this in a function to isolate the alias
      graph =
        (fn ->
           RDF.Graph.build do
             # TODO: the following leads to a (RDF.Namespace.UndefinedTermError) Elixir.TestNS is not a RDF.Namespace
             # @prefix custom: TestNS.Custom
             @prefix cust: RDF.Graph.BuilderTest.TestNS.Custom

             Custom.S |> Custom.p(Custom.O)
           end
         end).()

      assert graph ==
               RDF.graph(TestNS.Custom.S |> TestNS.Custom.p(TestNS.Custom.O),
                 prefixes: RDF.default_prefixes(cust: TestNS.Custom)
               )
    end

    test "for vocabulary namespace with auto-generated prefix" do
      # we're wrapping this in a function to isolate the alias
      graph =
        (fn ->
           RDF.Graph.build do
             # TODO: the following leads to a (RDF.Namespace.UndefinedTermError) Elixir.TestNS is not a RDF.Namespace
             # @prefix custom: TestNS.Custom
             @prefix RDF.Graph.BuilderTest.TestNS.Custom

             Custom.S |> Custom.p(Custom.O)
           end
         end).()

      assert graph ==
               RDF.graph(TestNS.Custom.S |> TestNS.Custom.p(TestNS.Custom.O),
                 prefixes: RDF.default_prefixes(custom: TestNS.Custom)
               )
    end

    test "merge with prefixes opt" do
      # we're wrapping this in a function to isolate the alias
      graph =
        (fn ->
           RDF.Graph.build prefixes: [custom: EX] do
             # TODO: the following leads to a (RDF.Namespace.UndefinedTermError) Elixir.TestNS is not a RDF.Namespace
             # @prefix custom: TestNS.Custom
             @prefix custom: RDF.Graph.BuilderTest.TestNS.Custom

             Custom.S |> Custom.p(Custom.O)
           end
         end).()

      assert graph ==
               RDF.graph(TestNS.Custom.S |> TestNS.Custom.p(TestNS.Custom.O),
                 prefixes: [custom: TestNS.Custom]
               )
    end
  end

  describe "@base" do
    test "with vocabulary namespace" do
      # we're wrapping this in a function to isolate the alias
      graph =
        (fn ->
           RDF.Graph.build do
             # TODO: the following leads to a (RDF.Namespace.UndefinedTermError) Elixir.TestNS is not a RDF.Namespace
             # @prefix custom: TestNS.Custom
             @base RDF.Graph.BuilderTest.TestNS.Custom

             Custom.S |> Custom.p(Custom.O)
           end
         end).()

      assert graph ==
               RDF.graph(TestNS.Custom.S |> TestNS.Custom.p(TestNS.Custom.O),
                 base_iri: TestNS.Custom
               )
    end

    test "with RDF.IRI" do
      graph =
        RDF.Graph.build do
          @base ~I<http://example.com/base>

          EX.S |> EX.p(EX.O)
        end

      assert graph == RDF.graph(EX.S |> EX.p(EX.O), base_iri: "http://example.com/base")
    end

    test "with URI as string" do
      graph =
        RDF.Graph.build do
          @base "http://example.com/base"

          EX.S |> EX.p(EX.O)
        end

      assert graph == RDF.graph(EX.S |> EX.p(EX.O), base_iri: "http://example.com/base")
    end

    test "with URI from variable" do
      graph =
        RDF.Graph.build do
          foo = "http://example.com/base"
          @base foo

          EX.S |> EX.p(EX.O)
        end

      assert graph == RDF.graph(EX.S |> EX.p(EX.O), base_iri: "http://example.com/base")
    end

    test "conflict with base_iri opt" do
      graph =
        RDF.Graph.build base_iri: "http://example.com/old" do
          @base "http://example.com/base"

          EX.S |> EX.p(EX.O)
        end

      assert graph == RDF.graph(EX.S |> EX.p(EX.O), base_iri: "http://example.com/base")
    end
  end

  test "opts" do
    initial = {EX.S, EX.p(), "init"}

    opts = [
      name: EX.Graph,
      base_iri: "http://base_iri/",
      prefixes: [ex: EX],
      init: initial
    ]

    graph =
      RDF.Graph.build opts do
        EX.S |> EX.p(EX.O)
      end

    assert graph == RDF.graph(EX.S |> EX.p(EX.O, "init"), opts)
  end
end
