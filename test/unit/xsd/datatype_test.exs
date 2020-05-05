defmodule RDF.XSD.DatatypeTest do
  use ExUnit.Case

  alias RDF.XSD

  test "base_primitive/1" do
    assert XSD.integer(42) |> XSD.Datatype.base_primitive() == XSD.Integer
    assert XSD.non_negative_integer(42) |> XSD.Datatype.base_primitive() == XSD.Integer
    assert XSD.positive_integer(42) |> XSD.Datatype.base_primitive() == XSD.Integer
  end

  test "derived_from?/2" do
    assert XSD.integer(42) |> XSD.Datatype.derived_from?(XSD.Integer)
    assert XSD.non_negative_integer(42) |> XSD.Datatype.derived_from?(XSD.Integer)
    assert XSD.positive_integer(42) |> XSD.Datatype.derived_from?(XSD.Integer)
    assert XSD.positive_integer(42) |> XSD.Datatype.derived_from?(XSD.NonNegativeInteger)
  end
end
