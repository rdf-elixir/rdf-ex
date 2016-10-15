defmodule RDF.LiteralTest do
  use ExUnit.Case

  doctest RDF.Literal

  alias RDF.{Literal, XSD}

  describe "construction by type inference" do
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

end
