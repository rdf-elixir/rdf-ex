defmodule RDF.Star.Triple do
  @moduledoc """
  Helper functions for RDF-star triples.

  An RDF-star triple is represented as a plain Elixir tuple consisting of three valid
  RDF values for subject, predicate and object.
  As opposed to an `RDF.Triple` the subject or object can be a triple itself.
  """

  alias RDF.Star.Statement
  alias RDF.PropertyMap

  @type t :: {Statement.subject(), Statement.predicate(), Statement.object()}

  @type coercible ::
          {
            Statement.coercible_subject(),
            Statement.coercible_predicate(),
            Statement.coercible_object()
          }

  @doc """
  Creates a `RDF.Star.Triple` with proper RDF-star values.

  An error is raised when the given elements are not coercible to RDF-star values.

  Note: The `RDF.triple` function is a shortcut to this function.

  ## Examples

      iex> RDF.Star.Triple.new({"http://example.com/S", "http://example.com/p", 42}, "http://example.com/p2", 43)
      {{~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42)}, ~I<http://example.com/p2>, RDF.literal(43)}

      iex> RDF.Star.Triple.new({EX.S, EX.p, 42}, EX.p2, 43)
      {{~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42)}, ~I<http://example.com/p2>, RDF.literal(43)}

      iex> RDF.Star.Triple.new(EX.S, EX.p, 42)
      {RDF.iri("http://example.com/S"), RDF.iri("http://example.com/p"), RDF.literal(42)}

      iex> RDF.Star.Triple.new({EX.S, :p, 42}, :p2, 43, RDF.PropertyMap.new(p: EX.p, p2: EX.p2))
      {{~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42)}, ~I<http://example.com/p2>, RDF.literal(43)}
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
      Statement.coerce_subject(subject, property_map),
      Statement.coerce_predicate(predicate, property_map),
      Statement.coerce_object(object, property_map)
    }
  end

  @doc """
  Creates a `RDF.Star.Triple` with proper RDF-star values.

  An error is raised when the given elements are not coercible to RDF-star values.

  Note: The `RDF.triple` function is a shortcut to this function.

  ## Examples

      iex> RDF.Star.Triple.new {"http://example.com/S", "http://example.com/p", 42}
      {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42)}

      iex> RDF.Star.Triple.new {EX.S, EX.p, 42}
      {RDF.iri("http://example.com/S"), RDF.iri("http://example.com/p"), RDF.literal(42)}

      iex> RDF.Star.Triple.new {EX.S, EX.p, 42, EX.Graph}
      {RDF.iri("http://example.com/S"), RDF.iri("http://example.com/p"), RDF.literal(42)}

      iex> RDF.Star.Triple.new {EX.S, :p, 42}, RDF.PropertyMap.new(p: EX.p)
      {RDF.iri("http://example.com/S"), RDF.iri("http://example.com/p"), RDF.literal(42)}

      iex> RDF.Star.Triple.new({{EX.S, :p, 42}, :p2, 43}, RDF.PropertyMap.new(p: EX.p, p2: EX.p2))
      {{~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42)}, ~I<http://example.com/p2>, RDF.literal(43)}
  """
  @spec new(Statement.coercible(), PropertyMap.t() | nil) :: t
  def new(statement, property_map \\ nil)

  def new({subject, predicate, object}, property_map),
    do: new(subject, predicate, object, property_map)

  def new({subject, predicate, object, _}, property_map),
    do: new(subject, predicate, object, property_map)

  @doc """
  Checks if the given tuple is a valid RDF-star triple.

  The elements of a valid RDF-star triple must be RDF terms. On the subject
  position only IRIs, blank nodes and triples are allowed, while on the predicate
  position only IRIs allowed. The object position can be any RDF term or triple.
  """
  @spec valid?(t | any) :: boolean
  def valid?(tuple)
  def valid?({_, _, _} = triple), do: Statement.valid?(triple)
  def valid?(_), do: false
end
