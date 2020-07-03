defmodule RDF.Query.BGP.BlankNodeHandler do
  @moduledoc false

  alias RDF.Query.BGP
  alias RDF.BlankNode

  @default_remove_bnode_query_variables Application.get_env(
                                          :rdf,
                                          :default_remove_bnode_query_variables,
                                          true
                                        )

  def preprocess(triple_patterns) do
    Enum.reduce(triple_patterns, {false, []}, fn
      original_triple_pattern, {had_blank_nodes, triple_patterns} ->
        {is_converted, triple_pattern} = convert_blank_nodes(original_triple_pattern)
        {had_blank_nodes || is_converted, [triple_pattern | triple_patterns]}
    end)
  end

  defp convert_blank_nodes({%BlankNode{} = s, %BlankNode{} = p, %BlankNode{} = o}),
    do: {true, {bnode_var(s), bnode_var(p), bnode_var(o)}}

  defp convert_blank_nodes({s, %BlankNode{} = p, %BlankNode{} = o}),
    do: {true, {s, bnode_var(p), bnode_var(o)}}

  defp convert_blank_nodes({%BlankNode{} = s, p, %BlankNode{} = o}),
    do: {true, {bnode_var(s), p, bnode_var(o)}}

  defp convert_blank_nodes({%BlankNode{} = s, %BlankNode{} = p, o}),
    do: {true, {bnode_var(s), bnode_var(p), o}}

  defp convert_blank_nodes({%BlankNode{} = s, p, o}), do: {true, {bnode_var(s), p, o}}
  defp convert_blank_nodes({s, %BlankNode{} = p, o}), do: {true, {s, bnode_var(p), o}}
  defp convert_blank_nodes({s, p, %BlankNode{} = o}), do: {true, {s, p, bnode_var(o)}}
  defp convert_blank_nodes(triple_pattern), do: {false, triple_pattern}

  defp bnode_var(bnode), do: bnode |> to_string() |> String.to_atom()

  def postprocess(solutions, bgp, has_blank_nodes, opts) do
    if has_blank_nodes and
         Keyword.get(opts, :remove_bnode_query_variables, @default_remove_bnode_query_variables) do
      bnode_vars = bgp |> bnodes() |> Enum.map(&bnode_var/1)
      Enum.map(solutions, &Map.drop(&1, bnode_vars))
    else
      solutions
    end
  end

  defp bnodes(%BGP{triple_patterns: triple_patterns}), do: bnodes(triple_patterns)

  defp bnodes(triple_patterns) when is_list(triple_patterns) do
    triple_patterns
    |> Enum.flat_map(&bnodes/1)
    |> Enum.uniq()
  end

  defp bnodes({%BlankNode{} = s, %BlankNode{} = p, %BlankNode{} = o}), do: [s, p, o]
  defp bnodes({%BlankNode{} = s, %BlankNode{} = p, _}), do: [s, p]
  defp bnodes({%BlankNode{} = s, _, %BlankNode{} = o}), do: [s, o]
  defp bnodes({_, %BlankNode{} = p, %BlankNode{} = o}), do: [p, o]
  defp bnodes({%BlankNode{} = s, _, _}), do: [s]
  defp bnodes({_, %BlankNode{} = p, _}), do: [p]
  defp bnodes({_, _, %BlankNode{} = o}), do: [o]

  defp bnodes(_), do: []
end
