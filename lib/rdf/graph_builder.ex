defmodule RDF.Graph.Builder do
  alias RDF.{Description, Graph, Dataset, PrefixMap}

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
  end

  def build({:__block__, _, block}, opts) do
    {declarations, data} = Enum.split_with(block, &declaration?/1)
    {prefixes, declarations} = extract_prefixes(declarations)
    {base, declarations} = extract_base(declarations)

    quote do
      alias RDF.XSD
      alias RDF.NS.{RDFS, OWL}

      import RDF.Sigils
      import Helper

      unquote(declarations)

      RDF.Graph.Builder.do_build(unquote(data), unquote(opts), unquote(prefixes), unquote(base))
    end
  end

  def build(single, opts) do
    build({:__block__, [], List.wrap(single)}, opts)
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

  defp extract_base(declarations) do
    {base, declarations} =
      Enum.reduce(declarations, {nil, []}, fn
        {:@, line, [{:base, _, [{:__aliases__, _, ns}] = aliases}]}, {_, declarations} ->
          {Module.concat(ns), [{:alias, line, aliases} | declarations]}

        {:@, _, [{:base, _, [base]}]}, {_, declarations} ->
          {base, declarations}

        declaration, {base, declarations} ->
          {base, [declaration | declarations]}
      end)

    {base, Enum.reverse(declarations)}
  end

  defp extract_prefixes(declarations) do
    {prefixes, declarations} =
      Enum.reduce(declarations, {[], []}, fn
        {:@, line, [{:prefix, _, [[{prefix, {:__aliases__, _, ns} = aliases}]]}]},
        {prefixes, declarations} ->
          {[prefix(prefix, ns) | prefixes], [{:alias, line, [aliases]} | declarations]}

        {:@, line, [{:prefix, _, [{:__aliases__, _, ns}] = aliases}]}, {prefixes, declarations} ->
          {[prefix(ns) | prefixes], [{:alias, line, aliases} | declarations]}

        declaration, {prefixes, declarations} ->
          {prefixes, [declaration | declarations]}
      end)

    {prefixes, Enum.reverse(declarations)}
  end

  defp prefix(namespace) do
    namespace
    |> Enum.reverse()
    |> hd()
    |> to_string()
    |> Macro.underscore()
    |> String.to_atom()
    |> prefix(namespace)
  end

  defp prefix(prefix, namespace), do: {prefix, Module.concat(namespace)}

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
end
