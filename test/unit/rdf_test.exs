defmodule RDFTest do
  use RDF.Test.Case

  doctest RDF

  test "Datatype constructor alias functions" do
    RDF.Literal.Datatype.Registry.datatypes() -- [RDF.LangString]
    |> Enum.each(fn datatype ->
         assert apply(RDF, String.to_atom(datatype.name), [1]) == datatype.new(1)
         assert apply(RDF, String.to_atom(Macro.underscore(datatype.name)), [1]) == datatype.new(1)
       end)
  end

  test "true and false aliases" do
    assert RDF.true  == RDF.XSD.Boolean.new(true)
    assert RDF.false == RDF.XSD.Boolean.new(false)
  end

  describe "default_prefixes/0" do
    test "when nothing configured returns the standard prefixes" do
      assert RDF.default_prefixes() == RDF.standard_prefixes()
    end
  end
end
