defmodule RDF.Triple do
  @moduledoc """
  Helper functions for RDF triples.

  A RDF Triple is represented as a plain Elixir tuple consisting of three valid
  RDF values for subject, predicate and object.
  """

  alias RDF.{BlankNode, Statement}

  @doc """
  Creates a `RDF.Triple` with proper RDF values.

  An error is raised when the given elements are not convertible to RDF values.

  Note: The `RDF.triple` function is a shortcut to this function.

  ## Examples

      iex> RDF.Triple.new("http://example.com/S", "http://example.com/p", 42)
      {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42)}
  """
  def new(subject, predicate, object) do
    {
      Statement.convert_subject(subject),
      Statement.convert_predicate(predicate),
      Statement.convert_object(object)
    }
  end

  @doc """
  Creates a `RDF.Triple` with proper RDF values.

  An error is raised when the given elements are not convertible to RDF values.

  Note: The `RDF.triple` function is a shortcut to this function.

  ## Examples

      iex> RDF.Triple.new {"http://example.com/S", "http://example.com/p", 42}
      {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42)}
  """
  def new({subject, predicate, object}), do: new(subject, predicate, object)

end
