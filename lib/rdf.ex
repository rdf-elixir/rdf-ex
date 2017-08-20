defmodule RDF do
  @moduledoc """
  The top-level module of RDF.ex.

  RDF.ex consists of:

  - modules for the nodes of an RDF graph
    - `RDF.IRI`
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
    - `RDF.List`
  - the foundations for the definition of RDF serialization formats
    - `RDF.Serialization`
    - `RDF.Serialization.Decoder`
    - `RDF.Serialization.Encoder`
  - and the implementation of various RDF serialization formats
    - `RDF.NTriples`
    - `RDF.NQuads`
    - `RDF.Turtle`

  This top-level module provides shortcut functions for the construction of the
  basic elements and structures of RDF and some general helper functions.

  For a general introduction you may refer to the [README](readme.html).
  """

  alias RDF.{IRI, Namespace, Literal, BlankNode, Triple, Quad,
             Description, Graph, Dataset}

  @doc """
  Checks if the given value is a RDF resource.

  ## Examples

      iex> RDF.resource?(RDF.iri("http://example.com/resource"))
      true
      iex> RDF.resource?(EX.resource)
      true
      iex> RDF.resource?(RDF.bnode)
      true
      iex> RDF.resource?(42)
      false
  """
  def resource?(value)
  def resource?(%IRI{}),                  do: true
  def resource?(%BlankNode{}),            do: true
  def resource?(atom) when is_atom(atom), do: resource?(Namespace.resolve_term(atom))
  def resource?(_),                       do: false


  defdelegate uri?(value), to: IRI, as: :valid?
  defdelegate iri?(value), to: IRI, as: :valid?
  defdelegate uri(value),  to: IRI, as: :new
  defdelegate iri(value),  to: IRI, as: :new
  defdelegate uri!(value), to: IRI, as: :new!
  defdelegate iri!(value), to: IRI, as: :new!

  @doc """
  Checks if the given value is a blank node.

  ## Examples

      iex> RDF.bnode?(RDF.bnode)
      true
      iex> RDF.bnode?(RDF.iri("http://example.com/resource"))
      false
      iex> RDF.bnode?(42)
      false
  """
  def bnode?(%BlankNode{}), do: true
  def bnode?(_), do: false

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

  defdelegate list?(resource, graph), to: RDF.List, as: :node?
  defdelegate list?(description),     to: RDF.List, as: :node?

  def list(native_list),
    do: RDF.List.from(native_list)

  def list(head, %Graph{} = graph),
    do: RDF.List.new(head, graph)

  def list(native_list, opts),
    do: RDF.List.from(native_list, opts)



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

  defdelegate   __base_iri__(), to: RDF.NS.RDF
end
