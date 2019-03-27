defmodule RDFTest do
  use RDF.Test.Case

  doctest RDF

  test "Datatype constructor alias functions" do
    RDF.Datatype.modules
    |> Enum.each(fn datatype ->
         "rdf/" <> alias_name = datatype |> Macro.underscore
         assert apply(RDF, String.to_atom(alias_name), [1]) == datatype.new(1)
       end)
  end

  test "true and false aliases" do
    assert RDF.true  == RDF.Boolean.new(true)
    assert RDF.false == RDF.Boolean.new(false)
  end

  describe "default_prefixes/0" do
    test "when nothing configured returns the standard prefixes" do
      assert RDF.default_prefixes() == RDF.standard_prefixes()
    end
  end

end
