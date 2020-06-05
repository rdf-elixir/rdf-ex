defmodule RDF.Query.BGP.Simple do
  @behaviour RDF.Query.BGP

  defmodule Planner do
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

  defmodule BlankNodeHandler do
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

  alias RDF.{Graph, Description}

  @impl RDF.Query.BGP
  def query(data, pattern, opts \\ [])

  def query(_, [], _), do: [%{}]  # https://www.w3.org/TR/sparql11-query/#emptyGroupPattern

  def query(data, triple_patterns, opts) do
    {bnode_state, triple_patterns} =
      BlankNodeHandler.preprocess(triple_patterns)

    triple_patterns
    |> Planner.query_plan()
    |> do_query(data)
    |> BlankNodeHandler.postprocess(bnode_state, opts)
  end


  defp do_query(triple_patterns, data, solutions \\ [])

  defp do_query([], _, solutions), do: solutions

  defp do_query([triple_pattern | remaining], data, acc) do
    solutions = match(data, triple_pattern, acc)

    if solutions not in [nil, []] do
      do_query(remaining, data, solutions)
    else
      []
    end
  end


  defp match(data, {s, p, o} = triple_pattern, existing_solutions)
       when is_tuple(s) or is_tuple(p) or is_tuple(o) do
    triple_pattern
    |> apply_solutions(existing_solutions)
    |> Enum.flat_map(&(merge_matches(&1, data)))
  end

  defp match(data, triple_pattern, []), do: match(data, triple_pattern)

  defp match(data, triple_pattern, existing_solutions) do
    data
    |> match(triple_pattern)
    |> Enum.flat_map(fn solution ->
      Enum.map(existing_solutions, &(Map.merge(solution, &1)))
    end)
  end

  defp match(%Graph{descriptions: descriptions}, {subject_variable, _, _} = triple_pattern)
       when is_binary(subject_variable) do
    descriptions
    |> Enum.reduce([], fn ({subject, description}, acc) ->
      case match(description, solve_variables(subject_variable, subject, triple_pattern)) do
        nil       -> acc
        solutions ->
          Enum.map(solutions, fn solution ->
            Map.put(solution, subject_variable, subject)
          end) ++ acc
      end
    end)
  end

  defp match(%Graph{} = graph, {subject, _, _} = triple_pattern) do
    case graph[subject] do
      nil         -> nil
      description -> match(description, triple_pattern)
    end
  end

  defp match(%Description{predications: predications},
         {_, predicate_variable, object_variable})
       when is_binary(predicate_variable) and is_binary(object_variable) do
    if predicate_variable == object_variable do # repeated variable
      Enum.reduce predications, [], fn ({predicate, objects}, solutions) ->
        if Map.has_key?(objects, predicate) do
          [%{predicate_variable => predicate} | solutions]
        else
          solutions
        end
      end
    else
      Enum.reduce predications, [], fn ({predicate, objects}, solutions) ->
        solutions ++
        Enum.map(objects, fn {object, _} ->
          %{predicate_variable => predicate, object_variable => object}
        end)
      end
    end
  end

  defp match(%Description{predications: predications},
         {_, predicate_variable, object}) when is_binary(predicate_variable) do
    predications
    |> Enum.reduce([], fn ({predicate, objects}, solutions) ->
      if Map.has_key?(objects, object) do
        [%{predicate_variable => predicate} | solutions]
      else
        solutions
      end
    end)
  end

  defp match(%Description{predications: predications},
         {_, predicate, object_or_variable}) do
    case predications[predicate] do
      nil -> nil
      objects -> cond do
                   # object_or_variable is a variable
                   is_binary(object_or_variable) ->
                     Enum.map(objects, fn {object, _} ->
                       %{object_or_variable => object}
                     end)

                   # object_or_variable is a object
                   Map.has_key?(objects, object_or_variable) ->
                     [%{}]

                   # else
                   true ->
                     nil
                 end
    end
  end

  defp solve_variables(var, val, {var, var, var}), do: {val, val, val}
  defp solve_variables(var, val, {s, var, var}),   do: {s, val, val}
  defp solve_variables(var, val, {var, p, var}),   do: {val, p, val}
  defp solve_variables(var, val, {var, var, o}),   do: {val, val, o}
  defp solve_variables(var, val, {var, p, o}),     do: {val, p, o}
  defp solve_variables(var, val, {s, var, o}),     do: {s, val, o}
  defp solve_variables(var, val, {s, p, var}),     do: {s, p, val}
  defp solve_variables(_, _, pattern),             do: pattern

  defp merge_matches({dependent_solution, triple_pattern}, data) do
    case match(data, triple_pattern) do
      nil -> []
      solutions ->
        Enum.map solutions, fn solution ->
          Map.merge(dependent_solution, solution)
        end
    end
  end

  defp apply_solutions(triple_pattern, solutions) do
    apply_solution =
      case triple_pattern do
        {{s}, {p}, {o}} -> fn solution -> {solution, {solution[s], solution[p], solution[o]}} end
        {{s}, {p},  o } -> fn solution -> {solution, {solution[s], solution[p], o}} end
        {{s},  p , {o}} -> fn solution -> {solution, {solution[s], p          , solution[o]}} end
        {{s},  p ,  o } -> fn solution -> {solution, {solution[s], p          , o}} end
        { s , {p}, {o}} -> fn solution -> {solution, {s          , solution[p], solution[o]}} end
        { s , {p} , o } -> fn solution -> {solution, {s          , solution[p], o}} end
        { s ,  p , {o}} -> fn solution -> {solution, {s          , p          , solution[o]}} end
        _ -> nil
      end
    if apply_solution do
      Stream.map(solutions, apply_solution)
    else
      solutions
    end
  end
end
