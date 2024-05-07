defmodule RDF.TurtleTriG.Encoder.CompactStarGraph do
  @moduledoc !"""
             A compact graph representation in which annotations are directly stored under
             the objects of the annotated triples.

             This representation is not meant for direct use, but just for the Turtle and TriG encoders.
             """

  alias RDF.{Graph, Description}

  def compact(graph, false), do: graph

  def compact(graph, true) do
    Enum.reduce(graph.descriptions, graph, fn
      {{_, _, _} = quoted_triple, _}, compact_graph ->
        # First check the original graph to see if the quoted triple is asserted.
        if Graph.include?(graph, quoted_triple) do
          annotation =
            compact_graph
            # We'll have to re-fetch the description, since the compact_graph might already contain
            # an updated description with an annotation.
            |> Graph.description(quoted_triple)
            |> as_annotation()

          compact_graph
          |> add_annotation(quoted_triple, annotation)
          |> Graph.delete_descriptions(quoted_triple)
        else
          compact_graph
        end

      _, compact_graph ->
        compact_graph
    end)
  end

  defp add_annotation(compact_graph, {{_, _, _} = quoted_triple, p, o} = triple, annotation) do
    # Check if the compact graph still contains the annotated triple, we want to put the annotation under.
    if Graph.describes?(compact_graph, quoted_triple) do
      do_add_annotation(compact_graph, triple, annotation)
    else
      # It's not there anymore, which means the description of the quoted triple was already moved as an annotation.
      # Next we have to search recursively for the annotation, we want to put the nested annotation under.
      path = find_annotation_path(compact_graph, quoted_triple, [p, o])
      do_add_annotation(compact_graph, path, annotation)
    end
  end

  defp add_annotation(compact_graph, triple, annotation) do
    do_add_annotation(compact_graph, triple, annotation)
  end

  defp do_add_annotation(compact_graph, {s, p, o}, annotation) do
    update_in(compact_graph, [s], &put_in(&1.predications[p][o], annotation))
  end

  defp do_add_annotation(compact_graph, [s | path], annotation) do
    update_in(compact_graph, [s], &update_annotation_in(&1, path, annotation))
  end

  defp update_annotation_in(_, [], annotation), do: annotation

  defp update_annotation_in(description, [p, o | rest], annotation) do
    %Description{
      description
      | predications:
          update_in(description.predications, [p, o], &update_annotation_in(&1, rest, annotation))
    }
  end

  defp find_annotation_path(compact_graph, {s, p, o}, path) do
    cond do
      Graph.describes?(compact_graph, s) -> [s, p, o | path]
      match?({_, _, _}, s) -> find_annotation_path(compact_graph, s, [p, o | path])
    end
  end

  defp as_annotation(description), do: %{description | subject: nil}
end
