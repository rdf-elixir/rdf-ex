defmodule RDF.Namespace do
  @moduledoc """
  A behaviour for resolvers of module atoms to URIs.

  Currently there's only one type of such namespaces: `RDF.Vocabulary.Namespace`,
  but other types are thinkable and might be implemented in the future, eg.
  namespaces for JSON-LD contexts.
  """

  @doc """
  Resolves a term to an URI.
  """
  @callback __resolve_term__(atom) :: URI.t

  @doc """
  All terms of a `RDF.Namespace`.
  """
  @callback __terms__() :: [atom]


  @doc """
  Resolves a qualified term to an URI.

  It determines a `RDF.Namespace` from the qualifier of the given term and
  delegates to remaining part of the term to `__resolve_term__/1` of this
  determined namespace.
  """
  def resolve_term(expr)

  def resolve_term(uri = %URI{}),
    do: uri
  def resolve_term(namespaced_term) when is_atom(namespaced_term),
    do: namespaced_term |> to_string() |> do_resolve_term()

  defp do_resolve_term("Elixir." <> _ = namespaced_term) do
    {term, namespace} =
      namespaced_term
      |> Module.split
      |> List.pop_at(-1)
    {term, namespace} = {String.to_atom(term), Module.concat(namespace)}
    if Keyword.has_key?(namespace.__info__(:functions), :__resolve_term__) do
      namespace.__resolve_term__(term)
    else
      raise RDF.Namespace.UndefinedTermError,
        "#{namespaced_term} is not a term on a RDF.Namespace"
    end
  end

  defp do_resolve_term(namespaced_term) do
    raise RDF.Namespace.UndefinedTermError,
      "#{namespaced_term} is not a term on a RDF.Namespace"
  end

end
