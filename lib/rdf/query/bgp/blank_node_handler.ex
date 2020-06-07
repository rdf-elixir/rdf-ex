defmodule RDF.Query.BGP.BlankNodeHandler do
  @moduledoc false

  alias RDF.BlankNode

  @blank_node_prefix "_:"
  @default_remove_bnode_query_variables Application.get_env(:rdf, :default_remove_bnode_query_variables, true)

  def preprocess(triple_patterns) do
    Enum.reduce(triple_patterns, {false, []}, fn
      original_triple_pattern, {had_blank_nodes, triple_patterns} ->
        {is_converted, triple_pattern} = convert_blank_nodes(original_triple_pattern)
        {had_blank_nodes || is_converted, [triple_pattern | triple_patterns]}
    end)
  end

  defp convert_blank_nodes({%BlankNode{} = s, %BlankNode{} = p, %BlankNode{} = o}), do: {true, {to_string(s), to_string(p), to_string(o)}}
  defp convert_blank_nodes({s, %BlankNode{} = p, %BlankNode{} = o}), do: {true, {s, to_string(p), to_string(o)}}
  defp convert_blank_nodes({%BlankNode{} = s, p, %BlankNode{} = o}), do: {true, {to_string(s), p, to_string(o)}}
  defp convert_blank_nodes({%BlankNode{} = s, %BlankNode{} = p, o}), do: {true, {to_string(s), to_string(p), o}}
  defp convert_blank_nodes({%BlankNode{} = s, p, o}), do: {true, {to_string(s), p, o}}
  defp convert_blank_nodes({s, %BlankNode{} = p, o}), do: {true, {s, to_string(p), o}}
  defp convert_blank_nodes({s, p, %BlankNode{} = o}), do: {true, {s, p, to_string(o)}}
  defp convert_blank_nodes(triple_pattern),           do: {false, triple_pattern}


  def postprocess(solutions, has_blank_nodes, opts) do
    if has_blank_nodes and
       Keyword.get(opts, :remove_bnode_query_variables, @default_remove_bnode_query_variables) do
      Enum.map(solutions, &remove_blank_nodes/1)
    else
      solutions
    end
  end

  defp remove_blank_nodes(solution) do
    solution
    |> Enum.filter(fn
      {@blank_node_prefix <> _, _} -> false
      _                            -> true
    end)
    |> Map.new
  end
end
