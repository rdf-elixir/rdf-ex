defmodule RDF.Query.BGP.QueryPlanner do
  @moduledoc false

  alias RDF.Query.BGP

  import RDF.Guards

  @dedup_var ""

  def query_plan(triple_patterns, solved \\ [], plan \\ [])

  def query_plan([], _, plan), do: Enum.reverse(plan)

  def query_plan(triple_patterns, solved, plan) do
    [next_best | rest] = Enum.sort(triple_patterns, &best_triple_pattern/2)
    new_solved = Enum.uniq(BGP.variables(next_best) ++ solved)

    query_plan(
      mark_solved_variables(rest, new_solved),
      new_solved,
      [next_best | plan]
    )
  end

  defp best_triple_pattern(triple_pattern1, triple_pattern2) do
    triple_pattern1 = deduplicate(triple_pattern1)
    triple_pattern2 = deduplicate(triple_pattern2)
    {var_count1, var_positions1} = var_info(triple_pattern1)
    {var_count2, var_positions2} = var_info(triple_pattern2)

    if var_count1 != var_count2 do
      var_count1 < var_count2
    else
      better_positioning(var_positions1, var_positions2)
    end
  end

  defp deduplicate({v, v, v}), do: {v, @dedup_var, @dedup_var}
  defp deduplicate({v, v, o}), do: {v, @dedup_var, o}
  defp deduplicate({v, p, v}), do: {v, p, @dedup_var}
  defp deduplicate({s, v, v}), do: {s, v, @dedup_var}

  defp deduplicate({s, _, o} = star_triple) when is_triple(s) or is_triple(o) do
    {deduplicated_triple, _} = deduplicate_star(star_triple, [])
    deduplicated_triple
  end

  defp deduplicate(triple_pattern), do: triple_pattern

  defp deduplicate_star({s, p, o}, vars) do
    {s, vars} = deduplicate_star(s, vars)
    {p, vars} = deduplicate_star(p, vars)
    {o, vars} = deduplicate_star(o, vars)
    {{s, p, o}, vars}
  end

  defp deduplicate_star(var, vars) when is_atom(var) do
    if var in vars do
      {@dedup_var, vars}
    else
      {var, [var | vars]}
    end
  end

  defp deduplicate_star(var, vars), do: {var, vars}

  defp var_info({s, p, o}) when is_triple(s) or is_triple(o) do
    {s_var_count, s_quoted?} = var_info_star(s)
    {p_var_count, _} = var_info_star(p)
    {o_var_count, o_quoted?} = var_info_star(o)

    {
      star_term_value(s_var_count, s_quoted?) +
        p_var_count +
        star_term_value(o_var_count, o_quoted?),
      {
        if(s_quoted? and not (s_var_count == 0), do: {s_var_count}, else: s_var_count),
        p_var_count,
        if(o_quoted? and not (o_var_count == 0), do: {o_var_count}, else: o_var_count)
      }
    }
  end

  defp var_info({s, p, o}) when is_atom(s) and is_atom(p) and is_atom(o), do: {3, {1, 1, 1}}
  defp var_info({s, p, _}) when is_atom(s) and is_atom(p), do: {2, {1, 1, 0}}
  defp var_info({s, _, o}) when is_atom(s) and is_atom(o), do: {2, {1, 0, 1}}
  defp var_info({_, p, o}) when is_atom(p) and is_atom(o), do: {2, {0, 1, 1}}
  defp var_info({s, _, _}) when is_atom(s), do: {1, {1, 0, 0}}
  defp var_info({_, p, _}) when is_atom(p), do: {1, {0, 1, 0}}
  defp var_info({_, _, o}) when is_atom(o), do: {1, {0, 0, 1}}

  defp var_info(_), do: {0, {0, 0, 0}}

  defp var_info_star({s, p, o}) do
    {s_var_count, _} = var_info_star(s)
    {p_var_count, _} = var_info_star(p)
    {o_var_count, _} = var_info_star(o)
    {s_var_count + p_var_count + o_var_count, true}
  end

  defp var_info_star(var) when is_atom(var), do: {1, false}
  defp var_info_star(_), do: {0, false}

  defp star_term_value(0, _), do: 0
  defp star_term_value(1, false), do: 1
  defp star_term_value(count, _) when count > 2, do: 1
  defp star_term_value(_, _), do: 0

  defp better_positioning(var_position, var_position), do: true
  defp better_positioning({0, _, _}, {_, _, _}), do: true
  defp better_positioning({{_}, _, _}, {1, _, _}), do: true
  defp better_positioning({{c1}, _, _}, {{c2}, _, _}) when c1 != c2, do: c1 < c2
  defp better_positioning({s, 0, _}, {s, _, _}), do: true
  defp better_positioning({s, p, 0}, {s, p, _}), do: true
  defp better_positioning({s, p, {_}}, {s, p, 1}), do: true
  defp better_positioning({s, p, {c1}}, {s, p, {c2}}), do: c1 < c2
  defp better_positioning(_, _), do: false

  defp mark_solved_variables(triple_patterns, solved) do
    Enum.map(triple_patterns, &mark_solved(&1, solved))
  end

  defp mark_solved(var, solved) when is_atom(var) do
    if var in solved, do: {var}, else: var
  end

  defp mark_solved({s, p, o}, solved) do
    {mark_solved(s, solved), mark_solved(p, solved), mark_solved(o, solved)}
  end

  defp mark_solved(var, _), do: var
end
