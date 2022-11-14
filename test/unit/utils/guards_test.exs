defmodule RDF.Utils.GuardsTest do
  use RDF.Test.Case

  import RDF.Utils.Guards

  doctest RDF.Utils.Guards

  describe "maybe_module/1" do
    def test_fun(term) when maybe_module(term), do: true
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
