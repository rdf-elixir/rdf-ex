defprotocol RDF.Data do
  @moduledoc """
  An abstraction over the different data structures for collections of RDF statements.
  """

  @doc """
  Adds statements to an RDF data structure.

  As opposed to the specific `add` functions on the RDF data structures, which
  always return the same structure type than the first argument, `merge` might
  result in another RDF data structure, e.g. merging two `RDF.Description` with
  different subjects results in a `RDF.Graph` or adding a quad to a `RDF.Graph`
  with a different name than the graph context of the quad results in a
  `RDF.Dataset`. But it is always guaranteed that the resulting structure has
  a `RDF.Data` implementation.
  """
  def merge(data, input, opts \\ [])

  @doc """
  Deletes statements from an RDF data structure.

  As opposed to the `delete` functions on RDF data structures directly, this
  function only deletes exactly matching structures.
  """
  def delete(data, input, opts \\ [])

  @doc """
  Deletes one statement from an RDF data structure and returns a tuple with deleted statement and the changed data structure.
  """
  def pop(data)

  @doc """
  Returns if the given RDF data structure is empty.
  """
  def empty?(data)

  @doc """
  Checks if the given statement exists within an RDF data structure.
  """
  def include?(data, input, opts \\ [])

  @doc """
  Checks if an RDF data structure contains statements about the given resource.
  """
  def describes?(data, subject)

  @doc """
  Returns a `RDF.Description` of the given subject.

  Note: On a `RDF.Dataset` this will return an aggregated `RDF.Description` with
  the statements about this subject from all graphs.
  """
  def description(data, subject)

  @doc """
  Returns all `RDF.Description`s within an RDF data structure.

  Note: On a `RDF.Dataset` this will return aggregated `RDF.Description`s about
  the same subject from all graphs.
  """
  def descriptions(data)

  @doc """
  Returns the list of all statements of an RDF data structure.
  """
  def statements(data)

  @doc """
  Returns the set of all resources which are subject of the statements of an RDF data structure.
  """
  def subjects(data)

  @doc """
  Returns the set of all properties used within the statements of an RDF data structure.
  """
  def predicates(data)

  @doc """
  Returns the set of all resources used in the objects within the statements of an RDF data structure.
  """
  def objects(data)

  @doc """
  Returns the set of all resources used within the statements of an RDF data structure
  """
  def resources(data)

  @doc """
  Returns the count of all resources which are subject of the statements of an RDF data structure.
  """
  def subject_count(data)

  @doc """
  Returns the count of all statements of an RDF data structure.
  """
  def statement_count(data)

  @doc """
  Returns a nested map of the native Elixir values of an RDF data structure.

  When a `:context` option is given with a `RDF.PropertyMap`, predicates will
  be mapped to the terms defined in the `RDF.PropertyMap`, if present.
  """
  def values(data, opts \\ [])

  @doc """
  Returns a map representation of an RDF data structure where each element from its statements is mapped with the given function.
  """
  def map(data, fun)

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
  alias RDF.{Description, Graph, Dataset, Statement}

  def merge(description, input, opts \\ [])

  def merge(%Description{subject: subject} = description, {s, _, _} = triple, opts) do
    case Statement.coerce_subject(s) do
      ^subject -> Description.add(description, triple, opts)
      _ -> description |> Graph.new() |> Graph.add(triple, opts)
    end
  end

  def merge(description, {_, _, _, _} = quad, opts),
    do: Dataset.new(description) |> Dataset.add(quad, opts)

  def merge(
        %Description{subject: subject} = description,
        %Description{subject: other_subject} = other_description,
        opts
      )
      when other_subject == subject,
      do: Description.add(description, other_description, opts)

  def merge(description, %Description{} = other_description, opts),
    do: Graph.new(description) |> Graph.add(other_description, opts)

  def merge(description, %Graph{} = graph, opts),
    do: RDF.Data.merge(graph, description, opts)

  def merge(description, %Dataset{} = dataset, opts),
    do: RDF.Data.merge(dataset, description, opts)

  def merge(description, %_{} = other, opts) do
    if RDF.Data.impl_for(other) do
      RDF.Data.merge(other, description, opts)
    else
      raise ArgumentError, "no RDF.Data implementation found for #{inspect(other)}"
    end
  end

  def delete(description, input, opts \\ [])

  def delete(
        %Description{subject: subject} = description,
        %Description{subject: other_subject},
        _opts
      )
      when subject != other_subject,
      do: description

  def delete(description, input, opts), do: Description.delete(description, input, opts)

  def pop(description), do: Description.pop(description)

  def empty?(description), do: Description.empty?(description)

  def include?(description, input, opts \\ []),
    do: Description.include?(description, input, opts)

  def describes?(description, subject),
    do: Description.describes?(description, subject)

  def description(%Description{subject: subject} = description, s) do
    if match?(^subject, Statement.coerce_subject(s)) do
      description
    else
      Description.new(s)
    end
  end

  def descriptions(description), do: [description]

  def statements(description), do: Description.statements(description)

  def subjects(%Description{subject: subject}), do: MapSet.new([subject])
  def predicates(description), do: Description.predicates(description)
  def objects(description), do: Description.objects(description)

  def resources(%Description{subject: subject} = description),
    do: Description.resources(description) |> MapSet.put(subject)

  def subject_count(_), do: 1
  def statement_count(description), do: Description.count(description)

  def values(description, opts \\ []),
    do: Description.values(description, opts)

  def map(description, fun), do: Description.map(description, fun)

  def equal?(description, %Description{} = other_description) do
    Description.equal?(description, other_description)
  end

  def equal?(description, %Graph{} = graph) do
    case Graph.descriptions(graph) do
      [single_description] -> Description.equal?(description, single_description)
      _ -> false
    end
  end

  def equal?(description, %Dataset{} = dataset) do
    RDF.Data.equal?(dataset, description)
  end

  def equal?(description, %_{} = other) do
    if RDF.Data.impl_for(other) do
      RDF.Data.equal?(other, description)
    else
      raise ArgumentError, "no RDF.Data implementation found for #{inspect(other)}"
    end
  end

  def equal?(_, _), do: false
end

defimpl RDF.Data, for: RDF.Graph do
  alias RDF.{Description, Graph, Dataset, Statement}

  def merge(graph, input, opts \\ [])

  def merge(%Graph{name: name} = graph, {_, _, _, graph_context} = quad, opts) do
    case Statement.coerce_graph_name(graph_context) do
      ^name -> Graph.add(graph, quad, opts)
      _ -> graph |> Dataset.new() |> Dataset.add(quad, opts)
    end
  end

  def merge(graph, {_, _, _} = triple, opts),
    do: Graph.add(graph, triple, opts)

  def merge(description, {_, _, _, _} = quad, opts),
    do: Dataset.new(description) |> Dataset.add(quad, opts)

  def merge(graph, %Description{} = description, opts),
    do: Graph.add(graph, description, opts)

  def merge(
        %Graph{name: name} = graph,
        %Graph{name: other_name} = other_graph,
        opts
      )
      when other_name == name,
      do: Graph.add(graph, other_graph, opts)

  def merge(graph, %Graph{} = other_graph, opts),
    do: Dataset.new(graph) |> Dataset.add(other_graph, opts)

  def merge(graph, %Dataset{} = dataset, opts),
    do: RDF.Data.merge(dataset, graph, opts)

  def merge(graph, %_{} = other, opts) do
    if RDF.Data.impl_for(other) do
      RDF.Data.merge(other, graph, opts)
    else
      raise ArgumentError, "no RDF.Data implementation found for #{inspect(other)}"
    end
  end

  def delete(graph, input, opts \\ [])

  def delete(%Graph{name: name} = graph, %Graph{name: other_name}, _opts)
      when name != other_name,
      do: graph

  def delete(graph, input, opts), do: Graph.delete(graph, input, opts)

  def pop(graph), do: Graph.pop(graph)

  def empty?(graph), do: Graph.empty?(graph)

  def include?(graph, input, opts \\ []), do: Graph.include?(graph, input, opts)

  def describes?(graph, subject), do: Graph.describes?(graph, subject)

  def description(graph, subject), do: Graph.description(graph, subject)

  def descriptions(graph), do: Graph.descriptions(graph)

  def statements(graph), do: Graph.statements(graph)

  def subjects(graph), do: Graph.subjects(graph)
  def predicates(graph), do: Graph.predicates(graph)
  def objects(graph), do: Graph.objects(graph)
  def resources(graph), do: Graph.resources(graph)

  def subject_count(graph), do: Graph.subject_count(graph)
  def statement_count(graph), do: Graph.triple_count(graph)
  def values(graph, opts \\ []), do: Graph.values(graph, opts)
  def map(graph, fun), do: Graph.map(graph, fun)

  def equal?(graph, %Description{} = description),
    do: RDF.Data.equal?(description, graph)

  def equal?(graph, %Graph{} = other_graph),
    do:
      Graph.equal?(
        %Graph{graph | name: nil},
        %Graph{other_graph | name: nil}
      )

  def equal?(graph, %Dataset{} = dataset),
    do: RDF.Data.equal?(dataset, graph)

  def equal?(graph, %_{} = other) do
    if RDF.Data.impl_for(other) do
      RDF.Data.equal?(other, graph)
    else
      raise ArgumentError, "no RDF.Data implementation found for #{inspect(other)}"
    end
  end

  def equal?(_, _), do: false
end

defimpl RDF.Data, for: RDF.Dataset do
  alias RDF.{Description, Graph, Dataset, Statement}

  def merge(dataset, input, opts \\ [])

  def merge(dataset, {_, _, _} = triple, opts),
    do: Dataset.add(dataset, triple, opts)

  def merge(dataset, {_, _, _, _} = quad, opts),
    do: Dataset.add(dataset, quad, opts)

  def merge(dataset, %Description{} = description, opts),
    do: Dataset.add(dataset, description, opts)

  def merge(dataset, %Graph{} = graph, opts),
    do: Dataset.add(dataset, graph, opts)

  def merge(dataset, %Dataset{} = other_dataset, opts),
    do: Dataset.add(dataset, other_dataset, opts)

  def merge(dataset, %_{} = other, opts) do
    if RDF.Data.impl_for(other) do
      RDF.Data.merge(other, dataset, opts)
    else
      raise ArgumentError, "no RDF.Data implementation found for #{inspect(other)}"
    end
  end

  def delete(dataset, input, opts \\ [])

  def delete(%Dataset{name: name} = dataset, %Dataset{name: other_name}, _opts)
      when name != other_name,
      do: dataset

  def delete(dataset, input, opts), do: Dataset.delete(dataset, input, opts)

  def pop(dataset), do: Dataset.pop(dataset)

  def empty?(dataset), do: Dataset.empty?(dataset)

  def include?(dataset, input, opts), do: Dataset.include?(dataset, input, opts)

  def describes?(dataset, subject),
    do: Dataset.who_describes(dataset, subject) != []

  def description(dataset, subject) do
    subject = Statement.coerce_subject(subject)

    Enum.reduce(Dataset.graphs(dataset), Description.new(subject), fn
      %Graph{descriptions: %{^subject => graph_description}}, description ->
        Description.add(description, graph_description)

      _, description ->
        description
    end)
  end

  def descriptions(dataset) do
    dataset
    |> subjects
    |> Enum.map(&description(dataset, &1))
  end

  def statements(dataset), do: Dataset.statements(dataset)

  def subjects(dataset), do: Dataset.subjects(dataset)
  def predicates(dataset), do: Dataset.predicates(dataset)
  def objects(dataset), do: Dataset.objects(dataset)
  def resources(dataset), do: Dataset.resources(dataset)

  def subject_count(dataset), do: dataset |> subjects() |> MapSet.size()

  def statement_count(dataset), do: Dataset.statement_count(dataset)
  def values(dataset, opts \\ []), do: Dataset.values(dataset, opts)
  def map(dataset, fun), do: Dataset.map(dataset, fun)

  def equal?(dataset, %Description{} = description) do
    case Dataset.graphs(dataset) do
      [graph] -> RDF.Data.equal?(description, graph)
      _ -> false
    end
  end

  def equal?(dataset, %Graph{} = graph) do
    case Dataset.graphs(dataset) do
      [single_graph] -> Graph.equal?(graph, single_graph)
      _ -> false
    end
  end

  def equal?(dataset, %Dataset{} = other_dataset) do
    Dataset.equal?(
      %Dataset{dataset | name: nil},
      %Dataset{other_dataset | name: nil}
    )
  end

  def equal?(dataset, %_{} = other) do
    if RDF.Data.impl_for(other) do
      RDF.Data.equal?(other, dataset)
    else
      raise ArgumentError, "no RDF.Data implementation found for #{inspect(other)}"
    end
  end

  def equal?(_, _), do: false
end
