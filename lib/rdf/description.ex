defmodule RDF.Description do
  @moduledoc """
  Defines a RDF Description.

  A `RDF.Description` represents a set of `RDF.Triple`s about a subject.
  """
  defstruct subject: nil, predications: %{}

  alias RDF.Triple

  @type t :: module

  @doc """
  Creates a new `RDF.Description` about the given subject.

  When given a triple, it must contain the subject.
  When given a list of statements, the first one must contain a subject.
  """
  @spec new(Triple.convertible_subject) :: RDF.Description.t
  def new(subject)

  def new({subject, predicate, object}),
    do: new(subject) |> add({predicate, object})
  def new([statement | more_statements]),
    do: new(statement) |> add(more_statements)
  def new(subject),
    do: %RDF.Description{subject: Triple.convert_subject(subject)}

  @doc """
  Adds statements to a `RDF.Description`.
  """
  def add(description, statements)

  def add(desc = %RDF.Description{}, {predicate, object}) do
    with triple_predicate = Triple.convert_predicate(predicate),
         triple_object = Triple.convert_object(object),
         predications = Map.update(desc.predications,
           triple_predicate, %{triple_object => nil}, fn objects ->
             Map.put_new(objects, triple_object, nil) end) do
      %RDF.Description{subject: desc.subject, predications: predications}
    end
  end

  def add(desc = %RDF.Description{}, {subject, predicate, object}) do
    if RDF.uri(subject) == desc.subject,
      do:   add(desc, {predicate, object}),
      else: desc
  end

  def add(desc, statements) when is_list(statements) do
    Enum.reduce statements, desc, fn (statement, desc) ->
      add(desc, statement)
    end
  end

  @doc """
  Returns the number of statements of a `RDF.Description`.
  """
  def count(%RDF.Description{predications: predications}) do
    Enum.reduce predications, 0,
      fn ({_, objects}, count) -> count + Enum.count(objects) end
  end


  @doc """
  The set of all properties used in the predicates within a `RDF.Description`.

  # Examples

      iex> RDF.Description.new([
      ...>   {EX.S1, EX.p1, EX.O1},
      ...>          {EX.p2, EX.O2},
      ...>          {EX.p2, EX.O3}]) |>
      ...>   RDF.Description.predicates
      MapSet.new([EX.p1, EX.p2])
  """
  def predicates(%RDF.Description{predications: predications}),
    do: predications |> Map.keys |> MapSet.new

  @doc """
  The set of all resources used in the objects within a `RDF.Description`.

  Note: This function does collect only URIs and BlankNodes, not Literals.

  # Examples

      iex> RDF.Description.new([
      ...>   {EX.S1, EX.p1, EX.O1},
      ...>          {EX.p2, EX.O2},
      ...>          {EX.p3, EX.O2},
      ...>          {EX.p4, RDF.bnode(:bnode)},
      ...>          {EX.p3, "foo"}
      ...> ]) |> RDF.Description.objects
      MapSet.new([RDF.uri(EX.O1), RDF.uri(EX.O2), RDF.bnode(:bnode)])
  """
  def objects(%RDF.Description{predications: predications}) do
    Enum.reduce predications, MapSet.new, fn ({_, objects}, acc) ->
      objects
      |> Map.keys
      |> Enum.filter(&RDF.resource?/1)
      |> MapSet.new
      |> MapSet.union(acc)
    end
  end

  @doc """
  The set of all resources used within a `RDF.Description`.

  # Examples

      iex> RDF.Description.new([
      ...>   {EX.S1, EX.p1, EX.O1},
      ...>          {EX.p2, EX.O2},
      ...>          {EX.p1, EX.O2},
      ...>          {EX.p2, RDF.bnode(:bnode)},
      ...>          {EX.p3, "foo"}
      ...> ]) |> RDF.Description.resources
      MapSet.new([RDF.uri(EX.O1), RDF.uri(EX.O2), RDF.bnode(:bnode), EX.p1, EX.p2, EX.p3])
  """
  def resources(description) do
    description
    |> objects
    |> MapSet.union(predicates(description))
  end


  @doc """
  Checks if the given statement exists within a `RDF.Description`.
  """
  def include?(description, statement)

  def include?(%RDF.Description{predications: predications},
                {predicate, object}) do
    with triple_predicate = Triple.convert_predicate(predicate),
         triple_object    = Triple.convert_object(object) do
      predications
      |> Map.get(triple_predicate, %{})
      |> Map.has_key?(triple_object)
    end
  end

  def include?(desc = %RDF.Description{subject: desc_subject},
              {subject, predicate, object}) do
    Triple.convert_subject(subject) == desc_subject &&
      include?(desc, {predicate, object})
  end

  def include?(%RDF.Description{}, _), do: false


  # TODO: Can/should we isolate and move the Enumerable specific part to the Enumerable implementation?

  def reduce(%RDF.Description{predications: predications}, {:cont, acc}, _fun)
    when map_size(predications) == 0, do: {:done, acc}

  def reduce(description = %RDF.Description{}, {:cont, acc}, fun) do
    {triple, rest} = RDF.Description.pop(description)
    reduce(rest, fun.(triple, acc), fun)
  end

  def reduce(_,       {:halt, acc}, _fun), do: {:halted, acc}
  def reduce(description = %RDF.Description{}, {:suspend, acc}, fun) do
    {:suspended, acc, &reduce(description, &1, fun)}
  end


  def pop(description = %RDF.Description{predications: predications})
    when predications == %{}, do: {nil, description}

  def pop(%RDF.Description{subject: subject, predications: predications}) do
    # TODO: Find a faster way ...
    predicate = List.first(Map.keys(predications))
    [{object, _}] = Enum.take(objects = predications[predicate], 1)

    popped = if Enum.count(objects) == 1,
      do:   elem(Map.pop(predications, predicate), 1),
      else: elem(pop_in(predications, [predicate, object]), 1)

    {{subject, predicate, object},
       %RDF.Description{subject: subject, predications: popped}}
  end
end

defimpl Enumerable, for: RDF.Description do
  def reduce(desc, acc, fun), do: RDF.Description.reduce(desc, acc, fun)
  def member?(desc, triple),  do: {:ok, RDF.Description.include?(desc, triple)}
  def count(desc),            do: {:ok, RDF.Description.count(desc)}
end
