defmodule RDF do
  alias RDF.{Namespace, Literal, BlankNode, Triple, Quad}

  @doc """
  Generator function for URIs from strings or term atoms of a `RDF.Namespace`.

  This function is used for the `~I` sigil.

  ## Examples

      iex> RDF.uri("http://www.example.com/foo")
      %URI{authority: "www.example.com", fragment: nil, host: "www.example.com",
       path: "/foo", port: 80, query: nil, scheme: "http", userinfo: nil}

      iex> RDF.uri(RDF.NS.RDFS.Class)
      %URI{authority: "www.w3.org", fragment: "Class", host: "www.w3.org",
       path: "/2000/01/rdf-schema", port: 80, query: nil, scheme: "http",
       userinfo: nil}

      iex> RDF.uri("not a uri")
      ** (RDF.InvalidURIError) string "not a uri" is not a valid URI
  """
  @spec uri(URI.t | binary | atom) :: URI.t
  def uri(atom) when is_atom(atom), do: Namespace.resolve_term(atom)

  def uri(string) do
    parsed_uri = URI.parse(string)
    if uri?(parsed_uri) do
      parsed_uri
    else
      raise RDF.InvalidURIError, ~s(string "#{string}" is not a valid URI)
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
      _uri -> true
    end
  end
  def uri?(value) when is_binary(value), do: uri?(URI.parse(value))
  def uri?(_), do: false


  @doc """
  Generator function for `RDF.Literal` values.

  ## Examples

      iex> RDF.literal(42)
      %RDF.Literal{value: 42, datatype: XSD.integer}
  """
  def literal(value)

  def literal(lit = %Literal{}), do: lit
  def literal(value),            do: Literal.new(value)
  def literal(value, opts),      do: Literal.new(value, opts)

  @doc """
  Generator function for `RDF.Triple`s.

  ## Examples

      iex> RDF.triple("http://example.com/S", "http://example.com/p", 42)
      {RDF.uri("http://example.com/S"), RDF.uri("http://example.com/p"), RDF.literal(42)}
      iex> RDF.triple(EX.S, EX.p, 42)
      {RDF.uri("http://example.com/S"), RDF.uri("http://example.com/p"), RDF.literal(42)}
  """
  def triple(subject, predicate, object), do: Triple.new(subject, predicate, object)
  def triple(tuple), do: Triple.new(tuple)

  @doc """
  Generator function for `RDF.quad`s.

  ## Examples

      iex> RDF.quad("http://example.com/S", "http://example.com/p", 42, "http://example.com/Graph")
      {RDF.uri("http://example.com/S"), RDF.uri("http://example.com/p"), RDF.literal(42), RDF.uri("http://example.com/Graph")}
      iex> RDF.quad(EX.S, EX.p, 42, EX.Graph)
      {RDF.uri("http://example.com/S"), RDF.uri("http://example.com/p"), RDF.literal(42), RDF.uri("http://example.com/Graph")}
  """
  def quad(subject, predicate, object, graph_context),
    do: Quad.new(subject, predicate, object, graph_context)
  def quad(tuple), do: Quad.new(tuple)


  @doc """
  Generator function for `RDF.BlankNode`s.
  """
  def bnode, do: BlankNode.new

  @doc """
  Generator function for `RDF.BlankNode`s with a user-defined identity.

  ## Examples

      iex> RDF.bnode(:foo)
      %RDF.BlankNode{id: "foo"}
  """
  def bnode(id), do: BlankNode.new(id)


  @doc """
  Checks if the given value is a RDF resource.

  ## Examples

      iex> RDF.resource?(RDF.uri("http://example.com/resource"))
      true
      iex> RDF.resource?(EX.resource)
      true
      iex> RDF.resource?(RDF.bnode)
      true
      iex> RDF.resource?(42)
      false
  """
  def resource?(value)
  def resource?(%URI{}), do: true
  def resource?(atom) when is_atom(atom), do: resource?(Namespace.resolve_term(atom))
  def resource?(%BlankNode{}), do: true
  def resource?(_), do: false


  for term <- ~w[type subject predicate object first rest value]a do
    defdelegate unquote(term)(),                      to: RDF.NS.RDF
    defdelegate unquote(term)(s, o),                  to: RDF.NS.RDF
    defdelegate unquote(term)(s, o1, o2),             to: RDF.NS.RDF
    defdelegate unquote(term)(s, o1, o2, o3),         to: RDF.NS.RDF
    defdelegate unquote(term)(s, o1, o2, o3, o4),     to: RDF.NS.RDF
    defdelegate unquote(term)(s, o1, o2, o3, o4, o5), to: RDF.NS.RDF
  end

  defdelegate langString(),   to: RDF.NS.RDF
  defdelegate unquote(nil)(), to: RDF.NS.RDF

end
