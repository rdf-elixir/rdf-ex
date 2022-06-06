defmodule RDF.Graph.Builder do
  alias RDF.{Description, Graph, Dataset, PrefixMap, IRI}

  defmodule Error do
    defexception [:message]
  end

  defmodule Helper do
    defdelegate a(), to: RDF.NS.RDF, as: :type
    defdelegate a(s, o), to: RDF.NS.RDF, as: :type
    defdelegate a(s, o1, o2), to: RDF.NS.RDF, as: :type
    defdelegate a(s, o1, o2, o3), to: RDF.NS.RDF, as: :type
    defdelegate a(s, o1, o2, o3, o4), to: RDF.NS.RDF, as: :type
    defdelegate a(s, o1, o2, o3, o4, o5), to: RDF.NS.RDF, as: :type

    def exclude(_), do: nil
  end

  def build({:__block__, _, block}, env, opts) do
    env_aliases = env_aliases(env)
    {declarations, data} = Enum.split_with(block, &declaration?/1)
    {base, declarations} = extract_base(declarations, env_aliases)
    base_string = base_string(base)
    data = resolve_relative_iris(data, base_string)
    declarations = resolve_relative_iris(declarations, base_string)
    {prefixes, declarations} = extract_prefixes(declarations, env_aliases)

    quote do
      alias RDF.XSD
      alias RDF.NS.{RDFS, OWL}

      import RDF.Sigils
      import Helper

      unquote(declarations)

      RDF.Graph.Builder.do_build(
        unquote(data),
        unquote(opts),
        unquote(prefixes),
        unquote(base_string)
      )
    end
  end

  def build(single, env, opts) do
    build({:__block__, [], List.wrap(single)}, env, opts)
  end

  @doc false
  def do_build(data, opts, prefixes, base) do
    RDF.graph(graph_opts(opts, prefixes, base))
    |> Graph.add(Enum.filter(data, &rdf?/1))
  end

  defp graph_opts(opts, prefixes, base) do
    opts
    |> set_base_opt(base)
    |> set_prefix_opt(prefixes)
  end

  defp set_base_opt(opts, nil), do: opts
  defp set_base_opt(opts, base), do: Keyword.put(opts, :base_iri, base)

  defp set_prefix_opt(opts, []), do: opts

  defp set_prefix_opt(opts, prefixes) do
    Keyword.update(opts, :prefixes, RDF.default_prefixes(prefixes), fn opt_prefixes ->
      PrefixMap.new(prefixes)
      |> PrefixMap.merge!(opt_prefixes, :ignore)
    end)
  end

  defp base_string(nil), do: nil
  defp base_string(base) when is_binary(base), do: base
  defp base_string(base) when is_atom(base), do: apply(base, :__base_iri__, [])
  defp base_string({:sigil_I, _, [{_, _, [base]}, _]}), do: base

  defp base_string(_) do
    raise Error,
      message: "invalid @base expression; only literal values are allowed as @base value"
  end

  defp resolve_relative_iris(ast, base) do
    Macro.prewalk(ast, fn
      {:sigil_I, meta_outer, [{:<<>>, meta_inner, [iri]}, list]} = sigil ->
        if IRI.absolute?(iri) do
          sigil
        else
          absolute = iri |> IRI.absolute(base) |> IRI.to_string()
          {:sigil_I, meta_outer, [{:<<>>, meta_inner, [absolute]}, list]}
        end

      other ->
        other
    end)
  end

  defp extract_base(declarations, env_aliases) do
    {base, declarations} =
      Enum.reduce(declarations, {nil, []}, fn
        {:@, line, [{:base, _, [{:__aliases__, _, ns}] = aliases}]}, {_, declarations} ->
          {
            ns |> expand_module(env_aliases) |> Module.concat(),
            [{:alias, line, aliases} | declarations]
          }

        {:@, _, [{:base, _, [base]}]}, {_, declarations} ->
          {base, declarations}

        declaration, {base, declarations} ->
          {base, [declaration | declarations]}
      end)

    {base, Enum.reverse(declarations)}
  end

  defp extract_prefixes(declarations, env_aliases) do
    {prefixes, declarations} =
      Enum.reduce(declarations, {[], []}, fn
        {:@, line, [{:prefix, _, [[{prefix, {:__aliases__, _, ns} = aliases}]]}]},
        {prefixes, declarations} ->
          {[prefix(prefix, ns, env_aliases) | prefixes],
           [{:alias, line, [aliases]} | declarations]}

        {:@, line, [{:prefix, _, [{:__aliases__, _, ns}] = aliases}]}, {prefixes, declarations} ->
          {[prefix(ns, env_aliases) | prefixes], [{:alias, line, aliases} | declarations]}

        declaration, {prefixes, declarations} ->
          {prefixes, [declaration | declarations]}
      end)

    {prefixes, Enum.reverse(declarations)}
  end

  defp prefix(namespace, env_aliases) do
    namespace
    |> determine_prefix()
    |> prefix(namespace, env_aliases)
  end

  defp prefix(prefix, namespace, env_aliases) do
    {prefix, namespace |> expand_module(env_aliases) |> Module.concat()}
  end

  defp determine_prefix(namespace) do
    namespace
    |> Enum.reverse()
    |> hd()
    |> to_string()
    |> Macro.underscore()
    |> String.to_atom()
  end

  defp declaration?({:=, _, _}), do: true
  defp declaration?({:@, _, [{:prefix, _, _}]}), do: true
  defp declaration?({:@, _, [{:base, _, _}]}), do: true
  defp declaration?({:alias, _, _}), do: true
  defp declaration?({:import, _, _}), do: true
  defp declaration?({:require, _, _}), do: true
  defp declaration?({:use, _, _}), do: true
  defp declaration?(_), do: false

  defp rdf?(nil), do: false
  defp rdf?(:ok), do: false
  defp rdf?(%Description{}), do: true
  defp rdf?(%Graph{}), do: true
  defp rdf?(%Dataset{}), do: true
  defp rdf?(statements) when is_map(statements), do: true
  defp rdf?(statements) when is_tuple(statements), do: true
  defp rdf?(list) when is_list(list), do: true

  defp rdf?(invalid) do
    raise Error, message: "invalid RDF data: #{inspect(invalid)}"
  end

  defp expand_module([first | rest] = module, env_aliases) do
    if full = env_aliases[first] do
      full ++ rest
    else
      module
    end
  end

  defp env_aliases(env) do
    Map.new(env.aliases, fn {short, full} ->
      {
        module_to_atom_without_elixir_prefix(short),
        full |> Module.split() |> Enum.map(&String.to_atom/1)
      }
    end)
  end

  defp module_to_atom_without_elixir_prefix(module) do
    [short] = Module.split(module)
    String.to_atom(short)
  end
end
