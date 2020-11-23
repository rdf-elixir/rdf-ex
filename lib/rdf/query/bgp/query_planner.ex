defmodule RDF.Query.BGP.QueryPlanner do
  @moduledoc false

  alias RDF.Query.BGP

  def query_plan(triple_patterns, solved \\ [], plan \\ [])

  def query_plan([], _, plan), do: Enum.reverse(plan)

  def query_plan(triple_patterns, solved, plan) do
    [next_best | rest] = Enum.sort_by(triple_patterns, &triple_priority/1)
    new_solved = Enum.uniq(BGP.variables(next_best) ++ solved)

    query_plan(
      mark_solved_variables(rest, new_solved),
      new_solved,
      [next_best | plan]
    )
  end

  defp triple_priority({v, v, v}), do: triple_priority({v, "p", "o"})
  defp triple_priority({v, v, o}), do: triple_priority({v, "p", o})
  defp triple_priority({v, p, v}), do: triple_priority({v, p, "o"})
  defp triple_priority({s, v, v}), do: triple_priority({s, v, "o"})

  defp triple_priority({s, p, o}) do
    {sp, pp, op} = {value_priority(s), value_priority(p), value_priority(o)}
    <<sp + pp + op::size(2), sp::size(1), pp::size(1), op::size(1)>>
  end

  defp value_priority(value) when is_atom(value), do: 1
  defp value_priority(_), do: 0

  defp mark_solved_variables(triple_patterns, solved) do
    Enum.map(triple_patterns, fn {s, p, o} ->
      {
        if(is_atom(s) and s in solved, do: {s}, else: s),
        if(is_atom(p) and p in solved, do: {p}, else: p),
        if(is_atom(o) and o in solved, do: {o}, else: o)
      }
    end)
  end
end
