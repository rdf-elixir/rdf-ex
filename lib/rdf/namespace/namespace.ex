defmodule RDF.Namespace do
  @moduledoc """
  A behaviour for resolvers of atoms to `RDF.IRI`s.

  Currently there's only one type of such namespaces: `RDF.Vocabulary.Namespace`,
  but other types are thinkable and might be implemented in the future, eg.
  namespaces for JSON-LD contexts.
  """

  alias RDF.IRI
  alias RDF.Namespace.Builder

  import RDF.Guards

  @doc """
  Resolves a term to a `RDF.IRI`.
  """
  @callback __resolve_term__(atom) :: {:ok, IRI.t()} | {:error, Exception.t()}

  @doc """
  All terms of a `RDF.Namespace`.
  """
  @callback __terms__ :: [atom]

  @doc """
  All `RDF.IRI`s of a `RDF.Namespace`.
  """
  @callback __iris__ :: [IRI.t()]

  defmacro defnamespace({:__aliases__, _, [module]}, term_mapping, opts \\ []) do
    env = __CALLER__
    module = module(env, module)

    quote do
      result =
        Builder.create!(
          unquote(module),
          unquote(term_mapping),
          unquote(Macro.escape(env)),
          unquote(opts)
        )

      alias unquote(module)

      result
    end
  end

  defdelegate create(module, term_mapping, location), to: Builder
  defdelegate create(module, term_mapping, location, opts), to: Builder
  defdelegate create!(module, term_mapping, location), to: Builder
  defdelegate create!(module, term_mapping, location, opts), to: Builder

  @doc false
  def module(env, module), do: Module.concat(env.module, module)

  @doc """
  Resolves a qualified term to a `RDF.IRI`.

  It determines a `RDF.Namespace` from the qualifier of the given term and
  delegates to remaining part of the term to `__resolve_term__/1` of this
  determined namespace.
  """
  @spec resolve_term(IRI.t() | module) :: {:ok, IRI.t()} | {:error, Exception.t()}
  def resolve_term(expr)

  def resolve_term(%IRI{} = iri), do: {:ok, iri}

  def resolve_term(namespaced_term) when maybe_ns_term(namespaced_term) do
    namespaced_term
    |> to_string()
    |> do_resolve_term()
  end

  @doc """
  Resolves a qualified term to a `RDF.IRI` or raises an error when that's not possible.

  See `resolve_term/1` for more.
  """
  @spec resolve_term!(IRI.t() | module) :: IRI.t()
  def resolve_term!(expr) do
    with {:ok, iri} <- resolve_term(expr) do
      iri
    else
      {:error, error} -> raise error
    end
  end

  defp do_resolve_term("Elixir." <> _ = namespaced_term) do
    {term, namespace} =
      namespaced_term
      |> Module.split()
      |> List.pop_at(-1)

    do_resolve_term(Module.concat(namespace), String.to_atom(term))
  end

  defp do_resolve_term(namespaced_term) do
    {:error,
     %RDF.Namespace.UndefinedTermError{
       message: "#{namespaced_term} is not a term on a RDF.Namespace"
     }}
  end

  defp do_resolve_term(RDF, term), do: do_resolve_term(RDF.NS.RDF, term)

  defp do_resolve_term(Elixir, term) do
    {:error,
     %RDF.Namespace.UndefinedTermError{
       message: "#{term} is not a RDF.Namespace; top-level modules can't be RDF.Namespaces"
     }}
  end

  defp do_resolve_term(namespace, term) do
    is_module =
      case Code.ensure_compiled(namespace) do
        {:module, _} -> true
        _ -> false
      end

    if is_module and Keyword.has_key?(namespace.__info__(:functions), :__resolve_term__) do
      namespace.__resolve_term__(term)
    else
      {:error, %RDF.Namespace.UndefinedTermError{message: "#{namespace} is not a RDF.Namespace"}}
    end
  end
end
