defmodule RDF.XSD.Facets.ExplicitTimezoneTest do
  use RDF.Test.Case

  import RDF.XSD.Datatype.Test.Case, only: [dt: 1]

  alias RDF.TestDatatypes.{DateTimeWithTz, DateWithoutTz, CustomTime}

  test "DateTimeWithTz" do
    assert DateTimeWithTz.new(dt("2010-01-01T00:00:00Z")) |> RDF.Literal.valid?()
    assert DateTimeWithTz.new("2010-01-01T00:00:00Z") |> RDF.Literal.valid?()
    refute DateTimeWithTz.new(~N[2010-01-01T00:00:00]) |> RDF.Literal.valid?()
    refute DateTimeWithTz.new("2010-01-01T00:00:00") |> RDF.Literal.valid?()
  end

  test "DateWithoutTz" do
    assert DateWithoutTz.new(~D[2010-01-01]) |> RDF.Literal.valid?()
    assert DateWithoutTz.new("2010-01-01") |> RDF.Literal.valid?()
    refute DateWithoutTz.new("2010-01-01Z") |> RDF.Literal.valid?()
  end

  test "CustomTime" do
    assert CustomTime.new(~T[00:00:00]) |> RDF.Literal.valid?()
    assert CustomTime.new("00:00:00Z") |> RDF.Literal.valid?()
    assert CustomTime.new("00:00:00") |> RDF.Literal.valid?()
  end
end
