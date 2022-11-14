defmodule RDF.Star.Graph do
  @moduledoc !"""
             Functions on RDF-star graphs.

             These functions are not meant to be used directly, but through the
             respective delegator functions on `RDF.Graph`.
             """

  alias RDF.{Graph, Description}
  alias RDF.Star.Statement

  import RDF.Sigils

  def clear_annotation_opts(opts),
    do: Keyword.drop(opts, ~w[add_annotations put_annotations put_annotation_properties]a)

  def normalize_annotation_opts(opts) do
    cond do
      Enum.empty?(opts) ->
        opts

      put_annotations = Keyword.get(opts, :put_annotations) ->
        Keyword.put(opts, :put_annotations, normalize_annotations(put_annotations))

      put_annotation_properties = Keyword.get(opts, :put_annotation_properties) ->
        Keyword.put(
          opts,
          :put_annotation_properties,
          normalize_annotations(put_annotation_properties)
        )

      add_annotations = Keyword.get(opts, :add_annotations) ->
        Keyword.put(opts, :add_annotations, normalize_annotations(add_annotations))

      true ->
        opts
    end
  end

  defp normalize_annotations(nil), do: nil
  defp normalize_annotations(%Description{} = annotation), do: annotation
  defp normalize_annotations(annotation), do: Description.new(~B<placeholder>, init: annotation)

  @spec annotations(Graph.t()) :: Graph.t()
  def annotations(%Graph{} = graph) do
    %Graph{
      graph
      | descriptions:
          for(annotation = {{_, _, _}, _} <- graph.descriptions, into: %{}, do: annotation)
    }
  end

  @spec without_annotations(Graph.t()) :: Graph.t()
  def without_annotations(%Graph{} = graph) do
    %Graph{
      graph
      | descriptions:
          for(
            non_annotation = {subject, _} when not is_tuple(subject) <- graph.descriptions,
            into: %{},
            do: non_annotation
          )
    }
  end

  @spec without_star_statements(Graph.t()) :: Graph.t()
  def without_star_statements(%Graph{} = graph) do
    %Graph{
      graph
      | descriptions:
          Enum.reduce(graph.descriptions, graph.descriptions, fn
            {subject, description}, descriptions when not is_tuple(subject) ->
              description_without_quoted_triples =
                Description.without_quoted_triple_objects(description)

              if Description.empty?(description_without_quoted_triples) do
                Map.delete(descriptions, subject)
              else
                Map.put(descriptions, subject, description_without_quoted_triples)
              end

            {subject, _}, descriptions ->
              Map.delete(descriptions, subject)
          end)
    }
  end

  @spec add_annotations(Graph.t(), Graph.input(), Description.input() | nil) :: Graph.t()
  def add_annotations(graph, statements, annotations)

  def add_annotations(%Graph{} = graph, %rdf_struct{} = statements, annotations)
      when rdf_struct in [Graph, Description] do
    if annotations = normalize_annotations(annotations) do
      Enum.reduce(statements, graph, &Graph.add(&2, Description.change_subject(annotations, &1)))
    else
      graph
    end
  end

  def add_annotations(graph, statements, annotations) do
    add_annotations(graph, Graph.new(statements), annotations)
  end

  @spec put_annotations(Graph.t(), Graph.input(), Description.input() | nil) :: Graph.t()
  def put_annotations(graph, statements, annotations)

  def put_annotations(%Graph{} = graph, %rdf_struct{} = statements, annotations)
      when rdf_struct in [Graph, Description] do
    if annotations = normalize_annotations(annotations) do
      Enum.reduce(
        statements,
        graph,
        &%Graph{
          &2
          | descriptions:
              Map.put(&2.descriptions, &1, Description.change_subject(annotations, &1))
        }
      )
    else
      graph
    end
  end

  def put_annotations(graph, statements, annotations) do
    put_annotations(graph, Graph.new(statements), annotations)
  end

  @spec put_annotation_properties(Graph.t(), Graph.input(), Description.input() | nil) ::
          Graph.t()
  def put_annotation_properties(graph, statements, annotations)

  def put_annotation_properties(%Graph{} = graph, %rdf_struct{} = statements, annotations)
      when rdf_struct in [Graph, Description] do
    if annotations = normalize_annotations(annotations) do
      Enum.reduce(
        statements,
        graph,
        &Graph.put_properties(&2, Description.change_subject(annotations, &1))
      )
    else
      graph
    end
  end

  def put_annotation_properties(graph, statements, annotations) do
    put_annotation_properties(graph, Graph.new(statements), annotations)
  end

  @spec delete_annotations(
          Graph.t(),
          Graph.input(),
          boolean | Statement.coercible_predicate() | [Statement.coercible_predicate()]
        ) :: Graph.t()
  def delete_annotations(graph, statements, delete \\ true)
  def delete_annotations(graph, _, false), do: graph

  def delete_annotations(graph, statements, true) do
    Graph.delete_descriptions(graph, statements |> Graph.new() |> Graph.triples())
  end

  def delete_annotations(graph, statements, predicates) do
    statements
    |> Graph.new()
    |> Enum.reduce(graph, fn triple, graph ->
      Graph.update(graph, triple, &Description.delete_predicates(&1, predicates))
    end)
  end

  def handle_addition_annotations(graph, statements, opts) do
    cond do
      Enum.empty?(opts) ->
        graph

      put_annotations = Keyword.get(opts, :put_annotations) ->
        put_annotations(graph, annotation_statements(statements, opts), put_annotations)

      put_annotation_properties = Keyword.get(opts, :put_annotation_properties) ->
        put_annotation_properties(
          graph,
          annotation_statements(statements, opts),
          put_annotation_properties
        )

      add_annotations = Keyword.get(opts, :add_annotations) ->
        add_annotations(graph, annotation_statements(statements, opts), add_annotations)

      true ->
        graph
    end
  end

  def handle_overwrite_annotations(graph, original_graph, statements, opts) do
    cond do
      Enum.empty?(opts) ->
        graph

      delete_annotations = Keyword.get(opts, :delete_annotations_on_deleted) ->
        delete_annotations(graph, deletions(original_graph, statements), delete_annotations)

      put_annotations = Keyword.get(opts, :put_annotations_on_deleted) ->
        put_annotations(graph, deletions(original_graph, statements), put_annotations)

      put_annotation_properties = Keyword.get(opts, :put_annotation_properties_on_deleted) ->
        put_annotation_properties(
          graph,
          deletions(original_graph, statements),
          put_annotation_properties
        )

      add_annotations = Keyword.get(opts, :add_annotations_on_deleted) ->
        add_annotations(graph, deletions(original_graph, statements), add_annotations)

      true ->
        graph
    end
  end

  def handle_deletion_annotations(graph, statements, opts) do
    cond do
      Enum.empty?(opts) ->
        graph

      delete_annotations = Keyword.get(opts, :delete_annotations) ->
        delete_annotations(graph, annotation_statements(statements, opts), delete_annotations)

      put_annotations = Keyword.get(opts, :put_annotations) ->
        put_annotations(graph, annotation_statements(statements, opts), put_annotations)

      put_annotation_properties = Keyword.get(opts, :put_annotation_properties) ->
        put_annotation_properties(
          graph,
          annotation_statements(statements, opts),
          put_annotation_properties
        )

      add_annotations = Keyword.get(opts, :add_annotations) ->
        add_annotations(graph, annotation_statements(statements, opts), add_annotations)

      true ->
        graph
    end
  end

  defp annotation_statements({subject, predications}, opts),
    do: Description.new(subject, Keyword.put(opts, :init, predications))

  defp annotation_statements(statements, _), do: statements

  defp deletions(original, input) do
    diff =
      original
      |> Graph.take(Map.keys(input.descriptions))
      |> RDF.Diff.diff(input)

    diff.deletions
  end
end
