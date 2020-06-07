defmodule RDF.Query.BGP.QueryPlanner do
  @moduledoc false

  def query_plan(triple_patterns, solved \\ MapSet.new, plan \\ [])

  def query_plan([], _, plan), do: Enum.reverse(plan)

  def query_plan(triple_patterns, solved, plan) do
    [next_best | rest] = Enum.sort_by(triple_patterns, &triple_priority/1)
    new_solved = MapSet.union(solved, variables(next_best))

    query_plan(
      mark_solved_variables(rest, new_solved),
      new_solved,
      [next_best | plan])
  end

  defp variables({v1, v2, v3}) when is_binary(v1) and is_binary(v2) and is_binary(v3), do: MapSet.new([v1, v2, v3])
  defp variables({_, v2, v3}) when is_binary(v2) and is_binary(v3), do: MapSet.new([v2, v3])
  defp variables({v1, _, v3}) when is_binary(v1) and is_binary(v3), do: MapSet.new([v1, v3])
  defp variables({v1, v2, _}) when is_binary(v1) and is_binary(v2), do: MapSet.new([v1, v2])
  defp variables({v1, _, _}) when is_binary(v1), do: MapSet.new([v1])
  defp variables({_, v2, _}) when is_binary(v2), do: MapSet.new([v2])
  defp variables({_, _, v3}) when is_binary(v3), do: MapSet.new([v3])
  defp variables(_), do: MapSet.new()

  defp triple_priority({v, v, v}), do: triple_priority({v, :p, :o})
  defp triple_priority({v, v, o}), do: triple_priority({v, :p, o})
  defp triple_priority({v, p, v}), do: triple_priority({v, p, :o})
  defp triple_priority({s, v, v}), do: triple_priority({s, v, :o})
  defp triple_priority({s, p, o}) do
    {sp, pp, op} = {value_priority(s), value_priority(p), value_priority(o)}
    <<(sp + pp + op) :: size(2), sp :: size(1), pp :: size(1), op :: size(1)>>
  end

  defp value_priority(value) when is_binary(value), do: 1
  defp value_priority(_),                           do: 0

  defp mark_solved_variables(triple_patterns, solved) do
    Enum.map triple_patterns, fn {s, p, o} ->
      {
        (if is_binary(s) and MapSet.member?(solved, s), do: {s}, else: s),
        (if is_binary(p) and MapSet.member?(solved, p), do: {p}, else: p),
        (if is_binary(o) and MapSet.member?(solved, o), do: {o}, else: o)
      }
    end
  end
end
