defmodule RDF.Triple do
  @moduledoc """
  Helper functions for RDF triples.

  A RDF Triple is represented as a plain Elixir tuple consisting of three valid
  RDF values for subject, predicate and object.
  """

  alias RDF.Statement

  @type t :: {Statement.subject, Statement.predicate, Statement.object}


  @doc """
  Creates a `RDF.Triple` with proper RDF values.

  An error is raised when the given elements are not coercible to RDF values.

  Note: The `RDF.triple` function is a shortcut to this function.

  ## Examples

      iex> RDF.Triple.new("http://example.com/S", "http://example.com/p", 42)
      {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42)}
      iex> RDF.Triple.new(EX.S, EX.p, 42)
      {RDF.iri("http://example.com/S"), RDF.iri("http://example.com/p"), RDF.literal(42)}
  """
  def new(subject, predicate, object) do
    {
      Statement.coerce_subject(subject),
      Statement.coerce_predicate(predicate),
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
  """
  def new({subject, predicate, object}), do: new(subject, predicate, object)


  @doc """
  Returns a tuple of native Elixir values from a `RDF.Triple` of RDF terms.

  Returns `nil` if one of the components of the given tuple is not convertible via `RDF.Term.value/1`.

  The optional second argument allows to specify a custom mapping with a function
  which will receive a tuple `{statement_position, rdf_term}` where
  `statement_position` is one of the atoms `:subject`, `:predicate` or `:object`,
  while `rdf_term` is the RDF term to be mapped. When the given function returns
  `nil` this will be interpreted as an error and will become the overhaul result
  of the `values/2` call.

  ## Examples

      iex> RDF.Triple.values {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42)}
      {"http://example.com/S", "http://example.com/p", 42}

      iex> {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42)}
      ...> |> RDF.Triple.values(fn
      ...>      {:object, object} -> RDF.Term.value(object)
      ...>      {_, term}         -> term |> to_string() |> String.last()
      ...>    end)
      {"S", "p", 42}

  """
  def values(triple, mapping \\ &Statement.default_term_mapping/1)

  def values({subject, predicate, object}, mapping) do
    with subject_value when not is_nil(subject_value)     <- mapping.({:subject, subject}),
         predicate_value when not is_nil(predicate_value) <- mapping.({:predicate, predicate}),
         object_value when not is_nil(object_value)       <- mapping.({:object, object})
    do
      {subject_value, predicate_value, object_value}
    else
      _ -> nil
    end
  end

  def values(_, _), do: nil


  @doc """
  Checks if the given tuple is a valid RDF triple.

  The elements of a valid RDF triple must be RDF terms. On the subject
  position only IRIs and blank nodes allowed, while on the predicate position
  only IRIs allowed. The object position can be any RDF term.
  """
  def valid?(tuple)
  def valid?({_, _, _} = triple), do: Statement.valid?(triple)
  def valid?(_), do: false

end
