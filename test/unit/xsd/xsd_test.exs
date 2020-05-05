defmodule RDF.XSDTest do
  use RDF.Test.Case

  doctest RDF.XSD

  test "Datatype constructor alias functions" do
    Enum.each(XSD.datatypes(), fn datatype ->
      assert apply(XSD, String.to_atom(datatype.name), [1]) == datatype.new(1)
      assert apply(XSD, String.to_atom(Macro.underscore(datatype.name)), [1]) == datatype.new(1)
    end)
  end

  test "true and false aliases" do
    assert XSD.true  == XSD.Boolean.new(true)
    assert XSD.false == XSD.Boolean.new(false)
  end
end
