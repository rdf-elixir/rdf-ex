defmodule RDF.Graph do
  @moduledoc """
  Defines a RDF Graph.

  A `RDF.Graph` represents a set of `RDF.Description`s.

  Named vs. unnamed graphs ...
  """
  defstruct name: nil, descriptions: %{}

  alias RDF.{Description, Triple}

  @type t :: module

  @doc """
  Creates an empty unnamed `RDF.Graph`.
  """
  def new,
    do: %RDF.Graph{}

  @doc """
  Creates an unnamed `RDF.Graph` with an initial triple.
  """
  def new(triple = {_, _, _}),
    do: new |> add(triple)

  @doc """
  Creates an unnamed `RDF.Graph` with initial triples.
  """
  def new(triples) when is_list(triples),
    do: new |> add(triples)

  @doc """
  Creates an empty named `RDF.Graph`.
  """
  def new(name),
    do: %RDF.Graph{name: RDF.uri(name)}

  @doc """
  Creates a named `RDF.Graph` with an initial triple.
  """
  def new(name, triple = {_, _, _}),
    do: new(name) |> add(triple)

  @doc """
  Creates a named `RDF.Graph` with initial triples.
  """
  def new(name, triples) when is_list(triples),
    do: new(name) |> add(triples)

  @doc """
  Creates an unnamed `RDF.Graph` with initial triples.
  """
  def new(subject, predicate, objects),
    do: new |> add(subject, predicate, objects)

  @doc """
  Creates a named `RDF.Graph` with initial triples.
  """
  def new(name, subject, predicate, objects),
    do: new(name) |> add(subject, predicate, objects)


  @doc """
  Adds triples to a `RDF.Graph`.
  """
  def add(graph, subject, predicate, objects)

  def add(graph, subject, predicate, objects) when is_list(objects) do
    Enum.reduce objects, graph, fn (object, graph) ->
      add(graph, subject, predicate, object)
    end
  end

  def add(%RDF.Graph{name: name, descriptions: descriptions},
          subject, predicate, object) do
    with triple_subject = Triple.convert_subject(subject),
         updated_descriptions = Map.update(descriptions, triple_subject,
           Description.new({triple_subject, predicate, object}), fn description ->
             description |> Description.add({predicate, object})
           end) do
      %RDF.Graph{name: name, descriptions: updated_descriptions}
    end
  end

  @doc """
  Adds triples to a `RDF.Graph`.
  """
  def add(graph, triples)

  def add(graph, {subject, predicate, object}),
    do: add(graph, subject, predicate, object)

  def add(graph, triples) when is_list(triples) do
    Enum.reduce triples, graph, fn (triple, graph) ->
      add(graph, triple)
    end
  end

  def subject_count(graph), do: Enum.count(graph.descriptions)

  def triple_count(%RDF.Graph{descriptions: descriptions}) do
    Enum.reduce descriptions, 0, fn ({_subject, description}, count) ->
      count + Description.count(description)
    end
  end

  @doc """
  The set of all properties used in the predicates within a `RDF.Graph`.

  # Examples

      iex> RDF.Graph.new([
      ...>   {EX.S1, EX.p1, EX.O1},
      ...>   {EX.S2, EX.p2, EX.O2},
      ...>   {EX.S1, EX.p2, EX.O3}]) |>
      ...>   RDF.Graph.subjects
      MapSet.new([RDF.uri(EX.S1), RDF.uri(EX.S2)])
  """
  def subjects(%RDF.Graph{descriptions: descriptions}),
    do: descriptions |> Map.keys |> MapSet.new

  @doc """
  The set of all properties used in the predicates within a `RDF.Graph`.

  # Examples

      iex> RDF.Graph.new([
      ...>   {EX.S1, EX.p1, EX.O1},
      ...>   {EX.S2, EX.p2, EX.O2},
      ...>   {EX.S1, EX.p2, EX.O3}]) |>
      ...>   RDF.Graph.predicates
      MapSet.new([EX.p1, EX.p2])
  """
  def predicates(%RDF.Graph{descriptions: descriptions}) do
    Enum.reduce descriptions, MapSet.new, fn ({_, description}, acc) ->
      description
      |> Description.predicates
      |> MapSet.union(acc)
    end
  end

  @doc """
  The set of all resources used in the objects within a `RDF.Graph`.

  Note: This function does collect only URIs and BlankNodes, not Literals.

  # Examples

      iex> RDF.Graph.new([
      ...>   {EX.S1, EX.p1, EX.O1},
      ...>   {EX.S2, EX.p2, EX.O2},
      ...>   {EX.S3, EX.p1, EX.O2},
      ...>   {EX.S4, EX.p2, RDF.bnode(:bnode)},
      ...>   {EX.S5, EX.p3, "foo"}
      ...> ]) |> RDF.Graph.objects
      MapSet.new([RDF.uri(EX.O1), RDF.uri(EX.O2), RDF.bnode(:bnode)])
  """
  def objects(%RDF.Graph{descriptions: descriptions}) do
    Enum.reduce descriptions, MapSet.new, fn ({_, description}, acc) ->
      description
      |> Description.objects
      |> MapSet.union(acc)
    end
  end

  @doc """
  The set of all resources used within a `RDF.Graph`.

  # Examples

    iex> RDF.Graph.new([
    ...>   {EX.S1, EX.p1, EX.O1},
    ...>   {EX.S2, EX.p1, EX.O2},
    ...>   {EX.S2, EX.p2, RDF.bnode(:bnode)},
    ...>   {EX.S3, EX.p1, "foo"}
    ...> ]) |> RDF.Graph.resources
    MapSet.new([RDF.uri(EX.S1), RDF.uri(EX.S2), RDF.uri(EX.S3),
      RDF.uri(EX.O1), RDF.uri(EX.O2), RDF.bnode(:bnode), EX.p1, EX.p2])
  """
  def resources(graph = %RDF.Graph{descriptions: descriptions}) do
    Enum.reduce(descriptions, MapSet.new, fn ({_, description}, acc) ->
      description
      |> Description.resources
      |> MapSet.union(acc)
    end) |> MapSet.union(subjects(graph))
  end


  def include?(%RDF.Graph{descriptions: descriptions},
              triple = {subject, _, _}) do
    with triple_subject = Triple.convert_subject(subject),
         %Description{} <- description = descriptions[triple_subject] do
      Description.include?(description, triple)
    else
      _ -> false
    end
  end


  # TODO: Can/should we isolate and move the Enumerable specific part to the Enumerable implementation?

  def reduce(%RDF.Graph{descriptions: descriptions}, {:cont, acc}, _fun)
    when map_size(descriptions) == 0, do: {:done, acc}

  def reduce(graph = %RDF.Graph{}, {:cont, acc}, fun) do
    {triple, rest} = RDF.Graph.pop(graph)
    reduce(rest, fun.(triple, acc), fun)
  end

  def reduce(_,       {:halt, acc}, _fun), do: {:halted, acc}
  def reduce(graph = %RDF.Graph{}, {:suspend, acc}, fun) do
    {:suspended, acc, &reduce(graph, &1, fun)}
  end


  def pop(graph = %RDF.Graph{descriptions: descriptions})
    when descriptions == %{}, do: {nil, graph}

  def pop(%RDF.Graph{name: name, descriptions: descriptions}) do
    # TODO: Find a faster way ...
    [{subject, description}] = Enum.take(descriptions, 1)
    {triple, popped_description} = Description.pop(description)
    popped = if Enum.empty?(popped_description),
      do:   descriptions |> Map.delete(subject),
      else: descriptions |> Map.put(subject, popped_description)

    {triple, %RDF.Graph{name: name, descriptions: popped}}
  end
end

defimpl Enumerable, for: RDF.Graph do
  def reduce(desc, acc, fun), do: RDF.Graph.reduce(desc, acc, fun)
  def member?(desc, triple),  do: {:ok, RDF.Graph.include?(desc, triple)}
  def count(desc),            do: {:ok, RDF.Graph.triple_count(desc)}
end
