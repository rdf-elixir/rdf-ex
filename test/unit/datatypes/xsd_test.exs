defmodule RDF.Literal.XSDTest do
  use ExUnit.Case

  import RDF.TestLiterals
  alias RDF.Literal

  @examples [
    {RDF.XSD.Boolean, XSD.Boolean, true},
    {RDF.XSD.Boolean, XSD.Boolean, false},
    {RDF.XSD.String, XSD.String, :plain},
    {RDF.XSD.Date, XSD.Date, :date},
    {RDF.XSD.Time, XSD.Time, :time},
    {RDF.XSD.DateTime, XSD.DateTime, :datetime},
    {RDF.XSD.DateTime, XSD.DateTime, :naive_datetime},
    {RDF.XSD.AnyURI, XSD.AnyURI, :uri},
    {RDF.XSD.Decimal, XSD.Decimal, :decimal},
    {RDF.XSD.Integer, XSD.Integer, :long},
    {RDF.XSD.Long, XSD.Long, :long},
    {RDF.XSD.Int, XSD.Int, :int},
    {RDF.XSD.Short, XSD.Short, :int},
    {RDF.XSD.Byte, XSD.Byte, :int},
    {RDF.XSD.NonNegativeInteger, XSD.NonNegativeInteger, :long},
    {RDF.XSD.PositiveInteger, XSD.PositiveInteger, :long},
    {RDF.XSD.UnsignedLong, XSD.UnsignedLong, :long},
    {RDF.XSD.UnsignedInt, XSD.UnsignedInt, :int},
    {RDF.XSD.UnsignedShort, XSD.UnsignedShort, :int},
    {RDF.XSD.UnsignedByte, XSD.UnsignedByte, :int},
    {RDF.XSD.NonPositiveInteger, XSD.NonPositiveInteger, :neg_int},
    {RDF.XSD.NegativeInteger, XSD.NegativeInteger, :neg_int},
    {RDF.XSD.Double, XSD.Double, :double},
    {RDF.XSD.Float, XSD.Float, :double},
  ]

  Enum.each(@examples, fn {rdf_datatype, xsd_datatype, value_type} ->
    value = value_type |> value() |> List.first()
    @tag rdf_datatype: rdf_datatype, xsd_datatype: xsd_datatype, value: value
    test "#{rdf_datatype}.new(#{inspect value})", %{rdf_datatype: rdf_datatype, xsd_datatype: xsd_datatype, value: value} do
      assert %Literal{literal: %datatype{}} = literal = rdf_datatype.new(value)
      assert datatype == xsd_datatype
      assert rdf_datatype.valid?(literal) == true
    end
  end)

  Enum.each(@examples, fn {rdf_datatype, xsd_datatype, value_type} ->
    value = value_type |> value() |> List.first()
    @tag rdf_datatype: rdf_datatype, xsd_datatype: xsd_datatype
    test "#{rdf_datatype}.name/0 (#{inspect value})", %{rdf_datatype: rdf_datatype, xsd_datatype: xsd_datatype} do
      assert rdf_datatype.name() == xsd_datatype.name()
    end
  end)

  Enum.each(@examples, fn {rdf_datatype, xsd_datatype, value_type} ->
    value = value_type |> value() |> List.first()
    @tag rdf_datatype: rdf_datatype, xsd_datatype: xsd_datatype
    test "#{rdf_datatype}.id/0 (#{inspect value})", %{rdf_datatype: rdf_datatype, xsd_datatype: xsd_datatype} do
      assert rdf_datatype.id() == xsd_datatype.id()
    end
  end)

  Enum.each(@examples, fn {rdf_datatype, xsd_datatype, value_type} ->
    value = value_type |> value() |> List.first()
    @tag rdf_datatype: rdf_datatype, xsd_datatype: xsd_datatype, value: value
    test "#{rdf_datatype}.datatype/1 (#{inspect value})", %{rdf_datatype: rdf_datatype, xsd_datatype: xsd_datatype, value: value} do
      assert rdf_datatype.new(value) |> rdf_datatype.datatype() == RDF.iri(xsd_datatype.id())
    end
  end)

  Enum.each(@examples, fn {rdf_datatype, xsd_datatype, value_type} ->
    value = value_type |> value() |> List.first()
    @tag rdf_datatype: rdf_datatype, xsd_datatype: xsd_datatype, value: value
    test "#{rdf_datatype}.language/1 (#{inspect value})", %{rdf_datatype: rdf_datatype, value: value} do
      assert rdf_datatype.new(value) |> rdf_datatype.language() == nil
    end
  end)

  Enum.each(@examples, fn {rdf_datatype, xsd_datatype, value_type} ->
    value = value_type |> value() |> List.first()
    @tag rdf_datatype: rdf_datatype, xsd_datatype: xsd_datatype, value: value
    test "#{rdf_datatype}.value/1 (#{inspect value})", %{rdf_datatype: rdf_datatype, value: value} do
      literal = rdf_datatype.new(value)
      assert rdf_datatype.value(literal) == value
    end
  end)

  Enum.each(@examples, fn {rdf_datatype, xsd_datatype, value_type} ->
    value = value_type |> value() |> List.first()
    @tag rdf_datatype: rdf_datatype, xsd_datatype: xsd_datatype, value: value
    test "#{rdf_datatype}.lexical/1 (#{inspect value})", %{rdf_datatype: rdf_datatype, xsd_datatype: xsd_datatype, value: value} do
      literal = rdf_datatype.new(value)
      assert rdf_datatype.lexical(literal) ==
               xsd_datatype.new(value) |> xsd_datatype.lexical()
    end
  end)

  Enum.each(@examples, fn {rdf_datatype, xsd_datatype, value_type} ->
    value = value_type |> value() |> List.first()
    @tag rdf_datatype: rdf_datatype, xsd_datatype: xsd_datatype, value: value
    test "#{rdf_datatype}.canonical/1 (#{inspect value})", %{rdf_datatype: rdf_datatype, xsd_datatype: xsd_datatype, value: value} do
      literal = rdf_datatype.new(value)
      assert rdf_datatype.canonical(literal) ==
               %Literal{literal: xsd_datatype.new(value) |> xsd_datatype.canonical()}
    end
  end)

  Enum.each(@examples, fn {rdf_datatype, xsd_datatype, value_type} ->
    value = value_type |> value() |> List.first()
    @tag rdf_datatype: rdf_datatype, xsd_datatype: xsd_datatype, value: value
    test "#{rdf_datatype}.canonical?/1 (#{inspect value})", %{rdf_datatype: rdf_datatype, xsd_datatype: xsd_datatype, value: value} do
      literal = rdf_datatype.new(value)
      assert rdf_datatype.canonical?(literal) ==
               xsd_datatype.new(value) |> xsd_datatype.canonical?()
    end
  end)

  Enum.each(@examples, fn {rdf_datatype, xsd_datatype, value_type} ->
    value = value_type |> value() |> List.first()
    @tag rdf_datatype: rdf_datatype, xsd_datatype: xsd_datatype, value: value
    test "#{rdf_datatype}.valid?/1 (#{inspect value})", %{rdf_datatype: rdf_datatype, value: value} do
      literal = rdf_datatype.new(value)
      assert rdf_datatype.valid?(literal) == true
    end
  end)

  Enum.each(@examples, fn {rdf_datatype, xsd_datatype, value_type} ->
    value = value_type |> value() |> List.first()
    @tag rdf_datatype: rdf_datatype, xsd_datatype: xsd_datatype, value: value
    test "#{rdf_datatype}.equal_value?/2 (#{inspect value})", %{rdf_datatype: rdf_datatype, value: value} do
      literal = rdf_datatype.new(value)
      assert rdf_datatype.equal_value?(literal, literal) == true
      assert rdf_datatype.equal_value?(literal, value) == true
    end
  end)

  Enum.each(@examples, fn {rdf_datatype, xsd_datatype, value_type} ->
    value = value_type |> value() |> List.first()
    @tag rdf_datatype: rdf_datatype, xsd_datatype: xsd_datatype, value: value
    test "#{rdf_datatype}.compare/2 (#{inspect value})", %{rdf_datatype: rdf_datatype, value: value} do
      literal = rdf_datatype.new(value)
      assert rdf_datatype.compare(literal, literal) == :eq
    end
  end)

  describe "cast/1" do
    test "when given a literal with the same datatype" do
      assert RDF.XSD.String.new("foo") |> RDF.XSD.String.cast() == RDF.XSD.String.new("foo")
      assert RDF.XSD.Integer.new(42) |> RDF.XSD.Integer.cast() == RDF.XSD.Integer.new(42)
      assert RDF.XSD.Byte.new(42) |> RDF.XSD.Byte.cast() == RDF.XSD.Byte.new(42)
    end

    test "when given a literal with a datatype which is castable" do
      assert RDF.XSD.Integer.new(42) |> RDF.XSD.String.cast() == RDF.XSD.String.new("42")
      assert RDF.XSD.String.new("42") |> RDF.XSD.Integer.cast() == RDF.XSD.Integer.new(42)
      assert RDF.XSD.Decimal.new(42) |> RDF.XSD.Byte.cast() == RDF.XSD.Byte.new(42)
    end

    test "when given a literal with a datatype which is not castable" do
      assert RDF.XSD.String.new("foo") |> RDF.XSD.Integer.cast() == nil
      assert RDF.XSD.Integer.new(12345) |> RDF.XSD.Byte.cast() == nil
    end

    test "when given a coercible value" do
      assert "foo" |> RDF.XSD.String.cast() == RDF.XSD.String.new("foo")
      assert "42" |> RDF.XSD.Integer.cast() == RDF.XSD.Integer.new(42)
      assert 42 |> RDF.XSD.Byte.cast() == RDF.XSD.Byte.new(42)
    end

    test "with invalid literals" do
      assert RDF.XSD.Integer.new(3.14) |> RDF.XSD.Integer.cast() == nil
      assert RDF.XSD.Decimal.new("NAN") |> RDF.XSD.Decimal.cast() == nil
      assert RDF.XSD.Double.new(true) |> RDF.XSD.Double.cast() == nil
      assert RDF.XSD.Boolean.new("42") |> RDF.XSD.Boolean.cast() == nil
    end

    test "with non-coercible value" do
      assert_raise RDF.Literal.InvalidError, fn -> RDF.XSD.String.cast(:foo) end
      assert_raise RDF.Literal.InvalidError, fn -> assert RDF.XSD.String.cast(make_ref()) end
    end
  end

  describe "RDF.XSD.Boolean" do
    test "ebv/1" do
      assert RDF.true |> RDF.XSD.Boolean.ebv() == RDF.true
      assert RDF.string("foo") |> RDF.XSD.Boolean.ebv() == RDF.true
      assert false |> RDF.XSD.Boolean.ebv() == RDF.false
      assert "" |> RDF.XSD.Boolean.ebv() == RDF.false
      assert 1 |> RDF.XSD.Boolean.ebv() == RDF.true
      assert self() |> RDF.XSD.Boolean.ebv() == nil
    end

    test "fn_not/1" do
      assert RDF.true |> RDF.XSD.Boolean.fn_not() == RDF.false
      assert false |> RDF.XSD.Boolean.fn_not() == RDF.true
    end

    test "logical_and/1" do
      assert RDF.true |> RDF.XSD.Boolean.logical_and(false) == RDF.false
      assert true |> RDF.XSD.Boolean.logical_and(RDF.true) == RDF.true
      assert false |> RDF.XSD.Boolean.logical_and(false) == RDF.false
      assert 42 |> RDF.XSD.Boolean.logical_and(self()) == nil
    end

    test "logical_or/1" do
      assert RDF.true |> RDF.XSD.Boolean.logical_or(false) == RDF.true
      assert true |> RDF.XSD.Boolean.logical_or(RDF.true) == RDF.true
      assert false |> RDF.XSD.Boolean.logical_or(false) == RDF.false
      assert self() |> RDF.XSD.Boolean.logical_or(self()) == nil
    end
  end

  describe "RDF.XSD.DateTime" do
    test "now/0" do
      assert %Literal{literal: %XSD.DateTime{}} = RDF.XSD.DateTime.now()
    end
  end
end
