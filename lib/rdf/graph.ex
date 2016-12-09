defmodule RDF.Graph do
  @moduledoc """
  Defines a RDF Graph.

  A `RDF.Graph` represents a set of `RDF.Description`s.

  Named vs. unnamed graphs ...
  """
  defstruct name: nil, descriptions: %{}

  @behaviour Access

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
  def new({_, _, _} = triple),
    do: new |> add(triple)

  @doc """
  Creates an unnamed `RDF.Graph` with initial triples.
  """
  def new(triples) when is_list(triples),
    do: new |> add(triples)

  @doc """
  Creates an unnamed `RDF.Graph` with an `RDF.Description`.
  """
  def new(%RDF.Description{} = description),
    do: new |> add(description)

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
  Creates a named `RDF.Graph` with an `RDF.Description`.
  """
  def new(name, %RDF.Description{} = description),
    do: new(name) |> add(description)

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

  def add(%RDF.Graph{name: name, descriptions: descriptions},
          %Description{subject: subject} = description) do
    description = if existing_description = descriptions[subject],
      do:   Description.add(existing_description, description),
      else: description
    %RDF.Graph{name: name,
               descriptions: Map.put(descriptions, subject, description)}
  end


  @doc """
  Puts statements to a `RDF.Graph`, overwriting all statements with the same subject and predicate.

  # Examples

      iex> RDF.Graph.new(EX.S, EX.P, EX.O1) |> RDF.Graph.put(EX.S, EX.P, EX.O2)
      RDF.Graph.new(EX.S, EX.P, EX.O2)
      iex> RDF.Graph.new(EX.S, EX.P1, EX.O1) |> RDF.Graph.put(EX.S, EX.P2, EX.O2)
      RDF.Graph.new([{EX.S, EX.P1, EX.O1}, {EX.S, EX.P2, EX.O2}])
  """
  def put(%RDF.Graph{name: name, descriptions: descriptions},
          subject, predicate, objects) do
    with triple_subject = Triple.convert_subject(subject) do
      new_description = case descriptions[triple_subject] do
        desc = %Description{} -> Description.put(desc, predicate, objects)
        nil -> Description.new(triple_subject, predicate, objects)
      end
      %RDF.Graph{name: name,
          descriptions: Map.put(descriptions, triple_subject, new_description)}
    end
  end

  @doc """
  Adds statements to a `RDF.Graph` and overwrites all existing statements with the same subjects and predicates.

  # Examples

      iex> RDF.Graph.new([{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2}]) |>
      ...>   RDF.Graph.put([{EX.S1, EX.P2, EX.O3}, {EX.S2, EX.P2, EX.O3}])
      RDF.Graph.new([{EX.S1, EX.P1, EX.O1}, {EX.S1, EX.P2, EX.O3}, {EX.S2, EX.P2, EX.O3}])
  """
  def put(graph, statements)

  def put(graph = %RDF.Graph{}, {subject, predicate, object}),
    do: put(graph, subject, predicate, object)

  def put(%RDF.Graph{name: name, descriptions: descriptions},
          %Description{subject: subject} = description) do
    description = if existing_description = descriptions[subject],
      do:   Description.put(existing_description, description),
      else: description
    %RDF.Graph{name: name,
               descriptions: Map.put(descriptions, subject, description)}
  end

  def put(graph = %RDF.Graph{}, statements) when is_map(statements) do
    Enum.reduce statements, graph, fn ({subject, predications}, graph) ->
      put(graph, subject, predications)
    end
  end

  def put(graph = %RDF.Graph{}, statements) when is_list(statements) do
    put(graph, Enum.group_by(statements, &(elem(&1, 0)), fn {_, p, o} -> {p, o} end))
  end

  def put(%RDF.Graph{name: name, descriptions: descriptions}, subject, predications)
        when is_list(predications) do
    with triple_subject = Triple.convert_subject(subject),
         description = Map.get(descriptions, triple_subject)
                       || Description.new(triple_subject) do
      new_descriptions = descriptions
        |> Map.put(triple_subject, Description.put(description, predications))
      %RDF.Graph{name: name, descriptions: new_descriptions}
    end
  end

  def put(graph, subject, predications = {_predicate, _objects}),
    do: put(graph, subject, [predications])


  @doc """
  Fetches the description of the given subject.

  When the subject can not be found `:error` is returned.

  # Examples

      iex> RDF.Graph.new([{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2}]) |>
      ...>   RDF.Graph.fetch(EX.S1)
      {:ok, RDF.Description.new({EX.S1, EX.P1, EX.O1})}
      iex> RDF.Graph.fetch(RDF.Graph.new, EX.foo)
      :error
  """
  def fetch(%RDF.Graph{descriptions: descriptions}, subject) do
    Access.fetch(descriptions, Triple.convert_subject(subject))
  end

  @doc """
  Gets the description of the given subject.

  When the subject can not be found the optionally given default value or `nil` is returned.

  # Examples

      iex> RDF.Graph.new([{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2}]) |>
      ...>   RDF.Graph.get(EX.S1)
      RDF.Description.new({EX.S1, EX.P1, EX.O1})
      iex> RDF.Graph.get(RDF.Graph.new, EX.Foo)
      nil
      iex> RDF.Graph.get(RDF.Graph.new, EX.Foo, :bar)
      :bar
  """
  def get(graph = %RDF.Graph{}, subject, default \\ nil) do
    case fetch(graph, subject) do
      {:ok, value} -> value
      :error       -> default
    end
  end

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

  # Examples

      iex> RDF.Graph.new({EX.S, EX.P, EX.O}) |>
      ...>   RDF.Graph.get_and_update(EX.S, fn current_description ->
      ...>     {current_description, {EX.P, EX.NEW}}
      ...>   end)
      {RDF.Description.new(EX.S, EX.P, EX.O), RDF.Graph.new(EX.S, EX.P, EX.NEW)}
  """
  def get_and_update(graph = %RDF.Graph{}, subject, fun) do
    with triple_subject = Triple.convert_subject(subject) do
      case fun.(get(graph, triple_subject)) do
        {old_description, new_description} ->
          {old_description, put(graph, triple_subject, new_description)}
        :pop -> pop(graph, triple_subject)
      end
    end
  end

  @doc """
  Pops the description of the given subject.

  When the subject can not be found the optionally given default value or `nil` is returned.

  # Examples

      iex> RDF.Graph.new([{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2}]) |>
      ...>   RDF.Graph.pop(EX.S1)
      {RDF.Description.new({EX.S1, EX.P1, EX.O1}), RDF.Graph.new({EX.S2, EX.P2, EX.O2})}
      iex> RDF.Graph.pop(RDF.Graph.new({EX.S, EX.P, EX.O}), EX.Missing)
      {nil, RDF.Graph.new({EX.S, EX.P, EX.O})}
  """
  def pop(graph = %RDF.Graph{name: name, descriptions: descriptions}, subject) do
    case Access.pop(descriptions, Triple.convert_subject(subject)) do
      {nil, _} ->
        {nil, graph}
      {description, new_descriptions} ->
        {description, %RDF.Graph{name: name, descriptions: new_descriptions}}
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

  def triples(graph = %RDF.Graph{}), do: Enum.to_list(graph)

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
