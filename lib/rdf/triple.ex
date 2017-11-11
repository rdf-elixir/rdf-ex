defmodule RDF.Triple do
  @moduledoc """
  Helper functions for RDF triples.

  A RDF Triple is represented as a plain Elixir tuple consisting of three valid
  RDF values for subject, predicate and object.
  """

  alias RDF.{Statement, BlankNode}

  @doc """
  Creates a `RDF.Triple` with proper RDF values.

  An error is raised when the given elements are not coercible to RDF values.

  Note: The `RDF.triple` function is a shortcut to this function.

  ## Examples

      iex> RDF.Triple.new("http://example.com/S", "http://example.com/p", 42)
      {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42)}
      iex> RDF.Triple.new(EX.S, EX.p, 42)
      {RDF.iri("http://example.com/S"), RDF.iri("http://example.com/p"), RDF.literal(42)}
  """
  def new(subject, predicate, object) do
    {
      Statement.coerce_subject(subject),
      Statement.coerce_predicate(predicate),
      Statement.coerce_object(object)
    }
  end

  @doc """
  Creates a `RDF.Triple` with proper RDF values.

  An error is raised when the given elements are not coercible to RDF values.

  Note: The `RDF.triple` function is a shortcut to this function.

  ## Examples

      iex> RDF.Triple.new {"http://example.com/S", "http://example.com/p", 42}
      {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42)}
      iex> RDF.Triple.new {EX.S, EX.p, 42}
      {RDF.iri("http://example.com/S"), RDF.iri("http://example.com/p"), RDF.literal(42)}
  """
  def new({subject, predicate, object}), do: new(subject, predicate, object)


  def has_bnode?({%BlankNode{}, _, _}), do: true
  def has_bnode?({_, %BlankNode{}, _}), do: true
  def has_bnode?({_, _, %BlankNode{}}), do: true
  def has_bnode?({_, _, _}),            do: false

  def include_value?({value, _, _}, value), do: true
  def include_value?({_, value, _}, value), do: true
  def include_value?({_, _, value}, value), do: true
  def include_value?({_, _, _}),            do: false

end
