defmodule RDF.Dataset do
  @moduledoc """
  A set of `RDF.Graph`s.

  It may have multiple named graphs and at most one unnamed ("default") graph.

  `RDF.Dataset` implements:

  - Elixir's `Access` behaviour
  - Elixir's `Enumerable` protocol
  - Elixir's `Inspect` protocol
  - the `RDF.Data` protocol

  """

  @behaviour Access

  alias RDF.{Description, Graph, IRI, Statement}
  import RDF.Statement

  @type graph_name :: IRI.t | nil

  @type t :: %__MODULE__{
          name: graph_name,
          graphs: %{graph_name => Graph.t}
  }

  @type input :: Graph.input | t

  @type update_graph_fun :: (Graph.t -> {Graph.t, input} | :pop)

  defstruct name: nil, graphs: %{}


  @doc """
  Creates an empty unnamed `RDF.Dataset`.
  """
  @spec new :: t
  def new, do: %RDF.Dataset{}

  @doc """
  Creates an `RDF.Dataset`.

  If a keyword list is given an empty dataset is created.
  Otherwise an unnamed dataset initialized with the given data is created.

  See `new/2` for available arguments and the different ways to provide data.

  ## Examples

      RDF.Graph.new({EX.S, EX.p, EX.O})

      RDF.Graph.new(name: EX.GraphName)

  """
  @spec new(input | [input] | keyword) :: t
  def new(data_or_options)

  def new(data_or_options)
      when is_list(data_or_options) and length(data_or_options) != 0 do
    if Keyword.keyword?(data_or_options) do
      new([], data_or_options)
    else
      new(data_or_options, [])
    end
  end

  def new(data), do: new(data, [])

  @doc """
  Creates an `RDF.Dataset` initialized with data.

  The initial RDF triples can be provided

  - as a single statement tuple
  - an `RDF.Description`
  - an `RDF.Graph`
  - an `RDF.Dataset`
  - or a list with any combination of the former

  Available options:

  - `name`: the name of the dataset to be created

  """
  @spec new(input | [input], keyword) :: t
  def new(data, options)

  def new(%RDF.Dataset{} = graph, options) do
    %RDF.Dataset{graph | name: options |> Keyword.get(:name) |> coerce_graph_name()}
  end

  def new(data, options) do
    %RDF.Dataset{}
    |> new(options)
    |> add(data)
  end


  @doc """
  Adds triples and quads to a `RDF.Dataset`.

  The optional third `graph_context` argument allows to set a different
  destination graph to which the statements are added, ignoring the graph context
  of given quads or the name of given graphs.
  """
  @spec add(t, input | [input], boolean | nil) :: t
  def add(dataset, statements, graph_context \\ false)

  def add(dataset, statements, graph_context) when is_list(statements) do
    with graph_context = graph_context && coerce_graph_name(graph_context) do
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
    with graph_context = coerce_graph_name(graph_context) do
      updated_graphs =
        Map.update(graphs, graph_context,
          Graph.new({subject, predicate, objects}, name: graph_context),
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
    with graph_context = coerce_graph_name(graph_context) do
      updated_graph =
        Map.get(graphs, graph_context, Graph.new(name: graph_context))
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
    do: add(dataset, %Graph{graph | name: coerce_graph_name(graph_context)}, false)

  def add(%RDF.Dataset{} = dataset, %RDF.Dataset{} = other_dataset, graph_context) do
    with graph_context = graph_context && coerce_graph_name(graph_context) do
      Enum.reduce graphs(other_dataset), dataset, fn (graph, dataset) ->
        add(dataset, graph, graph_context)
      end
    end
  end


  @doc """
  Adds statements to a `RDF.Dataset` and overwrites all existing statements with the same subjects and predicates in the specified graph context.

  ## Examples

      iex> dataset = RDF.Dataset.new({EX.S, EX.P1, EX.O1})
      ...> RDF.Dataset.put(dataset, {EX.S, EX.P1, EX.O2})
      RDF.Dataset.new({EX.S, EX.P1, EX.O2})
      iex> RDF.Dataset.put(dataset, {EX.S, EX.P2, EX.O2})
      RDF.Dataset.new([{EX.S, EX.P1, EX.O1}, {EX.S, EX.P2, EX.O2}])
      iex> RDF.Dataset.new([{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2}]) |>
      ...>   RDF.Dataset.put([{EX.S1, EX.P2, EX.O3}, {EX.S2, EX.P2, EX.O3}])
      RDF.Dataset.new([{EX.S1, EX.P1, EX.O1}, {EX.S1, EX.P2, EX.O3}, {EX.S2, EX.P2, EX.O3}])
  """
  @spec put(t, input | [input], Statement.coercible_graph_name | boolean | nil) :: t
  def put(dataset, statements, graph_context \\ false)

  def put(%RDF.Dataset{} = dataset, {subject, predicate, objects}, false),
    do: put(dataset, {subject, predicate, objects, nil})

  def put(%RDF.Dataset{} = dataset, {subject, predicate, objects}, graph_context),
    do: put(dataset, {subject, predicate, objects, graph_context})

  def put(%RDF.Dataset{name: name, graphs: graphs},
          {subject, predicate, objects, graph_context}, false) do
    with graph_context = coerce_graph_name(graph_context) do
      new_graph =
        case graphs[graph_context] do
          graph = %Graph{} ->
            Graph.put(graph, {subject, predicate, objects})
          nil ->
            Graph.new({subject, predicate, objects}, name: graph_context)
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
          {s, _, _, c}    -> {s, coerce_graph_name(c)}
        end,
        fn
          {_, p, o, _} -> {p, o}
          {_, p, o}    -> {p, o}
        end)
  end

  def put(%RDF.Dataset{} = dataset, statements, graph_context) when is_list(statements) do
    with graph_context = coerce_graph_name(graph_context) do
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
    with graph_context = coerce_graph_name(graph_context) do
      updated_graph =
        Map.get(graphs, graph_context, Graph.new(name: graph_context))
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
    do: put(dataset, %Graph{graph | name: coerce_graph_name(graph_context)}, false)

  def put(%RDF.Dataset{} = dataset, %RDF.Dataset{} = other_dataset, graph_context) do
    with graph_context = graph_context && coerce_graph_name(graph_context) do
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
    with graph_context = coerce_graph_name(graph_context) do
      graph = Map.get(graphs, graph_context, Graph.new(name: graph_context))
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
  @spec delete(t, input | [input],  Statement.coercible_graph_name | boolean | nil) :: t
  def delete(dataset, statements, graph_context \\ false)

  def delete(%RDF.Dataset{} = dataset, statements, graph_context) when is_list(statements) do
    with graph_context = graph_context && coerce_graph_name(graph_context) do
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
    with graph_context = coerce_graph_name(graph_context),
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
  @spec delete_graph(t, Statement.graph_name | [Statement.graph_name] | nil) :: t
  def delete_graph(graph, graph_names)

  def delete_graph(%RDF.Dataset{} = dataset, graph_names) when is_list(graph_names) do
    Enum.reduce graph_names, dataset, fn (graph_name, dataset) ->
      delete_graph(dataset, graph_name)
    end
  end

  def delete_graph(%RDF.Dataset{name: name, graphs: graphs}, graph_name) do
    with graph_name = coerce_graph_name(graph_name) do
      %RDF.Dataset{name: name, graphs: Map.delete(graphs, graph_name)}
    end
  end

  @doc """
  Deletes the default graph.
  """
  @spec delete_default_graph(t) :: t
  def delete_default_graph(%RDF.Dataset{} = graph),
    do: delete_graph(graph, nil)


  @doc """
  Fetches the `RDF.Graph` with the given name.

  When a graph with the given name can not be found can not be found `:error` is returned.

  ## Examples

      iex> dataset = RDF.Dataset.new([{EX.S1, EX.P1, EX.O1, EX.Graph}, {EX.S2, EX.P2, EX.O2}])
      ...> RDF.Dataset.fetch(dataset, EX.Graph)
      {:ok, RDF.Graph.new({EX.S1, EX.P1, EX.O1}, name: EX.Graph)}
      iex> RDF.Dataset.fetch(dataset, nil)
      {:ok, RDF.Graph.new({EX.S2, EX.P2, EX.O2})}
      iex> RDF.Dataset.fetch(dataset, EX.Foo)
      :error
  """
  @impl Access
  @spec fetch(t, Statement.graph_name | nil) :: {:ok, Graph.t} | :error
  def fetch(%RDF.Dataset{graphs: graphs}, graph_name) do
    Access.fetch(graphs, coerce_graph_name(graph_name))
  end

  @doc """
  Fetches the `RDF.Graph` with the given name.

  When a graph with the given name can not be found can not be found the optionally
  given default value or `nil` is returned

  ## Examples

      iex> dataset = RDF.Dataset.new([{EX.S1, EX.P1, EX.O1, EX.Graph}, {EX.S2, EX.P2, EX.O2}])
      ...> RDF.Dataset.get(dataset, EX.Graph)
      RDF.Graph.new({EX.S1, EX.P1, EX.O1}, name: EX.Graph)
      iex> RDF.Dataset.get(dataset, nil)
      RDF.Graph.new({EX.S2, EX.P2, EX.O2})
      iex> RDF.Dataset.get(dataset, EX.Foo)
      nil
      iex> RDF.Dataset.get(dataset, EX.Foo, :bar)
      :bar
  """
  @spec get(t, Statement.graph_name | nil, Graph.t | nil) :: Graph.t | nil
  def get(%RDF.Dataset{} = dataset, graph_name, default \\ nil) do
    case fetch(dataset, graph_name) do
      {:ok, value} -> value
      :error       -> default
    end
  end

  @doc """
  The graph with given name.
  """
  @spec graph(t, Statement.graph_name | nil) :: Graph.t
  def graph(%RDF.Dataset{graphs: graphs}, graph_name),
    do: Map.get(graphs, coerce_graph_name(graph_name))

  @doc """
  The default graph of a `RDF.Dataset`.
  """
  @spec default_graph(t) :: Graph.t
  def default_graph(%RDF.Dataset{graphs: graphs}),
    do: Map.get(graphs, nil, Graph.new)


  @doc """
  The set of all graphs.
  """
  @spec graphs(t) :: [Graph.t]
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

  ## Examples

      iex> dataset = RDF.Dataset.new({EX.S, EX.P, EX.O, EX.Graph})
      ...> RDF.Dataset.get_and_update(dataset, EX.Graph, fn current_graph ->
      ...>     {current_graph, {EX.S, EX.P, EX.NEW}}
      ...>   end)
      {RDF.Graph.new({EX.S, EX.P, EX.O}, name: EX.Graph), RDF.Dataset.new({EX.S, EX.P, EX.NEW, EX.Graph})}
  """
  @impl Access
  @spec get_and_update(t, Statement.graph_name | nil, update_graph_fun) :: {Graph.t, input}
  def get_and_update(%RDF.Dataset{} = dataset, graph_name, fun) do
    with graph_context = coerce_graph_name(graph_name) do
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
  @spec pop(t) :: {Statement.t | nil, t}
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

  ## Examples

      iex> dataset = RDF.Dataset.new([
      ...>   {EX.S1, EX.P1, EX.O1, EX.Graph},
      ...>   {EX.S2, EX.P2, EX.O2}])
      ...> RDF.Dataset.pop(dataset, EX.Graph)
      {RDF.Graph.new({EX.S1, EX.P1, EX.O1}, name: EX.Graph), RDF.Dataset.new({EX.S2, EX.P2, EX.O2})}
      iex> RDF.Dataset.pop(dataset, EX.Foo)
      {nil, dataset}
  """
  @impl Access
  @spec pop(t, Statement.coercible_graph_name) :: {Statement.t | nil, t}
  def pop(%RDF.Dataset{name: name, graphs: graphs} = dataset, graph_name) do
    case Access.pop(graphs, coerce_graph_name(graph_name)) do
      {nil, _} ->
        {nil, dataset}
      {graph, new_graphs} ->
        {graph, %RDF.Dataset{name: name, graphs: new_graphs}}
    end
  end



  @doc """
  The number of statements within a `RDF.Dataset`.

  ## Examples

      iex> RDF.Dataset.new([
      ...>   {EX.S1, EX.p1, EX.O1, EX.Graph},
      ...>   {EX.S2, EX.p2, EX.O2},
      ...>   {EX.S1, EX.p2, EX.O3}]) |>
      ...>   RDF.Dataset.statement_count
      3
  """
  @spec statement_count(t) :: non_neg_integer
  def statement_count(%RDF.Dataset{graphs: graphs}) do
    Enum.reduce graphs, 0, fn ({_, graph}, count) ->
      count + Graph.triple_count(graph)
    end
  end

  @doc """
  The set of all subjects used in the statement within all graphs of a `RDF.Dataset`.

  ## Examples

      iex> RDF.Dataset.new([
      ...>   {EX.S1, EX.p1, EX.O1, EX.Graph},
      ...>   {EX.S2, EX.p2, EX.O2},
      ...>   {EX.S1, EX.p2, EX.O3}]) |>
      ...>   RDF.Dataset.subjects
      MapSet.new([RDF.iri(EX.S1), RDF.iri(EX.S2)])
  """
  def subjects(%RDF.Dataset{graphs: graphs}) do
    Enum.reduce graphs, MapSet.new, fn ({_, graph}, subjects) ->
      MapSet.union(subjects, Graph.subjects(graph))
    end
  end

  @doc """
  The set of all properties used in the predicates within all graphs of a `RDF.Dataset`.

  ## Examples

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

  Note: This function does collect only IRIs and BlankNodes, not Literals.

  ## Examples

      iex> RDF.Dataset.new([
      ...>   {EX.S1, EX.p1, EX.O1, EX.Graph},
      ...>   {EX.S2, EX.p2, EX.O2, EX.Graph},
      ...>   {EX.S3, EX.p1, EX.O2},
      ...>   {EX.S4, EX.p2, RDF.bnode(:bnode)},
      ...>   {EX.S5, EX.p3, "foo"}
      ...> ]) |> RDF.Dataset.objects
      MapSet.new([RDF.iri(EX.O1), RDF.iri(EX.O2), RDF.bnode(:bnode)])
  """
  def objects(%RDF.Dataset{graphs: graphs}) do
    Enum.reduce graphs, MapSet.new, fn ({_, graph}, objects) ->
      MapSet.union(objects, Graph.objects(graph))
    end
  end

  @doc """
  The set of all resources used within a `RDF.Dataset`.

  ## Examples

    iex> RDF.Dataset.new([
    ...>   {EX.S1, EX.p1, EX.O1, EX.Graph},
    ...>   {EX.S2, EX.p1, EX.O2, EX.Graph},
    ...>   {EX.S2, EX.p2, RDF.bnode(:bnode)},
    ...>   {EX.S3, EX.p1, "foo"}
    ...> ]) |> RDF.Dataset.resources
    MapSet.new([RDF.iri(EX.S1), RDF.iri(EX.S2), RDF.iri(EX.S3),
      RDF.iri(EX.O1), RDF.iri(EX.O2), RDF.bnode(:bnode), EX.p1, EX.p2])
  """
  def resources(%RDF.Dataset{graphs: graphs}) do
    Enum.reduce graphs, MapSet.new, fn ({_, graph}, resources) ->
      MapSet.union(resources, Graph.resources(graph))
    end
  end

  @doc """
  All statements within all graphs of a `RDF.Dataset`.

  ## Examples

        iex> RDF.Dataset.new([
        ...>   {EX.S1, EX.p1, EX.O1, EX.Graph},
        ...>   {EX.S2, EX.p2, EX.O2},
        ...>   {EX.S1, EX.p2, EX.O3}]) |>
        ...>   RDF.Dataset.statements
        [{RDF.iri(EX.S1), RDF.iri(EX.p1), RDF.iri(EX.O1), RDF.iri(EX.Graph)},
         {RDF.iri(EX.S1), RDF.iri(EX.p2), RDF.iri(EX.O3)},
         {RDF.iri(EX.S2), RDF.iri(EX.p2), RDF.iri(EX.O2)}]
  """
  @spec statements(t) :: [Statement.t]
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

  ## Examples

        iex> dataset = RDF.Dataset.new([
        ...>   {EX.S1, EX.p1, EX.O1, EX.Graph},
        ...>   {EX.S2, EX.p2, EX.O2},
        ...>   {EX.S1, EX.p2, EX.O3}])
        ...> RDF.Dataset.include?(dataset, {EX.S1, EX.p1, EX.O1, EX.Graph})
        true
  """
  @spec include?(t, Statement.t, Statement.coercible_graph_name | nil) :: boolean
  def include?(dataset, statement, graph_context \\ nil)

  def include?(%RDF.Dataset{graphs: graphs}, triple = {_, _, _}, graph_context) do
    with graph_context = coerce_graph_name(graph_context) do
      if graph = graphs[graph_context] do
        Graph.include?(graph, triple)
      else
        false
      end
    end
  end

  def include?(%RDF.Dataset{} = dataset, {subject, predicate, object, graph_context}, _),
    do: include?(dataset, {subject, predicate, object}, graph_context)


  @doc """
  Checks if a graph of a `RDF.Dataset` contains statements about the given resource.

  ## Examples

        iex> RDF.Dataset.new([{EX.S1, EX.p1, EX.O1}]) |> RDF.Dataset.describes?(EX.S1)
        true
        iex> RDF.Dataset.new([{EX.S1, EX.p1, EX.O1}]) |> RDF.Dataset.describes?(EX.S2)
        false
  """
  @spec describes?(t, Statement.t, Statement.coercible_graph_name | nil) :: boolean
  def describes?(%RDF.Dataset{graphs: graphs}, subject, graph_context \\ nil) do
    with graph_context = coerce_graph_name(graph_context) do
      if graph = graphs[graph_context] do
        Graph.describes?(graph, subject)
      else
        false
      end
    end
  end

  @doc """
  Returns the names of all graphs of a `RDF.Dataset` containing statements about the given subject.

  ## Examples
        iex> dataset = RDF.Dataset.new([
        ...>   {EX.S1, EX.p, EX.O},
        ...>   {EX.S2, EX.p, EX.O},
        ...>   {EX.S1, EX.p, EX.O, EX.Graph1},
        ...>   {EX.S2, EX.p, EX.O, EX.Graph2}])
        ...> RDF.Dataset.who_describes(dataset, EX.S1)
        [nil, RDF.iri(EX.Graph1)]
  """
  @spec who_describes(t, Statement.coercible_subject) :: [Graph.t]
  def who_describes(%RDF.Dataset{graphs: graphs}, subject) do
    with subject = coerce_subject(subject) do
      graphs
      |> Map.values
      |> Stream.filter(&Graph.describes?(&1, subject))
      |> Enum.map(&(&1.name))
    end
  end


  @doc """
  Returns a nested map of the native Elixir values of a `RDF.Dataset`.

  The optional second argument allows to specify a custom mapping with a function
  which will receive a tuple `{statement_position, rdf_term}` where
  `statement_position` is one of the atoms `:subject`, `:predicate`, `:object`,
   or `graph_name` while `rdf_term` is the RDF term to be mapped.

  ## Examples

      iex> [
      ...>   {~I<http://example.com/S>, ~I<http://example.com/p>, ~L"Foo", ~I<http://example.com/Graph>},
      ...>   {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.integer(42), }
      ...> ]
      ...> |> RDF.Dataset.new()
      ...> |> RDF.Dataset.values()
      %{
        "http://example.com/Graph" => %{
          "http://example.com/S" => %{"http://example.com/p" => ["Foo"]}
        },
        nil => %{
          "http://example.com/S" => %{"http://example.com/p" => [42]}
        }
      }

      iex> [
      ...>   {~I<http://example.com/S>, ~I<http://example.com/p>, ~L"Foo", ~I<http://example.com/Graph>},
      ...>   {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.integer(42), }
      ...> ]
      ...> |> RDF.Dataset.new()
      ...> |> RDF.Dataset.values(fn
      ...>      {:graph_name, graph_name} ->
      ...>        graph_name
      ...>      {:predicate, predicate} ->
      ...>        predicate
      ...>        |> to_string()
      ...>        |> String.split("/")
      ...>        |> List.last()
      ...>        |> String.to_atom()
      ...>    {_, term} ->
      ...>      RDF.Term.value(term)
      ...>    end)
      %{
        ~I<http://example.com/Graph> => %{
          "http://example.com/S" => %{p: ["Foo"]}
        },
        nil => %{
          "http://example.com/S" => %{p: [42]}
        }
      }

  """
  @spec values(t, Statement.term_mapping) :: map
  def values(dataset, mapping \\ &RDF.Statement.default_term_mapping/1)

  def values(%RDF.Dataset{graphs: graphs}, mapping) do
    Map.new graphs, fn {graph_name, graph} ->
      {mapping.({:graph_name, graph_name}), Graph.values(graph, mapping)}
    end
  end


  @doc """
  Checks if two `RDF.Dataset`s are equal.

  Two `RDF.Dataset`s are considered to be equal if they contain the same triples
  and have the same name.
  """
  @spec equal?(t | any, t | any) :: boolean
  def equal?(dataset1, dataset2)

  def equal?(%RDF.Dataset{} = dataset1, %RDF.Dataset{} = dataset2) do
    clear_metadata(dataset1) == clear_metadata(dataset2)
  end

  def equal?(_, _), do: false

  defp clear_metadata(%RDF.Dataset{graphs: graphs} = dataset) do
    %RDF.Dataset{dataset |
      graphs:
        Map.new(graphs, fn {name, graph} ->
          {name, RDF.Graph.clear_metadata(graph)}
        end)
    }
  end


  defimpl Enumerable do
    def member?(dataset, statement), do: {:ok, RDF.Dataset.include?(dataset, statement)}
    def count(dataset),              do: {:ok, RDF.Dataset.statement_count(dataset)}
    def slice(_dataset),             do: {:error, __MODULE__}

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


  defimpl Collectable do
    def into(original) do
      collector_fun = fn
        dataset, {:cont, list} when is_list(list)
                               -> RDF.Dataset.add(dataset, List.to_tuple(list))
        dataset, {:cont, elem} -> RDF.Dataset.add(dataset, elem)
        dataset, :done         -> dataset
        _dataset, :halt        -> :ok
      end

      {original, collector_fun}
    end
  end

end
