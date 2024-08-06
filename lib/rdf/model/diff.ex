defmodule RDF.Diff do
  @moduledoc """
  A data structure for diffs between `RDF.Graph`s and `RDF.Description`s.

  A `RDF.Diff` is a struct consisting of two fields `additions` and `deletions`
  with `RDF.Graph`s of added and deleted statements.
  """

  alias RDF.{Description, Graph}

  @type t :: %__MODULE__{
          additions: Graph.t(),
          deletions: Graph.t()
        }

  defstruct [:additions, :deletions]

  @doc """
  Creates a `RDF.Diff` struct.

  Some initial additions and deletions can be provided optionally with the resp.
  `additions` and `deletions` keywords. The statements for the additions and
  deletions can be provided in any form supported by the `RDF.Graph.new/1` function.
  """
  @spec new(keyword) :: t
  def new(diff \\ []) do
    %__MODULE__{
      additions: Keyword.get(diff, :additions) |> coerce_graph(),
      deletions: Keyword.get(diff, :deletions) |> coerce_graph()
    }
  end

  defp coerce_graph(nil), do: Graph.new()

  defp coerce_graph(%Description{} = description),
    do: if(Description.empty?(description), do: Graph.new(), else: Graph.new(description))

  defp coerce_graph(data), do: Graph.new(init: data)

  @doc """
  Computes a diff between two `RDF.Graph`s or `RDF.Description`s.

  The first argument represents the original and the second argument the new version
  of the RDF data to be compared. Any combination of `RDF.Graph`s or
  `RDF.Description`s can be passed as first and second argument.

  ## Examples

    iex> RDF.Diff.diff(
    ...>   RDF.description(EX.S1, init: {EX.S1, EX.p1, [EX.O1, EX.O2]}),
    ...>   RDF.graph([
    ...>    {EX.S1, EX.p1, [EX.O2, EX.O3]},
    ...>    {EX.S2, EX.p2, EX.O4}
    ...>   ]))
    %RDF.Diff{
      additions: RDF.graph([
        {EX.S1, EX.p1, EX.O3},
        {EX.S2, EX.p2, EX.O4}
      ]),
      deletions: RDF.graph({EX.S1, EX.p1, EX.O1})
    }
  """
  @spec diff(Description.t() | Graph.t(), Description.t() | Graph.t()) :: t
  def diff(original_rdf_data, new_rdf_data)

  def diff(%Description{} = description, description), do: new()

  def diff(
        %Description{subject: subject} = original_description,
        %Description{subject: subject} = new_description
      ) do
    {additions, deletions} =
      original_description
      |> Description.predicates()
      |> Enum.reduce(
        {new_description, Description.new(subject)},
        fn property, {additions, deletions} ->
          original_objects = Description.get(original_description, property)

          case Description.get(new_description, property) do
            nil ->
              {
                additions,
                Description.add(deletions, {property, original_objects})
              }

            new_objects ->
              {unchanged_objects, deleted_objects} =
                Enum.reduce(original_objects, {[], []}, fn
                  original_object, {unchanged_objects, deleted_objects} ->
                    if original_object in new_objects do
                      {[original_object | unchanged_objects], deleted_objects}
                    else
                      {unchanged_objects, [original_object | deleted_objects]}
                    end
                end)

              {
                Description.delete(additions, {property, unchanged_objects}),
                Description.add(deletions, {property, deleted_objects})
              }
          end
        end
      )

    new(additions: additions, deletions: deletions)
  end

  def diff(%Description{} = original_description, %Description{} = new_description),
    do: new(additions: new_description, deletions: original_description)

  def diff(%Graph{} = graph1, %Graph{} = graph2) do
    graph1_subjects = graph1 |> Graph.subjects() |> MapSet.new()
    graph2_subjects = graph2 |> Graph.subjects() |> MapSet.new()
    deleted_subjects = MapSet.difference(graph1_subjects, graph2_subjects)
    added_subjects = MapSet.difference(graph2_subjects, graph1_subjects)

    graph1_subjects
    |> MapSet.intersection(graph2_subjects)
    |> Enum.reduce(
      new(
        additions: Graph.take(graph2, added_subjects),
        deletions: Graph.take(graph1, deleted_subjects)
      ),
      fn subject, diff ->
        union(
          diff,
          diff(
            Graph.description(graph1, subject),
            Graph.description(graph2, subject)
          )
        )
      end
    )
  end

  def diff(%Description{} = description, %Graph{} = graph) do
    case Graph.pop(graph, description.subject) do
      {nil, graph} ->
        new(
          additions: graph,
          deletions: description
        )

      {new_description, graph} ->
        new(additions: graph)
        |> union(diff(description, new_description))
    end
  end

  def diff(%Graph{} = graph, %Description{} = description) do
    diff = diff(description, graph)
    %__MODULE__{diff | additions: diff.deletions, deletions: diff.additions}
  end

  @doc """
  Returns the union of two diffs.

  The diffs are merged by adding up the `additions` and `deletions` of both
  diffs respectively.
  """
  @spec union(t, t) :: t
  def union(%__MODULE__{} = diff1, %__MODULE__{} = diff2) do
    new(
      additions: Graph.add(diff1.additions, diff2.additions),
      deletions: Graph.add(diff1.deletions, diff2.deletions)
    )
  end

  @doc """
  Determines if a diff is empty.

  A `RDF.Diff` is empty, if its `additions` and `deletions` graphs are empty.
  """
  @spec empty?(t) :: boolean
  def empty?(%__MODULE__{} = diff) do
    Enum.empty?(diff.additions) and Enum.empty?(diff.deletions)
  end

  @doc """
  Applies a diff to a `RDF.Graph` or `RDF.Description` by deleting the `deletions` and adding the `additions` of the `diff`.

  Deletions of statements which are not present in the given graph or description
  are simply ignored.

  The result of an application is always a `RDF.Graph`, even if a `RDF.Description`
  is given and the additions from the diff are all about the subject of this description.
  """
  @spec apply(t, Description.t() | Graph.t()) :: Graph.t()
  def apply(diff, rdf_data)

  def apply(%__MODULE__{} = diff, %Graph{} = graph) do
    graph
    |> Graph.delete(diff.deletions)
    |> Graph.add(diff.additions)
  end

  def apply(%__MODULE__{} = diff, %Description{} = description) do
    __MODULE__.apply(diff, Graph.new(description))
  end
end
