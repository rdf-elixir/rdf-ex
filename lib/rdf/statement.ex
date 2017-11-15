defmodule RDF.Statement do
  @moduledoc """
  Helper functions for RDF statements.

  A RDF statement is either a `RDF.Triple` or a `RDF.Quad`.
  """

  alias RDF.{Triple, Quad, IRI, BlankNode, Literal}

  @type subject    :: IRI.t | BlankNode.t
  @type predicate  :: IRI.t
  @type object     :: IRI.t | BlankNode.t | Literal.t
  @type graph_name :: IRI.t | BlankNode.t

  @type coercible_subject    :: subject    | atom | String.t
  @type coercible_predicate  :: predicate  | atom | String.t
  @type coercible_object     :: object     | atom | String.t # TODO: all basic Elixir types coercible to Literals
  @type coercible_graph_name :: graph_name | atom | String.t


  @doc """
  Creates a `RDF.Statement` tuple with proper RDF values.

  An error is raised when the given elements are not coercible to RDF values.

  ## Examples

      iex> RDF.Statement.coerce {"http://example.com/S", "http://example.com/p", 42}
      {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42)}
      iex> RDF.Statement.coerce {"http://example.com/S", "http://example.com/p", 42, "http://example.com/Graph"}
      {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42), ~I<http://example.com/Graph>}
  """
  def coerce(statement)
  def coerce({_, _, _} = triple),  do: Triple.new(triple)
  def coerce({_, _, _, _} = quad), do: Quad.new(quad)

  @doc false
  def coerce_subject(iri)
  def coerce_subject(iri = %IRI{}), do: iri
  def coerce_subject(bnode = %BlankNode{}), do: bnode
  def coerce_subject("_:" <> identifier), do: RDF.bnode(identifier)
  def coerce_subject(iri) when is_atom(iri) or is_binary(iri), do: RDF.iri!(iri)
  def coerce_subject(arg), do: raise RDF.Triple.InvalidSubjectError, subject: arg

  @doc false
  def coerce_predicate(iri)
  def coerce_predicate(iri = %IRI{}), do: iri
  # Note: Although, RDF does not allow blank nodes for properties, JSON-LD allows
  # them, by introducing the notion of "generalized RDF".
  # TODO: Support an option `:strict_rdf` to explicitly disallow them or produce warnings or ...
  def coerce_predicate(bnode = %BlankNode{}), do: bnode
  def coerce_predicate(iri) when is_atom(iri) or is_binary(iri), do: RDF.iri!(iri)
  def coerce_predicate(arg), do: raise RDF.Triple.InvalidPredicateError, predicate: arg

  @doc false
  def coerce_object(iri)
  def coerce_object(iri = %IRI{}), do: iri
  def coerce_object(literal = %Literal{}), do: literal
  def coerce_object(bnode = %BlankNode{}), do: bnode
  def coerce_object(bool) when is_boolean(bool), do: Literal.new(bool)
  def coerce_object(atom) when is_atom(atom), do: RDF.iri(atom)
  def coerce_object(arg), do: Literal.new(arg)

  @doc false
  def coerce_graph_name(iri)
  def coerce_graph_name(nil), do: nil
  def coerce_graph_name(iri = %IRI{}), do: iri
  def coerce_graph_name(bnode = %BlankNode{}), do: bnode
  def coerce_graph_name("_:" <> identifier), do: RDF.bnode(identifier)
  def coerce_graph_name(iri) when is_atom(iri) or is_binary(iri), do: RDF.iri!(iri)
  def coerce_graph_name(arg),
    do: raise RDF.Quad.InvalidGraphContextError, graph_context: arg


  @doc """
  Creates a `RDF.Statement` by mapping the nodes of another statement.

  The input nodes are coerced to proper RDF values, but the returned tuple is not
  coerced. If wanted, this could be easily achieved by piping the result through
  `RDF.Statement.coerce/1`.

  ## Examples

      iex> RDF.Statement.map {EX.S, EX.p, EX.O}, fn node -> to_string(node) <> "1" end
      {"http://example.com/S1", "http://example.com/p1", "http://example.com/O1"}
      iex> RDF.Statement.map {EX.S, EX.p, EX.O, EX.G}, fn node -> to_string(node) <> "1" end
      {"http://example.com/S1", "http://example.com/p1", "http://example.com/O1", "http://example.com/G1"}
  """
  def map(statement, f)

  def map({s, p, o}, f) do
    {
      (s |> coerce_subject()   |> f.()),
      (p |> coerce_predicate() |> f.()),
      (o |> coerce_object()    |> f.())
    }
  end

  def map({s, p, o, g}, f) do
    {
      (s |> coerce_subject()    |> f.()),
      (p |> coerce_predicate()  |> f.()),
      (o |> coerce_object()     |> f.()),
      (g |> coerce_graph_name() |> f.())
    }
  end


  def has_bnode?({_, _, _, _} = quad), do: Quad.has_bnode?(quad)
  def has_bnode?({_, _, _} = triple),  do: Triple.has_bnode?(triple)

  def include_value?({_, _, _, _} = quad, value), do: Quad.include_value?(quad, value)
  def include_value?({_, _, _} = triple, value),  do: Triple.include_value?(triple, value)

end
