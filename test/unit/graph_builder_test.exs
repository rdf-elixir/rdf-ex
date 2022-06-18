defmodule RDF.Graph.BuilderTest do
  use ExUnit.Case

  require RDF.Graph

  doctest RDF.Graph.Builder

  alias RDF.Graph.Builder

  import ExUnit.CaptureLog

  defmodule TestNS do
    use RDF.Vocabulary.Namespace
    defvocab EX, base_iri: "http://example.com/", terms: [], strict: false
    defvocab Custom, base_iri: "http://custom.com/foo/", terms: [], strict: false
    defvocab ImportTest, base_iri: "http://import.com/bar#", terms: [:foo, :Bar]
  end

  @compile {:no_warn_undefined, __MODULE__.TestNS.EX}
  @compile {:no_warn_undefined, __MODULE__.TestNS.Custom}
  @compile {:no_warn_undefined, RDF.Test.Case.EX}

  alias TestNS.EX
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

  test "triples given as maps" do
    graph =
      RDF.Graph.build do
        %{
          EX.S => %{
            EX.p1() => EX.O1,
            EX.p2() => [EX.O2, EX.O3]
          }
        }
      end

    assert graph ==
             RDF.graph([
               EX.S
               |> EX.p1(EX.O1)
               |> EX.p2(EX.O2, EX.O3)
             ])
  end

  test "triples given as nested list" do
    graph =
      RDF.Graph.build do
        [
          {EX.S,
           [
             {EX.p1(), EX.O1},
             {EX.p2(), [EX.O2, EX.O3]}
           ]}
        ]
      end

    assert graph ==
             RDF.graph([
               EX.S
               |> EX.p1(EX.O1)
               |> EX.p2(EX.O2, EX.O3)
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
  end

  describe "variable assignments" do
    test "assignments on the outer level" do
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

    test "including RDF data to assigned variables" do
      graph =
        RDF.Graph.build do
          triple = EX.S |> EX.p(EX.O)
          triple
        end

      assert graph == RDF.graph([EX.S |> EX.p(EX.O)])
    end

    test "assignments in blocks" do
      graph =
        RDF.Graph.build do
          literal = "foo"

          if false do
            literal = "bar"
            EX.S2 |> EX.p2(literal)
          end

          EX.S |> EX.p(literal)
        end

      assert graph == RDF.graph([EX.S |> EX.p("foo")])

      graph =
        RDF.Graph.build do
          literal = "foo"

          if true do
            literal = "bar"
            EX.S2 |> EX.p2(literal)
          end

          EX.S |> EX.p(literal)
        end

      assert graph == RDF.graph([EX.S |> EX.p("foo"), EX.S2 |> EX.p2("bar")])
    end
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
    graph =
      RDF.Graph.build do
        EX.S |> EX.p(XSD.byte(42))
      end

    assert graph == RDF.graph(EX.S |> EX.p(RDF.XSD.byte(42)))
  end

  test "default aliases" do
    graph =
      RDF.Graph.build do
        OWL.Class |> RDFS.subClassOf(RDFS.Class)
      end

    assert graph == RDF.graph(NS.OWL.Class |> NS.RDFS.subClassOf(NS.RDFS.Class))
  end

  test "alias" do
    graph =
      RDF.Graph.build do
        alias TestNS.Custom
        Custom.S |> Custom.p(Custom.O)
      end

    assert graph == RDF.graph(TestNS.Custom.S |> TestNS.Custom.p(TestNS.Custom.O))
  end

  test "aliasing an already taken name" do
    graph =
      RDF.Graph.build do
        alias RDF.Test.Case.EX, as: EX2
        {EX2.S, EX.p(), EX2.foo()}
      end

    quote do
      alias RDF.Test.Case.EX, as: EX2
    end

    assert graph == RDF.graph(RDF.Test.Case.EX.S |> EX.p(RDF.Test.Case.EX.foo()))
  end

  test "import" do
    graph =
      RDF.Graph.build do
        import TestNS.ImportTest
        EX.S |> foo(TestNS.ImportTest.Bar)
      end

    assert graph == RDF.graph(EX.S |> TestNS.ImportTest.foo(TestNS.ImportTest.Bar))
  end

  test "require" do
    log =
      capture_log(fn ->
        graph =
          RDF.Graph.build do
            require Logger
            Logger.info("logged successfully")
            EX.S |> EX.p(EX.O)
          end

        assert graph == RDF.graph(EX.S |> EX.p(EX.O))
      end)

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
      graph =
        RDF.Graph.build do
          @prefix cust: TestNS.Custom

          Custom.S |> Custom.p(Custom.O)
        end

      assert graph ==
               RDF.graph(TestNS.Custom.S |> TestNS.Custom.p(TestNS.Custom.O),
                 prefixes: RDF.default_prefixes(cust: TestNS.Custom)
               )
    end

    test "for vocabulary namespace with auto-generated prefix" do
      graph =
        RDF.Graph.build do
          @prefix TestNS.Custom

          Custom.S |> Custom.p(Custom.O)
        end

      assert graph ==
               RDF.graph(TestNS.Custom.S |> TestNS.Custom.p(TestNS.Custom.O),
                 prefixes: RDF.default_prefixes(custom: TestNS.Custom)
               )
    end

    test "ad-hoc vocabulary namespace for URIs given as string" do
      graph =
        RDF.Graph.build do
          @prefix ad: "http://example.com/ad-hoc/"

          Ad.S |> Ad.p(Ad.O)
        end

      assert graph ==
               RDF.graph(
                 {
                   RDF.iri("http://example.com/ad-hoc/S"),
                   RDF.iri("http://example.com/ad-hoc/p"),
                   RDF.iri("http://example.com/ad-hoc/O")
                 },
                 prefixes: RDF.default_prefixes(ad: "http://example.com/ad-hoc/")
               )
    end

    test "two ad-hoc vocabulary namespaces for the same URI in the same context" do
      graph1 =
        RDF.Graph.build do
          @prefix ad: "http://example.com/ad-hoc/"
          @prefix ex1: "http://example.com/ad-hoc/ex1#"

          Ad.S |> Ad.p(Ex1.O)
        end

      graph2 =
        RDF.Graph.build do
          @prefix ad: "http://example.com/ad-hoc/"
          @prefix ex2: "http://example.com/ad-hoc/ex2#"

          Ad.S |> Ad.p(Ex2.O)
        end

      assert graph1 ==
               RDF.graph(
                 [
                   {
                     RDF.iri("http://example.com/ad-hoc/S"),
                     RDF.iri("http://example.com/ad-hoc/p"),
                     RDF.iri("http://example.com/ad-hoc/ex1#O")
                   }
                 ],
                 prefixes:
                   RDF.default_prefixes(
                     ad: "http://example.com/ad-hoc/",
                     ex1: "http://example.com/ad-hoc/ex1#"
                   )
               )

      assert graph2 ==
               RDF.graph(
                 [
                   {
                     RDF.iri("http://example.com/ad-hoc/S"),
                     RDF.iri("http://example.com/ad-hoc/p"),
                     RDF.iri("http://example.com/ad-hoc/ex2#O")
                   }
                 ],
                 prefixes:
                   RDF.default_prefixes(
                     ad: "http://example.com/ad-hoc/",
                     ex2: "http://example.com/ad-hoc/ex2#"
                   )
               )
    end

    test "merge with prefixes opt" do
      graph =
        RDF.Graph.build prefixes: [custom: EX] do
          @prefix custom: TestNS.Custom

          Custom.S |> Custom.p(Custom.O)
        end

      assert graph ==
               RDF.graph(TestNS.Custom.S |> TestNS.Custom.p(TestNS.Custom.O),
                 prefixes: [custom: TestNS.Custom]
               )
    end
  end

  describe "@base" do
    test "with vocabulary namespace" do
      import RDF.Sigils

      graph =
        RDF.Graph.build do
          @base TestNS.Custom

          ~I<S> |> Custom.p(~I<O>)
          {~I<foo>, ~I<bar>, ~I<baz>}
        end

      assert graph ==
               RDF.graph(
                 [
                   TestNS.Custom.S |> TestNS.Custom.p(TestNS.Custom.O),
                   TestNS.Custom.foo() |> TestNS.Custom.bar(TestNS.Custom.baz())
                 ],
                 base_iri: TestNS.Custom
               )
    end

    test "with RDF.IRI" do
      graph =
        RDF.Graph.build do
          @base ~I<http://example.com/base>

          ~I<#S> |> EX.p(~I<#O>)
          {~I<#foo>, ~I<#bar>, ~I<#baz>}
        end

      import RDF.Sigils

      assert graph ==
               RDF.graph(
                 [
                   ~I<http://example.com/base#S> |> EX.p(~I<http://example.com/base#O>),
                   {~I<http://example.com/base#foo>, ~I<http://example.com/base#bar>,
                    ~I<http://example.com/base#baz>}
                 ],
                 base_iri: "http://example.com/base"
               )
    end

    test "with URI as string" do
      graph =
        RDF.Graph.build do
          @base "http://example.com/base"

          ~I<#S> |> EX.p(~I<#O>)
          {~I<#foo>, ~I<#bar>, ~I<#baz>}
        end

      import RDF.Sigils

      assert graph ==
               RDF.graph(
                 [
                   ~I<http://example.com/base#S> |> EX.p(~I<http://example.com/base#O>),
                   {~I<http://example.com/base#foo>, ~I<http://example.com/base#bar>,
                    ~I<http://example.com/base#baz>}
                 ],
                 base_iri: "http://example.com/base"
               )
    end

    test "conflict with base_iri opt" do
      graph =
        RDF.Graph.build base_iri: "http://example.com/old" do
          @base "http://example.com/base"

          ~I<#S> |> EX.p(~I<#O>)
        end

      import RDF.Sigils

      assert graph ==
               RDF.graph(~I<http://example.com/base#S> |> EX.p(~I<http://example.com/base#O>),
                 base_iri: "http://example.com/base"
               )
    end
  end

  test "exclude" do
    graph =
      RDF.Graph.build do
        exclude "this is not a triple"

        EX.S |> EX.p(EX.O)

        exclude "this is not a triple"
      end

    assert graph == RDF.graph(EX.S |> EX.p(EX.O))
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
