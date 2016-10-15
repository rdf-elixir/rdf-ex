defmodule RDF.Triple do
  @moduledoc """
  Defines a RDF Triple.

  A Triple is a plain Elixir tuple consisting of three valid RDF values for
  subject, predicate and object.
  """

  alias RDF.{BlankNode, Literal}

  @type subject :: URI.t | BlankNode.t
  @type predicate :: URI.t
  @type object :: URI.t | BlankNode.t | Literal.t

  @type convertible_subject :: subject | atom | String.t
  @type convertible_predicate :: predicate | atom | String.t
  @type convertible_object :: object | atom | String.t # TODO: all basic Elixir types convertible to Literals

  defmodule InvalidSubjectError do
    defexception [:subject]
    def message(%{subject: subject}),
      do: "'#{inspect(subject)}' is not a valid subject of a RDF.Triple"
  end

  defmodule InvalidPredicateError do
    defexception [:predicate]
    def message(%{predicate: predicate}),
      do: "'#{inspect(predicate)}' is not a valid predicate of a RDF.Triple"
  end

  @doc """
  Creates a `RDF.Triple` with proper RDF values.

  An error is raised when the given elements are not convertible to RDF values.

  Note: The `RDF.triple` function is a shortcut to this function.

  # Examples

      iex> RDF.Triple.new("http://example.com/S", "http://example.com/p", 42)
      {RDF.uri("http://example.com/S"), RDF.uri("http://example.com/p"), RDF.literal(42)}
  """
  def new(subject, predicate, object) do
    {
      convert_subject(subject),
      convert_predicate(predicate),
      convert_object(object)
    }
  end

  @doc """
  Creates a `RDF.Triple` with proper RDF values.

  An error is raised when the given elements are not convertible to RDF values.

  Note: The `RDF.triple` function is a shortcut to this function.

  # Examples

      iex> RDF.Triple.new {"http://example.com/S", "http://example.com/p", 42}
      {RDF.uri("http://example.com/S"), RDF.uri("http://example.com/p"), RDF.literal(42)}
  """
  def new({subject, predicate, object}), do: new(subject, predicate, object)


  @doc false
  def convert_subject(uri)
  def convert_subject(uri = %URI{}), do: uri
  def convert_subject(bnode = %BlankNode{}), do: bnode
  def convert_subject(uri) when is_atom(uri) or is_binary(uri), do: RDF.uri(uri)
  def convert_subject(arg), do: raise InvalidSubjectError, subject: arg

  @doc false
  def convert_predicate(uri)
  def convert_predicate(uri = %URI{}), do: uri
  def convert_predicate(uri) when is_atom(uri) or is_binary(uri), do: RDF.uri(uri)
  def convert_predicate(arg), do: raise InvalidPredicateError, predicate: arg

  @doc false
  def convert_object(uri)
  def convert_object(uri = %URI{}), do: uri
  def convert_object(literal = %Literal{}), do: literal
  def convert_object(bnode = %BlankNode{}), do: bnode
  def convert_object(atom) when is_atom(atom), do: RDF.uri(atom)
  def convert_object(arg), do: Literal.new(arg)

end
