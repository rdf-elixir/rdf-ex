defmodule RDF.GuardsTest do
  use RDF.Test.Case

  doctest RDF.Guards

  import RDF.Guards

  describe "maybe_ns_term/1" do
    def test_fun(term) when maybe_ns_term(term), do: true
    def test_fun(_), do: false

    test "with booleans" do
      refute test_fun(true)
      refute test_fun(false)
    end

    test "with nil" do
      refute test_fun(nil)
    end

    test "any other atom" do
      assert test_fun(:foo)
      assert test_fun(Foo)
    end
  end
end
