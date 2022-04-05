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

  defstruct name: nil, graphs: %{}

  @behaviour Access

  alias RDF.{Graph, Description, IRI, Statement, PrefixMap, PropertyMap}
  import RDF.Statement, only: [coerce_subject: 1, coerce_graph_name: 1]
  import RDF.Utils

  @type graph_name :: IRI.t() | nil

  @type t :: %__MODULE__{
          name: graph_name,
          graphs: %{graph_name => Graph.t()}
        }

  @type input :: Graph.input() | t

  @type update_graph_fun :: (Graph.t() -> {Graph.t(), input} | :pop)

  @doc """
  Creates an empty unnamed `RDF.Dataset`.
  """
  @spec new :: t
  def new, do: %__MODULE__{}

  @doc """
  Creates an `RDF.Dataset`.

  If a keyword list is given an empty dataset is created.
  Otherwise an unnamed dataset initialized with the given data is created.

  See `new/2` for available arguments and the different ways to provide data.

  ## Examples

      RDF.Dataset.new(name: EX.GraphName)

      RDF.Dataset.new(init: {EX.S, EX.p, EX.O})

      RDF.Dataset.new({EX.S, EX.p, EX.O})

  """
  @spec new(input | keyword) :: t
  def new(data_or_opts)

  def new(data_or_opts) when is_list(data_or_opts) and length(data_or_opts) != 0 do
    if Keyword.keyword?(data_or_opts) do
      {data, options} = Keyword.pop(data_or_opts, :init)
      new(data, options)
    else
      new(data_or_opts, [])
    end
  end

  def new(data), do: new(data, [])

  @doc """
  Creates an `RDF.Dataset` initialized with data.

  The initial RDF triples can be provided in any form accepted by `add/3`.

  Available options:

  - `name`: the name of the dataset to be created
  - `init`: some data with which the dataset should be initialized; the data can be
    provided in any form accepted by `add/3` and above that also with a function returning
    the initialization data in any of these forms

  """
  @spec new(input, keyword) :: t
  def new(data, opts)

  def new(%__MODULE__{} = graph, opts) do
    %__MODULE__{graph | name: opts |> Keyword.get(:name) |> coerce_graph_name()}
  end

  def new(data, opts) do
    %__MODULE__{}
    |> new(opts)
    |> init(data, opts)
  end

  defp init(dataset, nil, _), do: dataset
  defp init(dataset, fun, opts) when is_function(fun), do: add(dataset, fun.(), opts)
  defp init(dataset, data, opts), do: add(dataset, data, opts)

  @doc """
  Returns the dataset name IRI of `dataset`.
  """
  @spec name(t) :: Statement.graph_name()
  def name(%__MODULE__{} = dataset), do: dataset.name

  @doc """
  Changes the dataset name of `dataset`.
  """
  @spec change_name(t, Statement.coercible_graph_name()) :: t
  def change_name(%__MODULE__{} = dataset, new_name) do
    %__MODULE__{dataset | name: coerce_graph_name(new_name)}
  end

  defp destination_graph(opts, default \\ nil) do
    opts
    |> Keyword.get(:graph, default)
    |> coerce_graph_name()
  end

  @doc """
  Adds triples and quads to a `RDF.Dataset`.

  The triples can be provided in any form accepted by `add/2`.

  - as a single statement tuple
  - an `RDF.Description`
  - an `RDF.Graph`
  - an `RDF.Dataset`
  - or a list with any combination of the former

  The `graph` option allows to set a different destination graph to which the
  statements should be added, ignoring the graph context of given quads or the
  name of given graphs in `input`.

  Note: When the statements to be added are given as another `RDF.Dataset` and
  a destination graph is set with the `graph` option, the descriptions of the
  subjects in the different graphs are aggregated.
  """
  @spec add(t, input, keyword) :: t
  def add(dataset, input, opts \\ [])

  def add(%__MODULE__{} = dataset, {_, _, _, graph} = quad, opts),
    do: do_add(dataset, destination_graph(opts, graph), quad, opts)

  def add(%__MODULE__{} = dataset, %Description{} = description, opts),
    do: do_add(dataset, destination_graph(opts), description, opts)

  def add(%__MODULE__{} = dataset, %Graph{} = graph, opts),
    do: do_add(dataset, destination_graph(opts, graph.name), graph, opts)

  def add(%__MODULE__{} = dataset, %__MODULE__{} = other_dataset, opts) do
    other_dataset
    |> graphs()
    |> Enum.reduce(dataset, &add(&2, &1, opts))
  end

  def add(dataset, input, opts)
      when is_list(input) or (is_map(input) and not is_struct(input)) do
    Enum.reduce(input, dataset, &add(&2, &1, opts))
  end

  def add(%__MODULE__{} = dataset, input, opts),
    do: do_add(dataset, destination_graph(opts), input, opts)

  defp do_add(dataset, graph_name, input, opts) do
    %__MODULE__{
      dataset
      | graphs:
          lazy_map_update(
            dataset.graphs,
            graph_name,
            # when new:
            fn -> Graph.new(input, Keyword.put(opts, :name, graph_name)) end,
            # when update:
            fn graph -> Graph.add(graph, input, opts) end
          )
    }
  end

  @doc """
  Adds statements to a `RDF.Dataset` overwriting existing statements with the subjects given in the `input` data.

  The `graph` option allows to set a different destination graph to which the
  statements should be added, ignoring the graph context of given quads or the
  name of given graphs in `input`.

  Note: When the statements to be added are given as another `RDF.Dataset` and
  a destination graph is set with the `graph` option, the descriptions of the
  subjects in the different graphs are aggregated.

  ## Examples

      iex> dataset = RDF.Dataset.new({EX.S, EX.P1, EX.O1})
      ...> RDF.Dataset.put(dataset, {EX.S, EX.P2, EX.O2})
      RDF.Dataset.new({EX.S, EX.P2, EX.O2})
      iex> RDF.Dataset.put(dataset, {EX.S2, EX.P2, EX.O2})
      RDF.Dataset.new([{EX.S, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2}])
  """

  @spec put(t, input, keyword) :: t
  def put(dataset, input, opts \\ [])

  def put(%__MODULE__{} = dataset, %__MODULE__{} = input, opts) do
    %__MODULE__{
      dataset
      | graphs:
          Enum.reduce(
            input.graphs,
            dataset.graphs,
            fn {graph_name, graph}, graphs ->
              Map.update(
                graphs,
                graph_name,
                graph,
                fn current -> Graph.put(current, graph, opts) end
              )
            end
          )
    }
  end

  def put(%__MODULE__{} = dataset, input, opts) do
    put(dataset, new() |> add(input, opts), opts)
  end

  @doc """
  Adds statements to a `RDF.Dataset` and overwrites all existing statements with the same subject-predicate combinations given in the `input` data.

  The `graph` option allows to set a different destination graph to which the
  statements should be added, ignoring the graph context of given quads or the
  name of given graphs in `input`.

  Note: When the statements to be added are given as another `RDF.Dataset` and
  a destination graph is set with the `graph` option, the descriptions of the
  subjects in the different graphs are aggregated.

  ## Examples

      iex> dataset = RDF.Dataset.new({EX.S, EX.P1, EX.O1})
      ...> RDF.Dataset.put_properties(dataset, {EX.S, EX.P1, EX.O2})
      RDF.Dataset.new({EX.S, EX.P1, EX.O2})
      iex> RDF.Dataset.put_properties(dataset, {EX.S, EX.P2, EX.O2})
      RDF.Dataset.new([{EX.S, EX.P1, EX.O1}, {EX.S, EX.P2, EX.O2}])
      iex> RDF.Dataset.new([{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2}])
      ...> |> RDF.Dataset.put_properties([{EX.S1, EX.P2, EX.O3}, {EX.S2, EX.P2, EX.O3}])
      RDF.Dataset.new([{EX.S1, EX.P1, EX.O1}, {EX.S1, EX.P2, EX.O3}, {EX.S2, EX.P2, EX.O3}])
  """

  @spec put_properties(t, input, keyword) :: t
  def put_properties(dataset, input, opts \\ [])

  def put_properties(%__MODULE__{} = dataset, %__MODULE__{} = input, opts) do
    %__MODULE__{
      dataset
      | graphs:
          Enum.reduce(
            input.graphs,
            dataset.graphs,
            fn {graph_name, graph}, graphs ->
              Map.update(
                graphs,
                graph_name,
                graph,
                fn current -> Graph.put_properties(current, graph, opts) end
              )
            end
          )
    }
  end

  def put_properties(%__MODULE__{} = dataset, input, opts) do
    put_properties(dataset, new() |> add(input, opts), opts)
  end

  @doc """
  Deletes statements from a `RDF.Dataset`.

  The `graph` option allows to set a different destination graph from which the
  statements should be deleted, ignoring the graph context of given quads or the
  name of given graphs.

  Note: When the statements to be deleted are given as another `RDF.Dataset`,
  the dataset name must not match dataset name of the dataset from which the statements
  are deleted. If you want to delete only datasets with matching names, you can
  use `RDF.Data.delete/2`.
  """
  @spec delete(t, input, keyword) :: t
  def delete(dataset, input, opts \\ [])

  def delete(%__MODULE__{} = dataset, {_, _, _, graph} = quad, opts),
    do: do_delete(dataset, destination_graph(opts, graph), quad, opts)

  def delete(%__MODULE__{} = dataset, %Description{} = description, opts),
    do: do_delete(dataset, destination_graph(opts), description, opts)

  def delete(%__MODULE__{} = dataset, %Graph{} = graph, opts),
    do: do_delete(dataset, destination_graph(opts, graph.name), graph, opts)

  def delete(%__MODULE__{} = dataset, %__MODULE__{} = other_dataset, opts) do
    other_dataset
    |> graphs()
    |> Enum.reduce(dataset, &delete(&2, &1, opts))
  end

  def delete(dataset, input, opts)
      when is_list(input) or (is_map(input) and not is_struct(input)) do
    Enum.reduce(input, dataset, &delete(&2, &1, opts))
  end

  def delete(%__MODULE__{} = dataset, input, opts) when not is_struct(input),
    do: do_delete(dataset, destination_graph(opts), input, opts)

  defp do_delete(dataset, graph_name, input, opts) do
    if existing_graph = dataset.graphs[graph_name] do
      new_graph = Graph.delete(existing_graph, input, opts)

      %__MODULE__{
        dataset
        | graphs:
            if Enum.empty?(new_graph) do
              Map.delete(dataset.graphs, graph_name)
            else
              Map.put(dataset.graphs, graph_name, new_graph)
            end
      }
    else
      dataset
    end
  end

  @doc """
  Deletes the given graph.
  """
  @spec delete_graph(t, Statement.graph_name() | [Statement.graph_name()] | nil) :: t
  def delete_graph(graph, graph_names)

  def delete_graph(%__MODULE__{} = dataset, graph_names) when is_list(graph_names) do
    Enum.reduce(graph_names, dataset, &delete_graph(&2, &1))
  end

  def delete_graph(%__MODULE__{} = dataset, graph_name) do
    %__MODULE__{dataset | graphs: Map.delete(dataset.graphs, coerce_graph_name(graph_name))}
  end

  @doc """
  Deletes the default graph.
  """
  @spec delete_default_graph(t) :: t
  def delete_default_graph(%__MODULE__{} = graph),
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
  @spec fetch(t, Statement.graph_name() | nil) :: {:ok, Graph.t()} | :error
  def fetch(%__MODULE__{} = dataset, graph_name) do
    Access.fetch(dataset.graphs, coerce_graph_name(graph_name))
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
  @spec get(t, Statement.graph_name() | nil, Graph.t() | nil) :: Graph.t() | nil
  def get(%__MODULE__{} = dataset, graph_name, default \\ nil) do
    case fetch(dataset, graph_name) do
      {:ok, value} -> value
      :error -> default
    end
  end

  @doc """
  The graph with given name.
  """
  @spec graph(t, Statement.graph_name() | nil) :: Graph.t()
  def graph(%__MODULE__{} = dataset, graph_name) do
    Map.get(dataset.graphs, coerce_graph_name(graph_name))
  end

  @doc """
  The default graph of a `RDF.Dataset`.
  """
  @spec default_graph(t) :: Graph.t()
  def default_graph(%__MODULE__{} = dataset) do
    Map.get(dataset.graphs, nil, Graph.new())
  end

  @doc """
  The set of all graphs.
  """
  @spec graphs(t) :: [Graph.t()]
  def graphs(%__MODULE__{} = dataset), do: Map.values(dataset.graphs)

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
  @spec get_and_update(t, Statement.graph_name() | nil, update_graph_fun) :: {Graph.t(), input}
  def get_and_update(%__MODULE__{} = dataset, graph_name, fun) do
    graph_context = coerce_graph_name(graph_name)

    case fun.(get(dataset, graph_context)) do
      {old_graph, new_graph} ->
        {old_graph, put(dataset, new_graph, graph: graph_context)}

      :pop ->
        pop(dataset, graph_context)

      other ->
        raise "the given function must return a two-element tuple or :pop, got: #{inspect(other)}"
    end
  end

  @doc """
  Pops an arbitrary statement from a `RDF.Dataset`.
  """
  @spec pop(t) :: {Statement.t() | nil, t}
  def pop(dataset)

  def pop(%__MODULE__{graphs: graphs} = dataset)
      when graphs == %{},
      do: {nil, dataset}

  def pop(%__MODULE__{graphs: graphs} = dataset) do
    # TODO: Find a faster way ...
    [{graph_name, graph}] = Enum.take(graphs, 1)
    {{s, p, o}, popped_graph} = Graph.pop(graph)

    popped =
      if Enum.empty?(popped_graph),
        do: graphs |> Map.delete(graph_name),
        else: graphs |> Map.put(graph_name, popped_graph)

    {
      {s, p, o, graph_name},
      %__MODULE__{dataset | graphs: popped}
    }
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
  @spec pop(t, Statement.coercible_graph_name()) :: {Statement.t() | nil, t}
  def pop(%__MODULE__{} = dataset, graph_name) do
    case Access.pop(dataset.graphs, coerce_graph_name(graph_name)) do
      {nil, _} ->
        {nil, dataset}

      {graph, new_graphs} ->
        {graph, %__MODULE__{dataset | graphs: new_graphs}}
    end
  end

  @doc """
  The number of graphs within a `RDF.Dataset`.

  ## Examples

      iex> RDF.Dataset.new([
      ...>   {EX.S1, EX.p1, EX.O1},
      ...>   {EX.S2, EX.p2, EX.O2},
      ...>   {EX.S1, EX.p2, EX.O3, EX.Graph}])
      ...> |> RDF.Dataset.graph_count()
      2

  """
  @spec graph_count(t) :: non_neg_integer
  def graph_count(%__MODULE__{} = dataset) do
    Enum.count(dataset.graphs)
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
  def statement_count(%__MODULE__{} = dataset) do
    Enum.reduce(dataset.graphs, 0, fn {_, graph}, count ->
      count + Graph.triple_count(graph)
    end)
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
  def subjects(%__MODULE__{} = dataset) do
    Enum.reduce(dataset.graphs, MapSet.new(), fn {_, graph}, subjects ->
      MapSet.union(subjects, Graph.subjects(graph))
    end)
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
  def predicates(%__MODULE__{} = dataset) do
    Enum.reduce(dataset.graphs, MapSet.new(), fn {_, graph}, predicates ->
      MapSet.union(predicates, Graph.predicates(graph))
    end)
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
  def objects(%__MODULE__{} = dataset) do
    Enum.reduce(dataset.graphs, MapSet.new(), fn {_, graph}, objects ->
      MapSet.union(objects, Graph.objects(graph))
    end)
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
  def resources(%__MODULE__{} = dataset) do
    Enum.reduce(dataset.graphs, MapSet.new(), fn {_, graph}, resources ->
      MapSet.union(resources, Graph.resources(graph))
    end)
  end

  @doc """
  All statements within all graphs of a `RDF.Dataset`.

  When the optional `:filter_star` flag is set to `true` RDF-star statements with
  a triple as subject or object will be filtered. The default value is `false`.

  ## Examples

        iex> RDF.Dataset.new([
        ...>   {EX.S1, EX.p1, EX.O1, EX.Graph},
        ...>   {EX.S2, EX.p2, EX.O2},
        ...>   {EX.S1, EX.p2, EX.O3}]) |>
        ...>   RDF.Dataset.statements
        [{RDF.iri(EX.S1), RDF.iri(EX.p2), RDF.iri(EX.O3)},
         {RDF.iri(EX.S2), RDF.iri(EX.p2), RDF.iri(EX.O2)},
         {RDF.iri(EX.S1), RDF.iri(EX.p1), RDF.iri(EX.O1), RDF.iri(EX.Graph)}]
  """
  @spec statements(t, keyword) :: [Statement.t()]
  def statements(%__MODULE__{} = dataset, opts \\ []) do
    Enum.flat_map(dataset.graphs, fn
      {nil, graph} ->
        Graph.triples(graph, opts)

      {name, graph} ->
        graph |> Graph.triples(opts) |> Enum.map(fn {s, p, o} -> {s, p, o, name} end)
    end)
  end

  @doc """
  Returns if the given `dataset` is empty.

  Note: You should always prefer this over the use of `Enum.empty?/1` as it is significantly faster.
  """
  @spec empty?(t) :: boolean
  def empty?(%__MODULE__{} = dataset) do
    Enum.empty?(dataset.graphs) or dataset |> graphs() |> Enum.all?(&Graph.empty?/1)
  end

  @doc """
  Checks if the given `input` statements exist within `dataset`.

  The `graph` option allows to set a different destination graph in which the
  statements should be checked, ignoring the graph context of given quads or the
  name of given graphs.

  ## Examples

        iex> dataset = RDF.Dataset.new([
        ...>   {EX.S1, EX.p1, EX.O1, EX.Graph},
        ...>   {EX.S2, EX.p2, EX.O2},
        ...>   {EX.S1, EX.p2, EX.O3}])
        ...> RDF.Dataset.include?(dataset, {EX.S1, EX.p1, EX.O1, EX.Graph})
        true
  """
  @spec include?(t, input, keyword) :: boolean
  def include?(dataset, input, opts \\ [])

  def include?(%__MODULE__{} = dataset, {_, _, _, graph} = quad, opts),
    do: do_include?(dataset, destination_graph(opts, graph), quad, opts)

  def include?(%__MODULE__{} = dataset, %Description{} = description, opts),
    do: do_include?(dataset, destination_graph(opts), description, opts)

  def include?(%__MODULE__{} = dataset, %Graph{} = graph, opts),
    do: do_include?(dataset, destination_graph(opts, graph.name), graph, opts)

  def include?(%__MODULE__{} = dataset, %__MODULE__{} = other_dataset, opts) do
    other_dataset
    |> graphs()
    |> Enum.all?(&include?(dataset, &1, opts))
  end

  def include?(dataset, input, opts)
      when is_list(input) or (is_map(input) and not is_struct(input)) do
    Enum.all?(input, &include?(dataset, &1, opts))
  end

  def include?(dataset, input, opts) when not is_struct(input),
    do: do_include?(dataset, destination_graph(opts), input, opts)

  defp do_include?(%__MODULE__{} = dataset, graph_name, input, opts) do
    if graph = dataset.graphs[graph_name] do
      Graph.include?(graph, input, opts)
    else
      false
    end
  end

  @doc """
  Checks if a graph of a `RDF.Dataset` contains statements about the given resource.

  ## Examples

        iex> RDF.Dataset.new([{EX.S1, EX.p1, EX.O1}]) |> RDF.Dataset.describes?(EX.S1)
        true
        iex> RDF.Dataset.new([{EX.S1, EX.p1, EX.O1}]) |> RDF.Dataset.describes?(EX.S2)
        false
  """
  @spec describes?(t, Statement.t(), Statement.coercible_graph_name() | nil) :: boolean
  def describes?(%__MODULE__{} = dataset, subject, graph_context \\ nil) do
    if graph = dataset.graphs[coerce_graph_name(graph_context)] do
      Graph.describes?(graph, subject)
    else
      false
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
  @spec who_describes(t, Statement.coercible_subject()) :: [Graph.t()]
  def who_describes(%__MODULE__{} = dataset, subject) do
    subject = coerce_subject(subject)

    dataset.graphs
    |> Map.values()
    |> Stream.filter(&Graph.describes?(&1, subject))
    |> Enum.map(& &1.name)
  end

  @doc """
  Returns a nested map of the native Elixir values of a `RDF.Dataset`.

  When a `:context` option is given with a `RDF.PropertyMap`, predicates will
  be mapped to the terms defined in the `RDF.PropertyMap`, if present.

  ## Examples

      iex> [
      ...>   {~I<http://example.com/S>, ~I<http://example.com/p>, ~L"Foo", ~I<http://example.com/Graph>},
      ...>   {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.XSD.integer(42), }
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

  """
  @spec values(t, keyword) :: map
  def values(%__MODULE__{} = dataset, opts \\ []) do
    if property_map = PropertyMap.from_opts(opts) do
      map(dataset, Statement.default_property_mapping(property_map))
    else
      map(dataset, &Statement.default_term_mapping/1)
    end
  end

  @doc """
  Returns a nested map of a `RDF.Dataset` where each element from its quads is mapped with the given function.

  The function `fun` will receive a tuple `{statement_position, rdf_term}` where
  `statement_position` is one of the atoms `:subject`, `:predicate`, `:object` or
  `:graph_name` while `rdf_term` is the RDF term to be mapped. When the given function
  returns `nil` this will be interpreted as an error and will become the overhaul
  result of the `map/2` call.

  ## Examples

      iex> [
      ...>   {~I<http://example.com/S>, ~I<http://example.com/p>, ~L"Foo", ~I<http://example.com/Graph>},
      ...>   {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.XSD.integer(42), }
      ...> ]
      ...> |> RDF.Dataset.new()
      ...> |> RDF.Dataset.map(fn
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
  @spec map(t, Statement.term_mapping()) :: map
  def map(dataset, fun)

  def map(%__MODULE__{} = dataset, fun) do
    Map.new(dataset.graphs, fn {graph_name, graph} ->
      {fun.({:graph_name, graph_name}), Graph.map(graph, fun)}
    end)
  end

  @doc """
  Checks if two `RDF.Dataset`s are equal.

  Two `RDF.Dataset`s are considered to be equal if they contain the same triples
  and have the same name.
  """
  @spec equal?(t | any, t | any) :: boolean
  def equal?(dataset1, dataset2)

  def equal?(%__MODULE__{} = dataset1, %__MODULE__{} = dataset2) do
    clear_metadata(dataset1) == clear_metadata(dataset2)
  end

  def equal?(_, _), do: false

  @doc """
  Returns the aggregated prefixes of all graphs of `dataset` as a `RDF.PrefixMap`.
  """
  @spec prefixes(t) :: PrefixMap.t() | nil
  def prefixes(%__MODULE__{} = dataset) do
    dataset
    |> RDF.Dataset.graphs()
    |> Enum.reduce(RDF.PrefixMap.new(), fn graph, prefixes ->
      if graph.prefixes do
        RDF.PrefixMap.merge!(prefixes, graph.prefixes, :ignore)
      else
        prefixes
      end
    end)
  end

  defp clear_metadata(%__MODULE__{} = dataset) do
    %__MODULE__{
      dataset
      | graphs:
          Map.new(dataset.graphs, fn {name, graph} ->
            {name, Graph.clear_metadata(graph)}
          end)
    }
  end

  defimpl Enumerable do
    alias RDF.Dataset

    def member?(dataset, statement), do: {:ok, Dataset.include?(dataset, statement)}
    def count(dataset), do: {:ok, Dataset.statement_count(dataset)}

    def slice(dataset) do
      size = Dataset.statement_count(dataset)
      {:ok, size, &Enumerable.List.slice(Dataset.statements(dataset), &1, &2, size)}
    end

    def reduce(dataset, acc, fun) do
      dataset
      |> Dataset.statements()
      |> Enumerable.List.reduce(acc, fun)
    end
  end

  defimpl Collectable do
    alias RDF.Dataset

    def into(original) do
      collector_fun = fn
        dataset, {:cont, list} when is_list(list) ->
          Dataset.add(dataset, List.to_tuple(list))

        dataset, {:cont, elem} ->
          Dataset.add(dataset, elem)

        dataset, :done ->
          dataset

        _dataset, :halt ->
          :ok
      end

      {original, collector_fun}
    end
  end
end
