defmodule RDF.Dataset do
  @moduledoc """
  A set of `RDF.Graph`s.

  It may have multiple named graphs and at most one unnamed ("default") graph.

  `RDF.Dataset` implements:

  - Elixirs `Access` behaviour
  - Elixirs `Enumerable` protocol
  - Elixirs `Inspect` protocol
  - the `RDF.Data` protocol

  """

  defstruct name: nil, graphs: %{}

  @behaviour Access

  alias RDF.{Graph, Description}
  import RDF.Statement

  @type t :: module


  @doc """
  Creates an empty unnamed `RDF.Dataset`.
  """
  def new,
    do: %RDF.Dataset{}

  @doc """
  Creates an unnamed `RDF.Dataset` with an initial statement.
  """
  def new(statement) when is_tuple(statement),
    do: new() |> add(statement)

  @doc """
  Creates an unnamed `RDF.Dataset` with initial statements.
  """
  def new(statements) when is_list(statements),
    do: new() |> add(statements)

  @doc """
  Creates an unnamed `RDF.Dataset` with a `RDF.Description`.
  """
  def new(%RDF.Description{} = description),
    do: new() |> add(description)

  @doc """
  Creates an unnamed `RDF.Dataset` with a `RDF.Graph`.
  """
  def new(%RDF.Graph{} = graph),
    do: new() |> add(graph, graph.name)

  @doc """
  Creates an unnamed `RDF.Dataset` from another `RDF.Dataset`.
  """
  def new(%RDF.Dataset{graphs: graphs}),
    do: %RDF.Dataset{graphs: graphs}

  @doc """
  Creates an empty named `RDF.Dataset`.
  """
  def new(name),
    do: %RDF.Dataset{name: RDF.uri(name)}

  @doc """
  Creates a named `RDF.Dataset` with an initial statement.
  """
  def new(name, statement) when is_tuple(statement),
    do: new(name) |> add(statement)

  @doc """
  Creates a named `RDF.Dataset` with initial statements.
  """
  def new(name, statements) when is_list(statements),
    do: new(name) |> add(statements)

  @doc """
  Creates a named `RDF.Dataset` with a `RDF.Description`.
  """
  def new(name, %RDF.Description{} = description),
    do: new(name) |> add(description)

  @doc """
  Creates a named `RDF.Dataset` with a `RDF.Graph`.
  """
  def new(name, %RDF.Graph{} = graph),
    do: new(name) |> add(graph, graph.name)

  @doc """
  Creates a named `RDF.Dataset` from another `RDF.Dataset`.
  """
  def new(name, %RDF.Dataset{graphs: graphs}),
    do: %RDF.Dataset{new(name) | graphs: graphs}


  @doc """
  Adds triples and quads to a `RDF.Dataset`.

  The optional third `graph_context` argument allows to set a different
  destination graph to which the statements are added, ignoring the graph context
  of given quads or the name of given graphs.
  """
  def add(dataset, statements, graph_context \\ false)

  def add(dataset, statements, graph_context) when is_list(statements) do
    with graph_context = graph_context && convert_graph_name(graph_context) do
      Enum.reduce statements, dataset, fn (statement, dataset) ->
        add(dataset, statement, graph_context)
      end
    end
  end

  def add(dataset, {subject, predicate, objects}, false),
    do: add(dataset, {subject, predicate, objects, nil})

  def add(dataset, {subject, predicate, objects}, graph_context),
    do: add(dataset, {subject, predicate, objects, graph_context})

  def add(%RDF.Dataset{name: name, graphs: graphs},
          {subject, predicate, objects, graph_context}, false) do
    with graph_context = convert_graph_name(graph_context) do
      updated_graphs =
        Map.update(graphs, graph_context,
          Graph.new(graph_context, {subject, predicate, objects}),
            fn graph -> Graph.add(graph, {subject, predicate, objects}) end)
      %RDF.Dataset{name: name, graphs: updated_graphs}
    end
  end

  def add(%RDF.Dataset{} = dataset, {subject, predicate, objects, _}, graph_context),
    do: add(dataset, {subject, predicate, objects, graph_context}, false)

  def add(%RDF.Dataset{} = dataset, %Description{} = description, false),
    do: add(dataset, description, nil)

  def add(%RDF.Dataset{name: name, graphs: graphs},
          %Description{} = description, graph_context) do
    with graph_context = convert_graph_name(graph_context) do
      updated_graph =
        Map.get(graphs, graph_context, Graph.new(graph_context))
        |> Graph.add(description)
      %RDF.Dataset{
        name:   name,
        graphs: Map.put(graphs, graph_context, updated_graph)
      }
    end
  end

  def add(%RDF.Dataset{name: name, graphs: graphs}, %Graph{} = graph, false) do
    %RDF.Dataset{name: name,
      graphs:
        Map.update(graphs, graph.name, graph, fn current ->
          Graph.add(current, graph)
        end)
    }
  end

  def add(%RDF.Dataset{} = dataset, %Graph{} = graph, graph_context),
    do: add(dataset, %Graph{graph | name: convert_graph_name(graph_context)}, false)

  def add(%RDF.Dataset{} = dataset, %RDF.Dataset{} = other_dataset, graph_context) do
    with graph_context = graph_context && convert_graph_name(graph_context) do
      Enum.reduce graphs(other_dataset), dataset, fn (graph, dataset) ->
        add(dataset, graph, graph_context)
      end
    end
  end


  @doc """
  Adds statements to a `RDF.Dataset` and overwrites all existing statements with the same subjects and predicates in the specified graph context.

  # Examples

      iex> dataset = RDF.Dataset.new({EX.S, EX.P1, EX.O1})
      ...> RDF.Dataset.put(dataset, {EX.S, EX.P1, EX.O2})
      RDF.Dataset.new({EX.S, EX.P1, EX.O2})
      iex> RDF.Dataset.put(dataset, {EX.S, EX.P2, EX.O2})
      RDF.Dataset.new([{EX.S, EX.P1, EX.O1}, {EX.S, EX.P2, EX.O2}])
      iex> RDF.Dataset.new([{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2}]) |>
      ...>   RDF.Dataset.put([{EX.S1, EX.P2, EX.O3}, {EX.S2, EX.P2, EX.O3}])
      RDF.Dataset.new([{EX.S1, EX.P1, EX.O1}, {EX.S1, EX.P2, EX.O3}, {EX.S2, EX.P2, EX.O3}])
  """
  def put(dataset, statements, graph_context \\ false)

  def put(%RDF.Dataset{} = dataset, {subject, predicate, objects}, false),
    do: put(dataset, {subject, predicate, objects, nil})

  def put(%RDF.Dataset{} = dataset, {subject, predicate, objects}, graph_context),
    do: put(dataset, {subject, predicate, objects, graph_context})

  def put(%RDF.Dataset{name: name, graphs: graphs},
          {subject, predicate, objects, graph_context}, false) do
    with graph_context = convert_graph_name(graph_context) do
      new_graph =
        case graphs[graph_context] do
          graph = %Graph{} ->
            Graph.put(graph, {subject, predicate, objects})
          nil ->
            Graph.new(graph_context, {subject, predicate, objects})
        end
      %RDF.Dataset{name: name,
          graphs: Map.put(graphs, graph_context, new_graph)}
    end
  end

  def put(%RDF.Dataset{} = dataset, {subject, predicate, objects, _}, graph_context),
    do: put(dataset, {subject, predicate, objects, graph_context}, false)

  def put(%RDF.Dataset{} = dataset, statements, false) when is_list(statements) do
    do_put dataset, Enum.group_by(statements,
        fn
          {s, _, _}       -> {s, nil}
          {s, _, _, nil}  -> {s, nil}
          {s, _, _, c}    -> {s, convert_graph_name(c)}
        end,
        fn
          {_, p, o, _} -> {p, o}
          {_, p, o}    -> {p, o}
        end)
  end

  def put(%RDF.Dataset{} = dataset, statements, graph_context) when is_list(statements) do
    with graph_context = convert_graph_name(graph_context) do
      do_put dataset, Enum.group_by(statements,
          fn
            {s, _, _, _} -> {s, graph_context}
            {s, _, _}    -> {s, graph_context}
          end,
          fn
            {_, p, o, _} -> {p, o}
            {_, p, o}    -> {p, o}
          end)
    end
  end

  def put(%RDF.Dataset{} = dataset, %Description{} = description, false),
    do: put(dataset, description, nil)

  def put(%RDF.Dataset{name: name, graphs: graphs},
          %Description{} = description, graph_context) do
    with graph_context = convert_graph_name(graph_context) do
      updated_graph =
        Map.get(graphs, graph_context, Graph.new(graph_context))
        |> Graph.put(description)
      %RDF.Dataset{
        name:   name,
        graphs: Map.put(graphs, graph_context, updated_graph)
      }
    end
  end

  def put(%RDF.Dataset{name: name, graphs: graphs}, %Graph{} = graph, false) do
    %RDF.Dataset{name: name,
      graphs:
        Map.update(graphs, graph.name, graph, fn current ->
          Graph.put(current, graph)
        end)
    }
  end

  def put(%RDF.Dataset{} = dataset, %Graph{} = graph, graph_context),
    do: put(dataset, %Graph{graph | name: convert_graph_name(graph_context)}, false)

  def put(%RDF.Dataset{} = dataset, %RDF.Dataset{} = other_dataset, graph_context) do
    with graph_context = graph_context && convert_graph_name(graph_context) do
      Enum.reduce graphs(other_dataset), dataset, fn (graph, dataset) ->
        put(dataset, graph, graph_context)
      end
    end
  end

  defp do_put(%RDF.Dataset{} = dataset, statements) when is_map(statements) do
    Enum.reduce statements, dataset,
      fn ({subject_with_context, predications}, dataset) ->
        do_put(dataset, subject_with_context, predications)
      end
  end

  defp do_put(%RDF.Dataset{name: name, graphs: graphs},
            {subject, graph_context}, predications)
        when is_list(predications) do
    with graph_context = convert_graph_name(graph_context) do
      graph = Map.get(graphs, graph_context, Graph.new(graph_context))
      new_graphs = graphs
        |> Map.put(graph_context, Graph.put(graph, subject, predications))
      %RDF.Dataset{name: name, graphs: new_graphs}
    end
  end


  @doc """
  Deletes statements from a `RDF.Dataset`.

  The optional third `graph_context` argument allows to set a different
  destination graph from which the statements are deleted, ignoring the graph
  context of given quads or the name of given graphs.

  Note: When the statements to be deleted are given as another `RDF.Dataset`,
  the dataset name must not match dataset name of the dataset from which the statements
  are deleted. If you want to delete only datasets with matching names, you can
  use `RDF.Data.delete/2`.
  """
  def delete(dataset, statements, graph_context \\ false)

  def delete(%RDF.Dataset{} = dataset, statements, graph_context) when is_list(statements) do
    with graph_context = graph_context && convert_graph_name(graph_context) do
      Enum.reduce statements, dataset, fn (statement, dataset) ->
        delete(dataset, statement, graph_context)
      end
    end
  end

  def delete(%RDF.Dataset{} = dataset, {_, _, _} = statement, false),
    do: do_delete(dataset, nil, statement)

  def delete(%RDF.Dataset{} = dataset, {_, _, _} = statement, graph_context),
    do: do_delete(dataset, graph_context, statement)

  def delete(%RDF.Dataset{} = dataset, {subject, predicate, objects, graph_context}, false),
    do: do_delete(dataset, graph_context, {subject, predicate, objects})

  def delete(%RDF.Dataset{} = dataset, {subject, predicate, objects, _}, graph_context),
    do: do_delete(dataset, graph_context, {subject, predicate, objects})

  def delete(%RDF.Dataset{} = dataset, %Description{} = description, false),
    do: do_delete(dataset, nil, description)

  def delete(%RDF.Dataset{} = dataset, %Description{} = description, graph_context),
    do: do_delete(dataset, graph_context, description)

  def delete(%RDF.Dataset{} = dataset, %RDF.Graph{name: name} = graph, false),
    do: do_delete(dataset, name, graph)

  def delete(%RDF.Dataset{} = dataset, %RDF.Graph{} = graph, graph_context),
    do: do_delete(dataset, graph_context, graph)

  def delete(%RDF.Dataset{} = dataset, %RDF.Dataset{graphs: graphs}, graph_context) do
    Enum.reduce graphs, dataset, fn ({_, graph}, dataset) ->
      delete(dataset, graph, graph_context)
    end
  end

  defp do_delete(%RDF.Dataset{name: name, graphs: graphs} = dataset,
          graph_context, statements) do
    with graph_context = convert_graph_name(graph_context),
         graph when not is_nil(graph) <- graphs[graph_context],
         new_graph = Graph.delete(graph, statements)
    do
      %RDF.Dataset{name: name,
        graphs:
          if Enum.empty?(new_graph) do
            Map.delete(graphs, graph_context)
          else
            Map.put(graphs, graph_context, new_graph)
          end
      }
    else
      nil -> dataset
    end
  end


  @doc """
  Deletes the given graph.
  """
  def delete_graph(graph, graph_names)

  def delete_graph(%RDF.Dataset{} = dataset, graph_names) when is_list(graph_names) do
    Enum.reduce graph_names, dataset, fn (graph_name, dataset) ->
      delete_graph(dataset, graph_name)
    end
  end

  def delete_graph(%RDF.Dataset{name: name, graphs: graphs}, graph_name) do
    with graph_name = convert_graph_name(graph_name) do
      %RDF.Dataset{name: name, graphs: Map.delete(graphs, graph_name)}
    end
  end

  @doc """
  Deletes the default graph.
  """
  def delete_default_graph(%RDF.Dataset{} = graph),
    do: delete_graph(graph, nil)


  @doc """
  Fetches the `RDF.Graph` with the given name.

  When a graph with the given name can not be found can not be found `:error` is returned.

  # Examples

      iex> dataset = RDF.Dataset.new([{EX.S1, EX.P1, EX.O1, EX.Graph}, {EX.S2, EX.P2, EX.O2}])
      ...> RDF.Dataset.fetch(dataset, EX.Graph)
      {:ok, RDF.Graph.new(EX.Graph, {EX.S1, EX.P1, EX.O1})}
      iex> RDF.Dataset.fetch(dataset, nil)
      {:ok, RDF.Graph.new({EX.S2, EX.P2, EX.O2})}
      iex> RDF.Dataset.fetch(dataset, EX.Foo)
      :error
  """
  def fetch(%RDF.Dataset{graphs: graphs}, graph_name) do
    Access.fetch(graphs, convert_graph_name(graph_name))
  end

  @doc """
  Fetches the `RDF.Graph` with the given name.

  When a graph with the given name can not be found can not be found the optionally
  given default value or `nil` is returned

  # Examples

      iex> dataset = RDF.Dataset.new([{EX.S1, EX.P1, EX.O1, EX.Graph}, {EX.S2, EX.P2, EX.O2}])
      ...> RDF.Dataset.get(dataset, EX.Graph)
      RDF.Graph.new(EX.Graph, {EX.S1, EX.P1, EX.O1})
      iex> RDF.Dataset.get(dataset, nil)
      RDF.Graph.new({EX.S2, EX.P2, EX.O2})
      iex> RDF.Dataset.get(dataset, EX.Foo)
      nil
      iex> RDF.Dataset.get(dataset, EX.Foo, :bar)
      :bar
  """
  def get(%RDF.Dataset{} = dataset, graph_name, default \\ nil) do
    case fetch(dataset, graph_name) do
      {:ok, value} -> value
      :error       -> default
    end
  end

  @doc """
  The graph with given name.
  """
  def graph(%RDF.Dataset{graphs: graphs}, graph_name),
    do: Map.get(graphs, convert_graph_name(graph_name))

  @doc """
  The default graph of a `RDF.Dataset`.
  """
  def default_graph(%RDF.Dataset{graphs: graphs}),
    do: Map.get(graphs, nil, Graph.new)


  @doc """
  The set of all graphs.
  """
  def graphs(%RDF.Dataset{graphs: graphs}), do: Map.values(graphs)


  @doc """
  Gets and updates the graph with the given name, in a single pass.

  Invokes the passed function on the `RDF.Graph` with the given name;
  this function should return either `{graph_to_return, new_graph}` or `:pop`.

  If the passed function returns `{graph_to_return, new_graph}`, the
  return value of `get_and_update` is `{graph_to_return, new_dataset}` where
  `new_dataset` is the input `Dataset` updated with `new_graph` for
  the given name.

  If the passed function returns `:pop` the graph with the given name is
  removed and a `{removed_graph, new_dataset}` tuple gets returned.

  # Examples

      iex> dataset = RDF.Dataset.new({EX.S, EX.P, EX.O, EX.Graph})
      ...> RDF.Dataset.get_and_update(dataset, EX.Graph, fn current_graph ->
      ...>     {current_graph, {EX.S, EX.P, EX.NEW}}
      ...>   end)
      {RDF.Graph.new(EX.Graph, {EX.S, EX.P, EX.O}), RDF.Dataset.new({EX.S, EX.P, EX.NEW, EX.Graph})}
  """
  def get_and_update(%RDF.Dataset{} = dataset, graph_name, fun) do
    with graph_context = convert_graph_name(graph_name) do
      case fun.(get(dataset, graph_context)) do
        {old_graph, new_graph} ->
          {old_graph, put(dataset, new_graph, graph_context)}
        :pop ->
          pop(dataset, graph_context)
        other ->
          raise "the given function must return a two-element tuple or :pop, got: #{inspect(other)}"
      end
    end
  end


  @doc """
  Pops an arbitrary statement from a `RDF.Dataset`.
  """
  def pop(dataset)

  def pop(%RDF.Dataset{graphs: graphs} = dataset)
    when graphs == %{}, do: {nil, dataset}

  def pop(%RDF.Dataset{name: name, graphs: graphs}) do
    # TODO: Find a faster way ...
    [{graph_name, graph}] = Enum.take(graphs, 1)
    {{s, p, o}, popped_graph} = Graph.pop(graph)
    popped = if Enum.empty?(popped_graph),
      do:   graphs |> Map.delete(graph_name),
      else: graphs |> Map.put(graph_name, popped_graph)

    {{s, p, o, graph_name}, %RDF.Dataset{name: name, graphs: popped}}
  end

  @doc """
  Pops the graph with the given name.

  When a graph with given name can not be found the optionally given default value
  or `nil` is returned.

  # Examples

      iex> dataset = RDF.Dataset.new([
      ...>   {EX.S1, EX.P1, EX.O1, EX.Graph},
      ...>   {EX.S2, EX.P2, EX.O2}])
      ...> RDF.Dataset.pop(dataset, EX.Graph)
      {RDF.Graph.new(EX.Graph, {EX.S1, EX.P1, EX.O1}), RDF.Dataset.new({EX.S2, EX.P2, EX.O2})}
      iex> RDF.Dataset.pop(dataset, EX.Foo)
      {nil, dataset}
  """
  def pop(%RDF.Dataset{name: name, graphs: graphs} = dataset, graph_name) do
    case Access.pop(graphs, convert_graph_name(graph_name)) do
      {nil, _} ->
        {nil, dataset}
      {graph, new_graphs} ->
        {graph, %RDF.Dataset{name: name, graphs: new_graphs}}
    end
  end



  @doc """
  The number of statements within a `RDF.Dataset`.

  # Examples

      iex> RDF.Dataset.new([
      ...>   {EX.S1, EX.p1, EX.O1, EX.Graph},
      ...>   {EX.S2, EX.p2, EX.O2},
      ...>   {EX.S1, EX.p2, EX.O3}]) |>
      ...>   RDF.Dataset.statement_count
      3
  """
  def statement_count(%RDF.Dataset{graphs: graphs}) do
    Enum.reduce graphs, 0, fn ({_, graph}, count) ->
      count + Graph.triple_count(graph)
    end
  end

  @doc """
  The set of all subjects used in the statement within all graphs of a `RDF.Dataset`.

  # Examples

      iex> RDF.Dataset.new([
      ...>   {EX.S1, EX.p1, EX.O1, EX.Graph},
      ...>   {EX.S2, EX.p2, EX.O2},
      ...>   {EX.S1, EX.p2, EX.O3}]) |>
      ...>   RDF.Dataset.subjects
      MapSet.new([RDF.uri(EX.S1), RDF.uri(EX.S2)])
  """
  def subjects(%RDF.Dataset{graphs: graphs}) do
    Enum.reduce graphs, MapSet.new, fn ({_, graph}, subjects) ->
      MapSet.union(subjects, Graph.subjects(graph))
    end
  end

  @doc """
  The set of all properties used in the predicates within all graphs of a `RDF.Dataset`.

  # Examples

      iex> RDF.Dataset.new([
      ...>   {EX.S1, EX.p1, EX.O1, EX.Graph},
      ...>   {EX.S2, EX.p2, EX.O2},
      ...>   {EX.S1, EX.p2, EX.O3}]) |>
      ...>   RDF.Dataset.predicates
      MapSet.new([EX.p1, EX.p2])
  """
  def predicates(%RDF.Dataset{graphs: graphs}) do
    Enum.reduce graphs, MapSet.new, fn ({_, graph}, predicates) ->
      MapSet.union(predicates, Graph.predicates(graph))
    end
  end

  @doc """
  The set of all resources used in the objects within a `RDF.Dataset`.

  Note: This function does collect only URIs and BlankNodes, not Literals.

  # Examples

      iex> RDF.Dataset.new([
      ...>   {EX.S1, EX.p1, EX.O1, EX.Graph},
      ...>   {EX.S2, EX.p2, EX.O2, EX.Graph},
      ...>   {EX.S3, EX.p1, EX.O2},
      ...>   {EX.S4, EX.p2, RDF.bnode(:bnode)},
      ...>   {EX.S5, EX.p3, "foo"}
      ...> ]) |> RDF.Dataset.objects
      MapSet.new([RDF.uri(EX.O1), RDF.uri(EX.O2), RDF.bnode(:bnode)])
  """
  def objects(%RDF.Dataset{graphs: graphs}) do
    Enum.reduce graphs, MapSet.new, fn ({_, graph}, objects) ->
      MapSet.union(objects, Graph.objects(graph))
    end
  end

  @doc """
  The set of all resources used within a `RDF.Dataset`.

  # Examples

    iex> RDF.Dataset.new([
    ...>   {EX.S1, EX.p1, EX.O1, EX.Graph},
    ...>   {EX.S2, EX.p1, EX.O2, EX.Graph},
    ...>   {EX.S2, EX.p2, RDF.bnode(:bnode)},
    ...>   {EX.S3, EX.p1, "foo"}
    ...> ]) |> RDF.Dataset.resources
    MapSet.new([RDF.uri(EX.S1), RDF.uri(EX.S2), RDF.uri(EX.S3),
      RDF.uri(EX.O1), RDF.uri(EX.O2), RDF.bnode(:bnode), EX.p1, EX.p2])
  """
  def resources(%RDF.Dataset{graphs: graphs}) do
    Enum.reduce graphs, MapSet.new, fn ({_, graph}, resources) ->
      MapSet.union(resources, Graph.resources(graph))
    end
  end

  @doc """
  All statements within all graphs of a `RDF.Dataset`.

  # Examples

        iex> RDF.Dataset.new([
        ...>   {EX.S1, EX.p1, EX.O1, EX.Graph},
        ...>   {EX.S2, EX.p2, EX.O2},
        ...>   {EX.S1, EX.p2, EX.O3}]) |>
        ...>   RDF.Dataset.statements
        [{RDF.uri(EX.S1), RDF.uri(EX.p1), RDF.uri(EX.O1), RDF.uri(EX.Graph)},
         {RDF.uri(EX.S1), RDF.uri(EX.p2), RDF.uri(EX.O3)},
         {RDF.uri(EX.S2), RDF.uri(EX.p2), RDF.uri(EX.O2)}]
  """
  def statements(%RDF.Dataset{graphs: graphs}) do
    Enum.reduce graphs, [], fn ({_, graph}, all_statements) ->
      statements = Graph.triples(graph)
      if graph.name do
        Enum.map statements, fn {s, p, o} -> {s, p, o, graph.name} end
      else
        statements
      end ++ all_statements
    end
  end


  @doc """
  Returns if a given statement is in a `RDF.Dataset`.

  # Examples

        iex> dataset = RDF.Dataset.new([
        ...>   {EX.S1, EX.p1, EX.O1, EX.Graph},
        ...>   {EX.S2, EX.p2, EX.O2},
        ...>   {EX.S1, EX.p2, EX.O3}])
        ...> RDF.Dataset.include?(dataset, {EX.S1, EX.p1, EX.O1, EX.Graph})
        true
  """
  def include?(dataset, statement, graph_context \\ nil)

  def include?(%RDF.Dataset{graphs: graphs}, triple = {_, _, _}, graph_context) do
    with graph_context = convert_graph_name(graph_context) do
      if graph = graphs[graph_context] do
        Graph.include?(graph, triple)
      else
        false
      end
    end
  end

  def include?(%RDF.Dataset{} = dataset, {subject, predicate, object, graph_context}, _),
    do: include?(dataset, {subject, predicate, object}, graph_context)


  defimpl Enumerable do
    def member?(graph, statement), do: {:ok, RDF.Dataset.include?(graph, statement)}
    def count(graph),              do: {:ok, RDF.Dataset.statement_count(graph)}

    def reduce(%RDF.Dataset{graphs: graphs}, {:cont, acc}, _fun)
      when map_size(graphs) == 0, do: {:done, acc}

    def reduce(%RDF.Dataset{} = dataset, {:cont, acc}, fun) do
      {statement, rest} = RDF.Dataset.pop(dataset)
      reduce(rest, fun.(statement, acc), fun)
    end

    def reduce(_,       {:halt, acc}, _fun), do: {:halted, acc}
    def reduce(dataset = %RDF.Dataset{}, {:suspend, acc}, fun) do
      {:suspended, acc, &reduce(dataset, &1, fun)}
    end
  end
end
