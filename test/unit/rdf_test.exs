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
end
