defmodule RDF.Quad do
  @moduledoc """
  Defines a RDF Quad.

  A Quad is a plain Elixir tuple consisting of four valid RDF values for
  subject, predicate, object and a graph context.
  """

  alias RDF.BlankNode

  import RDF.Triple, except: [new: 1, new: 3]

  @type graph_context :: URI.t | BlankNode.t
  @type convertible_graph_context :: graph_context | atom | String.t

  @doc """
  Creates a `RDF.Quad` with proper RDF values.

  An error is raised when the given elements are not convertible to RDF values.

  Note: The `RDF.quad` function is a shortcut to this function.

  # Examples

      iex> RDF.Quad.new("http://example.com/S", "http://example.com/p", 42, "http://example.com/Graph")
      {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42), ~I<http://example.com/Graph>}
  """
  def new(subject, predicate, object, graph_context) do
    {
      convert_subject(subject),
      convert_predicate(predicate),
      convert_object(object),
      convert_graph_context(graph_context)
    }
  end

  @doc """
  Creates a `RDF.Quad` with proper RDF values.

  An error is raised when the given elements are not convertible to RDF values.

  Note: The `RDF.quad` function is a shortcut to this function.

  # Examples

      iex> RDF.Quad.new {"http://example.com/S", "http://example.com/p", 42, "http://example.com/Graph"}
      {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42), ~I<http://example.com/Graph>}
  """
  def new({subject, predicate, object, graph_context}),
    do: new(subject, predicate, object, graph_context)


  @doc false
  def convert_graph_context(uri)
  def convert_graph_context(nil), do: nil
  def convert_graph_context(uri = %URI{}), do: uri
  def convert_graph_context(bnode = %BlankNode{}), do: bnode
  def convert_graph_context(uri) when is_atom(uri) or is_binary(uri),
    do: RDF.uri(uri)
  def convert_graph_context(arg),
    do: raise RDF.Quad.InvalidGraphContextError, graph_context: arg


end
