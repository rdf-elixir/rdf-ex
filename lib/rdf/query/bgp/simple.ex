defmodule RDF.Query.BGP.Simple do
  @moduledoc false

  @behaviour RDF.Query.BGP.Matcher

  alias RDF.Query.BGP
  alias RDF.Query.BGP.{QueryPlanner, BlankNodeHandler}
  alias RDF.{Graph, Description}

  import RDF.Guards
  import RDF.Query.BGP.Helper

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
    if quoted_triple_with_variables?(object) do
      Enum.flat_map(predications, fn {predicate, objects} ->
        objects
        |> matching_object_triples(object)
        |> Enum.map(&Map.put(&1, predicate_variable, predicate))
      end)
    else
      Enum.reduce(predications, [], fn {predicate, objects}, solutions ->
        if Map.has_key?(objects, object) do
          [%{predicate_variable => predicate} | solutions]
        else
          solutions
        end
      end)
    end
  end

  defp match(%Description{predications: predications}, {_, predicate, object_or_variable}) do
    if objects = predications[predicate] do
      if quoted_triple_with_variables?(object_or_variable) do
        matching_object_triples(objects, object_or_variable)
      else
        cond do
          # object_or_variable is a variable
          is_atom(object_or_variable) ->
            Enum.map(objects, fn {object, _} -> %{object_or_variable => object} end)

          # object_or_variable is a object
          Map.has_key?(objects, object_or_variable) ->
            [%{}]

          # else
          true ->
            []
        end
      end
    else
      []
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
end
