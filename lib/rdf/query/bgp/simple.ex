defmodule RDF.Query.BGP.Simple do
  @behaviour RDF.Query.BGP

  alias RDF.{Graph, Description, BlankNode}

  @blank_node_prefix "_:"

  @impl RDF.Query.BGP
  def query(data, pattern)

  def query(_, []), do: [%{}]  # https://www.w3.org/TR/sparql11-query/#emptyGroupPattern

  def query(data, triple_patterns) do
    triple_patterns
    |> Stream.map(&convert_blank_nodes/1)
    |> Enum.sort_by(&triple_priority/1)
    |> do_matching(data)
    |> Enum.map(&remove_blank_nodes/1)
  end


  defp convert_blank_nodes({%BlankNode{} = s, p, o}), do: convert_blank_nodes({to_string(s), p, o})
  defp convert_blank_nodes({s, %BlankNode{} = p, o}), do: convert_blank_nodes({s, to_string(p), o})
  defp convert_blank_nodes({s, p, %BlankNode{} = o}), do: convert_blank_nodes({s, p, to_string(o)})
  defp convert_blank_nodes(triple_pattern),           do: triple_pattern

  defp remove_blank_nodes(solution) do
    solution
    |> Enum.filter(fn
      {@blank_node_prefix <> _, _} -> false
      _                            -> true
    end)
    |> Map.new
  end


  defp do_matching(triple_patterns, data, solutions \\ [])

  defp do_matching([], _, solutions), do: solutions

  defp do_matching([triple_pattern | remaining], data, acc) do
    solutions = match(data, triple_pattern, acc)

    if solutions not in [nil, []] do
      remaining
      |> mark_solved_variables(solutions)
      |> Enum.sort_by(&triple_priority/1)
      |> do_matching(data, solutions)
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

  defp mark_solved_variables(triple_patterns, [solution | _]) do
    Stream.map triple_patterns, fn {s, p, o} ->
      {
        (if is_binary(s) and Map.has_key?(solution, s), do: {s}, else: s),
        (if is_binary(p) and Map.has_key?(solution, p), do: {p}, else: p),
        (if is_binary(o) and Map.has_key?(solution, o), do: {o}, else: o)
      }
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
end
