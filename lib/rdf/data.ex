defprotocol RDF.Data do
  @moduledoc """
  An abstraction over the different data structures for collections of RDF statements.
  """

  @doc """
  Adds statements to a RDF data structure.

  As opposed to the specific `add` functions on the RDF data structures, which
  always return the same structure type than the first argument, `merge` might
  result in another RDF data structure, eg. merging two `RDF.Description` with
  different subjects results in a `RDF.Graph` or adding a quad to a `RDF.Graph`
  with a different name than the graph context of the quad results in a
  `RDF.Dataset`. But it is always guaranteed that the resulting structure has
  a `RDF.Data` implementation.
  """
  def merge(data, statements)

  @doc """
  Deletes statements from a RDF data structure.

  As opposed to the `delete` functions on RDF data structures directly, this
  function only deletes exactly matching structures.

  TODO: rename this function to make the different semantics explicit
  """
  def delete(data, statements)

  @doc """
  Deletes one statement from a RDF data structure and returns a tuple with deleted statement and the changed data structure.
  """
  def pop(data)

  @doc """
  Checks if the given statement exists within a RDF data structure.
  """
  def include?(data, statements)

  @doc """
  Checks if a RDF data structure contains statements about the given resource.
  """
  def describes?(data, subject)

  @doc """
  Returns a `RDF.Description` of the given subject.

  Note: On a `RDF.Dataset` this will return an aggregated `RDF.Description` with
  the statements about this subject from all graphs.
  """
  def description(data, subject)

  @doc """
  Returns all `RDF.Description`s within a RDF data structure.

  Note: On a `RDF.Dataset` this will return aggregated `RDF.Description`s about
  the same subject from all graphs.
  """
  def descriptions(data)

  @doc """
  Returns the list of all statements of a RDF data structure.
  """
  def statements(data)

  @doc """
  Returns the set of all resources which are subject of the statements of a RDF data structure.
  """
  def subjects(data)

  @doc """
  Returns the set of all properties used within the statements of RDF data structure.
  """
  def predicates(data)

  @doc """
  Returns the  set of all resources used in the objects within the statements of a RDF data structure.
  """
  def objects(data)

  @doc """
  Returns the set of all resources used within the statements of a RDF data structure
  """
  def resources(data)

  @doc """
  Returns the count of all resources which are subject of the statements of a RDF data structure.
  """
  def subject_count(data)

  @doc """
  Returns the count of all statements of a RDF data structure.
  """
  def statement_count(data)

  @doc """
  Returns a nested map of the native Elixir values of a RDF data structure.
  """
  def values(data)

  @doc """
  Returns a nested map of the native Elixir values of a RDF data structure with values mapped with the given function.
  """
  def values(data, mapping)

  @doc """
  Checks if two RDF data structures are equal.

  Two RDF data structures are considered to be equal if they contain the same triples.

  - comparing two `RDF.Description`s it's just the same as `RDF.Description.equal?/2`
  - comparing two `RDF.Graph`s differs in `RDF.Graph.equal?/2` in that the graph
    name is ignored
  - comparing two `RDF.Dataset`s differs in `RDF.Dataset.equal?/2` in that the
    dataset name is ignored
  - a `RDF.Description` is equal to a `RDF.Graph`, if the graph has just one
    description which equals the given description
  - a `RDF.Description` is equal to a `RDF.Dataset`, if the dataset has just one
    graph which contains only the given description
  - a `RDF.Graph` is equal to a `RDF.Dataset`, if the dataset has just one
    graph which equals the given graph; note that in this case the graph names
    must match
  """
  def equal?(data1, data2)
end

defimpl RDF.Data, for: RDF.Description do
  def merge(%RDF.Description{subject: subject} = description, {s, _, _} = triple) do
    with ^subject <- RDF.Statement.coerce_subject(s) do
      RDF.Description.add(description, triple)
    else
      _ ->
        RDF.Graph.new(description)
        |> RDF.Graph.add(triple)
    end
  end

  def merge(description, {_, _, _, _} = quad),
    do: RDF.Dataset.new(description) |> RDF.Dataset.add(quad)

  def merge(
        %RDF.Description{subject: subject} = description,
        %RDF.Description{subject: other_subject} = other_description
      )
      when other_subject == subject,
      do: RDF.Description.add(description, other_description)

  def merge(description, %RDF.Description{} = other_description),
    do: RDF.Graph.new(description) |> RDF.Graph.add(other_description)

  def merge(description, %RDF.Graph{} = graph),
    do: RDF.Data.merge(graph, description)

  def merge(description, %RDF.Dataset{} = dataset),
    do: RDF.Data.merge(dataset, description)

  def delete(
        %RDF.Description{subject: subject} = description,
        %RDF.Description{subject: other_subject}
      )
      when subject != other_subject,
      do: description

  def delete(description, statements), do: RDF.Description.delete(description, statements)

  def pop(description), do: RDF.Description.pop(description)

  def include?(description, statements),
    do: RDF.Description.include?(description, statements)

  def describes?(description, subject),
    do: RDF.Description.describes?(description, subject)

  def description(%RDF.Description{subject: subject} = description, s) do
    with ^subject <- RDF.Statement.coerce_subject(s) do
      description
    else
      _ -> RDF.Description.new(s)
    end
  end

  def descriptions(description), do: [description]

  def statements(description), do: RDF.Description.statements(description)

  def subjects(%RDF.Description{subject: subject}), do: MapSet.new([subject])
  def predicates(description), do: RDF.Description.predicates(description)
  def objects(description), do: RDF.Description.objects(description)

  def resources(%RDF.Description{subject: subject} = description),
    do: RDF.Description.resources(description) |> MapSet.put(subject)

  def subject_count(_), do: 1
  def statement_count(description), do: RDF.Description.count(description)
  def values(description), do: RDF.Description.values(description)
  def values(description, mapping), do: RDF.Description.values(description, mapping)

  def equal?(description, %RDF.Description{} = other_description) do
    RDF.Description.equal?(description, other_description)
  end

  def equal?(description, %RDF.Graph{} = graph) do
    with [single_description] <- RDF.Graph.descriptions(graph) do
      RDF.Description.equal?(description, single_description)
    else
      _ -> false
    end
  end

  def equal?(description, %RDF.Dataset{} = dataset) do
    RDF.Data.equal?(dataset, description)
  end

  def equal?(_, _), do: false
end

defimpl RDF.Data, for: RDF.Graph do
  def merge(%RDF.Graph{name: name} = graph, {_, _, _, graph_context} = quad) do
    with ^name <- RDF.Statement.coerce_graph_name(graph_context) do
      RDF.Graph.add(graph, quad)
    else
      _ ->
        RDF.Dataset.new(graph)
        |> RDF.Dataset.add(quad)
    end
  end

  def merge(graph, {_, _, _} = triple),
    do: RDF.Graph.add(graph, triple)

  def merge(description, {_, _, _, _} = quad),
    do: RDF.Dataset.new(description) |> RDF.Dataset.add(quad)

  def merge(graph, %RDF.Description{} = description),
    do: RDF.Graph.add(graph, description)

  def merge(
        %RDF.Graph{name: name} = graph,
        %RDF.Graph{name: other_name} = other_graph
      )
      when other_name == name,
      do: RDF.Graph.add(graph, other_graph)

  def merge(graph, %RDF.Graph{} = other_graph),
    do: RDF.Dataset.new(graph) |> RDF.Dataset.add(other_graph)

  def merge(graph, %RDF.Dataset{} = dataset),
    do: RDF.Data.merge(dataset, graph)

  def delete(%RDF.Graph{name: name} = graph, %RDF.Graph{name: other_name})
      when name != other_name,
      do: graph

  def delete(graph, statements), do: RDF.Graph.delete(graph, statements)

  def pop(graph), do: RDF.Graph.pop(graph)

  def include?(graph, statements), do: RDF.Graph.include?(graph, statements)

  def describes?(graph, subject),
    do: RDF.Graph.describes?(graph, subject)

  def description(graph, subject),
    do: RDF.Graph.description(graph, subject) || RDF.Description.new(subject)

  def descriptions(graph), do: RDF.Graph.descriptions(graph)

  def statements(graph), do: RDF.Graph.statements(graph)

  def subjects(graph), do: RDF.Graph.subjects(graph)
  def predicates(graph), do: RDF.Graph.predicates(graph)
  def objects(graph), do: RDF.Graph.objects(graph)
  def resources(graph), do: RDF.Graph.resources(graph)

  def subject_count(graph), do: RDF.Graph.subject_count(graph)
  def statement_count(graph), do: RDF.Graph.triple_count(graph)
  def values(graph), do: RDF.Graph.values(graph)
  def values(graph, mapping), do: RDF.Graph.values(graph, mapping)

  def equal?(graph, %RDF.Description{} = description),
    do: RDF.Data.equal?(description, graph)

  def equal?(graph, %RDF.Graph{} = other_graph),
    do:
      RDF.Graph.equal?(
        %RDF.Graph{graph | name: nil},
        %RDF.Graph{other_graph | name: nil}
      )

  def equal?(graph, %RDF.Dataset{} = dataset),
    do: RDF.Data.equal?(dataset, graph)

  def equal?(_, _), do: false
end

defimpl RDF.Data, for: RDF.Dataset do
  def merge(dataset, {_, _, _} = triple),
    do: RDF.Dataset.add(dataset, triple)

  def merge(dataset, {_, _, _, _} = quad),
    do: RDF.Dataset.add(dataset, quad)

  def merge(dataset, %RDF.Description{} = description),
    do: RDF.Dataset.add(dataset, description)

  def merge(dataset, %RDF.Graph{} = graph),
    do: RDF.Dataset.add(dataset, graph)

  def merge(dataset, %RDF.Dataset{} = other_dataset),
    do: RDF.Dataset.add(dataset, other_dataset)

  def delete(%RDF.Dataset{name: name} = dataset, %RDF.Dataset{name: other_name})
      when name != other_name,
      do: dataset

  def delete(dataset, statements), do: RDF.Dataset.delete(dataset, statements)

  def pop(dataset), do: RDF.Dataset.pop(dataset)

  def include?(dataset, statements), do: RDF.Dataset.include?(dataset, statements)

  def describes?(dataset, subject),
    do: RDF.Dataset.who_describes(dataset, subject) != []

  def description(dataset, subject) do
    with subject = RDF.Statement.coerce_subject(subject) do
      Enum.reduce(RDF.Dataset.graphs(dataset), RDF.Description.new(subject), fn
        %RDF.Graph{descriptions: %{^subject => graph_description}}, description ->
          RDF.Description.add(description, graph_description)

        _, description ->
          description
      end)
    end
  end

  def descriptions(dataset) do
    dataset
    |> subjects
    |> Enum.map(&description(dataset, &1))
  end

  def statements(dataset), do: RDF.Dataset.statements(dataset)

  def subjects(dataset), do: RDF.Dataset.subjects(dataset)
  def predicates(dataset), do: RDF.Dataset.predicates(dataset)
  def objects(dataset), do: RDF.Dataset.objects(dataset)
  def resources(dataset), do: RDF.Dataset.resources(dataset)

  def subject_count(dataset), do: dataset |> subjects |> Enum.count()
  def statement_count(dataset), do: RDF.Dataset.statement_count(dataset)
  def values(dataset), do: RDF.Dataset.values(dataset)
  def values(dataset, mapping), do: RDF.Dataset.values(dataset, mapping)

  def equal?(dataset, %RDF.Description{} = description) do
    with [graph] <- RDF.Dataset.graphs(dataset) do
      RDF.Data.equal?(description, graph)
    else
      _ -> false
    end
  end

  def equal?(dataset, %RDF.Graph{} = graph) do
    with [single_graph] <- RDF.Dataset.graphs(dataset) do
      RDF.Graph.equal?(graph, single_graph)
    else
      _ -> false
    end
  end

  def equal?(dataset, %RDF.Dataset{} = other_dataset) do
    RDF.Dataset.equal?(
      %RDF.Dataset{dataset | name: nil},
      %RDF.Dataset{other_dataset | name: nil}
    )
  end

  def equal?(_, _), do: false
end
