defmodule RDF.Graph do
  @moduledoc """
  Defines a RDF Graph.

  A `RDF.Graph` represents a set of `RDF.Description`s.

  Named vs. unnamed graphs ...
  """
  defstruct name: nil, descriptions: %{}

  alias RDF.{Description, Triple}

  @type t :: module

  @doc """
  Creates a new `RDF.Graph`.
  """
  def new, do: %RDF.Graph{}
  def new(statement = {_, _, _}), do: new |> add(statement)
  def new([statement | rest]), do: new(statement) |> add(rest)
  def new(name), do: %RDF.Graph{name: RDF.uri(name)}
  def new(name, statement = {_, _, _}), do: new(name) |> add(statement)
  def new(name, [statement | rest]), do: new(name, statement) |> add(rest)


  def add(%RDF.Graph{name: name, descriptions: descriptions},
          {subject, predicate, object}) do
    with triple_subject = Triple.convert_subject(subject),
         updated_descriptions = Map.update(descriptions, triple_subject,
           Description.new({triple_subject, predicate, object}), fn description ->
             description |> Description.add({predicate, object})
           end) do
      %RDF.Graph{name: name, descriptions: updated_descriptions}
    end
  end

  def add(graph, statements) when is_list(statements) do
    Enum.reduce statements, graph, fn (statement, graph) ->
      RDF.Graph.add(graph, statement)
    end
  end

  def subject_count(graph), do: Enum.count(graph.descriptions)

  def triple_count(%RDF.Graph{descriptions: descriptions}) do
    Enum.reduce descriptions, 0, fn ({_subject, description}, count) ->
      count + Description.count(description)
    end
  end

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
