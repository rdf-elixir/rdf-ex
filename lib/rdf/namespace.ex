defmodule RDF.Namespace do
  @moduledoc """
  A `RDF.Namespace` is a module ...

  TODO: Rewrite this

  A `RDF.Namespace` is a collection of URIs and serves as a namespace for its
  elements, called terms. The terms can be accessed by qualification on the
  resp. namespace module.

  ## Using a `RDF.Namespace`

  There are two types of terms in a `RDF.Namespace`, which are resolved
  differently:

  1. Lowercased terms (usually used for RDF properties, but this is not
    enforced) are represented as functions on a Vocabulary module and return the
    URI directly.
  2. Capitalized terms are by standard Elixir semantics modules names, i.e.
    atoms. In all places in RDF.ex, where an URI is expected, you can use atoms
    qualified with a `RDF.Namespace` directly, but if you want to resolve it
    manually, you can pass the `RDF.Namespace` qualified atom to `RDF.uri`.

  Examples:

      iex> RDF.NS.RDFS.subClassOf
      %URI{authority: "www.w3.org", fragment: "subClassOf", host: "www.w3.org",
       path: "/2000/01/rdf-schema", port: 80, query: nil, scheme: "http",
       userinfo: nil}
      iex> RDF.NS.RDFS.Class
      RDF.NS.RDFS.Class
      iex> RDF.uri(RDF.NS.RDFS.Class)
      %URI{authority: "www.w3.org", fragment: "Class", host: "www.w3.org",
       path: "/2000/01/rdf-schema", port: 80, query: nil, scheme: "http",
       userinfo: nil}
      iex> alias RDF.NS.RDFS
      iex> RDF.triple(RDFS.Class, RDFS.subClassOf, RDFS.Resource)
      {RDF.uri(RDFS.Class), RDF.uri(RDFS.subClassOf), RDF.uri(RDFS.Resource)}

  """

  @callback __resolve_term__(atom) :: URI.t

  @callback __terms__() :: [atom]


  def resolve_term(expr)

  def resolve_term(uri = %URI{}), do: uri

  def resolve_term(namespaced_atom) when is_atom(namespaced_atom) do
    {term, namespace} =
      namespaced_atom
      |> Module.split
      |> List.pop_at(-1)
    {term, namespace} = {String.to_atom(term), Module.concat(namespace)}
    namespace.__resolve_term__(term)
  end

end
