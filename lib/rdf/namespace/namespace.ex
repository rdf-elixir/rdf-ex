defmodule RDF.Namespace do
  @moduledoc """
  A behaviour and generator for modules of terms resolving to `RDF.IRI`s.

  Note: A `RDF.Namespace` is NOT a IRI namespace! The terms of a `RDF.Namespace` don't
  have to necessarily refer to IRIs from the same IRI namespace. "Namespace" here is
  just meant in the sense that an Elixir module is a namespace. Most of the

  Most of the time you'll want to use a `RDF.Vocabulary.Namespace`, a special type of
  `RDF.Namespace` where all terms indeed resolve to IRIs of a shared base URI namespace.

  For an introduction into `RDF.Namespace`s and `RDF.Vocabulary.Namespace`s see
  [this guide](https://rdf-elixir.dev/rdf-ex/namespaces.html).
  """

  alias RDF.IRI
  alias RDF.Namespace.Builder

  import RDF.Guards

  @type t :: module

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

  @doc """
  A macro to define a `RDF.Namespace`.

  ## Example

      defmodule YourApp.NS do
        import RDF.Namespace

        defnamespace EX, [
                       foo: ~I<http://example1.com/foo>,
                       Bar: "http://example2.com/Bar",
                     ]
      end

  > #### Warning {: .warning}
  >
  > This macro is intended to be used at compile-time, i.e. in the body of a
  > `defmodule` definition. If you want to create `RDF.Namespace`s dynamically
  > at runtime, please use `create/4`.

  """
  defmacro defnamespace(module, term_mapping, opts \\ []) do
    env = Macro.Env.prune_compile_info(__CALLER__)
    module = fully_qualified_module(module, env)

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

  @doc """
  Creates a `RDF.Namespace` module with the given name and term mapping dynamically.

  The line where the module is defined and its file must be passed as options.
  """
  defdelegate create(module, term_mapping, location, opts \\ []), to: Builder

  @doc """
  Creates a `RDF.Namespace` module with the given name and term mapping dynamically.

  The line where the module is defined and its file must be passed as options.
  """
  defdelegate create!(module, term_mapping, location, opts \\ []), to: Builder

  @doc false
  def fully_qualified_module({:__aliases__, _, module}, env) do
    Module.concat([env.module | module])
  end

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
    case resolve_term(expr) do
      {:ok, iri} -> iri
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
    if namespace?(namespace) do
      namespace.__resolve_term__(term)
    else
      {:error, %RDF.Namespace.UndefinedTermError{message: "#{namespace} is not a RDF.Namespace"}}
    end
  end

  @doc """
  A macro to let a module act as a specified `RDF.Namespace` or `RDF.Vocabulary.Namespace`.

  ## Example

      defmodule Example.NS do
        use RDF.Vocabulary.Namespace

        defvocab Example,
          base_iri: "http://www.example.com/ns/",
          terms: [:Foo, :bar]
      end

      defmodule Example do
        import RDF.Namespace

        act_as_namespace Example.NS.Example

        # your application functions
      end

      Example.Foo |> Example.bar(42)

  """
  defmacro act_as_namespace({:__aliases__, _, ns_alias} = ns_expr) do
    ns_mod = Module.concat(ns_alias)
    ns_type = type(ns_mod)

    external_resources =
      ns_mod.__info__(:attributes) |> Keyword.get(:external_resource) |> List.wrap()

    unless ns_type do
      raise "#{ns_mod} is not a RDF.Namespace"
    end

    quote do
      @behaviour RDF.Namespace

      Enum.each(unquote(external_resources), fn external_resource ->
        @external_resource external_resource
      end)

      defdelegate __resolve_term__(term), to: unquote(ns_expr)
      defdelegate __terms__, to: unquote(ns_expr)
      defdelegate __iris__, to: unquote(ns_expr)

      if unquote(ns_type) == RDF.Vocabulary.Namespace do
        defdelegate __base_iri__, to: unquote(ns_expr)
        defdelegate __term_aliases__, to: unquote(ns_expr)
        defdelegate __file__, to: unquote(ns_expr)
        defdelegate __strict__, to: unquote(ns_expr)
      end
    end
    |> inject_property_defdelegates(ns_mod)
  end

  defmacro act_as_namespace(_) do
    raise "invalid namespace expression"
  end

  defp inject_property_defdelegates({:__block__, [], block}, ns) do
    property_function_defdelegates =
      for property <- ns.__terms__(), RDF.Utils.downcase?(property) do
        {:__block__, [], property_defdelegates} =
          quote do
            defdelegate unquote(property)(), to: unquote(ns)
            defdelegate unquote(property)(subject), to: unquote(ns)
            defdelegate unquote(property)(subject, objects), to: unquote(ns)
          end

        property_defdelegates
      end

    {:__block__, [], block ++ property_function_defdelegates}
  end

  defp type(mod) do
    cond do
      RDF.Vocabulary.Namespace.vocabulary_namespace?(mod) -> RDF.Vocabulary.Namespace
      namespace?(mod) -> RDF.Namespace
      true -> nil
    end
  end

  @doc false
  @spec namespace?(module) :: boolean
  def namespace?(name) do
    case Code.ensure_compiled(name) do
      {:module, name} -> function_exported?(name, :__resolve_term__, 1)
      _ -> false
    end
  end
end
