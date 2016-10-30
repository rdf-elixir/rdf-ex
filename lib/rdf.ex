defmodule RDF do
  alias RDF.{Vocabulary, Literal, BlankNode, Triple}

  defmodule InvalidURIError, do: defexception [:message]

  @doc """
  Generator function for URIs from strings or term atoms of a `RDF.Vocabulary`.

  ## Examples

      iex> RDF.uri("http://www.example.com/foo")
      %URI{authority: "www.example.com", fragment: nil, host: "www.example.com",
       path: "/foo", port: 80, query: nil, scheme: "http", userinfo: nil}

      iex> RDF.uri(RDF.RDFS.Class)
      %URI{authority: "www.w3.org", fragment: "Class", host: "www.w3.org",
       path: "/2000/01/rdf-schema", port: 80, query: nil, scheme: "http",
       userinfo: nil}

      iex> RDF.uri("not a uri")
      ** (RDF.InvalidURIError) string "not a uri" is not a valid URI
  """
  @spec uri(URI.t | binary | atom) :: URI.t
  def uri(atom) when is_atom(atom), do: Vocabulary.__uri__(atom)
  def uri(string) do
    parsed_uri = URI.parse(string)
    if uri?(parsed_uri) do
      parsed_uri
    else
      raise InvalidURIError, ~s(string "#{string}" is not a valid URI)
    end
  end

  @doc """
  Checks if the given value is an URI.

  ## Examples

      iex> RDF.uri?("http://www.example.com/foo")
      true
      iex> RDF.uri?("not a uri")
      false
  """
  def uri?(some_uri = %URI{}) do
    # The following was a suggested at http://stackoverflow.com/questions/30696761/check-if-a-url-is-valid-in-elixir
    # TODO: Find a better way! Maybe https://github.com/marcelog/ex_rfc3986 ?
    case some_uri do
      %URI{scheme: nil} -> false
      %URI{host:   nil} -> false
      %URI{path:   nil} -> false
      _uri -> true
    end
  end
  def uri?(value) when is_binary(value), do: uri?(URI.parse(value))
  def uri?(_), do: false


  @doc """
  Generator function for `RDF.Literal` values.

  ## Examples

      iex> RDF.literal(42)
      %RDF.Literal{value: 42, language: nil,
        datatype: %URI{authority: "www.w3.org", fragment: "integer",
        host: "www.w3.org", path: "/2001/XMLSchema", port: 80,
         query: nil, scheme: "http", userinfo: nil}}
  """
  def literal(value)

  def literal(lit = %Literal{}), do: lit
  def literal(value),            do: Literal.new(value)
  def literal(value, type),      do: Literal.new(value, type)

  @doc """
  Generator function for `RDF.Triple`s.

  ## Examples

      iex> RDF.triple("http://example.com/S", "http://example.com/p", 42)
      {RDF.uri("http://example.com/S"), RDF.uri("http://example.com/p"), RDF.literal(42)}
  """
  def triple(subject, predicate, object), do: Triple.new(subject, predicate, object)
  def triple(tuple), do: Triple.new(tuple)


  @doc """
  Generator function for `RDF.BlankNodes`.
  """
  def bnode, do: BlankNode.new

  @doc """
  Generator function for `RDF.BlankNodes` with a user-defined identity.

  ## Examples

      iex> RDF.bnode(:foo)
      %RDF.BlankNode{id: :foo}
  """
  def bnode(id), do: BlankNode.new(id)


################################################################################
# temporary manual RDF vocab definitions
# TODO: These should be defined as a vocabulary

  def langString do
    uri("http://www.w3.org/1999/02/22-rdf-syntax-ns#langString")
  end

end
