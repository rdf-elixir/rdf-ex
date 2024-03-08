defmodule RDF.Quad do
  @moduledoc """
  Helper functions for RDF quads.

  An RDF Quad is represented as a plain Elixir tuple consisting of four valid
  RDF values for subject, predicate, object and a graph name.
  """

  alias RDF.{Statement, BlankNode, PropertyMap}

  @type t :: {
          Statement.subject(),
          Statement.predicate(),
          Statement.object(),
          Statement.graph_name()
        }

  @type coercible ::
          {
            Statement.coercible_subject(),
            Statement.coercible_predicate(),
            Statement.coercible_object(),
            Statement.coercible_graph_name()
          }

  @type mapping_value :: {String.t(), String.t(), any, String.t()}

  @doc """
  Creates a `RDF.Quad` with proper RDF values.

  An error is raised when the given elements are not coercible to RDF values.

  Note: The `RDF.quad` function is a shortcut to this function.

  ## Examples

      iex> RDF.Quad.new("http://example.com/S", "http://example.com/p", 42, "http://example.com/Graph")
      {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42), ~I<http://example.com/Graph>}

      iex> RDF.Quad.new(EX.S, EX.p, 42, EX.Graph)
      {RDF.iri("http://example.com/S"), RDF.iri("http://example.com/p"), RDF.literal(42), RDF.iri("http://example.com/Graph")}

      iex> RDF.Quad.new(EX.S, :p, 42, EX.Graph, RDF.PropertyMap.new(p: EX.p))
      {RDF.iri("http://example.com/S"), RDF.iri("http://example.com/p"), RDF.literal(42), RDF.iri("http://example.com/Graph")}
  """
  @spec new(
          Statement.coercible_subject(),
          Statement.coercible_predicate(),
          Statement.coercible_object(),
          Statement.coercible_graph_name(),
          PropertyMap.t() | nil
        ) :: t
  def new(subject, predicate, object, graph_name, property_map \\ nil)

  def new(subject, predicate, object, graph_name, nil) do
    {
      Statement.coerce_subject(subject),
      Statement.coerce_predicate(predicate),
      Statement.coerce_object(object),
      Statement.coerce_graph_name(graph_name)
    }
  end

  def new(subject, predicate, object, graph_name, %PropertyMap{} = property_map) do
    {
      Statement.coerce_subject(subject),
      Statement.coerce_predicate(predicate, property_map),
      Statement.coerce_object(object),
      Statement.coerce_graph_name(graph_name)
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

      iex> RDF.Quad.new {EX.S, EX.p, 42}
      {RDF.iri("http://example.com/S"), RDF.iri("http://example.com/p"), RDF.literal(42), nil}

      iex> RDF.Quad.new {EX.S, :p, 42, EX.Graph}, RDF.PropertyMap.new(p: EX.p)
      {RDF.iri("http://example.com/S"), RDF.iri("http://example.com/p"), RDF.literal(42), RDF.iri("http://example.com/Graph")}
  """
  @spec new(Statement.coercible(), PropertyMap.t() | nil) :: t
  def new(statement, property_map \\ nil)

  def new({subject, predicate, object, graph_name}, property_map) do
    new(subject, predicate, object, graph_name, property_map)
  end

  def new({subject, predicate, object}, property_map) do
    new(subject, predicate, object, nil, property_map)
  end

  @doc """
  Returns a list of all `RDF.BlankNode`s within the given `quad`.
  """
  @spec bnodes(t) :: list(BlankNode.t())
  def bnodes(quad)
  def bnodes({%BlankNode{} = b, _, %BlankNode{} = b, %BlankNode{} = b}), do: [b]
  def bnodes({%BlankNode{} = s, _, %BlankNode{} = b, %BlankNode{} = b}), do: [s, b]
  def bnodes({%BlankNode{} = b, _, %BlankNode{} = o, %BlankNode{} = b}), do: [b, o]
  def bnodes({%BlankNode{} = b, _, %BlankNode{} = b, %BlankNode{} = g}), do: [b, g]
  def bnodes({%BlankNode{} = s, _, %BlankNode{} = o, %BlankNode{} = g}), do: [s, o, g]
  def bnodes({%BlankNode{} = b, _, %BlankNode{} = b, _}), do: [b]
  def bnodes({%BlankNode{} = s, _, %BlankNode{} = o, _}), do: [s, o]
  def bnodes({%BlankNode{} = b, _, _, %BlankNode{} = b}), do: [b]
  def bnodes({%BlankNode{} = s, _, _, %BlankNode{} = g}), do: [s, g]
  def bnodes({_, _, %BlankNode{} = b, %BlankNode{} = b}), do: [b]
  def bnodes({_, _, %BlankNode{} = o, %BlankNode{} = g}), do: [o, g]
  def bnodes({%BlankNode{} = s, _, _, _}), do: [s]
  def bnodes({_, _, %BlankNode{} = o, _}), do: [o]
  def bnodes(_), do: []

  @doc """
  Returns whether the given `quad` contains a blank node.
  """
  @spec has_bnode?(t) :: boolean
  def has_bnode?({%BlankNode{}, _, _, _}), do: true
  def has_bnode?({_, %BlankNode{}, _, _}), do: true
  def has_bnode?({_, _, %BlankNode{}, _}), do: true
  def has_bnode?({_, _, _, %BlankNode{}}), do: true
  def has_bnode?({_, _, _, _}), do: false

  @doc """
  Returns whether the given `value` is a component of the given `triple`.
  """
  @spec include_value?(t, any) :: boolean
  def include_value?({value, _, _, _}, value), do: true
  def include_value?({_, value, _, _}, value), do: true
  def include_value?({_, _, value, _}, value), do: true
  def include_value?({_, _, _, value}, value), do: true
  def include_value?({_, _, _, _}), do: false

  @doc """
  Returns a tuple of native Elixir values from a `RDF.Quad` of RDF terms.

  When a `:context` option is given with a `RDF.PropertyMap`, predicates will
  be mapped to the terms defined in the `RDF.PropertyMap`, if present.

  Returns `nil` if one of the components of the given tuple is not convertible via `RDF.Term.value/1`.

  ## Examples

      iex> RDF.Quad.values {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42), ~I<http://example.com/Graph>}
      {"http://example.com/S", "http://example.com/p", 42, "http://example.com/Graph"}

      iex> {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42), ~I<http://example.com/Graph>}
      ...> |> RDF.Quad.values(context: %{p: ~I<http://example.com/p>})
      {"http://example.com/S", :p, 42,  "http://example.com/Graph"}

  """
  @spec values(t, keyword) :: mapping_value | nil
  def values(quad, opts \\ []) do
    if property_map = PropertyMap.from_opts(opts) do
      map(quad, Statement.default_property_mapping(property_map))
    else
      map(quad, &Statement.default_term_mapping/1)
    end
  end

  @doc """
  Returns a tuple where each element from a `RDF.Quad` is mapped with the given function.

  Returns `nil` if one of the components of the given tuple is not convertible via `RDF.Term.value/1`.

  The function `fun` will receive a tuple `{statement_position, rdf_term}` where
  `statement_position` is one of the atoms `:subject`, `:predicate`, `:object` or
  `:graph_name` while `rdf_term` is the RDF term to be mapped. When the given function
  returns `nil` this will be interpreted as an error and will become the overhaul
  result of the `map/2` call.

  ## Examples

      iex> {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42), ~I<http://example.com/Graph>}
      ...> |> RDF.Quad.map(fn
      ...>      {:object, object} ->
      ...>        RDF.Term.value(object)
      ...>      {:graph_name, graph_name} ->
      ...>        graph_name
      ...>      {_, resource} ->
      ...>        resource |> to_string() |> String.last() |> String.to_atom()
      ...>    end)
      {:S, :p, 42, ~I<http://example.com/Graph>}

  """
  @spec map(t, Statement.term_mapping()) :: mapping_value | nil
  def map({subject, predicate, object, graph_name}, fun) do
    with subject_value when not is_nil(subject_value) <- fun.({:subject, subject}),
         predicate_value when not is_nil(predicate_value) <- fun.({:predicate, predicate}),
         object_value when not is_nil(object_value) <- fun.({:object, object}),
         graph_name_value <- fun.({:graph_name, graph_name}) do
      {subject_value, predicate_value, object_value, graph_name_value}
    else
      _ -> nil
    end
  end

  @doc """
  Checks if the given tuple is a valid RDF quad.

  The elements of a valid RDF quad must be RDF terms. On the subject
  position only IRIs and blank nodes allowed, while on the predicate and graph
  name position only IRIs allowed. The object position can be any RDF term.
  """
  @spec valid?(t | any) :: boolean
  def valid?(tuple)
  def valid?({_, _, _, _} = quad), do: Statement.valid?(quad)
  def valid?(_), do: false
end
