defmodule RDF.Quad do
  @moduledoc """
  Helper functions for RDF quads.

  A RDF Quad is represented as a plain Elixir tuple consisting of four valid
  RDF values for subject, predicate, object and a graph context.
  """

  alias RDF.{Statement, Term}

  @doc """
  Creates a `RDF.Quad` with proper RDF values.

  An error is raised when the given elements are not coercible to RDF values.

  Note: The `RDF.quad` function is a shortcut to this function.

  ## Examples

      iex> RDF.Quad.new("http://example.com/S", "http://example.com/p", 42, "http://example.com/Graph")
      {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42), ~I<http://example.com/Graph>}
      iex> RDF.Quad.new(EX.S, EX.p, 42, EX.Graph)
      {RDF.iri("http://example.com/S"), RDF.iri("http://example.com/p"), RDF.literal(42), RDF.iri("http://example.com/Graph")}
  """
  def new(subject, predicate, object, graph_context) do
    {
      Statement.coerce_subject(subject),
      Statement.coerce_predicate(predicate),
      Statement.coerce_object(object),
      Statement.coerce_graph_name(graph_context)
    }
  end

  @doc """
  Creates a `RDF.Quad` with proper RDF values.

  An error is raised when the given elements are not coercible to RDF values.

  Note: The `RDF.quad` function is a shortcut to this function.

  ## Examples

      iex> RDF.Quad.new {"http://example.com/S", "http://example.com/p", 42, "http://example.com/Graph"}
      {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42), ~I<http://example.com/Graph>}
      iex> RDF.Quad.new {EX.S, EX.p, 42, EX.Graph}
      {RDF.iri("http://example.com/S"), RDF.iri("http://example.com/p"), RDF.literal(42), RDF.iri("http://example.com/Graph")}
  """
  def new({subject, predicate, object, graph_context}),
    do: new(subject, predicate, object, graph_context)


  @doc """
  Returns a tuple of native Elixir values from a `RDF.Quad` of RDF terms.

  Returns `nil` if one of the components of the given tuple is not convertible via `RDF.Term.value/1`.

  ## Examples

      iex> RDF.Quad.values {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42), ~I<http://example.com/Graph>}
      {"http://example.com/S", "http://example.com/p", 42, "http://example.com/Graph"}

  """
  def values({subject, predicate, object, graph_context}) do
    with subject_value   when not is_nil(subject_value)       <- Term.value(subject),
         predicate_value when not is_nil(predicate_value)     <- Term.value(predicate),
         object_value    when not is_nil(object_value)        <- Term.value(object),
         graph_context_value when not is_nil(graph_context_value) or is_nil(graph_context) <-
           Term.value(graph_context)
    do
      {subject_value, predicate_value, object_value, graph_context_value}
    end
  end

  def values(_), do: nil

end
