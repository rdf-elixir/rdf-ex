defmodule RDFTest do
  use RDF.Test.Case

  doctest RDF

  test "Datatype constructor alias functions" do
    assert RDF.langString("foo", language: "en") == RDF.Literal.new("foo", language: "en")
  end

  describe "default_prefixes/0" do
    test "when nothing configured returns the standard prefixes" do
      assert RDF.default_prefixes() == RDF.standard_prefixes()
    end
  end
end
