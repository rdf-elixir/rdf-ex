defmodule RDF.NumericTest do
  use RDF.Test.Case

  alias RDF.Numeric

  test "zero?/1" do
    assert Numeric.zero?(RDF.integer(0)) == true
    assert Numeric.zero?(RDF.string("0")) == false
  end

  test "negative_zero?/1" do
    assert Numeric.negative_zero?(RDF.double("-0")) == true
    assert Numeric.negative_zero?(RDF.integer(0)) == false
  end

  test "add/2" do
    assert Numeric.add(RDF.integer(1), RDF.integer(2)) == RDF.integer(3)
    assert Numeric.add(RDF.float(1), 2) == RDF.float(3.0)
  end

  test "subtract/2" do
    assert Numeric.subtract(RDF.integer(2), RDF.integer(1)) == RDF.integer(1)
    assert Numeric.subtract(RDF.decimal(2), 1) == RDF.decimal(1.0)
  end

  test "multiply/2" do
    assert Numeric.multiply(RDF.integer(2), RDF.integer(3)) == RDF.integer(6)
    assert Numeric.multiply(RDF.double(2), 3) == RDF.double(6.0)
  end

  test "divide/2" do
    assert Numeric.divide(RDF.integer(4), RDF.integer(2)) == RDF.decimal(2)
    assert Numeric.divide(RDF.double(3), 2) == RDF.double(1.5)
  end

  test "abs/1" do
    assert Numeric.abs(RDF.integer(-2)) == RDF.integer(2)
    assert Numeric.abs(RDF.double(-3.14)) == RDF.double(3.14)
  end

  test "round/1" do
    assert Numeric.round(RDF.integer(2)) == RDF.integer(2)
    assert Numeric.round(RDF.double(3.14)) == RDF.double(3.0)
  end

  test "round/2" do
    assert Numeric.round(RDF.integer(2), 3) == RDF.integer(2)
    assert Numeric.round(RDF.double(3.1415), 2) == RDF.double(3.14)
  end

  test "ceil/1" do
    assert Numeric.ceil(RDF.integer(2)) == RDF.integer(2)
    assert Numeric.ceil(RDF.double(3.14)) == RDF.double("4")
  end

  test "floor/1" do
    assert Numeric.floor(RDF.integer(2)) == RDF.integer(2)
    assert Numeric.floor(RDF.double(3.14)) == RDF.double("3")
  end
end
