defmodule RDF.Namespace.IRI do
  @moduledoc """
  Provides the `term_to_iri/1` macro to resolve IRI values inside of pattern matches.
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
        term_to_iri(EX.Foo) -> ...
        term_to_iri(EX.bar()) -> ...
        ...
      end

  """
  defmacro term_to_iri({{:., _, [{:__aliases__, _, _} = module_alias, fun_name]}, _, []}) do
    {module, _} = Code.eval_quoted(module_alias, [], __CALLER__)

    resolve_fun_call(module, fun_name, Macro.Env.stacktrace(__CALLER__))
  end

  defmacro term_to_iri({{:., _, [module, fun_name]}, _, _}) do
    resolve_fun_call(module, fun_name, Macro.Env.stacktrace(__CALLER__))
  end

  defmacro term_to_iri({:__aliases__, _, _} = expr) do
    {value, _} = Code.eval_quoted(expr, [], __CALLER__)
    resolve_module(value, Macro.Env.stacktrace(__CALLER__))
  end

  defmacro term_to_iri(atom) when is_atom(atom) do
    resolve_module(atom, Macro.Env.stacktrace(__CALLER__))
  end

  defmacro term_to_iri(expr) do
    raise_error(
      ArgumentError,
      "forbidden expression in #{inspect(__MODULE__)}.term_to_iri/1 call: #{Macro.to_string(expr)}",
      Macro.Env.stacktrace(__CALLER__)
    )
  end

  defp resolve_fun_call(module, fun_name, stacktrace) do
    if RDF.Namespace.namespace?(module) do
      do_resolve_fun_call(module, fun_name, stacktrace)
    else
      raise_error(ArgumentError, "#{inspect(module)} is not a RDF.Namespace", stacktrace)
    end
  end

  defp do_resolve_fun_call(module, fun_name, stacktrace) do
    module
    |> apply(fun_name, [])
    |> quote_result_iri()
  rescue
    error -> reraise error, stacktrace
  end

  defp resolve_module(module, stacktrace) do
    module
    |> RDF.IRI.new()
    |> quote_result_iri()
  rescue
    error -> reraise error, stacktrace
  end

  defp quote_result_iri(iri) do
    quote do
      unquote(Macro.escape(iri))
    end
  end

  defp raise_error(exception, message, stacktrace) do
    reraise exception, [message: message], stacktrace
  end
end
