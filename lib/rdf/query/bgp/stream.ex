defmodule RDF.Query.BGP.Stream do
  @behaviour RDF.Query.BGP.Matcher

  alias RDF.Query.BGP
  alias RDF.Query.BGP.{QueryPlanner, BlankNodeHandler}
  alias RDF.{Graph, Description}


  @impl RDF.Query.BGP.Matcher
  def stream(bgp, graph, opts \\ [])

  def stream(%BGP{triple_patterns: []}, _, _), do: to_stream([%{}])  # https://www.w3.org/TR/sparql11-query/#emptyGroupPattern

  def stream(%BGP{triple_patterns: triple_patterns}, %Graph{} = graph, opts) do
    {bnode_state, preprocessed_triple_patterns} =
      BlankNodeHandler.preprocess(triple_patterns)

    preprocessed_triple_patterns
    |> QueryPlanner.query_plan()
    |> do_execute(graph)
    |> BlankNodeHandler.postprocess(triple_patterns, bnode_state, opts)
  end

  @impl RDF.Query.BGP.Matcher
  def execute(bgp, graph, opts \\ []) do
    stream(bgp, graph, opts)
    |> Enum.to_list()
  end

  defp do_execute([triple_pattern | remaining], graph) do
    do_execute(remaining, graph, match(graph, triple_pattern))
  end

  # CAUTION: Careful with using Enum.empty?/1 on the solution stream!! The first match must be
  # searched for every call in the query loop repeatedly then, which can have dramatic effects potentially.
  # Only use it very close to the data (in the match/1 functions operating on data directly).

  defp do_execute(triple_patterns, graph, solutions)

  defp do_execute(_, _, nil), do: to_stream([])

  defp do_execute([], _, solutions), do: solutions

  defp do_execute([triple_pattern | remaining], graph, solutions) do
    do_execute(remaining, graph, match_with_solutions(graph, triple_pattern, solutions))
  end


  defp match_with_solutions(graph, {s, p, o} = triple_pattern, existing_solutions)
       when is_tuple(s) or is_tuple(p) or is_tuple(o) do
    triple_pattern
    |> apply_solutions(existing_solutions)
    |> Stream.flat_map(&(merging_match(&1, graph)))
  end

  defp match_with_solutions(graph, triple_pattern, existing_solutions) do
    if solutions = match(graph, triple_pattern) do
      Stream.flat_map(solutions, fn solution ->
        Stream.map(existing_solutions, &(Map.merge(solution, &1)))
      end)
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

  defp merging_match({dependent_solution, triple_pattern}, graph) do
    case match(graph, triple_pattern) do
      nil -> []
      solutions ->
        Stream.map solutions, fn solution ->
          Map.merge(dependent_solution, solution)
        end
    end
  end


  defp match(%Graph{descriptions: descriptions}, {subject_variable, _, _} = triple_pattern)
       when is_atom(subject_variable) do
    Stream.flat_map(descriptions, fn {subject, description} ->
      case match(description, solve_variables(subject_variable, subject, triple_pattern)) do
        nil -> []
        solutions ->
          Stream.map(solutions, fn solution ->
            Map.put(solution, subject_variable, subject)
          end)
      end
    end)
  end

  defp match(%Graph{} = graph, {subject, _, _} = triple_pattern) do
    case graph[subject] do
      nil         -> nil
      description -> match(description, triple_pattern)
    end
  end

  defp match(%Description{predications: predications}, {_, variable, variable})
       when is_atom(variable) do
    matches =
      Stream.filter(predications, fn {predicate, objects} -> Map.has_key?(objects, predicate) end)

    unless Enum.empty?(matches) do
      Stream.map(matches, fn {predicate, _} -> %{variable => predicate} end)
    end
  end

  defp match(%Description{predications: predications}, {_, predicate_variable, object_variable})
       when is_atom(predicate_variable) and is_atom(object_variable) do
    Stream.flat_map(predications, fn {predicate, objects} ->
      Stream.map(objects, fn {object, _} ->
        %{predicate_variable => predicate, object_variable => object}
      end)
    end)
  end

  defp match(%Description{predications: predications},
         {_, predicate_variable, object}) when is_atom(predicate_variable) do
    matches =
      Stream.filter(predications, fn {_, objects} -> Map.has_key?(objects, object) end)

    unless Enum.empty?(matches) do
      Stream.map(matches, fn {predicate, _} -> %{predicate_variable => predicate} end)
    end
  end

  defp match(%Description{predications: predications},
         {_, predicate, object_or_variable}) do
    case predications[predicate] do
      nil -> nil
      objects ->
        cond do
          # object_or_variable is a variable
          is_atom(object_or_variable) ->
            Stream.map(objects, fn {object, _} ->
              %{object_or_variable => object}
            end)

          # object_or_variable is a object
          Map.has_key?(objects, object_or_variable) ->
            to_stream([%{}])

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

  defp to_stream(enum), do: Stream.into(enum, [])
end
