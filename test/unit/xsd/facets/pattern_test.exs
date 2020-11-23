defmodule RDF.XSD.Facets.PatternTest do
  use RDF.Test.Case

  alias RDF.TestDatatypes.{UsZipcode, AltUsZipcode}

  test "with one pattern" do
    assert UsZipcode.new("20521") |> RDF.Literal.valid?()
    assert UsZipcode.new("20521-9000") |> RDF.Literal.valid?()
    refute UsZipcode.new("2052") |> RDF.Literal.valid?()
    refute UsZipcode.new("foo") |> RDF.Literal.valid?()
  end

  test "with multiple patterns" do
    assert AltUsZipcode.new("20521") |> RDF.Literal.valid?()
    assert AltUsZipcode.new("20521-9000") |> RDF.Literal.valid?()
    refute AltUsZipcode.new("2052") |> RDF.Literal.valid?()
    refute AltUsZipcode.new("foo") |> RDF.Literal.valid?()
  end
end
