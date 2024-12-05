defmodule RDF.Dataset do
  @moduledoc """
  A set of `RDF.Graph`s.

  It may have multiple named graphs and at most one unnamed ("default") graph.

  `RDF.Dataset` implements:

  - Elixir's `Access` behaviour
  - Elixir's `Enumerable` protocol
  - Elixir's `Collectable` protocol
  - Elixir's `Inspect` protocol
  - the `RDF.Data` protocol

  """

  defstruct name: nil, graphs: %{}

  @behaviour Access

  alias RDF.{Graph, Description, IRI, Statement, Quad, Triple, PrefixMap, PropertyMap}
  import RDF.Statement, only: [coerce_subject: 1, coerce_graph_name: 1]
  import RDF.Utils

  @type graph_name :: IRI.t() | nil

  @type t :: %__MODULE__{
          name: graph_name,
          graphs: %{graph_name => Graph.t()}
        }

  @type input :: Graph.input() | t

  @type update_graph_fun :: (Graph.t() -> {Graph.t()})

  @type get_and_update_graph_fun :: (Graph.t() -> {Graph.t(), input} | :pop)

  @doc """
  Creates an empty unnamed `RDF.Dataset`.
  """
  @spec new :: t
  def new, do: %__MODULE__{}

  @doc """
  Creates an `RDF.Dataset`.

  If a keyword list is given an empty dataset is created.
  Otherwise, an unnamed dataset initialized with the given data is created.

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

  By overwriting statements with the same subject, this function has a similar
  semantics as `RDF.Graph.put/3`, if you want to replace whole graphs use
  `put_graph/3` instead.

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
    input =
      if destination_graph = Keyword.get(opts, :graph) do
        input
        |> Graph.new(name: destination_graph)
        |> new()
      else
        input
      end

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
    put(dataset, new() |> add(input, opts), Keyword.delete(opts, :graph))
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
  Adds new graphs to a `RDF.Dataset` overwriting any existing graphs with the same name.

  The `graph` option allows to set a different destination graph to which the
  statements should be added, ignoring the graph context of given quads or the
  name of given graphs in `input`.

  Note: When the statements to be added are given as another `RDF.Dataset` and
  a destination graph is set with the `graph` option, the descriptions of the
  subjects in the different graphs are aggregated.

  """
  @spec put_graph(t, input, keyword) :: t
  def put_graph(dataset, input, opts \\ [])

  def put_graph(%__MODULE__{} = dataset, %__MODULE__{} = input, opts) do
    input =
      if destination_graph = Keyword.get(opts, :graph) do
        input
        |> Graph.new(name: destination_graph)
        |> new()
      else
        input
      end

    %__MODULE__{
      dataset
      | graphs:
          Enum.reduce(
            input.graphs,
            dataset.graphs,
            fn {graph_name, graph}, graphs ->
              Map.put(graphs, graph_name, graph)
            end
          )
    }
  end

  def put_graph(%__MODULE__{} = dataset, input, opts) do
    put_graph(dataset, new() |> add(input, opts), Keyword.delete(opts, :graph))
  end

  @doc """
  Updates a graph in `dataset` with the given function.

  If `graph_name` is present in `dataset`, `fun` is invoked with argument `graph`
  and its result is used as the new graph with the given `graph_name`.
  If `graph_name` is not present in `dataset`, `initial` is inserted with the
  given `graph_name`. If no `initial` value is given, the `dataset` remains unchanged.
  If `nil` is returned by `fun`, the respective graph will be removed from `dataset`.

  The initial value and the returned values by the update function will be
  coerced to proper RDF graphs before added. If the initial or returned
  graph is a `RDF.Graph` with another graph name, it will still be added
  using the given `graph_name`.

  ## Examples

      iex> RDF.Dataset.new({EX.S, EX.p, EX.O, EX.Graph})
      ...> |> RDF.Dataset.update(EX.Graph,
      ...>      fn graph -> RDF.Graph.add(graph, {EX.S, EX.p, EX.O2})
      ...>    end)
      RDF.Dataset.new([{EX.S, EX.p, EX.O, EX.Graph}, {EX.S, EX.p, EX.O2, EX.Graph}])

      iex> RDF.Dataset.new()
      ...> |> RDF.Dataset.update(EX.Graph, RDF.Graph.new({EX.S, EX.p, EX.O}),
      ...>      fn graph -> RDF.Graph.add(graph, {EX.S, EX.p, EX.O2})
      ...>    end)
      RDF.Dataset.new([{EX.S, EX.p, EX.O, EX.Graph}])

  """
  @spec update(
          t,
          Statement.graph_name(),
          Graph.input() | nil,
          update_graph_fun
        ) :: t
  def update(%__MODULE__{} = dataset, graph_name, initial \\ nil, fun) do
    graph_name = RDF.coerce_graph_name(graph_name)

    case get(dataset, graph_name) do
      nil ->
        if initial do
          add(dataset, Graph.new(initial, name: graph_name))
        else
          dataset
        end

      graph ->
        graph
        |> fun.()
        |> case do
          nil ->
            delete_graph(dataset, graph_name)

          new_graph ->
            dataset
            |> delete_graph(graph_name)
            |> add(Graph.new(new_graph, name: graph_name))
        end
    end
  end

  @doc """
  Updates all graphs in `dataset` with the given function.

  The same behaviour as described in `RDF.Dataset.update/4` apply.
  If `nil` is returned by `fun`, the respective graph will be removed from `dataset`.
  The returned values by the update function will be coerced to proper RDF graphs before added.
  If the returned graph is a `RDF.Graph` with another graph name, it will still be added
  using the old graph name.

  ## Examples

      iex> RDF.Dataset.new([{EX.S1, EX.p1, EX.O1}, {EX.S2, EX.p2, EX.O2, EX.Graph}])
      ...> |> RDF.Dataset.update_all_graphs(&(RDF.Graph.add_prefixes(&1, ex: EX )))
      [
        RDF.Graph.new({EX.S1, EX.p1, EX.O1}, prefixes: [ex: EX]),
        RDF.Graph.new({EX.S2, EX.p2, EX.O2}, prefixes: [ex: EX], name: EX.Graph)
      ] |> RDF.Dataset.new()
  """
  def update_all_graphs(%__MODULE__{} = dataset, fun) do
    dataset
    |> graph_names()
    |> Enum.reduce(dataset, &update(&2, &1, fun))
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
            if Graph.empty?(new_graph) do
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
  def delete_graph(dataset, graph_names)

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
  @spec graph(t, Statement.graph_name() | nil) :: Graph.t() | nil
  def graph(%__MODULE__{} = dataset, graph_name) do
    Map.get(dataset.graphs, coerce_graph_name(graph_name))
  end

  @doc """
  The default graph of a `RDF.Dataset`.

  ## Examples

      iex> RDF.Dataset.new([
      ...>   {EX.S1, EX.p1, EX.O1},
      ...>   {EX.S2, EX.p2, EX.O2, EX.Graph1},
      ...>   {EX.S1, EX.p2, EX.O3, EX.Graph2}])
      ...> |> RDF.Dataset.default_graph()
      Graph.new({EX.S1, EX.p1, EX.O1})

  """
  @spec default_graph(t) :: Graph.t()
  def default_graph(%__MODULE__{} = dataset) do
    Map.get(dataset.graphs, nil, Graph.new())
  end

  @doc """
  The named graphs of a `RDF.Dataset`.

  ## Examples

      iex> RDF.Dataset.new([
      ...>   {EX.S1, EX.p1, EX.O1},
      ...>   {EX.S2, EX.p2, EX.O2, EX.Graph1},
      ...>   {EX.S1, EX.p2, EX.O3, EX.Graph2}])
      ...> |> RDF.Dataset.named_graphs()
      [
        Graph.new({EX.S2, EX.p2, EX.O2}, name: EX.Graph1),
        Graph.new({EX.S1, EX.p2, EX.O3}, name: EX.Graph2)
      ]
  """
  @spec named_graphs(t) :: [Graph.t()]
  def named_graphs(%__MODULE__{} = dataset) do
    dataset.graphs |> Map.delete(nil) |> Map.values()
  end

  @doc """
  A list of all graphs within the dataset.
  """
  @spec graphs(t) :: [Graph.t()]
  def graphs(%__MODULE__{} = dataset), do: Map.values(dataset.graphs)

  @doc """
  A list of all graph names within the dataset.

  Note, that this includes `nil` when the dataset has a default graph.

  ## Examples

      iex> RDF.Dataset.new([
      ...>   {EX.S1, EX.p1, EX.O1},
      ...>   {EX.S2, EX.p2, EX.O2, EX.Graph1},
      ...>   {EX.S1, EX.p2, EX.O3, EX.Graph2}])
      ...> |> RDF.Dataset.graph_names()
      [nil, RDF.iri(EX.Graph1), RDF.iri(EX.Graph2)]

  """
  @spec graph_names(t) :: [IRI.t() | nil]
  def graph_names(%__MODULE__{} = dataset), do: Map.keys(dataset.graphs)

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
  @spec get_and_update(t, Statement.graph_name() | nil, get_and_update_graph_fun) ::
          {Graph.t(), t}
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
      if Graph.empty?(popped_graph),
        do: graphs |> Map.delete(graph_name),
        else: graphs |> Map.put(graph_name, popped_graph)

    {
      {s, p, o, graph_name},
      %__MODULE__{dataset | graphs: popped}
    }
  end

  @doc """
  Pops the graph with the given name.

  Removes the graph of the given `graph_name` from `dataset`.

  Returns a tuple containing the graph of the given name
  and the updated dataset without this graph.
  `nil` is returned instead of the graph if `dataset` does
  not contain a graph_name of the given `graph_name`.

  ## Examples

      iex> dataset = RDF.Dataset.new([
      ...>   {EX.S1, EX.P1, EX.O1, EX.Graph},
      ...>   {EX.S2, EX.P2, EX.O2}])
      ...> RDF.Dataset.pop(dataset, EX.Graph)
      {
        RDF.Graph.new({EX.S1, EX.P1, EX.O1}, name: EX.Graph),
        RDF.Dataset.new({EX.S2, EX.P2, EX.O2})
      }
      iex> RDF.Dataset.pop(dataset, EX.Foo)
      {nil, dataset}
  """
  @impl Access
  @spec pop(t, Statement.coercible_graph_name()) :: {Graph.t() | nil, t}
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
    map_size(dataset.graphs)
  end

  @doc """
  The number of statements within a `RDF.Dataset`.

  ## Examples

      iex> RDF.Dataset.new([
      ...>   {EX.S1, EX.p1, EX.O1, EX.Graph},
      ...>   {EX.S2, EX.p2, EX.O2},
      ...>   {EX.S1, EX.p2, EX.O3}]) |>
      ...>   RDF.Dataset.statement_count()
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
      ...>   RDF.Dataset.subjects()
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
      ...>   RDF.Dataset.predicates()
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
      ...> ]) |> RDF.Dataset.objects()
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
    ...> ]) |> RDF.Dataset.resources()
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

  While the statements of named graphs are returned as quad tuples, the statements
  of the default graph are returned as triples. If you want to get quads or triples
  uniformly, use the `quads/2` resp. `triples/2` functions instead.

  When the optional `:filter_star` flag is set to `true` RDF-star statements with
  a triple as subject or object will be filtered. The default value is `false`.

  ## Examples

        iex> RDF.Dataset.new([
        ...>   {EX.S1, EX.p1, EX.O1, EX.Graph},
        ...>   {EX.S2, EX.p2, EX.O2},
        ...>   {EX.S1, EX.p2, EX.O3}])
        ...> |> RDF.Dataset.statements()
        [{RDF.iri(EX.S1), RDF.iri(EX.p2), RDF.iri(EX.O3)},
         {RDF.iri(EX.S2), RDF.iri(EX.p2), RDF.iri(EX.O2)},
         {RDF.iri(EX.S1), RDF.iri(EX.p1), RDF.iri(EX.O1), RDF.iri(EX.Graph)}]
  """
  @spec statements(t, keyword) :: [Statement.t()]
  def statements(%__MODULE__{} = dataset, opts \\ []) do
    Enum.flat_map(dataset.graphs, fn
      {nil, graph} -> Graph.triples(graph, opts)
      {_, graph} -> Graph.quads(graph, opts)
    end)
  end

  @doc """
  All statements within all graphs of a `RDF.Dataset` as quads.

  When the optional `:filter_star` flag is set to `true` RDF-star statements with
  a triple as subject or object will be filtered. The default value is `false`.

  ## Examples

        iex> RDF.Dataset.new([
        ...>   {EX.S1, EX.p1, EX.O1, EX.Graph},
        ...>   {EX.S2, EX.p2, EX.O2},
        ...>   {EX.S1, EX.p2, EX.O3}])
        ...> |> RDF.Dataset.quads()
        [{RDF.iri(EX.S1), RDF.iri(EX.p2), RDF.iri(EX.O3), nil},
         {RDF.iri(EX.S2), RDF.iri(EX.p2), RDF.iri(EX.O2), nil},
         {RDF.iri(EX.S1), RDF.iri(EX.p1), RDF.iri(EX.O1), RDF.iri(EX.Graph)}]
  """
  @spec quads(t, keyword) :: [Quad.t()]
  def quads(%__MODULE__{} = dataset, opts \\ []) do
    Enum.flat_map(dataset.graphs, fn {_, graph} -> Graph.quads(graph, opts) end)
  end

  @doc """
  All statements within all graphs of a `RDF.Dataset` as triples.

  When the optional `:filter_star` flag is set to `true` RDF-star statements with
  a triple as subject or object will be filtered. The default value is `false`.

  Note: When a triple is present in multiple graphs it will be present in the resulting
  list of triples multiple times for performance reasons. If you want to get a list with
  unique triples, you'll have to apply `Enum.uniq/1` on the result.

  ## Examples

        iex> RDF.Dataset.new([
        ...>   {EX.S1, EX.p1, EX.O1, EX.Graph},
        ...>   {EX.S2, EX.p2, EX.O2},
        ...>   {EX.S1, EX.p2, EX.O3}])
        ...> |> RDF.Dataset.triples()
        [{RDF.iri(EX.S1), RDF.iri(EX.p2), RDF.iri(EX.O3)},
         {RDF.iri(EX.S2), RDF.iri(EX.p2), RDF.iri(EX.O2)},
         {RDF.iri(EX.S1), RDF.iri(EX.p1), RDF.iri(EX.O1)}]
  """
  @spec triples(t, keyword) :: [Triple.t()]
  def triples(%__MODULE__{} = dataset, opts \\ []) do
    Enum.flat_map(dataset.graphs, fn {_, graph} -> Graph.triples(graph, opts) end)
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

  # This function relies on Map.intersect/3 that was added in Elixir v1.15
  if Version.match?(System.version(), ">= 1.15.0") do
    @doc """
    Returns a new dataset that is the intersection of the given `dataset` with the given `data`.

    The `data` can be given in any form an `RDF.Dataset` can be created from.

    ## Examples

        iex> RDF.Dataset.new([
        ...>   {EX.S1, EX.p(), [EX.O1, EX.O2]},
        ...>   {EX.S2, EX.p(), EX.O3, EX.Graph}
        ...> ])
        ...> |> RDF.Dataset.intersection([
        ...>     {EX.S1, EX.p(), EX.O2},
        ...>     {EX.S2, EX.p(), EX.O3}
        ...>   ])
        RDF.Dataset.new({EX.S1, EX.p(), EX.O2})

    """
    @spec intersection(t(), t() | Graph.t() | Description.t() | input()) :: t()
    def intersection(dataset, data)

    def intersection(%__MODULE__{} = dataset1, %__MODULE__{} = dataset2) do
      intersection =
        dataset1.graphs
        |> Map.intersect(dataset2.graphs, fn _, g1, g2 ->
          graph_intersection = Graph.intersection(g1, g2)
          unless Graph.empty?(graph_intersection), do: graph_intersection
        end)
        |> RDF.Utils.reject_empty_map_values()

      %__MODULE__{dataset1 | graphs: intersection}
    end

    def intersection(%__MODULE__{} = dataset, data) do
      intersection(dataset, new(data))
    end
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

  defdelegate isomorphic?(a, b), to: RDF.Canonicalization

  @doc """
  Canonicalizes the blank nodes of a dataset according to the RDF Dataset Canonicalization spec.

  See the `RDF.Canonicalization` module documentation on available options.

  ## Example

      iex> RDF.Dataset.new([{~B<foo>, EX.p(), ~B<bar>}, {~B<bar>, EX.p(), ~B<foo>}])
      ...> |> RDF.Dataset.canonicalize()
      RDF.Dataset.new([{~B<c14n0>, EX.p(), ~B<c14n1>}, {~B<c14n1>, EX.p(), ~B<c14n0>}])

  """
  @spec canonicalize(RDF.Dataset.t() | RDF.Graph.t(), keyword) :: RDF.Dataset.t()
  def canonicalize(%graph_or_dataset{} = dataset, opts \\ [])
      when graph_or_dataset in [__MODULE__, Graph] do
    {canonicalized_dataset, _} = RDF.Canonicalization.canonicalize(dataset, opts)
    canonicalized_dataset
  end

  @doc """
  Returns a hash of the canonical form of the given dataset.

  This hash is computed as follows:

  1. Compute the canonical form of the dataset according to the RDF Dataset Canonicalization spec
     using `canonicalize/1`.
  2. Serialize this canonical dataset to N-Quads sorted by Unicode code point order.
  3. Compute the SHA-256 of this N-Quads serialization.

  Note that the data structure is not relevant for the canonical hash, i.e.
  the same hash is generated for the same data regardless of whether it is
  passed in an `RDF.Graph`, `RDF.Dataset` or `RDF.Description`.

  ## Options

  - `:hash_algorithm` (default: `:sha256`): Allows to set the hash algorithm to be used in step 3.
    Any of the `:crypto.hash_algorithm()` values of Erlang's `:crypto` module are allowed.
    Note that this does NOT affect the hash function used during the


  ## Example

      iex> RDF.Dataset.new([{~B<foo>, EX.p(), ~B<bar>}, {~B<bar>, EX.p(), ~B<foo>}])
      ...> |> RDF.Dataset.canonical_hash()
      "053688e09a20a49acc3e1a5e6403c827b817eef9e4c90bfd71f2360e2a6446aa"

      iex> RDF.Graph.new([{~B<other>, EX.p(), ~B<bar>}, {~B<bar>, EX.p(), ~B<other>}])
      ...> |> RDF.Graph.canonical_hash()
      "053688e09a20a49acc3e1a5e6403c827b817eef9e4c90bfd71f2360e2a6446aa"
  """
  @spec canonical_hash(RDF.Dataset.t() | RDF.Graph.t(), keyword) :: binary
  def canonical_hash(%graph_or_dataset{} = dataset, opts \\ [])
      when graph_or_dataset in [__MODULE__, Graph] do
    canonical_nquads =
      dataset
      |> canonicalize()
      |> RDF.NQuads.write_string!(sort: true)

    opts
    |> Keyword.get(:hash_algorithm, :sha256)
    |> :crypto.hash(canonical_nquads)
    |> Base.encode16(case: :lower)
  end

  @doc """
  Returns the aggregated prefixes of all graphs of `dataset` as a `RDF.PrefixMap`.
  """
  @spec prefixes(t) :: PrefixMap.t() | nil
  def prefixes(%__MODULE__{} = dataset) do
    dataset
    |> graphs()
    |> Enum.reduce(PrefixMap.new(), fn graph, prefixes ->
      if graph.prefixes do
        PrefixMap.merge!(prefixes, graph.prefixes, :ignore)
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
      {:ok, size, &Dataset.statements/1}
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
          IO.warn(
            "statements as lists in `Collectable` implementation of `RDF.Dataset` are deprecated and will be removed in RDF.ex v2.0; use statements as tuples instead"
          )

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
