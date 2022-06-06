defmodule RDF.Namespace.IRI do
  @moduledoc """
  Provides the `iri/1` macro to resolve IRI values inside of pattern matches.
  """

  @doc """
  A macro which allows to resolve IRI values inside of pattern matches.

  Terms of a `RDF.Namespace` (which includes terms of `RDF.Vocabulary.Namespace`)
  can't be resolved in pattern matches. This macro allows just that, by wrapping
  the terms in a pattern match with a call of this macro.

  Note: Only literal values are allowed as arguments of this macro, since the argument
  expression needs to be evaluated at compile-time.


  ## Example

      import RDF.Namespace.IRI

      case expr do
        iri(EX.Foo) -> ...
        iri(EX.bar()) -> ...
        ...
      end

  """
  defmacro iri({{:., _, [{:__aliases__, _, _} = module_alias, _fun_name]}, _, []} = expr) do
    {module, _} = Code.eval_quoted(module_alias, [], __CALLER__)

    if RDF.Namespace.namespace?(module) do
      resolve_to_iri(expr, __CALLER__)
    else
      forbidden_iri_expr(expr)
    end
  end

  defmacro iri({:__aliases__, _, _} = expr), do: resolve_to_iri(expr, __CALLER__)

  defmacro iri(expr), do: forbidden_iri_expr(expr)

  defp resolve_to_iri(expr, env) do
    {value, _} = Code.eval_quoted(expr, [], env)
    iri = RDF.IRI.new(value)

    quote do
      unquote(Macro.escape(iri))
    end
  end

  defp forbidden_iri_expr(expr) do
    raise ArgumentError, "forbidden expression in RDF.Guard.iri/1 call: #{Macro.to_string(expr)}"
  end
end
