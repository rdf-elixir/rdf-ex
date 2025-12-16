defprotocol RDF.Data.Source do
  @moduledoc """
  Protocol for accessing and traversing RDF data structures.

  This protocol is the RDF equivalent of Elixir's Enumerable protocol,
  providing a minimal set of functions that enable a rich API in the
  `RDF.Data` module.

  ## Structure Types

  Implementations declare one of three structure types:

  - `:description` - statements about a single subject
  - `:graph` - statements in a single named graph
  - `:dataset` - statements across multiple graphs

  ## Fallback Pattern

  Many callbacks can return `{:error, __MODULE__}` to signal that the default
  algorithm in `RDF.Data` should be used. This allows implementations to
  provide optimized versions when possible while falling back to generic
  traversal-based implementations.
  """

  @type t :: RDF.Description.t() | RDF.Graph.t() | RDF.Dataset.t() | term
  @type structure_type :: :description | :graph | :dataset
  @type derive_error :: :no_subject
  @type acc :: {:cont, term} | {:halt, term} | {:suspend, term}
  @type reducer :: (RDF.Statement.t(), term -> acc)
  @type result :: {:done, term} | {:halted, term} | {:suspended, term, continuation}
  @type continuation :: (acc -> result)

  @doc """
  Returns the structure type of this implementation.

  Must return one of:

  - `:description` - Single subject structure
  - `:graph` - Multiple subjects, single graph
  - `:dataset` - Multiple graphs
  """
  @spec structure_type(t) :: structure_type
  def structure_type(data)

  @doc """
  Derives an empty structure of the desired type from a template.

  This callback serves two purposes:

  1. **System preservation**: Custom implementations can return their own
     corresponding structures, keeping operations within the same system of
     structures.

  2. **Metadata inheritance**: When `preserve_metadata: true` (default),
     relevant metadata from the template is copied to the new structure.

  ## When is this used?

  `RDF.Data` functions that need to create new structures call this callback to
  determine the appropriate target type. Examples include:

  - `RDF.Data.merge/2` - merging data of different structure types
  - `RDF.Data.map/2` - transforming statements while preserving structure type

  ## Options

  - `:subject` - Subject for description. When target is `:description`:
    - From Description template: uses template subject, option overrides if provided
    - From Graph/Dataset template: required (no template subject available)
  - `:preserve_metadata` - Whether to preserve metadata from template (default: true)
    - Graph → Graph: name, prefixes, base_iri
    - Dataset → Dataset: name

  ## Error

  Return `{:error, :no_subject}` when target is `:description` but no `:subject`
  option was provided and the template has no subject to inherit from (i.e.,
  template is a graph or dataset).
  """
  @spec derive(t, structure_type, keyword()) :: {:ok, t()} | {:error, derive_error()}
  def derive(template_data, target_type, opts \\ [])

  @doc """
  Returns the subject when the data represents a single-subject structure.

  Behavior by structure type:

  - `:description`: Returns the subject of the Description
  - `:graph`: Returns `nil` (multiple subjects)
  - `:dataset`: Returns `nil` (multiple subjects)
  """
  @spec subject(t) :: RDF.Resource.t() | nil
  def subject(data)

  @doc """
  Returns the graph name when the data represents a single-graph structure.

  Behavior by structure type:

  - `:description`: Returns `nil` (no graph context)
  - `:graph`: Returns the name of the graph (may be `nil` for unnamed graphs)
  - `:dataset`: Returns `nil` (multiple graphs)
  """
  @spec graph_name(t) :: RDF.Resource.t() | nil
  def graph_name(data)

  @doc """
  Reduces the RDF data structure into an element.

  This is the fundamental operation for traversing RDF data.
  """
  @spec reduce(t, acc, reducer) :: result
  def reduce(data, acc, fun)

  @doc """
  Gets the description of a specific subject.

  Returns `{:ok, description}` if the subject exists, `:error` otherwise.

  Behavior by structure type:

  - `:description`: Returns the Description when its subject matches
  - `:graph`: Returns the Description for the given subject
  - `:dataset`: Aggregates descriptions for the subject across all graphs
  """
  @spec description(t, RDF.Resource.coercible()) :: {:ok, t()} | :error
  def description(data, subject)

  @doc """
  Gets a specific graph from the data structure.

  Returns `{:ok, graph}` if the graph exists, `:error` otherwise.

  Behavior by structure type:

  - `:description`: Returns the description as unnamed graph when `graph_name` is `nil`
  - `:graph`: Returns the graph when its name matches
  - `:dataset`: Returns the graph for the given name
  """
  @spec graph(t, RDF.IRI.coercible() | nil) :: {:ok, t()} | :error
  def graph(data, graph_name)

  @doc """
  Returns all graph names in the data structure.

  It should return `{:ok, graph_names}` if you can collect all graph names
  in `data` in a faster way than fully traversing it.

  Otherwise, it should return `{:error, __MODULE__}` and a default algorithm
  built on top of `reduce/3` that runs in linear time will be used.
  """
  @spec graph_names(t) :: {:ok, [RDF.IRI.t() | nil]} | {:error, module}
  def graph_names(data)

  @doc """
  Returns all unique subjects in the data structure.

  It should return `{:ok, subjects}` if you can collect all subjects
  in `data` in a faster way than fully traversing it.

  Otherwise, it should return `{:error, __MODULE__}` and a default algorithm
  built on top of `reduce/3` that runs in linear time will be used.
  """
  @spec subjects(t) :: {:ok, [RDF.Resource.t()]} | {:error, module}
  def subjects(data)

  @doc """
  Counts statements (triples/quads).

  It should return `{:ok, count}` if you can count the number of statements
  in `data` in a faster way than fully traversing it.

  Otherwise, it should return `{:error, __MODULE__}` and a default algorithm
  built on top of `reduce/3` that runs in linear time will be used.
  """
  @spec statement_count(t) :: {:ok, non_neg_integer} | {:error, module}
  def statement_count(data)

  @doc """
  Counts unique subjects (descriptions).

  It should return `{:ok, count}` if you can count the number of subjects
  in `data` in a faster way than fully traversing it.

  Otherwise, it should return `{:error, __MODULE__}` and a default algorithm
  built on top of `reduce/3` that runs in linear time will be used.
  """
  @spec description_count(t) :: {:ok, non_neg_integer} | {:error, module}
  def description_count(data)

  @doc """
  Counts graphs.

  It should return `{:ok, count}` if you can count the number of graphs
  in `data` in a faster way than fully traversing it.

  Otherwise, it should return `{:error, __MODULE__}` and a default algorithm
  built on top of `reduce/3` that runs in linear time will be used.
  """
  @spec graph_count(t) :: {:ok, non_neg_integer} | {:error, module}
  def graph_count(data)

  @doc """
  Adds statements to the data structure.

  Enables efficient statement-based addition without double traversal,
  important for operations like `merge/2`.

  Returns `{:ok, updated_data}` on success.
  Returns `{:error, __MODULE__}` if not supported (falls back to generic implementation).

  Cross-type adaptation:
  - Quads → Graph: Graph component is removed (becomes triple)
  - Triples → Dataset: Go into default graph (nil)

  Statements are already coerced when this callback is invoked.
  """
  @spec add(t, RDF.Statement.t() | [RDF.Statement.t()]) :: {:ok, t} | {:error, module}
  def add(data, statements)

  @doc """
  Deletes statements from the data structure.

  Enables efficient statement-based deletion without double traversal.

  Returns `{:ok, updated_data}` on success.
  Returns `{:error, __MODULE__}` if not supported (falls back to generic implementation).

  Cross-type adaptation:
  - Quads → Graph: Graph component is removed (becomes triple)
  - Triples → Dataset: Go into default graph (nil)

  Statements are already coerced when this callback is invoked.
  """
  @spec delete(t, RDF.Statement.t() | [RDF.Statement.t()]) :: {:ok, t} | {:error, module}
  def delete(data, statements)
end

defimpl RDF.Data.Source, for: RDF.Description do
  alias RDF.Description

  def structure_type(_), do: :description

  def subject(%Description{subject: subject}), do: subject

  def graph_name(%Description{}), do: nil

  def derive(%Description{subject: subject}, :description, opts) do
    {:ok, Description.new(Keyword.get(opts, :subject, subject))}
  end

  def derive(%Description{}, :graph, opts) do
    {:ok, RDF.Graph.new(name: Keyword.get(opts, :name))}
  end

  def derive(%Description{}, :dataset, opts) do
    {:ok, RDF.Dataset.new(name: Keyword.get(opts, :name))}
  end

  def reduce(%Description{subject: subject, predications: predications}, acc, fun) do
    reduce_predications(:maps.iterator(predications), subject, acc, fun)
  end

  defp reduce_predications(_iterator, _subject, {:halt, acc}, _fun), do: {:halted, acc}

  defp reduce_predications(iterator, subject, {:suspend, acc}, fun) do
    {:suspended, acc, &reduce_predications(iterator, subject, &1, fun)}
  end

  defp reduce_predications(iterator, subject, {:cont, acc}, fun) do
    case :maps.next(iterator) do
      :none ->
        {:done, acc}

      {predicate, objects, next_iterator} ->
        reduce_objects(
          :maps.iterator(objects),
          subject,
          predicate,
          {:cont, acc},
          fun,
          next_iterator
        )
    end
  end

  defp reduce_objects(_obj_iter, _subject, _predicate, {:halt, acc}, _fun, _next_pred_iter) do
    {:halted, acc}
  end

  defp reduce_objects(obj_iter, subject, predicate, {:suspend, acc}, fun, next_pred_iter) do
    {:suspended, acc, &reduce_objects(obj_iter, subject, predicate, &1, fun, next_pred_iter)}
  end

  defp reduce_objects(obj_iter, subject, predicate, {:cont, acc}, fun, next_pred_iter) do
    case :maps.next(obj_iter) do
      :none ->
        reduce_predications(next_pred_iter, subject, {:cont, acc}, fun)

      {object, _, next_obj_iter} ->
        reduce_objects(
          next_obj_iter,
          subject,
          predicate,
          fun.({subject, predicate, object}, acc),
          fun,
          next_pred_iter
        )
    end
  end

  def description(%Description{predications: ps}, _) when map_size(ps) == 0, do: :error

  def description(%Description{} = desc, subject) do
    if desc.subject == RDF.coerce_subject(subject) do
      {:ok, desc}
    else
      :error
    end
  end

  def graph(%Description{} = desc, nil), do: {:ok, RDF.Graph.new(desc)}
  def graph(_, _graph_name), do: :error

  def graph_names(_desc), do: {:ok, [nil]}

  def subjects(%Description{predications: ps}) when map_size(ps) == 0, do: {:ok, []}
  def subjects(%Description{subject: subject}), do: {:ok, [subject]}

  def statement_count(%Description{} = desc), do: {:ok, Description.statement_count(desc)}

  def description_count(%Description{predications: ps}) when map_size(ps) == 0, do: {:ok, 0}
  def description_count(%Description{}), do: {:ok, 1}

  def graph_count(%Description{}), do: {:ok, 1}

  def add(%Description{} = desc, statements) do
    {:ok, Description.add(desc, statements)}
  end

  def delete(%Description{} = desc, statements) do
    {:ok, Description.delete(desc, statements, on_graph_mismatch: :skip)}
  end
end

defimpl RDF.Data.Source, for: RDF.Graph do
  alias RDF.Graph

  def structure_type(_), do: :graph

  def subject(%Graph{}), do: nil

  def graph_name(%Graph{name: name}), do: name

  def derive(%Graph{}, :description, opts) do
    case Keyword.fetch(opts, :subject) do
      {:ok, subject} -> {:ok, RDF.Description.new(subject)}
      :error -> {:error, :no_subject}
    end
  end

  def derive(%Graph{name: name, prefixes: prefixes, base_iri: base_iri}, :graph, opts) do
    if Keyword.get(opts, :preserve_metadata, true) do
      {:ok,
       Graph.new(name: Keyword.get(opts, :name, name), prefixes: prefixes, base_iri: base_iri)}
    else
      {:ok, Graph.new(name: Keyword.get(opts, :name))}
    end
  end

  def derive(%Graph{}, :dataset, _opts) do
    {:ok, RDF.Dataset.new()}
  end

  def reduce(%Graph{descriptions: descriptions}, acc, fun) do
    reduce_descriptions(:maps.iterator(descriptions), acc, fun)
  end

  defp reduce_descriptions(_iterator, {:halt, acc}, _fun), do: {:halted, acc}

  defp reduce_descriptions(iterator, {:suspend, acc}, fun) do
    {:suspended, acc, &reduce_descriptions(iterator, &1, fun)}
  end

  defp reduce_descriptions(iterator, {:cont, acc}, fun) do
    case :maps.next(iterator) do
      :none ->
        {:done, acc}

      {_subject, description, next_iterator} ->
        description
        |> RDF.Data.Source.reduce({:cont, acc}, fun)
        |> continue_after_description(next_iterator, fun)
    end
  end

  defp continue_after_description({:done, acc}, next_iterator, fun) do
    reduce_descriptions(next_iterator, {:cont, acc}, fun)
  end

  defp continue_after_description({:halted, acc}, _next_iterator, _fun) do
    {:halted, acc}
  end

  defp continue_after_description({:suspended, acc, continuation}, next_iterator, fun) do
    {:suspended, acc, &continue_after_description(continuation.(&1), next_iterator, fun)}
  end

  def description(%Graph{} = graph, subject) do
    Graph.fetch(graph, subject)
  end

  def graph(%Graph{name: name} = graph, graph_name) do
    if name == RDF.Statement.coerce_graph_name(graph_name) do
      {:ok, graph}
    else
      :error
    end
  end

  def graph_names(%Graph{name: name}), do: {:ok, [name]}

  def subjects(%Graph{descriptions: descriptions}), do: {:ok, Map.keys(descriptions)}

  def statement_count(%Graph{} = graph), do: {:ok, Graph.triple_count(graph)}

  def description_count(%Graph{} = graph), do: {:ok, Graph.subject_count(graph)}

  def graph_count(%Graph{}), do: {:ok, 1}

  def add(%Graph{} = graph, statements) do
    {:ok, Graph.add(graph, statements)}
  end

  def delete(%Graph{} = graph, statements) do
    {:ok, Graph.delete(graph, statements, on_graph_mismatch: :skip)}
  end
end

defimpl RDF.Data.Source, for: RDF.Dataset do
  alias RDF.Dataset

  def structure_type(_), do: :dataset

  def subject(%Dataset{}), do: nil

  def graph_name(%Dataset{}), do: nil

  def derive(%Dataset{}, :description, opts) do
    case Keyword.fetch(opts, :subject) do
      {:ok, subject} -> {:ok, RDF.Description.new(subject)}
      :error -> {:error, :no_subject}
    end
  end

  def derive(%Dataset{}, :graph, opts) do
    {:ok, RDF.Graph.new(name: Keyword.get(opts, :name))}
  end

  def derive(%Dataset{name: name}, :dataset, opts) do
    name = Keyword.get(opts, :name, if(Keyword.get(opts, :preserve_metadata, true), do: name))

    {:ok, Dataset.new(name: name)}
  end

  def reduce(%Dataset{graphs: graphs}, acc, fun) do
    reduce_graphs(:maps.iterator(graphs), acc, fun)
  end

  defp reduce_graphs(_iterator, {:halt, acc}, _fun) do
    {:halted, acc}
  end

  defp reduce_graphs(iterator, {:suspend, acc}, fun) do
    {:suspended, acc, &reduce_graphs(iterator, &1, fun)}
  end

  defp reduce_graphs(iterator, {:cont, acc}, fun) do
    case :maps.next(iterator) do
      :none ->
        {:done, acc}

      {graph_name, graph, next_iterator} ->
        quad_fun = fn {s, p, o}, acc -> fun.({s, p, o, graph_name}, acc) end

        graph
        |> RDF.Data.Source.reduce({:cont, acc}, quad_fun)
        |> continue_after_graph(next_iterator, fun)
    end
  end

  defp continue_after_graph({:done, acc}, next_iterator, fun) do
    reduce_graphs(next_iterator, {:cont, acc}, fun)
  end

  defp continue_after_graph({:halted, acc}, _next_iterator, _fun) do
    {:halted, acc}
  end

  defp continue_after_graph({:suspended, acc, continuation}, next_iterator, fun) do
    {:suspended, acc, &continue_after_graph(continuation.(&1), next_iterator, fun)}
  end

  def description(%Dataset{} = dataset, subject) do
    description =
      dataset
      |> Dataset.graphs()
      |> Enum.reduce(nil, fn graph, acc ->
        case RDF.Data.Source.description(graph, subject) do
          {:ok, desc} when is_nil(acc) -> desc
          {:ok, desc} -> RDF.Description.add(acc, desc)
          :error -> acc
        end
      end)

    if description, do: {:ok, description}, else: :error
  end

  def graph(%Dataset{} = dataset, graph_name) do
    if graph = Dataset.graph(dataset, graph_name) do
      {:ok, graph}
    else
      :error
    end
  end

  def graph_names(%Dataset{graphs: graphs}) do
    {:ok, Map.keys(graphs)}
  end

  def subjects(%Dataset{} = dataset), do: {:ok, Dataset.subjects(dataset) |> MapSet.to_list()}

  def statement_count(%Dataset{} = dataset), do: {:ok, Dataset.statement_count(dataset)}

  def description_count(%Dataset{} = dataset) do
    {:ok, dataset |> Dataset.subjects() |> MapSet.size()}
  end

  def graph_count(%Dataset{graphs: graphs}), do: {:ok, map_size(graphs)}

  def add(%Dataset{} = dataset, statements) do
    {:ok, Dataset.add(dataset, statements)}
  end

  def delete(%Dataset{} = dataset, statements) do
    {:ok, Dataset.delete(dataset, statements)}
  end
end
