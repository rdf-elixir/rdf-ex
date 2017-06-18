defmodule RDF do
  @moduledoc """
  The top-level module of RDF.ex.

  RDF.ex consists of:

  - modules for the nodes of an RDF graph
    - URIs are (currently) represented via Elixirs `URI` struct and should be
      constructed with `RDF.uri/1`
    - `RDF.BlankNode`
    - `RDF.Literal`
  - a facility for the mapping of URIs of a vocabulary to Elixir modules and
    functions: `RDF.Vocabulary.Namespace`
  - modules for the construction of statements
    - `RDF.Triple`
    - `RDF.Quad`
    - `RDF.Statement`
  - modules for collections of statements
    - `RDF.Description`
    - `RDF.Graph`
    - `RDF.Dataset`
    - `RDF.Data`
  - the foundations for the definition of RDF serialization formats
    - `RDF.Serialization`
    - `RDF.Serialization.Decoder`
    - `RDF.Serialization.Encoder`
  - and the implementation of two basic RDF serialization formats
    - `RDF.NTriples`
    - `RDF.NQuads`

  This top-level module provides shortcut functions for the construction of the
  basic elements and structures of RDF and some general helper functions.

  For a general introduction you may refer to the [README](readme.html).
  """

  alias RDF.{Namespace, Literal, BlankNode, Triple, Quad,
             Description, Graph, Dataset}

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


  @doc """
  Checks if the given value is an URI.

  ## Examples

      iex> RDF.uri?("http://www.example.com/foo")
      true
      iex> RDF.uri?("not a uri")
      false
  """
  def uri?(some_uri = %URI{}) do
    # The following was suggested at http://stackoverflow.com/questions/30696761/check-if-a-url-is-valid-in-elixir
    # TODO: Find a better way! Maybe <https://github.com/marcelog/ex_rfc3986>?
    case some_uri do
      %URI{scheme: nil} -> false
      _uri -> true
    end
  end
  def uri?(value) when is_binary(value), do: uri?(URI.parse(value))
  def uri?(_), do: false


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
    with parsed_uri = URI.parse(string) do
      if uri?(parsed_uri) do
        parsed_uri
      else
        raise RDF.InvalidURIError, ~s(string "#{string}" is not a valid URI)
      end
    end
  end


  defdelegate bnode(),   to: BlankNode, as: :new
  defdelegate bnode(id), to: BlankNode, as: :new

  defdelegate literal(value),       to: Literal, as: :new
  defdelegate literal(value, opts), to: Literal, as: :new

  defdelegate triple(s, p, o),  to: Triple, as: :new
  defdelegate triple(tuple),    to: Triple, as: :new

  defdelegate quad(s, p, o, g), to: Quad, as: :new
  defdelegate quad(tuple),      to: Quad, as: :new

  defdelegate description(arg),               to: Description, as: :new
  defdelegate description(arg1, arg2),        to: Description, as: :new
  defdelegate description(arg1, arg2, arg3),  to: Description, as: :new

  defdelegate graph(),                        to: Graph, as: :new
  defdelegate graph(arg),                     to: Graph, as: :new
  defdelegate graph(arg1, arg2),              to: Graph, as: :new
  defdelegate graph(arg1, arg2, arg3),        to: Graph, as: :new
  defdelegate graph(arg1, arg2, arg3, arg4),  to: Graph, as: :new

  defdelegate dataset(),                      to: Dataset, as: :new
  defdelegate dataset(arg),                   to: Dataset, as: :new
  defdelegate dataset(arg1, arg2),            to: Dataset, as: :new


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
