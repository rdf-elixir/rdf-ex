defmodule RDF.Namespace do
  @moduledoc """
  A behaviour for resolvers of atoms to `RDF.IRI`s.

  Currently there's only one type of such namespaces: `RDF.Vocabulary.Namespace`,
  but other types are thinkable and might be implemented in the future, eg.
  namespaces for JSON-LD contexts.
  """

  alias RDF.IRI

  @doc """
  Resolves a term to a `RDF.IRI`.
  """
  @callback __resolve_term__(atom) :: IRI.t

  @doc """
  All terms of a `RDF.Namespace`.
  """
  @callback __terms__() :: [atom]


  @doc """
  Resolves a qualified term to a `RDF.IRI`.

  It determines a `RDF.Namespace` from the qualifier of the given term and
  delegates to remaining part of the term to `__resolve_term__/1` of this
  determined namespace.
  """
  @spec resolve_term(IRI.t | module) :: IRI.t
  def resolve_term(expr)

  def resolve_term(%IRI{} = iri), do: iri

  def resolve_term(namespaced_term) when is_atom(namespaced_term) do
    namespaced_term
    |> to_string()
    |> do_resolve_term()
  end


  defp do_resolve_term("Elixir." <> _ = namespaced_term) do
    {term, namespace} =
      namespaced_term
      |> Module.split
      |> List.pop_at(-1)
    do_resolve_term(Module.concat(namespace), String.to_atom(term))
  end

  defp do_resolve_term(namespaced_term) do
    raise RDF.Namespace.UndefinedTermError,
      "#{namespaced_term} is not a term on a RDF.Namespace"
  end

  defp do_resolve_term(RDF, term), do: do_resolve_term(RDF.NS.RDF, term)

  defp do_resolve_term(namespace, term) do
    is_module =
      case Code.ensure_compiled(namespace) do
        {:module, _} -> true
        _ -> false
      end

    if is_module and Keyword.has_key?(namespace.__info__(:functions), :__resolve_term__) do
      namespace.__resolve_term__(term)
    else
      raise RDF.Namespace.UndefinedTermError,
        "#{namespace} is not a RDF.Namespace"
    end
  end

end
