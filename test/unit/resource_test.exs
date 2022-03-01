defmodule RDF.ResourceTest do
  use RDF.Test.Case

  doctest RDF.Resource

  alias RDF.Resource

  test "new/0" do
    assert %BlankNode{} = Resource.new()
  end
end
