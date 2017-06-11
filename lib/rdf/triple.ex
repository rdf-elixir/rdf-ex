defmodule RDF.Triple do
  @moduledoc """
  Defines a RDF Triple.

  A Triple is a plain Elixir tuple consisting of three valid RDF values for
  subject, predicate and object.
  """

  alias RDF.{BlankNode, Statement}

  @doc """
  Creates a `RDF.Triple` with proper RDF values.

  An error is raised when the given elements are not convertible to RDF values.

  Note: The `RDF.triple` function is a shortcut to this function.

  # Examples

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

  # Examples

      iex> RDF.Triple.new {"http://example.com/S", "http://example.com/p", 42}
      {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42)}
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
