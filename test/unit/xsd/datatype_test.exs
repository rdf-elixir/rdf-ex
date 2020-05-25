defmodule RDF.XSD.DatatypeTest do
  use RDF.Test.Case

  alias RDF.TestDatatypes.{CustomTime, Age}

  describe "most_specific/2" do
    test "when equal" do
      assert XSD.Datatype.most_specific(XSD.Integer, XSD.Integer) == XSD.Integer
      assert XSD.Datatype.most_specific(XSD.Byte, XSD.Byte) == XSD.Byte
      assert XSD.Datatype.most_specific(CustomTime, CustomTime) == CustomTime
    end

    test "when one is derived from the other datatype" do
      %{
        XSD.Byte => {XSD.Integer, XSD.Byte},
        XSD.UnsignedShort => {XSD.UnsignedInt, XSD.UnsignedShort},
        Age => {XSD.Integer, Age},
        CustomTime => {XSD.Time, CustomTime}
      }
      |> Enum.each(fn {most_specific, {left, right}} ->
        assert XSD.Datatype.most_specific(left, right) == most_specific
        assert XSD.Datatype.most_specific(right, left) == most_specific
      end)
    end

    test "when independent" do
      [
        {XSD.Double, XSD.Byte},
        {XSD.NegativeInteger, XSD.UnsignedShort},
        {XSD.Date, CustomTime}
      ]
      |> Enum.each(fn {left, right} ->
        refute XSD.Datatype.most_specific(left, right)
        refute XSD.Datatype.most_specific(right, left)
      end)
    end
  end
end
