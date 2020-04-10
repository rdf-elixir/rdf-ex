defmodule RDF.Quad do
  @moduledoc """
  Helper functions for RDF quads.

  A RDF Quad is represented as a plain Elixir tuple consisting of four valid
  RDF values for subject, predicate, object and a graph context.
  """

  alias RDF.Statement

  @type t :: {Statement.subject, Statement.predicate, Statement.object, Statement.graph_name}

  @type coercible_t ::
          {Statement.coercible_subject, Statement.coercible_predicate,
           Statement.coercible_object, Statement.coercible_graph_name}

  @type t_values :: {String.t, String.t, any, String.t}


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
  @spec new(
          Statement.coercible_subject,
          Statement.coercible_predicate,
          Statement.coercible_object,
          Statement.coercible_graph_name
        ) :: t
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
  @spec new(coercible_t) :: t
  def new({subject, predicate, object, graph_context}),
    do: new(subject, predicate, object, graph_context)


  @doc """
  Returns a tuple of native Elixir values from a `RDF.Quad` of RDF terms.

  Returns `nil` if one of the components of the given tuple is not convertible via `RDF.Term.value/1`.

  The optional second argument allows to specify a custom mapping with a function
  which will receive a tuple `{statement_position, rdf_term}` where
  `statement_position` is one of the atoms `:subject`, `:predicate`, `:object` or
  `:graph_name`, while `rdf_term` is the RDF term to be mapped. When the given
  function returns `nil` this will be interpreted as an error and will become
  the overhaul result of the `values/2` call.

  ## Examples

      iex> RDF.Quad.values {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42), ~I<http://example.com/Graph>}
      {"http://example.com/S", "http://example.com/p", 42, "http://example.com/Graph"}

      iex> {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42), ~I<http://example.com/Graph>}
      ...> |> RDF.Quad.values(fn
      ...>      {:object, object} ->
      ...>        RDF.Term.value(object)
      ...>      {:graph_name, graph_name} ->
      ...>        graph_name
      ...>      {_, resource} ->
      ...>        resource |> to_string() |> String.last() |> String.to_atom()
      ...>    end)
      {:S, :p, 42, ~I<http://example.com/Graph>}

  """
  @spec values(t | any, Statement.term_mapping) :: t_values | nil
  def values(quad, mapping \\ &Statement.default_term_mapping/1)

  def values({subject, predicate, object, graph_context}, mapping) do
    with subject_value when not is_nil(subject_value)     <- mapping.({:subject, subject}),
         predicate_value when not is_nil(predicate_value) <- mapping.({:predicate, predicate}),
         object_value when not is_nil(object_value)       <- mapping.({:object, object}),
         graph_context_value                              <- mapping.({:graph_name, graph_context})
    do
      {subject_value, predicate_value, object_value, graph_context_value}
    else
      _ -> nil
    end
  end

  def values(_, _), do: nil


  @doc """
  Checks if the given tuple is a valid RDF quad.

  The elements of a valid RDF quad must be RDF terms. On the subject
  position only IRIs and blank nodes allowed, while on the predicate and graph
  context position only IRIs allowed. The object position can be any RDF term.
  """
  @spec valid?(t | any) :: boolean
  def valid?(tuple)
  def valid?({_, _, _, _} = quad), do: Statement.valid?(quad)
  def valid?(_), do: false

end
