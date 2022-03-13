defmodule RDF.Star.Quad do
  @moduledoc """
  Helper functions for RDF-star quads.

  An RDF-star quad is represented as a plain Elixir tuple consisting of four valid
  RDF values for subject, predicate, object and a graph name.
  As opposed to an `RDF.Quad` the subject or object can be a triple.
  """

  alias RDF.Star.Statement
  alias RDF.PropertyMap

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

  @doc """
  Creates a `RDF.Star.Quad` with proper RDF-star values.

  An error is raised when the given elements are not coercible to RDF-star values.

  Note: The `RDF.quad` function is a shortcut to this function.

  ## Examples

      iex> RDF.Star.Quad.new("http://example.com/S", "http://example.com/p", 42, "http://example.com/Graph")
      {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42), ~I<http://example.com/Graph>}

      iex> RDF.Star.Quad.new(EX.S, EX.p, 42, EX.Graph)
      {RDF.iri("http://example.com/S"), RDF.iri("http://example.com/p"), RDF.literal(42), RDF.iri("http://example.com/Graph")}

      iex> RDF.Star.Quad.new(EX.S, :p, 42, EX.Graph, RDF.PropertyMap.new(p: EX.p))
      {RDF.iri("http://example.com/S"), RDF.iri("http://example.com/p"), RDF.literal(42), RDF.iri("http://example.com/Graph")}

      iex> RDF.Star.Quad.new(EX.S, :p, 42, EX.Graph, RDF.PropertyMap.new(p: EX.p))
      {RDF.iri("http://example.com/S"), RDF.iri("http://example.com/p"), RDF.literal(42), RDF.iri("http://example.com/Graph")}

      iex> RDF.Star.Quad.new({EX.S, :p, 42}, :p2, 43, EX.Graph, RDF.PropertyMap.new(p: EX.p, p2: EX.p2))
      {{~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42)}, ~I<http://example.com/p2>, RDF.literal(43), ~I<http://example.com/Graph>}

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
      Statement.coerce_subject(subject, property_map),
      Statement.coerce_predicate(predicate, property_map),
      Statement.coerce_object(object, property_map),
      Statement.coerce_graph_name(graph_name)
    }
  end

  @doc """
  Creates a `RDF.Star.Quad` with proper RDF-star values.

  An error is raised when the given elements are not coercible to RDF-star values.

  Note: The `RDF.quad` function is a shortcut to this function.

  ## Examples

      iex> RDF.Star.Quad.new {"http://example.com/S", "http://example.com/p", 42, "http://example.com/Graph"}
      {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42), ~I<http://example.com/Graph>}

      iex> RDF.Star.Quad.new {EX.S, EX.p, 42, EX.Graph}
      {RDF.iri("http://example.com/S"), RDF.iri("http://example.com/p"), RDF.literal(42), RDF.iri("http://example.com/Graph")}

      iex> RDF.Star.Quad.new {EX.S, EX.p, 42}
      {RDF.iri("http://example.com/S"), RDF.iri("http://example.com/p"), RDF.literal(42), nil}

      iex> RDF.Star.Quad.new {EX.S, :p, 42, EX.Graph}, RDF.PropertyMap.new(p: EX.p)
      {RDF.iri("http://example.com/S"), RDF.iri("http://example.com/p"), RDF.literal(42), RDF.iri("http://example.com/Graph")}

      iex> RDF.Star.Quad.new({{EX.S, :p, 42}, :p2, 43, EX.Graph}, RDF.PropertyMap.new(p: EX.p, p2: EX.p2))
      {{~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42)}, ~I<http://example.com/p2>, RDF.literal(43), ~I<http://example.com/Graph>}

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
  Checks if the given tuple is a valid RDF quad.

  The elements of a valid RDF-star quad must be RDF terms. On the subject position
  only IRIs, blank nodes and triples are allowed, while on the predicate and graph name
  position only IRIs allowed. The object position can be any RDF term or triple.
  """
  @spec valid?(t | any) :: boolean
  def valid?(tuple)
  def valid?({_, _, _, _} = quad), do: Statement.valid?(quad)
  def valid?(_), do: false
end
