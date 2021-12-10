defmodule RDF.Query.BGP.Simple do
  @moduledoc false

  @behaviour RDF.Query.BGP.Matcher

  alias RDF.Query.BGP
  alias RDF.Query.BGP.{QueryPlanner, BlankNodeHandler}
  alias RDF.{Graph, Description}

  import RDF.Guards

  @impl RDF.Query.BGP.Matcher
  def execute(bgp, graph, opts \\ [])

  # https://www.w3.org/TR/sparql11-query/#emptyGroupPattern
  def execute(%BGP{triple_patterns: []}, _, _), do: [%{}]

  def execute(%BGP{triple_patterns: triple_patterns}, %Graph{} = graph, opts) do
    {preprocessed_triple_patterns, bnode_state} = BlankNodeHandler.preprocess(triple_patterns)

    preprocessed_triple_patterns
    |> QueryPlanner.query_plan()
    |> do_execute(graph)
    |> BlankNodeHandler.postprocess(bnode_state, opts)
  end

  @impl RDF.Query.BGP.Matcher
  def stream(bgp, graph, opts \\ []) do
    execute(bgp, graph, opts)
    |> Stream.into([])
  end

  defp do_execute([triple_pattern | remaining], graph) do
    do_execute(remaining, graph, match(graph, triple_pattern))
  end

  defp do_execute(triple_patterns, graph, solutions)

  defp do_execute(_, _, []), do: []

  defp do_execute([], _, solutions), do: solutions

  defp do_execute([triple_pattern | remaining], graph, solutions) do
    do_execute(remaining, graph, match_with_solutions(graph, triple_pattern, solutions))
  end

  defp match_with_solutions(graph, {s, p, o} = triple_pattern, existing_solutions) do
    if solvable?(p) or solvable?(s) or solvable?(o) do
      triple_pattern
      |> apply_solutions(existing_solutions)
      |> Enum.flat_map(&merging_match(&1, graph))
    else
      graph
      |> match(triple_pattern)
      |> Enum.flat_map(fn solution ->
        Enum.map(existing_solutions, &Map.merge(solution, &1))
      end)
    end
  end

  defp apply_solutions(triple_pattern, solutions) do
    if solver = solver(triple_pattern) do
      Stream.map(solutions, solver)
    else
      solutions
    end
  end

  defp solver(triple_pattern) do
    if solver = solver_fun(triple_pattern) do
      &{&1, solver.(&1)}
    end
  end

  defp solver_fun({{s}, {p}, {o}}), do: &{&1[s], &1[p], &1[o]}
  defp solver_fun({{s}, p, {o}}), do: &{&1[s], p, &1[o]}

  defp solver_fun({{s}, {p}, o}) do
    if o_solver = solver_fun(o) do
      &{&1[s], &1[p], o_solver.(&1)}
    else
      &{&1[s], &1[p], o}
    end
  end

  defp solver_fun({{s}, p, o}) do
    if o_solver = solver_fun(o) do
      &{&1[s], p, o_solver.(&1)}
    else
      &{&1[s], p, o}
    end
  end

  defp solver_fun({s, {p}, {o}}) do
    if s_solver = solver_fun(s) do
      &{s_solver.(&1), &1[p], &1[o]}
    else
      &{s, &1[p], &1[o]}
    end
  end

  defp solver_fun({s, p, {o}}) do
    if s_solver = solver_fun(s) do
      &{s_solver.(&1), p, &1[o]}
    else
      &{s, p, &1[o]}
    end
  end

  defp solver_fun({s, {p}, o}) do
    s_solver = solver_fun(s)
    o_solver = solver_fun(o)

    cond do
      s_solver && o_solver -> &{s_solver.(&1), &1[p], o_solver.(&1)}
      s_solver -> &{s_solver.(&1), &1[p], o}
      o_solver -> &{s, &1[p], o_solver.(&1)}
      true -> &{s, &1[p], o}
    end
  end

  defp solver_fun({s, p, o}) do
    s_solver = solver_fun(s)
    o_solver = solver_fun(o)

    cond do
      s_solver && o_solver -> &{s_solver.(&1), p, o_solver.(&1)}
      s_solver -> &{s_solver.(&1), p, o}
      o_solver -> &{s, p, o_solver.(&1)}
      true -> fn _ -> {s, p, o} end
    end
  end

  defp solver_fun(_), do: nil

  defp merging_match({dependent_solution, triple_pattern}, graph) do
    case match(graph, triple_pattern) do
      nil ->
        []

      solutions ->
        Enum.map(solutions, fn solution ->
          Map.merge(dependent_solution, solution)
        end)
    end
  end

  defp match(%Graph{descriptions: descriptions}, {subject_variable, _, _} = triple_pattern)
       when is_atom(subject_variable) do
    Enum.reduce(descriptions, [], fn {subject, description}, acc ->
      case match(description, solve_variables(subject_variable, subject, triple_pattern)) do
        nil -> acc
        solutions -> Enum.map(solutions, &Map.put(&1, subject_variable, subject)) ++ acc
      end
    end)
  end

  defp match(%Graph{} = graph, {subject, _, _} = triple_pattern) do
    if quoted_triple_with_variables?(subject) do
      graph
      |> matching_subject_triples(subject)
      |> Enum.flat_map(fn {description, subject_solutions} ->
        case match(description, solve_variables(subject_solutions, triple_pattern)) do
          nil -> []
          solutions -> Enum.map(solutions, &Map.merge(&1, subject_solutions))
        end
      end)
    else
      case graph[subject] do
        nil -> []
        description -> match(description, triple_pattern)
      end
    end
  end

  defp match(%Description{predications: predications}, {_, variable, variable})
       when is_atom(variable) do
    Enum.reduce(predications, [], fn {predicate, objects}, solutions ->
      if Map.has_key?(objects, predicate) do
        [%{variable => predicate} | solutions]
      else
        solutions
      end
    end)
  end

  defp match(%Description{predications: predications}, {_, predicate_variable, object_variable})
       when is_atom(predicate_variable) and is_atom(object_variable) do
    Enum.reduce(predications, [], fn {predicate, objects}, solutions ->
      solutions ++
        Enum.map(objects, fn {object, _} ->
          %{predicate_variable => predicate, object_variable => object}
        end)
    end)
  end

  defp match(%Description{predications: predications}, {_, predicate_variable, object})
       when is_atom(predicate_variable) do
    Enum.reduce(predications, [], fn {predicate, objects}, solutions ->
      cond do
        Map.has_key?(objects, object) ->
          [%{predicate_variable => predicate} | solutions]

        quoted_triple_with_variables?(object) ->
          (objects
           |> matching_object_triples(object)
           |> Enum.map(&Map.put(&1, predicate_variable, predicate))) ++
            solutions

        true ->
          solutions
      end
    end)
  end

  defp match(%Description{predications: predications}, {_, predicate, object_or_variable}) do
    case predications[predicate] do
      nil ->
        []

      objects ->
        cond do
          # object_or_variable is a variable
          is_atom(object_or_variable) ->
            Enum.map(objects, fn {object, _} -> %{object_or_variable => object} end)

          # object_or_variable is a object
          Map.has_key?(objects, object_or_variable) ->
            [%{}]

          quoted_triple_with_variables?(object_or_variable) ->
            matching_object_triples(objects, object_or_variable)

          # else
          true ->
            []
        end
    end
  end

  defp matching_subject_triples(graph, triple_pattern) do
    Enum.reduce(graph.descriptions, [], fn
      {subject, description}, acc when is_triple(subject) ->
        case match_triple(subject, triple_pattern) do
          nil -> acc
          solutions -> [{description, solutions} | acc]
        end

      _, acc ->
        acc
    end)
  end

  defp matching_object_triples(objects, triple_pattern) do
    Enum.reduce(objects, [], fn
      {object, _}, acc when is_triple(object) ->
        case match_triple(object, triple_pattern) do
          nil -> acc
          solutions -> [solutions | acc]
        end

      _, acc ->
        acc
    end)
  end

  defp match_triple(triple, triple), do: %{}
  defp match_triple({s, p, o}, {var, p, o}) when is_atom(var), do: %{var => s}
  defp match_triple({s, p, o}, {s, var, o}) when is_atom(var), do: %{var => p}
  defp match_triple({s, p, o}, {s, p, var}) when is_atom(var), do: %{var => o}

  defp match_triple({s, p1, o1}, {triple_pattern, p2, o2}) when is_triple(triple_pattern) do
    if bindings = match_triple({"solved", p1, o1}, {"solved", p2, o2}) do
      if nested_bindings = match_triple(s, triple_pattern) do
        Map.merge(bindings, nested_bindings)
      end
    end
  end

  defp match_triple({s1, p1, o}, {s2, p2, triple_pattern}) when is_triple(triple_pattern) do
    if bindings = match_triple({s1, p1, "solved"}, {s2, p2, "solved"}) do
      if nested_bindings = match_triple(o, triple_pattern) do
        Map.merge(bindings, nested_bindings)
      end
    end
  end

  defp match_triple({s, p, o}, {var1, var2, o}) when is_atom(var1) and is_atom(var2),
    do: %{var1 => s, var2 => p}

  defp match_triple({s, p, o}, {var1, p, var2}) when is_atom(var1) and is_atom(var2),
    do: %{var1 => s, var2 => o}

  defp match_triple({s, p, o}, {s, var1, var2}) when is_atom(var1) and is_atom(var2),
    do: %{var1 => p, var2 => o}

  defp match_triple({s, p, o}, {var1, var2, var3})
       when is_atom(var1) and is_atom(var2) and is_atom(var3),
       do: %{var1 => s, var2 => p, var3 => o}

  defp match_triple(_, _), do: nil

  defp solvable?(term) when is_tuple(term) and tuple_size(term) == 1, do: true
  defp solvable?({s, p, o}), do: solvable?(p) or solvable?(s) or solvable?(o)
  defp solvable?(_), do: false

  defp quoted_triple_with_variables?({s, p, o}) do
    is_atom(s) or is_atom(p) or is_atom(o) or
      quoted_triple_with_variables?(s) or
      quoted_triple_with_variables?(p) or
      quoted_triple_with_variables?(o)
  end

  defp quoted_triple_with_variables?(_), do: false

  defp solve_variables(var, val, {s, p, o}),
    do: {solve_variables(var, val, s), solve_variables(var, val, p), solve_variables(var, val, o)}

  defp solve_variables(var, val, var), do: val
  defp solve_variables(_, _, term), do: term

  defp solve_variables(bindings, pattern) do
    Enum.reduce(bindings, pattern, fn {var, val}, pattern ->
      solve_variables(var, val, pattern)
    end)
  end
end
