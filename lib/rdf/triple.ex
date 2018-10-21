defmodule RDF.Triple do
  @moduledoc """
  Helper functions for RDF triples.

  A RDF Triple is represented as a plain Elixir tuple consisting of three valid
  RDF values for subject, predicate and object.
  """

  alias RDF.{Statement, Term}

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

  ## Examples

      iex> RDF.Triple.values {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42)}
      {"http://example.com/S", "http://example.com/p", 42}

  """
  def values({subject, predicate, object}) do
    with subject_value   when not is_nil(subject_value)   <- Term.value(subject),
         predicate_value when not is_nil(predicate_value) <- Term.value(predicate),
         object_value    when not is_nil(object_value)    <- Term.value(object)
    do
      {subject_value, predicate_value, object_value}
    end
  end

  def values(_), do: nil

end
