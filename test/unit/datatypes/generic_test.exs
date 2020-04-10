defmodule RDF.Literal.GenericTest do
  use ExUnit.Case

  alias RDF.Literal
  alias RDF.Literal.Generic

  @valid %{
    # input => { value , datatype }
    "foo" => { "foo"   , "http://example.com/datatype" },
  }

  describe "new" do
    test "with value and datatype" do
      Enum.each @valid, fn {input, {value, datatype}} ->
        datatype_iri = RDF.iri(datatype)
        assert %Literal{literal: %Generic{value: ^value, datatype: ^datatype_iri}} =
                 Generic.new(input, datatype: datatype_iri)
        assert %Literal{literal: %Generic{value: ^value, datatype: ^datatype_iri}} =
                 Generic.new(input, datatype: datatype)
      end
    end

    test "with canonicalize opts" do
      Enum.each @valid, fn {input, {value, datatype}} ->
        datatype_iri = RDF.iri(datatype)
        assert %Literal{literal: %Generic{value: ^value, datatype: ^datatype_iri}} =
                 Generic.new(input, datatype: datatype, canonicalize: true)
      end
    end

    test "without a datatype it produces an invalid literal" do
      Enum.each @valid, fn {input, {value, _}} ->
        assert %Literal{literal: %Generic{value: ^value, datatype: nil}} =
                 literal = Generic.new(input)
        assert Generic.valid?(literal) == false
      end
    end

    test "with nil as a datatype it produces an invalid literal" do
      Enum.each @valid, fn {input, {value, _}} ->
        assert %Literal{literal: %Generic{value: ^value, datatype: nil}} =
                 literal = Generic.new(input, datatype: nil)
        assert Generic.valid?(literal) == false
      end
    end

    test "with the empty string as a datatype it produces an invalid literal" do
      Enum.each @valid, fn {input, {value, _}} ->
        assert %Literal{literal: %Generic{value: ^value, datatype: nil}} =
                 literal = Generic.new(input, datatype: "")
        assert Generic.valid?(literal) == false
      end
    end
  end

  describe "new!" do
    test "with valid values, it behaves the same as new" do
      Enum.each @valid, fn {input, {_, datatype}} ->
        assert Generic.new!(input, datatype: datatype) ==
                 Generic.new(input, datatype: datatype)
        assert Generic.new!(input, datatype: datatype, canonicalize: true) ==
                 Generic.new(input, datatype: datatype, canonicalize: true)
      end
    end

    test "without a datatype it raises an error" do
      Enum.each @valid, fn {input, _} ->
        assert_raise ArgumentError, fn -> Generic.new!(input) end
      end
    end

    test "with nil as a datatype it raises an error" do
      Enum.each @valid, fn {input, _} ->
        assert_raise ArgumentError, fn -> Generic.new!(input, datatype: nil) end
      end
    end

    test "with the empty string as a datatype it raises an error" do
      Enum.each @valid, fn {input, _} ->
        assert_raise ArgumentError, fn -> Generic.new!(input, datatype: "") end
      end
    end
  end

  test "datatype/1" do
    Enum.each @valid, fn {input, {_, datatype}} ->
      assert (Generic.new(input, datatype: datatype) |> Generic.datatype()) == RDF.iri(datatype)
    end
  end

  test "language/1" do
    Enum.each @valid, fn {input, {_, datatype}} ->
      assert (Generic.new(input, datatype: datatype) |> Generic.language()) == nil
    end
  end

  test "value/1" do
    Enum.each @valid, fn {input, {value, datatype}} ->
      assert (Generic.new(input, datatype: datatype) |> Generic.value()) == value
    end
  end

  test "lexical/1" do
    Enum.each @valid, fn {input, {value, datatype}} ->
      assert (Generic.new(input, datatype: datatype) |> Generic.lexical()) == value
    end
  end

  test "canonical/1" do
    Enum.each @valid, fn {input, {_, datatype}} ->
      assert (Generic.new(input, datatype: datatype) |> Generic.canonical()) ==
               Generic.new(input, datatype: datatype)
    end
  end

  test "canonical?/1" do
    Enum.each @valid, fn {input, {_, datatype}} ->
      assert (Generic.new(input, datatype: datatype) |> Generic.canonical?()) == true
    end
  end

  describe "valid?/1" do
    test "with a datatype" do
      Enum.each @valid, fn {input, {_, datatype}} ->
        assert (Generic.new(input, datatype: datatype) |> Generic.valid?()) == true
      end
    end

    test "without a datatype" do
      Enum.each @valid, fn {input, _} ->
        assert (Generic.new(input, datatype: nil) |> Generic.valid?()) == false
        assert (Generic.new(input, datatype: "") |> Generic.valid?()) == false
      end
    end
  end

  describe "cast/1" do
    test "when given a RDF.Literal.Generic literal" do
      Enum.each @valid, fn {input, {_, datatype}} ->
        assert (Generic.new(input, datatype: datatype) |> Generic.cast()) ==
                 Generic.new(input, datatype: datatype)
      end
    end

    test "when given a literal with a datatype which is not castable" do
      assert RDF.XSD.String.new("foo") |> Generic.cast() == nil
      assert RDF.XSD.Integer.new(12345) |> Generic.cast() == nil
    end

    test "with invalid literals" do
      assert RDF.XSD.Integer.new(3.14) |> Generic.cast() == nil
      assert RDF.XSD.Decimal.new("NAN") |> Generic.cast() == nil
      assert RDF.XSD.Double.new(true) |> Generic.cast() == nil
    end

    test "with non-coercible value" do
      assert Generic.cast(:foo) == nil
      assert Generic.cast(make_ref()) == nil
    end
  end

  test "equal_value?/2" do
    Enum.each @valid, fn {input, {_, datatype}} ->
      assert Generic.equal_value?(
               Generic.new(input, datatype: datatype),
               Generic.new(input, datatype: datatype)) == true
    end

    assert Generic.equal_value?(
             Generic.new("foo", datatype: "http://example.com/foo"),
             Generic.new("foo", datatype: "http://example.com/bar")) == false
    assert Generic.equal_value?(Generic.new("foo"), Generic.new("foo")) == true
    assert Generic.equal_value?(Generic.new("foo"), Generic.new("bar")) == false
    assert Generic.equal_value?(Generic.new("foo", datatype: "foo"), RDF.XSD.String.new("foo")) == false
  end

  test "compare/2" do
    Enum.each @valid, fn {input, {_, datatype}} ->
      assert Generic.compare(
               Generic.new(input, datatype: datatype),
               Generic.new(input, datatype: datatype)) == :eq
    end

    assert Generic.compare(Generic.new("foo", datatype: "en"), Generic.new("bar", datatype: "en")) == :gt
    assert Generic.compare(Generic.new("bar", datatype: "en"), Generic.new("baz", datatype: "en")) == :lt

    assert Generic.compare(
             Generic.new("foo", datatype: "en"),
             Generic.new("foo", datatype: "de")) == nil
    assert Generic.compare(Generic.new("foo"), Generic.new("foo")) == nil
    assert Generic.compare(Generic.new("foo"), RDF.XSD.String.new("foo")) == nil
  end
end
