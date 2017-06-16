defmodule RDF.Quad do
  @moduledoc """
  Helper functions for RDF quads.

  A RDF Quad is represented as a plain Elixir tuple consisting of four valid
  RDF values for subject, predicate, object and a graph context.
  """

  alias RDF.Statement

  @doc """
  Creates a `RDF.Quad` with proper RDF values.

  An error is raised when the given elements are not convertible to RDF values.

  Note: The `RDF.quad` function is a shortcut to this function.

  ## Examples

      iex> RDF.Quad.new("http://example.com/S", "http://example.com/p", 42, "http://example.com/Graph")
      {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42), ~I<http://example.com/Graph>}
      iex> RDF.Quad.new(EX.S, EX.p, 42, EX.Graph)
      {RDF.uri("http://example.com/S"), RDF.uri("http://example.com/p"), RDF.literal(42), RDF.uri("http://example.com/Graph")}
  """
  def new(subject, predicate, object, graph_context) do
    {
      Statement.convert_subject(subject),
      Statement.convert_predicate(predicate),
      Statement.convert_object(object),
      Statement.convert_graph_name(graph_context)
    }
  end

  @doc """
  Creates a `RDF.Quad` with proper RDF values.

  An error is raised when the given elements are not convertible to RDF values.

  Note: The `RDF.quad` function is a shortcut to this function.

  ## Examples

      iex> RDF.Quad.new {"http://example.com/S", "http://example.com/p", 42, "http://example.com/Graph"}
      {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42), ~I<http://example.com/Graph>}
      iex> RDF.Quad.new {EX.S, EX.p, 42, EX.Graph}
      {RDF.uri("http://example.com/S"), RDF.uri("http://example.com/p"), RDF.literal(42), RDF.uri("http://example.com/Graph")}
  """
  def new({subject, predicate, object, graph_context}),
    do: new(subject, predicate, object, graph_context)

end
