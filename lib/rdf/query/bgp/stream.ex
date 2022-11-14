defmodule RDF.Query.BGP.Stream do
  @moduledoc false

  @behaviour RDF.Query.BGP.Matcher

  alias RDF.Query.BGP
  alias RDF.Query.BGP.{QueryPlanner, BlankNodeHandler}
  alias RDF.{Graph, Description}

  import RDF.Query.BGP.Helper
  import RDF.Guards

  @impl RDF.Query.BGP.Matcher
  def stream(bgp, graph, opts \\ [])

  # https://www.w3.org/TR/sparql11-query/#emptyGroupPattern
  def stream(%BGP{triple_patterns: []}, _, _), do: to_stream([%{}])

  def stream(%BGP{triple_patterns: triple_patterns}, %Graph{} = graph, opts) do
    {preprocessed_triple_patterns, bnode_state} = BlankNodeHandler.preprocess(triple_patterns)

    preprocessed_triple_patterns
    |> QueryPlanner.query_plan()
    |> do_execute(graph)
    |> BlankNodeHandler.postprocess(bnode_state, opts)
  end

  @impl RDF.Query.BGP.Matcher
  def execute(bgp, graph, opts \\ []) do
    stream(bgp, graph, opts)
    |> Enum.to_list()
  end

  defp do_execute([triple_pattern | remaining], graph) do
    do_execute(remaining, graph, match(graph, triple_pattern))
  end

  defp do_execute(triple_patterns, graph, solutions)

  defp do_execute(_, _, nil), do: to_stream([])

  defp do_execute([], _, solutions), do: solutions

  defp do_execute([triple_pattern | remaining], graph, solutions) do
    do_execute(remaining, graph, match_with_solutions(graph, triple_pattern, solutions))
  end

  defp match_with_solutions(graph, {s, p, o} = triple_pattern, existing_solutions) do
    if solvable?(p) or solvable?(s) or solvable?(o) do
      triple_pattern
      |> apply_solutions(existing_solutions)
      |> Stream.flat_map(&merging_match(&1, graph))
    else
      if solutions = match(graph, triple_pattern) do
        Stream.flat_map(solutions, fn solution ->
          Stream.map(existing_solutions, &Map.merge(solution, &1))
        end)
      end
    end
  end

  defp merging_match({dependent_solution, triple_pattern}, graph) do
    case match(graph, triple_pattern) do
      nil -> []
      solutions -> Stream.map(solutions, &Map.merge(dependent_solution, &1))
    end
  end

  defp match(%Graph{descriptions: descriptions}, {subject_variable, _, _} = triple_pattern)
       when is_atom(subject_variable) do
    Stream.flat_map(descriptions, fn {subject, description} ->
      case match(description, solve_variables(subject_variable, subject, triple_pattern)) do
        nil -> []
        solutions -> Stream.map(solutions, &Map.put(&1, subject_variable, subject))
      end
    end)
  end

  defp match(%Graph{} = graph, {subject, _, _} = triple_pattern) do
    if quoted_triple_with_variables?(subject) do
      graph
      |> matching_subject_triples(subject)
      |> Stream.flat_map(fn {description, subject_solutions} ->
        case match(description, solve_variables(subject_solutions, triple_pattern)) do
          nil -> []
          solutions -> Stream.map(solutions, &Map.merge(&1, subject_solutions))
        end
      end)
    else
      case graph[subject] do
        nil -> nil
        description -> match(description, triple_pattern)
      end
    end
  end

  defp match(%Description{predications: predications}, {_, variable, variable})
       when is_atom(variable) do
    Stream.flat_map(predications, fn {predicate, objects} ->
      if Map.has_key?(objects, predicate) do
        [%{variable => predicate}]
      else
        []
      end
    end)
  end

  defp match(%Description{predications: predications}, {_, predicate_variable, object_variable})
       when is_atom(predicate_variable) and is_atom(object_variable) do
    Stream.flat_map(predications, fn {predicate, objects} ->
      Stream.map(objects, fn {object, _} ->
        %{predicate_variable => predicate, object_variable => object}
      end)
    end)
  end

  defp match(%Description{predications: predications}, {_, predicate_variable, object})
       when is_atom(predicate_variable) do
    if quoted_triple_with_variables?(object) do
      Stream.flat_map(predications, fn {predicate, objects} ->
        objects
        |> matching_object_triples(object)
        |> Stream.map(&Map.put(&1, predicate_variable, predicate))
      end)
    else
      Stream.flat_map(predications, fn {predicate, objects} ->
        if Map.has_key?(objects, object) do
          [%{predicate_variable => predicate}]
        else
          []
        end
      end)
    end
  end

  defp match(%Description{predications: predications}, {_, predicate, object_or_variable}) do
    if objects = predications[predicate] do
      if quoted_triple_with_variables?(object_or_variable) do
        matching_object_triples(objects, object_or_variable)
        matching_object_triples(objects, object_or_variable)
      else
        cond do
          # object_or_variable is a variable
          is_atom(object_or_variable) ->
            Stream.map(objects, fn {object, _} -> %{object_or_variable => object} end)

          # object_or_variable is a object
          Map.has_key?(objects, object_or_variable) ->
            to_stream([%{}])

          # else
          true ->
            nil
        end
      end
    end
  end

  defp matching_subject_triples(graph, triple_pattern) do
    Stream.flat_map(graph.descriptions, fn
      {subject, description} when is_triple(subject) ->
        case match_triple(subject, triple_pattern) do
          nil -> []
          solutions -> [{description, solutions}]
        end

      _ ->
        []
    end)
  end

  defp matching_object_triples(objects, triple_pattern) do
    Stream.flat_map(objects, fn
      {object, _} when is_triple(object) -> match_triple(object, triple_pattern) |> List.wrap()
      _ -> []
    end)
  end

  defp to_stream(enum), do: Stream.into(enum, [])
end
