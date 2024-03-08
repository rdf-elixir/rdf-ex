defmodule RDF.Statement do
  @moduledoc """
  Helper functions for RDF statements.

  An RDF statement is either a `RDF.Triple` or a `RDF.Quad`.
  """

  alias RDF.{Resource, BlankNode, IRI, Literal, Quad, Term, Triple, PropertyMap}
  import RDF.Guards

  @type subject :: Resource.t()
  @type predicate :: Resource.t()
  @type object :: Resource.t() | Literal.t()
  @type graph_name :: Resource.t() | nil

  @type coercible_subject :: Resource.coercible()
  @type coercible_predicate :: Resource.coercible()
  @type coercible_object :: object | any
  @type coercible_graph_name :: graph_name | atom | String.t()

  @type position :: :subject | :predicate | :object | :graph_name
  @type qualified_term :: {position, Term.t() | nil}
  @type term_mapping :: (qualified_term -> any | nil)

  @type t :: Triple.t() | Quad.t()
  @type coercible :: Triple.coercible() | Quad.coercible()

  @doc """
  Creates a `RDF.Triple` or `RDF.Quad` with proper RDF values.

  An error is raised when the given elements are not coercible to RDF values.

  Note: The `RDF.statement` function is a shortcut to this function.

  ## Examples

      iex> RDF.Statement.new({EX.S, EX.p, 42})
      {RDF.iri("http://example.com/S"), RDF.iri("http://example.com/p"), RDF.literal(42)}

      iex> RDF.Statement.new({EX.S, EX.p, 42, EX.Graph})
      {RDF.iri("http://example.com/S"), RDF.iri("http://example.com/p"), RDF.literal(42), RDF.iri("http://example.com/Graph")}

      iex> RDF.Statement.new({EX.S, :p, 42, EX.Graph}, RDF.PropertyMap.new(p: EX.p))
      {RDF.iri("http://example.com/S"), RDF.iri("http://example.com/p"), RDF.literal(42), RDF.iri("http://example.com/Graph")}
  """
  def new(tuple, property_map \\ nil)
  def new({_, _, _} = tuple, property_map), do: Triple.new(tuple, property_map)
  def new({_, _, _, _} = tuple, property_map), do: Quad.new(tuple, property_map)

  defdelegate new(s, p, o), to: Triple, as: :new
  defdelegate new(s, p, o, g), to: Quad, as: :new

  @doc """
  The subject component of a statement.

  ## Examples

      iex> RDF.Statement.subject {"http://example.com/S", "http://example.com/p", 42}
      ~I<http://example.com/S>
  """
  def subject(statement) when tuple_size(statement) in [3, 4],
    do: statement |> elem(0) |> coerce_subject()

  @doc """
  The predicate component of a statement.

  ## Examples

      iex> RDF.Statement.predicate {"http://example.com/S", "http://example.com/p", 42}
      ~I<http://example.com/p>
  """
  def predicate(statement) when tuple_size(statement) in [3, 4],
    do: statement |> elem(1) |> coerce_predicate()

  @doc """
  The object component of a statement.

  ## Examples

      iex> RDF.Statement.object {"http://example.com/S", "http://example.com/p", 42}
      RDF.literal(42)
  """
  def object(statement) when tuple_size(statement) in [3, 4],
    do: statement |> elem(2) |> coerce_object()

  @doc """
  The graph name component of a statement.

  ## Examples

      iex> RDF.Statement.graph_name {"http://example.com/S", "http://example.com/p", 42, "http://example.com/Graph"}
      ~I<http://example.com/Graph>
      iex> RDF.Statement.graph_name {"http://example.com/S", "http://example.com/p", 42}
      nil
  """
  def graph_name(statement)
  def graph_name({_, _, _, graph_name}), do: coerce_graph_name(graph_name)
  def graph_name({_, _, _}), do: nil

  @doc """
  Creates a `RDF.Statement` tuple with proper RDF values.

  An error is raised when the given elements are not coercible to RDF values.

  ## Examples

      iex> RDF.Statement.coerce {"http://example.com/S", "http://example.com/p", 42}
      {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42)}
      iex> RDF.Statement.coerce {"http://example.com/S", "http://example.com/p", 42, "http://example.com/Graph"}
      {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42), ~I<http://example.com/Graph>}
  """
  @spec coerce(coercible(), PropertyMap.t() | nil) :: Triple.t() | Quad.t()
  def coerce(statement, property_map \\ nil)
  def coerce({_, _, _} = triple, property_map), do: Triple.new(triple, property_map)
  def coerce({_, _, _, _} = quad, property_map), do: Quad.new(quad, property_map)

  @doc """
  Coerces the given `value` to a valid subject of an RDF statement.

  Raises an `RDF.Triple.InvalidSubjectError` when the value can not be coerced.
  """
  @spec coerce_subject(coercible_subject) :: subject
  def coerce_subject(value)
  def coerce_subject(%IRI{} = iri), do: iri
  def coerce_subject(%BlankNode{} = bnode), do: bnode
  def coerce_subject("_:" <> identifier), do: BlankNode.new(identifier)
  def coerce_subject(iri) when is_binary(iri) or maybe_ns_term(iri), do: IRI.new!(iri)
  def coerce_subject(arg), do: raise(RDF.Triple.InvalidSubjectError, subject: arg)

  @doc """
  Coerces the given `value` to a valid predicate of an RDF statement.

  Raises an `RDF.Triple.InvalidPredicateError` when the value can not be coerced.
  """
  @spec coerce_predicate(coercible_predicate) :: predicate
  def coerce_predicate(value)
  def coerce_predicate(%IRI{} = iri), do: iri
  # Note: Although, RDF does not allow blank nodes for properties, JSON-LD allows
  # them, by introducing the notion of "generalized RDF".
  # TODO: Support an option `:strict_rdf` to explicitly disallow them or produce warnings or ...
  def coerce_predicate(%BlankNode{} = bnode), do: bnode
  def coerce_predicate(iri) when is_binary(iri) or maybe_ns_term(iri), do: IRI.new!(iri)
  def coerce_predicate(arg), do: raise(RDF.Triple.InvalidPredicateError, predicate: arg)

  @doc """
  Coerces the given `term` to a valid predicate of an RDF statement using a `RDF.PropertyMap`.

  Raises an `RDF.Triple.InvalidPredicateError` when the value can not be coerced.
  """
  @spec coerce_predicate(coercible_predicate, PropertyMap.t()) :: predicate
  def coerce_predicate(term, context)

  def coerce_predicate(term, %PropertyMap{} = property_map) when is_atom(term) do
    PropertyMap.iri(property_map, term) || coerce_predicate(term)
  end

  def coerce_predicate(term, _), do: coerce_predicate(term)

  @doc """
  Coerces the given `value` to a valid object of an RDF statement.
  """
  @spec coerce_object(coercible_object) :: object
  def coerce_object(value)
  def coerce_object(%IRI{} = iri), do: iri
  def coerce_object(%Literal{} = literal), do: literal
  def coerce_object(%BlankNode{} = bnode), do: bnode
  def coerce_object(bool) when is_boolean(bool), do: Literal.new(bool)
  def coerce_object(atom) when maybe_ns_term(atom), do: IRI.new(atom)
  def coerce_object(arg), do: Literal.new(arg)

  @doc """
  Coerces the given `value` to a valid graph context of an RDF statement.

  Raises an `RDF.Quad.InvalidGraphContextError` when the value can not be coerced.
  """
  @spec coerce_graph_name(coercible_graph_name) :: graph_name
  def coerce_graph_name(value)
  def coerce_graph_name(nil), do: nil
  def coerce_graph_name(%IRI{} = iri), do: iri
  def coerce_graph_name(%BlankNode{} = bnode), do: bnode
  def coerce_graph_name("_:" <> identifier), do: BlankNode.new(identifier)
  def coerce_graph_name(iri) when is_binary(iri) or maybe_ns_term(iri), do: IRI.new!(iri)

  def coerce_graph_name(arg),
    do: raise(RDF.Quad.InvalidGraphContextError, graph_context: arg)

  @doc """
  Returns a tuple of native Elixir values from a `RDF.Statement` of RDF terms.

  When a `:context` option is given with a `RDF.PropertyMap`, predicates will
  be mapped to the terms defined in the `RDF.PropertyMap`, if present.

  Returns `nil` if one of the components of the given tuple is not convertible via `RDF.Term.value/1`.

  ## Examples

      iex> RDF.Statement.values {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42)}
      {"http://example.com/S", "http://example.com/p", 42}

      iex> RDF.Statement.values {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42), ~I<http://example.com/Graph>}
      {"http://example.com/S", "http://example.com/p", 42, "http://example.com/Graph"}

      iex> {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42)}
      ...> |> RDF.Statement.values(context: %{p: ~I<http://example.com/p>})
      {"http://example.com/S", :p, 42}

  """
  @spec values(t, keyword) :: Triple.mapping_value() | Quad.mapping_value() | nil
  def values(quad, opts \\ [])
  def values({_, _, _} = triple, opts), do: Triple.values(triple, opts)
  def values({_, _, _, _} = quad, opts), do: Quad.values(quad, opts)

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

      iex> {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42), ~I<http://example.com/Graph>}
      ...> |> RDF.Statement.map(fn
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
  @spec map(t, term_mapping()) :: Triple.mapping_value() | Quad.mapping_value() | nil | nil
  def map(statement, fun)
  def map({_, _, _} = triple, fun), do: RDF.Triple.map(triple, fun)
  def map({_, _, _, _} = quad, fun), do: RDF.Quad.map(quad, fun)

  @doc false
  @spec default_term_mapping(qualified_term) :: any | nil
  def default_term_mapping(qualified_term)
  def default_term_mapping({:graph_name, nil}), do: nil
  def default_term_mapping({_, term}), do: RDF.Term.value(term)

  @spec default_property_mapping(PropertyMap.t()) :: term_mapping
  def default_property_mapping(%PropertyMap{} = property_map) do
    fn
      {:predicate, predicate} ->
        PropertyMap.term(property_map, predicate) || default_term_mapping({:predicate, predicate})

      other ->
        default_term_mapping(other)
    end
  end

  @doc """
  Checks if the given tuple is a valid RDF statement, i.e. RDF triple or quad.

  The elements of a valid RDF statement must be RDF terms. On the subject
  position only IRIs and blank nodes allowed, while on the predicate and graph
  context position only IRIs allowed. The object position can be any RDF term.
  """
  @spec valid?(Triple.t() | Quad.t() | any) :: boolean
  def valid?(tuple)

  def valid?({subject, predicate, object}) do
    valid_subject?(subject) && valid_predicate?(predicate) && valid_object?(object)
  end

  def valid?({subject, predicate, object, graph_name}) do
    valid_subject?(subject) && valid_predicate?(predicate) && valid_object?(object) &&
      valid_graph_name?(graph_name)
  end

  def valid?(_), do: false

  @spec valid_subject?(subject | any) :: boolean
  def valid_subject?(%IRI{}), do: true
  def valid_subject?(%BlankNode{}), do: true
  def valid_subject?(_), do: false

  @spec valid_predicate?(predicate | any) :: boolean
  def valid_predicate?(%IRI{}), do: true
  def valid_predicate?(_), do: false

  @spec valid_object?(object | any) :: boolean
  def valid_object?(%IRI{}), do: true
  def valid_object?(%BlankNode{}), do: true
  def valid_object?(%Literal{}), do: true
  def valid_object?(_), do: false

  @spec valid_graph_name?(graph_name | any) :: boolean
  def valid_graph_name?(%IRI{}), do: true
  def valid_graph_name?(_), do: false

  @doc """
  Returns a list of all `RDF.BlankNode`s within the given `statement`.
  """
  @spec bnodes(t) :: list(BlankNode.t())
  def bnodes(statement)
  def bnodes({_, _, _, _} = quad), do: Quad.bnodes(quad)
  def bnodes({_, _, _} = triple), do: Triple.bnodes(triple)

  @doc """
  Returns whether the given `statement` contains a blank node.
  """
  @spec has_bnode?(t) :: boolean
  def has_bnode?({_, _, _, _} = quad), do: Quad.has_bnode?(quad)
  def has_bnode?({_, _, _} = triple), do: Triple.has_bnode?(triple)

  @doc """
  Returns whether the given `value` is a component of the given `statement`.
  """
  @spec include_value?(t, any) :: boolean
  def include_value?({_, _, _, _} = quad, value), do: Quad.include_value?(quad, value)
  def include_value?({_, _, _} = triple, value), do: Triple.include_value?(triple, value)
end
