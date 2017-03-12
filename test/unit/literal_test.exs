defmodule RDF.LiteralTest do
  use ExUnit.Case

  alias RDF.{Literal}
  alias RDF.NS.XSD

  doctest RDF.Literal


  describe "construction by type inference" do
    test "creating an string literal" do
      string_literal = Literal.new("foo")
      assert string_literal.value == "foo"
      assert string_literal.datatype == XSD.string
    end

    test "creating an integer by type inference" do
      int_literal = Literal.new(42)
      assert int_literal.value == 42
      assert int_literal.datatype == XSD.integer
    end

    test "creating a boolean by type inference" do
      int_literal = Literal.new(true)
      assert int_literal.value == true
      assert int_literal.datatype == XSD.boolean

      int_literal = Literal.new(false)
      assert int_literal.value == false
      assert int_literal.datatype == XSD.boolean
    end

  end

  describe "construction with an explicit unknown datatype" do
    literal = Literal.new("custom typed value", datatype: "http://example/dt")
    assert literal.value == "custom typed value"
    assert literal.datatype == RDF.uri("http://example/dt")
  end

  describe "construction with an explicit known (XSD) datatype" do
    test "creating a boolean" do
      bool_literal = Literal.new("true", datatype: XSD.boolean)
      assert bool_literal.value == true
      assert bool_literal.datatype == XSD.boolean

      bool_literal = Literal.new(true, datatype: XSD.boolean)
      assert bool_literal.value == true
      assert bool_literal.datatype == XSD.boolean

      bool_literal = Literal.new("false", datatype: XSD.boolean)
      assert bool_literal.value == false
      assert bool_literal.datatype == XSD.boolean

      bool_literal = Literal.new(false, datatype: XSD.boolean)
      assert bool_literal.value == false
      assert bool_literal.datatype == XSD.boolean
    end

    test "creating an integer" do
      int_literal = Literal.new(42, datatype: XSD.integer)
      assert int_literal.value == 42
      assert int_literal.datatype == XSD.integer

      int_literal = Literal.new("42", datatype: XSD.integer)
      assert int_literal.value == 42
      assert int_literal.datatype == XSD.integer

      int_literal = Literal.new(true, datatype: XSD.integer)
      assert int_literal.value == 1
      assert int_literal.datatype == XSD.integer
      int_literal = Literal.new(false, datatype: XSD.integer)
      assert int_literal.value == 0
      assert int_literal.datatype == XSD.integer
    end

  end

  test "creating a language-tagged string literal" do
    literal = Literal.new("Eule", language: "de")
    assert literal.value == "Eule"
    assert literal.datatype == RDF.langString
    assert literal.language == "de"
  end

  @tag :skip
  test "construction of a typed and language-tagged literal fails" do
  end


end
