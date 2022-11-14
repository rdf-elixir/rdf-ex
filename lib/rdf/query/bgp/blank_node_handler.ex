defmodule RDF.Query.BGP.BlankNodeHandler do
  @moduledoc false

  alias RDF.BlankNode

  @default_remove_bnode_query_variables Application.compile_env(
                                          :rdf,
                                          :default_remove_bnode_query_variables,
                                          true
                                        )

  def preprocess(triple_patterns) do
    convert_triple_patterns(triple_patterns)
  end

  defp convert_triple_patterns(triple_patterns, acc \\ {[], []})
  defp convert_triple_patterns([], acc), do: acc

  defp convert_triple_patterns([triple_pattern | rest], {converted, bnode_vars}) do
    {converted_triple_pattern, bnode_vars} = convert_triple_pattern(triple_pattern, bnode_vars)
    convert_triple_patterns(rest, {[converted_triple_pattern | converted], bnode_vars})
  end

  defp convert_triple_pattern({s, p, o}, bnode_vars) do
    {converted_s, bnode_vars} = convert_term(s, bnode_vars)
    {converted_p, bnode_vars} = convert_term(p, bnode_vars)
    {converted_o, bnode_vars} = convert_term(o, bnode_vars)
    {{converted_s, converted_p, converted_o}, bnode_vars}
  end

  defp convert_term(%BlankNode{} = bnode, bnode_vars) do
    bnode_var = bnode_var(bnode)
    {bnode_var, [bnode_var | bnode_vars]}
  end

  defp convert_term({_, _, _} = quoted_triple, bnode_vars) do
    convert_triple_pattern(quoted_triple, bnode_vars)
  end

  defp convert_term(term, bnode_vars), do: {term, bnode_vars}

  defp bnode_var(bnode), do: bnode |> to_string() |> String.to_atom()

  def postprocess(solutions, [], _), do: solutions

  def postprocess(solutions, bnode_vars, opts) do
    if Keyword.get(opts, :remove_bnode_query_variables, @default_remove_bnode_query_variables) do
      Enum.map(solutions, &Map.drop(&1, bnode_vars))
    else
      solutions
    end
  end
end
