defmodule RDF.Namespace.ActAsNamespaceTest do
  use ExUnit.Case

  alias RDF.TestVocabularyNamespaces.EX

  @compile {:no_warn_undefined, RDF.TestVocabularyNamespaces.EX}

  {properties, classes} = Enum.split_with(RDF.NS.RDFS.__terms__(), &RDF.Utils.downcase?/1)

  @rdfs_classes classes
  @rdfs_properties properties

  defmodule TestNamespaces do
    use RDF.Vocabulary.Namespace
    import RDF.Namespace

    defnamespace TestNamespace,
      Foo: "http://example1.com/Foo",
      bar: "http://example2.com/bar",
      baz: "http://example2.com/baz"

    defvocab TestVocab,
      base_iri: "http://example.com/ns/TestVocab/",
      terms: %{
        foo: :Foo,
        Bar: :bar
      }
  end

  defmodule TestDelegateNamespace do
    import RDF.Namespace

    act_as_namespace RDF.Namespace.ActAsNamespaceTest.TestNamespaces.TestNamespace
  end

  defmodule TestDelegateVocab do
    import RDF.Namespace

    act_as_namespace RDF.Namespace.ActAsNamespaceTest.TestNamespaces.TestVocab
  end

  defmodule TestDelegateRDFS do
    import RDF.Namespace

    act_as_namespace RDF.NS.RDFS
  end

  import RDF.Sigils

  describe "RDF.Namespace compatibility" do
    test "modules under TestDelegateNamespace can be resolved to a RDF.IRI" do
      assert RDF.iri(TestDelegateNamespace.Foo) == ~I<http://example1.com/Foo>
    end

    test "TestDelegateNamespace property functions" do
      assert TestDelegateNamespace.bar() == ~I<http://example2.com/bar>
    end

    test "__iris__/0" do
      assert TestDelegateNamespace.__iris__() ==
               RDF.Namespace.ActAsNamespaceTest.TestNamespaces.TestNamespace.__iris__()
    end

    test "__terms__/0" do
      assert TestDelegateNamespace.__terms__() ==
               RDF.Namespace.ActAsNamespaceTest.TestNamespaces.TestNamespace.__terms__()
    end
  end

  describe "RDF.Vocabulary.Namespace compatibility" do
    test "sub-modules" do
      assert RDF.iri(TestDelegateVocab.Foo) == ~I<http://example.com/ns/TestVocab/Foo>
      assert RDF.iri(TestDelegateVocab.Bar) == ~I<http://example.com/ns/TestVocab/bar>

      Enum.each(@rdfs_classes, fn class ->
        assert TestDelegateRDFS
               |> Module.concat(class)
               |> RDF.iri() ==
                 RDF.NS.RDFS
                 |> Module.concat(class)
                 |> RDF.iri()
      end)
    end

    test "property functions" do
      assert TestDelegateVocab.foo() == ~I<http://example.com/ns/TestVocab/Foo>
      assert TestDelegateVocab.bar() == ~I<http://example.com/ns/TestVocab/bar>

      Enum.each(@rdfs_properties, fn property ->
        assert apply(TestDelegateRDFS, property, []) ==
                 apply(RDF.NS.RDFS, property, [])

        assert apply(TestDelegateRDFS, property, [EX.S, EX.O]) ==
                 apply(RDF.NS.RDFS, property, [EX.S, EX.O])

        o = RDF.iri(EX.O)
        desc = apply(RDF.NS.RDFS, property, [EX.S, o])
        assert apply(TestDelegateRDFS, property, [desc]) == [o]
      end)
    end

    test "__iris__/0" do
      assert TestDelegateRDFS.__iris__() == RDF.NS.RDFS.__iris__()
    end

    test "__terms__/0" do
      assert TestDelegateRDFS.__terms__() == RDF.NS.RDFS.__terms__()
    end

    test "__term_aliases__/0" do
      assert TestDelegateRDFS.__term_aliases__() == RDF.NS.RDFS.__term_aliases__()
    end

    test "__file__/0" do
      assert TestDelegateRDFS.__file__() == RDF.NS.RDFS.__file__()
    end

    test "__base_iri__/0" do
      assert TestDelegateRDFS.__base_iri__() == RDF.NS.RDFS.__base_iri__()
    end

    test "__strict__/0" do
      assert TestDelegateRDFS.__strict__() == RDF.NS.RDFS.__strict__()
    end
  end

  test "additional property function clauses" do
    defmodule TestDelegateWithConflicts do
      import RDF.Namespace

      def bar(_, :test), do: :matched
      def baz(_, _, _), do: :ok

      act_as_namespace RDF.Namespace.ActAsNamespaceTest.TestNamespaces.TestNamespace
    end

    assert TestDelegateWithConflicts.bar() == ~I<http://example2.com/bar>

    assert TestDelegateWithConflicts.bar(EX.S, EX.O) ==
             RDF.Namespace.ActAsNamespaceTest.TestNamespaces.TestNamespace.bar(EX.S, EX.O)

    assert TestDelegateWithConflicts.bar(EX.S, :test) == :matched
    assert TestDelegateWithConflicts.baz(1, 2, 3) == :ok
  end
end
