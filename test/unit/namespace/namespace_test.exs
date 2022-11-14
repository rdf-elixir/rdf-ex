defmodule RDF.NamespaceTest do
  use RDF.Test.Case

  doctest RDF.Namespace

  alias RDF.Namespace
  import RDF.Sigils

  alias RDF.TestNamespaces.{SimpleNS, NSfromPropertyMap}

  @compile {:no_warn_undefined, RDF.NamespaceTest.RelativeNS}

  describe "defnamespace/2" do
    test "create module is relative to current namespace" do
      assert {:module, RDF.NamespaceTest.RelativeNS, _, _} =
               Namespace.defnamespace(RelativeNS,
                 foo: ~I<http://example.com/foo>
               )

      assert RDF.NamespaceTest.RelativeNS.foo() == ~I<http://example.com/foo>
    end
  end

  describe "property functions" do
    test "returns IRI without args" do
      assert SimpleNS.foo() == ~I<http://example.com/foo>
      assert SimpleNS.bar() == ~I<http://example.com/bar>

      assert NSfromPropertyMap.foo() == ~I<http://example.com/foo>
      assert NSfromPropertyMap.bar() == ~I<http://example.com/bar>
    end

    test "description builder" do
      assert ~I<http://example.com/foo> |> SimpleNS.foo(~I<http://example.com/bar>) ==
               RDF.description(~I<http://example.com/foo>,
                 init: {SimpleNS.foo(), ~I<http://example.com/bar>}
               )

      assert EX.Foo |> SimpleNS.foo(EX.Bar) ==
               RDF.description(~I<http://example.com/Foo>,
                 init: {SimpleNS.foo(), ~I<http://example.com/Bar>}
               )

      assert EX.Foo |> SimpleNS.foo([1, 2, 3, 4, 5]) ==
               RDF.description(~I<http://example.com/Foo>,
                 init: {SimpleNS.foo(), [1, 2, 3, 4, 5]}
               )
    end

    test "description accessor" do
      assert RDF.description(~I<http://example.com/foo>,
               init: {SimpleNS.foo(), ~I<http://example.com/bar>}
             )
             |> SimpleNS.foo() ==
               [~I<http://example.com/bar>]

      assert RDF.description(~I<http://example.com/foo>)
             |> SimpleNS.foo() ==
               nil
    end
  end

  test "resolving module name atoms for non-property terms" do
    assert RDF.iri(SimpleNS.Baz) == ~I<http://example.com/Baz>
    assert RDF.iri(SimpleNS.Baaz) == ~I<http://example.com/Baaz>
  end

  test "__terms__" do
    assert SimpleNS.__terms__() == [:Baaz, :Baz, :bar, :foo]
    assert NSfromPropertyMap.__terms__() == [:bar, :foo]
  end

  test "__iris__" do
    assert SimpleNS.__iris__() == [
             ~I<http://example.com/Baaz>,
             ~I<http://example.com/Baz>,
             ~I<http://example.com/bar>,
             ~I<http://example.com/foo>
           ]

    assert NSfromPropertyMap.__iris__() == [
             ~I<http://example.com/bar>,
             ~I<http://example.com/foo>
           ]
  end

  describe "namespace?/1" do
    test "with RDF.Namespace modules" do
      assert RDF.Namespace.namespace?(RDF.TestNamespaces.SimpleNS) == true
      assert RDF.Namespace.namespace?(RDF.TestNamespaces.NSfromPropertyMap) == true
    end

    test "with RDF.Vocabulary.Namespace modules" do
      assert RDF.Namespace.namespace?(EX) == true
      assert RDF.Namespace.namespace?(RDF.NS.RDF) == true
      assert RDF.Namespace.namespace?(RDF.NS.RDFS) == true
      assert RDF.Namespace.namespace?(RDF.NS.OWL) == true
      assert RDF.Namespace.namespace?(RDF.NS.XSD) == true
    end

    test "with the top-level RDF module" do
      assert RDF.Namespace.namespace?(RDF) == true
    end

    test "with non-RDF.Namespace modules" do
      assert RDF.Namespace.namespace?(Enum) == false
      assert RDF.Namespace.namespace?(__MODULE__) == false
    end
  end
end
