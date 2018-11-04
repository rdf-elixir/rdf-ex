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
  Returns a tuple of native Elixir values from a `RDF.Statement` of RDF terms.

  Returns `nil` if one of the components of the given tuple is not convertible via `RDF.Term.value/1`.

  The optional second argument allows to specify a custom mapping with a function
  which will receive a tuple `{statement_position, rdf_term}` where
  `statement_position` is one of the atoms `:subject`, `:predicate`, `:object` or
  `:graph_name`, while `rdf_term` is the RDF term to be mapped. When the given
  function returns `nil` this will be interpreted as an error and will become
  the overhaul result of the `values/2` call.

  ## Examples

      iex> RDF.Statement.values {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42)}
      {"http://example.com/S", "http://example.com/p", 42}
      iex> RDF.Statement.values {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42), ~I<http://example.com/Graph>}
      {"http://example.com/S", "http://example.com/p", 42, "http://example.com/Graph"}

      iex> {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42), ~I<http://example.com/Graph>}
      ...> |> RDF.Statement.values(fn
      ...>      {:subject, subject} ->
      ...>        subject |> to_string() |> String.last()
      ...>      {:predicate, predicate} ->
      ...>        predicate |> to_string() |> String.last() |> String.to_atom()
      ...>      {:object, object} ->
      ...>        RDF.Term.value(object)
      ...>      {:graph_name, graph_name} ->
      ...>        graph_name
      ...>    end)
      {"S", :p, 42, ~I<http://example.com/Graph>}

  """
  def values(statement, mapping \\ &default_term_mapping/1)
  def values({_, _, _} = triple, mapping),  do: RDF.Triple.values(triple, mapping)
  def values({_, _, _, _} = quad, mapping), do: RDF.Quad.values(quad, mapping)
  def values(_, _), do: nil

  @doc false
  def default_term_mapping(qualified_term)
  def default_term_mapping({:graph_name, nil}), do: nil
  def default_term_mapping({_, term}), do: RDF.Term.value(term)

end
