defmodule RDF.Graph do
  @moduledoc """
  A set of RDF triples with an optional name.

  `RDF.Graph` implements:

  - Elixir's `Access` behaviour
  - Elixir's `Enumerable` protocol
  - Elixir's `Inspect` protocol
  - the `RDF.Data` protocol

  """

  defstruct name: nil, descriptions: %{}

  @behaviour Access

  alias RDF.Description
  import RDF.Statement

  @type t :: module

  @doc """
  Creates an empty unnamed `RDF.Graph`.
  """
  def new,
    do: %RDF.Graph{}

  @doc """
  Creates an unnamed `RDF.Graph` with an initial triple.
  """
  def new({_, _, _} = triple),
    do: new() |> add(triple)

  @doc """
  Creates an unnamed `RDF.Graph` with initial triples.
  """
  def new(triples) when is_list(triples),
    do: new() |> add(triples)

  @doc """
  Creates an unnamed `RDF.Graph` with a `RDF.Description`.
  """
  def new(%RDF.Description{} = description),
    do: new() |> add(description)

  @doc """
  Creates an unnamed `RDF.Graph` from another `RDF.Graph`.
  """
  def new(%RDF.Graph{descriptions: descriptions}),
    do: %RDF.Graph{descriptions: descriptions}

  @doc """
  Creates an empty unnamed `RDF.Graph`.
  """
  def new(nil),
    do: new()

  @doc """
  Creates an empty named `RDF.Graph`.
  """
  def new(name),
    do: %RDF.Graph{name: coerce_graph_name(name)}

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
  Creates a named `RDF.Graph` with a `RDF.Description`.
  """
  def new(name, %RDF.Description{} = description),
    do: new(name) |> add(description)

  @doc """
  Creates a named `RDF.Graph` from another `RDF.Graph`.
  """
  def new(name, %RDF.Graph{descriptions: descriptions}),
    do: %RDF.Graph{new(name) | descriptions: descriptions}

  @doc """
  Creates an unnamed `RDF.Graph` with initial triples.
  """
  def new(subject, predicate, objects),
    do: new() |> add(subject, predicate, objects)

  @doc """
  Creates a named `RDF.Graph` with initial triples.
  """
  def new(name, subject, predicate, objects),
    do: new(name) |> add(subject, predicate, objects)


  @doc """
  Adds triples to a `RDF.Graph`.
  """
  def add(%RDF.Graph{} = graph, subject, predicate, objects),
    do: add(graph, {subject, predicate, objects})


  @doc """
  Adds triples to a `RDF.Graph`.

  Note: When the statements to be added are given as another `RDF.Graph`,
  the graph name must not match graph name of the graph to which the statements
  are added. As opposed to that `RDF.Data.merge/2` will produce a `RDF.Dataset`
  containing both graphs.
  """
  def add(graph, triples)

  def add(%RDF.Graph{} = graph, {subject, _, _} = statement),
    do: do_add(graph, coerce_subject(subject), statement)

  def add(graph, {subject, predicate, object, _}),
    do: add(graph, {subject, predicate, object})

  def add(graph, triples) when is_list(triples) do
    Enum.reduce triples, graph, fn (triple, graph) ->
      add(graph, triple)
    end
  end

  def add(%RDF.Graph{} = graph, %Description{subject: subject} = description),
    do: do_add(graph, subject, description)

  def add(graph, %RDF.Graph{descriptions: descriptions}) do
    Enum.reduce descriptions, graph, fn ({_, description}, graph) ->
      add(graph, description)
    end
  end

  defp do_add(%RDF.Graph{name: name, descriptions: descriptions},
              subject, statements) do
    %RDF.Graph{name: name,
      descriptions:
        Map.update(descriptions, subject, Description.new(statements),
          fn description ->
            Description.add(description, statements)
          end)
    }
  end


  @doc """
  Adds statements to a `RDF.Graph` and overwrites all existing statements with the same subjects and predicates.

  ## Examples

      iex> RDF.Graph.new([{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2}]) |>
      ...>   RDF.Graph.put([{EX.S1, EX.P2, EX.O3}, {EX.S2, EX.P2, EX.O3}])
      RDF.Graph.new([{EX.S1, EX.P1, EX.O1}, {EX.S1, EX.P2, EX.O3}, {EX.S2, EX.P2, EX.O3}])
  """
  def put(graph, statements)

  def put(%RDF.Graph{} = graph, {subject, _, _} = statement),
    do: do_put(graph, coerce_subject(subject), statement)

  def put(graph, {subject, predicate, object, _}),
    do: put(graph, {subject, predicate, object})

  def put(%RDF.Graph{} = graph, %Description{subject: subject} = description),
    do: do_put(graph, subject, description)

  def put(graph, %RDF.Graph{descriptions: descriptions}) do
    Enum.reduce descriptions, graph, fn ({_, description}, graph) ->
      put(graph, description)
    end
  end

  def put(%RDF.Graph{} = graph, statements) when is_map(statements) do
    Enum.reduce statements, graph, fn ({subject, predications}, graph) ->
      put(graph, subject, predications)
    end
  end

  def put(%RDF.Graph{} = graph, statements) when is_list(statements) do
    put(graph, Enum.group_by(statements, &(elem(&1, 0)), fn {_, p, o} -> {p, o} end))
  end

  @doc """
  Add statements to a `RDF.Graph`, overwriting all statements with the same subject and predicate.
  """
  def put(graph, subject, predications)

  def put(%RDF.Graph{name: name, descriptions: descriptions}, subject, predications)
        when is_list(predications) do
    with subject = coerce_subject(subject) do
      # TODO: Can we reduce this case also to do_put somehow? Only the initializer of Map.update differs ...
      %RDF.Graph{name: name,
        descriptions:
          Map.update(descriptions, subject, Description.new(subject, predications),
            fn current ->
              Description.put(current, predications)
            end)
      }
    end
  end

  def put(graph, subject, {_predicate, _objects} = predications),
    do: put(graph, subject, [predications])

  defp do_put(%RDF.Graph{name: name, descriptions: descriptions},
          subject, statements) do
    %RDF.Graph{name: name,
      descriptions:
        Map.update(descriptions, subject, Description.new(statements),
          fn current ->
            Description.put(current, statements)
          end)
    }
  end

  @doc """
  Add statements to a `RDF.Graph`, overwriting all statements with the same subject and predicate.

  ## Examples

      iex> RDF.Graph.new(EX.S, EX.P, EX.O1) |> RDF.Graph.put(EX.S, EX.P, EX.O2)
      RDF.Graph.new(EX.S, EX.P, EX.O2)
      iex> RDF.Graph.new(EX.S, EX.P1, EX.O1) |> RDF.Graph.put(EX.S, EX.P2, EX.O2)
      RDF.Graph.new([{EX.S, EX.P1, EX.O1}, {EX.S, EX.P2, EX.O2}])
  """
  def put(%RDF.Graph{} = graph, subject, predicate, objects),
    do: put(graph, {subject, predicate, objects})


  @doc """
  Deletes statements from a `RDF.Graph`.
  """
  def delete(graph, subject, predicate, object),
    do: delete(graph, {subject, predicate, object})

  @doc """
  Deletes statements from a `RDF.Graph`.

  Note: When the statements to be deleted are given as another `RDF.Graph`,
  the graph name must not match graph name of the graph from which the statements
  are deleted. If you want to delete only graphs with matching names, you can
  use `RDF.Data.delete/2`.
  """
  def delete(graph, triples)

  def delete(%RDF.Graph{} = graph, {subject, _, _} = triple),
    do: do_delete(graph, coerce_subject(subject), triple)

  def delete(graph, {subject, predicate, object, _}),
    do: delete(graph, {subject, predicate, object})

  def delete(%RDF.Graph{} = graph, triples) when is_list(triples) do
    Enum.reduce triples, graph, fn (triple, graph) ->
      delete(graph, triple)
    end
  end

  def delete(%RDF.Graph{} = graph, %Description{subject: subject} = description),
    do: do_delete(graph, subject, description)

  def delete(%RDF.Graph{} = graph, %RDF.Graph{descriptions: descriptions}) do
    Enum.reduce descriptions, graph, fn ({_, description}, graph) ->
      delete(graph, description)
    end
  end

  defp do_delete(%RDF.Graph{name: name, descriptions: descriptions} = graph,
                 subject, statements) do
    with description when not is_nil(description) <- descriptions[subject],
         new_description = Description.delete(description, statements)
    do
      %RDF.Graph{name: name,
        descriptions:
          if Enum.empty?(new_description) do
            Map.delete(descriptions, subject)
          else
            Map.put(descriptions, subject, new_description)
          end
      }
    else
      nil -> graph
    end
  end


  @doc """
  Deletes all statements with the given subjects.
  """
  def delete_subjects(graph, subjects)

  def delete_subjects(%RDF.Graph{} = graph, subjects) when is_list(subjects) do
    Enum.reduce subjects, graph, fn (subject, graph) ->
      delete_subjects(graph, subject)
    end
  end

  def delete_subjects(%RDF.Graph{name: name, descriptions: descriptions}, subject) do
    with subject = coerce_subject(subject) do
      %RDF.Graph{name: name, descriptions: Map.delete(descriptions, subject)}
    end
  end


  @doc """
  Fetches the description of the given subject.

  When the subject can not be found `:error` is returned.

  ## Examples

      iex> RDF.Graph.new([{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2}]) |>
      ...>   RDF.Graph.fetch(EX.S1)
      {:ok, RDF.Description.new({EX.S1, EX.P1, EX.O1})}
      iex> RDF.Graph.fetch(RDF.Graph.new, EX.foo)
      :error
  """
  def fetch(%RDF.Graph{descriptions: descriptions}, subject) do
    Access.fetch(descriptions, coerce_subject(subject))
  end

  @doc """
  Gets the description of the given subject.

  When the subject can not be found the optionally given default value or `nil` is returned.

  ## Examples

      iex> RDF.Graph.new([{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2}]) |>
      ...>   RDF.Graph.get(EX.S1)
      RDF.Description.new({EX.S1, EX.P1, EX.O1})
      iex> RDF.Graph.get(RDF.Graph.new, EX.Foo)
      nil
      iex> RDF.Graph.get(RDF.Graph.new, EX.Foo, :bar)
      :bar
  """
  def get(%RDF.Graph{} = graph, subject, default \\ nil) do
    case fetch(graph, subject) do
      {:ok, value} -> value
      :error       -> default
    end
  end

  @doc """
  The `RDF.Description` of the given subject.
  """
  def description(%RDF.Graph{descriptions: descriptions}, subject),
    do: Map.get(descriptions, coerce_subject(subject))

  @doc """
  All `RDF.Description`s within a `RDF.Graph`.
  """
  def descriptions(%RDF.Graph{descriptions: descriptions}),
    do: Map.values(descriptions)


  @doc """
  Gets and updates the description of the given subject, in a single pass.

  Invokes the passed function on the `RDF.Description` of the given subject;
  this function should return either `{description_to_return, new_description}` or `:pop`.

  If the passed function returns `{description_to_return, new_description}`, the
  return value of `get_and_update` is `{description_to_return, new_graph}` where
  `new_graph` is the input `Graph` updated with `new_description` for
  the given subject.

  If the passed function returns `:pop` the description for the given subject is
  removed and a `{removed_description, new_graph}` tuple gets returned.

  ## Examples

      iex> RDF.Graph.new({EX.S, EX.P, EX.O}) |>
      ...>   RDF.Graph.get_and_update(EX.S, fn current_description ->
      ...>     {current_description, {EX.P, EX.NEW}}
      ...>   end)
      {RDF.Description.new(EX.S, EX.P, EX.O), RDF.Graph.new(EX.S, EX.P, EX.NEW)}
  """
  def get_and_update(%RDF.Graph{} = graph, subject, fun) do
    with subject = coerce_subject(subject) do
      case fun.(get(graph, subject)) do
        {old_description, new_description} ->
          {old_description, put(graph, subject, new_description)}
        :pop ->
          pop(graph, subject)
        other ->
          raise "the given function must return a two-element tuple or :pop, got: #{inspect(other)}"
      end
    end
  end


  @doc """
  Pops an arbitrary triple from a `RDF.Graph`.
  """
  def pop(graph)

  def pop(%RDF.Graph{descriptions: descriptions} = graph)
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

  @doc """
  Pops the description of the given subject.

  When the subject can not be found the optionally given default value or `nil` is returned.

  ## Examples

      iex> RDF.Graph.new([{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2}]) |>
      ...>   RDF.Graph.pop(EX.S1)
      {RDF.Description.new({EX.S1, EX.P1, EX.O1}), RDF.Graph.new({EX.S2, EX.P2, EX.O2})}
      iex> RDF.Graph.pop(RDF.Graph.new({EX.S, EX.P, EX.O}), EX.Missing)
      {nil, RDF.Graph.new({EX.S, EX.P, EX.O})}
  """
  def pop(%RDF.Graph{name: name, descriptions: descriptions} = graph, subject) do
    case Access.pop(descriptions, coerce_subject(subject)) do
      {nil, _} ->
        {nil, graph}
      {description, new_descriptions} ->
        {description, %RDF.Graph{name: name, descriptions: new_descriptions}}
    end
  end


  @doc """
  The number of subjects within a `RDF.Graph`.

  ## Examples

      iex> RDF.Graph.new([
      ...>   {EX.S1, EX.p1, EX.O1},
      ...>   {EX.S2, EX.p2, EX.O2},
      ...>   {EX.S1, EX.p2, EX.O3}]) |>
      ...>   RDF.Graph.subject_count
      2
  """
  def subject_count(%RDF.Graph{descriptions: descriptions}),
    do: Enum.count(descriptions)

  @doc """
  The number of statements within a `RDF.Graph`.

  ## Examples

      iex> RDF.Graph.new([
      ...>   {EX.S1, EX.p1, EX.O1},
      ...>   {EX.S2, EX.p2, EX.O2},
      ...>   {EX.S1, EX.p2, EX.O3}]) |>
      ...>   RDF.Graph.triple_count
      3
  """
  def triple_count(%RDF.Graph{descriptions: descriptions}) do
    Enum.reduce descriptions, 0, fn ({_subject, description}, count) ->
      count + Description.count(description)
    end
  end

  @doc """
  The set of all subjects used in the statements within a `RDF.Graph`.

  ## Examples

      iex> RDF.Graph.new([
      ...>   {EX.S1, EX.p1, EX.O1},
      ...>   {EX.S2, EX.p2, EX.O2},
      ...>   {EX.S1, EX.p2, EX.O3}]) |>
      ...>   RDF.Graph.subjects
      MapSet.new([RDF.iri(EX.S1), RDF.iri(EX.S2)])
  """
  def subjects(%RDF.Graph{descriptions: descriptions}),
    do: descriptions |> Map.keys |> MapSet.new

  @doc """
  The set of all properties used in the predicates of the statements within a `RDF.Graph`.

  ## Examples

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

  Note: This function does collect only IRIs and BlankNodes, not Literals.

  ## Examples

      iex> RDF.Graph.new([
      ...>   {EX.S1, EX.p1, EX.O1},
      ...>   {EX.S2, EX.p2, EX.O2},
      ...>   {EX.S3, EX.p1, EX.O2},
      ...>   {EX.S4, EX.p2, RDF.bnode(:bnode)},
      ...>   {EX.S5, EX.p3, "foo"}
      ...> ]) |> RDF.Graph.objects
      MapSet.new([RDF.iri(EX.O1), RDF.iri(EX.O2), RDF.bnode(:bnode)])
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

  ## Examples

    iex> RDF.Graph.new([
    ...>   {EX.S1, EX.p1, EX.O1},
    ...>   {EX.S2, EX.p1, EX.O2},
    ...>   {EX.S2, EX.p2, RDF.bnode(:bnode)},
    ...>   {EX.S3, EX.p1, "foo"}
    ...> ]) |> RDF.Graph.resources
    MapSet.new([RDF.iri(EX.S1), RDF.iri(EX.S2), RDF.iri(EX.S3),
      RDF.iri(EX.O1), RDF.iri(EX.O2), RDF.bnode(:bnode), EX.p1, EX.p2])
  """
  def resources(graph = %RDF.Graph{descriptions: descriptions}) do
    Enum.reduce(descriptions, MapSet.new, fn ({_, description}, acc) ->
      description
      |> Description.resources
      |> MapSet.union(acc)
    end) |> MapSet.union(subjects(graph))
  end

  @doc """
  The list of all statements within a `RDF.Graph`.

  ## Examples

        iex> RDF.Graph.new([
        ...>   {EX.S1, EX.p1, EX.O1},
        ...>   {EX.S2, EX.p2, EX.O2},
        ...>   {EX.S1, EX.p2, EX.O3}
        ...> ]) |> RDF.Graph.triples
        [{RDF.iri(EX.S1), RDF.iri(EX.p1), RDF.iri(EX.O1)},
         {RDF.iri(EX.S1), RDF.iri(EX.p2), RDF.iri(EX.O3)},
         {RDF.iri(EX.S2), RDF.iri(EX.p2), RDF.iri(EX.O2)}]
  """
  def triples(graph = %RDF.Graph{}), do: Enum.to_list(graph)

  defdelegate statements(graph), to: RDF.Graph, as: :triples


  @doc """
  Checks if the given statement exists within a `RDF.Graph`.
  """
  def include?(%RDF.Graph{descriptions: descriptions},
              triple = {subject, _, _}) do
    with subject = coerce_subject(subject),
         %Description{} <- description = descriptions[subject] do
      Description.include?(description, triple)
    else
      _ -> false
    end
  end

  @doc """
  Checks if a `RDF.Graph` contains statements about the given resource.

  ## Examples

        iex> RDF.Graph.new([{EX.S1, EX.p1, EX.O1}]) |> RDF.Graph.describes?(EX.S1)
        true
        iex> RDF.Graph.new([{EX.S1, EX.p1, EX.O1}]) |> RDF.Graph.describes?(EX.S2)
        false
  """
  def describes?(%RDF.Graph{descriptions: descriptions}, subject) do
    with subject = coerce_subject(subject) do
      Map.has_key?(descriptions, subject)
    end
  end


  defimpl Enumerable do
    def member?(graph, triple),  do: {:ok, RDF.Graph.include?(graph, triple)}
    def count(graph),            do: {:ok, RDF.Graph.triple_count(graph)}
    def slice(_graph),           do: {:error, __MODULE__}

    def reduce(%RDF.Graph{descriptions: descriptions}, {:cont, acc}, _fun)
      when map_size(descriptions) == 0, do: {:done, acc}

    def reduce(%RDF.Graph{} = graph, {:cont, acc}, fun) do
      {triple, rest} = RDF.Graph.pop(graph)
      reduce(rest, fun.(triple, acc), fun)
    end

    def reduce(_,       {:halt, acc}, _fun), do: {:halted, acc}
    def reduce(%RDF.Graph{} = graph, {:suspend, acc}, fun) do
      {:suspended, acc, &reduce(graph, &1, fun)}
    end

  end


  defimpl Collectable do
    def into(original) do
      collector_fun = fn
        graph, {:cont, list} when is_list(list)
                             -> RDF.Graph.add(graph, List.to_tuple(list))
        graph, {:cont, elem} -> RDF.Graph.add(graph, elem)
        graph, :done         -> graph
        _graph, :halt        -> :ok
      end

      {original, collector_fun}
    end
  end

end

