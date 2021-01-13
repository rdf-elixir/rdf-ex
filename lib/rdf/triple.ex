defmodule RDF.Triple do
  @moduledoc """
  Helper functions for RDF triples.

  An RDF Triple is represented as a plain Elixir tuple consisting of three valid
  RDF values for subject, predicate and object.
  """

  alias RDF.{Statement, PropertyMap}

  @type t :: {Statement.subject(), Statement.predicate(), Statement.object()}

  @type t_values :: {String.t(), String.t(), any}

  @doc """
  Creates a `RDF.Triple` with proper RDF values.

  An error is raised when the given elements are not coercible to RDF values.

  Note: The `RDF.triple` function is a shortcut to this function.

  ## Examples

      iex> RDF.Triple.new("http://example.com/S", "http://example.com/p", 42)
      {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42)}

      iex> RDF.Triple.new(EX.S, EX.p, 42)
      {RDF.iri("http://example.com/S"), RDF.iri("http://example.com/p"), RDF.literal(42)}

      iex> RDF.Triple.new(EX.S, :p, 42, RDF.PropertyMap.new(p: EX.p))
      {RDF.iri("http://example.com/S"), RDF.iri("http://example.com/p"), RDF.literal(42)}
  """
  @spec new(
          Statement.coercible_subject(),
          Statement.coercible_predicate(),
          Statement.coercible_object(),
          PropertyMap.t() | nil
        ) :: t
  def new(subject, predicate, object, property_map \\ nil)

  def new(subject, predicate, object, nil) do
    {
      Statement.coerce_subject(subject),
      Statement.coerce_predicate(predicate),
      Statement.coerce_object(object)
    }
  end

  def new(subject, predicate, object, %PropertyMap{} = property_map) do
    {
      Statement.coerce_subject(subject),
      Statement.coerce_predicate(predicate, property_map),
      Statement.coerce_object(object)
    }
  end

  @doc """
  Creates a `RDF.Triple` with proper RDF values.

  An error is raised when the given elements are not coercible to RDF values.

  Note: The `RDF.triple` function is a shortcut to this function.

  ## Examples

      iex> RDF.Triple.new {"http://example.com/S", "http://example.com/p", 42}
      {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42)}

      iex> RDF.Triple.new {EX.S, EX.p, 42}
      {RDF.iri("http://example.com/S"), RDF.iri("http://example.com/p"), RDF.literal(42)}

      iex> RDF.Triple.new {EX.S, EX.p, 42, EX.Graph}
      {RDF.iri("http://example.com/S"), RDF.iri("http://example.com/p"), RDF.literal(42)}

      iex> RDF.Triple.new {EX.S, :p, 42}, RDF.PropertyMap.new(p: EX.p)
      {RDF.iri("http://example.com/S"), RDF.iri("http://example.com/p"), RDF.literal(42)}
  """
  @spec new(Statement.coercible_t(), PropertyMap.t() | nil) :: t
  def new(statement, property_map \\ nil)

  def new({subject, predicate, object}, property_map),
    do: new(subject, predicate, object, property_map)

  def new({subject, predicate, object, _}, property_map),
    do: new(subject, predicate, object, property_map)

  @doc """
  Returns a tuple of native Elixir values from a `RDF.Triple` of RDF terms.

  When a `:context` option is given with a `RDF.PropertyMap`, predicates will
  be mapped to the terms defined in the `RDF.PropertyMap`, if present.

  Returns `nil` if one of the components of the given tuple is not convertible via `RDF.Term.value/1`.

  ## Examples

      iex> RDF.Triple.values {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42)}
      {"http://example.com/S", "http://example.com/p", 42}

      iex> {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42)}
      ...> |> RDF.Triple.values(context: %{p: ~I<http://example.com/p>})
      {"http://example.com/S", :p, 42}

  """
  @spec values(t, keyword) :: t_values | nil
  def values(triple, opts \\ []) do
    if property_map = PropertyMap.from_opts(opts) do
      map(triple, Statement.default_property_mapping(property_map))
    else
      map(triple, &Statement.default_term_mapping/1)
    end
  end

  @doc """
  Returns a triple where each element from a `RDF.Triple` is mapped with the given function.

  Returns `nil` if one of the components of the given tuple is not convertible via `RDF.Term.value/1`.

  The function `fun` will receive a tuple `{statement_position, rdf_term}` where
  `statement_position` is one of the atoms `:subject`, `:predicate` or `:object`,
  while `rdf_term` is the RDF term to be mapped. When the given function returns
  `nil` this will be interpreted as an error and will become the overhaul result
  of the `map/2` call.

  ## Examples

      iex> {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42)}
      ...> |> RDF.Triple.map(fn
      ...>      {:object, object} -> RDF.Term.value(object)
      ...>      {_, term}         -> term |> to_string() |> String.last()
      ...>    end)
      {"S", "p", 42}

  """
  @spec map(t, Statement.term_mapping()) :: t_values | nil
  def map({subject, predicate, object}, fun) do
    with subject_value when not is_nil(subject_value) <- fun.({:subject, subject}),
         predicate_value when not is_nil(predicate_value) <- fun.({:predicate, predicate}),
         object_value when not is_nil(object_value) <- fun.({:object, object}) do
      {subject_value, predicate_value, object_value}
    else
      _ -> nil
    end
  end

  @doc """
  Checks if the given tuple is a valid RDF triple.

  The elements of a valid RDF triple must be RDF terms. On the subject
  position only IRIs and blank nodes allowed, while on the predicate position
  only IRIs allowed. The object position can be any RDF term.
  """
  @spec valid?(t | any) :: boolean
  def valid?(tuple)
  def valid?({_, _, _} = triple), do: Statement.valid?(triple)
  def valid?(_), do: false
end
