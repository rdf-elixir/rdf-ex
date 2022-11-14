defmodule RDF.GuardsTest do
  use RDF.Test.Case

  import RDF.Guards
  import RDF.Sigils

  doctest RDF.Guards

  # The following raises a compiler warning due to this issue
  # in Elixir: https://github.com/elixir-lang/elixir/issues/10485

  #  test "is_rdf_literal/2" do
  #    refute is_rdf_literal(~I<http://example.com/>, XSD.String)
  #    refute is_rdf_literal(42, XSD.String)
  #  end

  #  test "is_plain_rdf_literal/1" do
  #    refute is_plain_rdf_literal(~I<http://example.com/>)
  #    refute is_plain_rdf_literal("foo")
  #  end

  #  test "is_typed_rdf_literal/1" do
  #    refute is_typed_rdf_literal(~I<http://example.com/>)
  #    refute is_typed_rdf_literal("foo")
  #  end
end
