defmodule RDF.Statement do
  @moduledoc """
  Helper functions for RDF statements.

  A RDF statement is either a `RDF.Triple` or a `RDF.Quad`.
  """

  alias RDF.{Triple, Quad, BlankNode, Literal}

  @type subject    :: URI.t | BlankNode.t
  @type predicate  :: URI.t
  @type object     :: URI.t | BlankNode.t | Literal.t
  @type graph_name :: URI.t | BlankNode.t

  @type convertible_subject    :: subject    | atom | String.t
  @type convertible_predicate  :: predicate  | atom | String.t
  @type convertible_object     :: object     | atom | String.t # TODO: all basic Elixir types convertible to Literals
  @type convertible_graph_name :: graph_name | atom | String.t


  @doc """
  Creates a `RDF.Statement` tuple with proper RDF values.

  An error is raised when the given elements are not convertible to RDF values.

  ## Examples

      iex> RDF.Statement.new {"http://example.com/S", "http://example.com/p", 42}
      {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42)}
      iex> RDF.Statement.new {"http://example.com/S", "http://example.com/p", 42, "http://example.com/Graph"}
      {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42), ~I<http://example.com/Graph>}
  """
  def convert(statement)
  def convert({_, _, _} = triple),  do: Triple.new(triple)
  def convert({_, _, _, _} = quad), do: Quad.new(quad)

  @doc false
  def convert_subject(uri)
  def convert_subject(uri = %URI{}), do: uri
  def convert_subject(bnode = %BlankNode{}), do: bnode
  def convert_subject("_:" <> identifier), do: RDF.bnode(identifier)
  def convert_subject(uri) when is_atom(uri) or is_binary(uri), do: RDF.uri(uri)
  def convert_subject(arg), do: raise RDF.Triple.InvalidSubjectError, subject: arg

  @doc false
  def convert_predicate(uri)
  def convert_predicate(uri = %URI{}), do: uri
  # Note: Although, RDF does not allow blank nodes for properties, JSON-LD allows
  # them, by introducing the notion of "generalized RDF".
  # TODO: Support an option `:strict_rdf` to explicitly disallow them or produce warnings or ...
  def convert_predicate(bnode = %BlankNode{}), do: bnode
  def convert_predicate(uri) when is_atom(uri) or is_binary(uri), do: RDF.uri(uri)
  def convert_predicate(arg), do: raise RDF.Triple.InvalidPredicateError, predicate: arg

  @doc false
  def convert_object(uri)
  def convert_object(uri = %URI{}), do: uri
  def convert_object(literal = %Literal{}), do: literal
  def convert_object(bnode = %BlankNode{}), do: bnode
  def convert_object(atom) when is_atom(atom), do: RDF.uri(atom)
  def convert_object(arg), do: Literal.new(arg)

  @doc false
  def convert_graph_name(uri)
  def convert_graph_name(nil), do: nil
  def convert_graph_name(uri = %URI{}), do: uri
  def convert_graph_name(bnode = %BlankNode{}), do: bnode
  def convert_graph_name("_:" <> identifier), do: RDF.bnode(identifier)
  def convert_graph_name(uri) when is_atom(uri) or is_binary(uri),
    do: RDF.uri(uri)
  def convert_graph_name(arg),
    do: raise RDF.Quad.InvalidGraphContextError, graph_context: arg

end
