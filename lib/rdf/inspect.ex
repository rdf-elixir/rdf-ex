defmodule RDF.InspectHelper do
  @moduledoc false

  import Inspect.Algebra

  def value_doc(%URI{} = uri, _opts), do: "~I<#{uri}>"
  def value_doc(value, opts),         do: to_doc(value, opts)

  def objects_doc(objects, opts) do
    objects
    |> Enum.map(fn {object, _}  -> value_doc(object, opts) end)
    |> fold_doc(fn(object, acc) -> line(object, acc) end)
  end

  def predications_doc(predications, opts) do
    predications
    |> Enum.map(fn {predicate, objects} ->
        value_doc(predicate, opts)
        |> line(objects_doc(objects, opts))
        |> nest(4)
       end)
    |> fold_doc(fn(predication, acc) ->
        line(predication, acc)
       end)
  end

  def descriptions_doc(descriptions, opts) do
    descriptions
    |> Enum.map(fn {subject, description} ->
        value_doc(subject, opts)
        |> line(predications_doc(description.predications, opts))
        |> nest(4)
       end)
    |> fold_doc(fn(predication, acc) ->
        line(predication, acc)
       end)
  end
end

defimpl Inspect, for: RDF.Literal do
  def inspect(%RDF.Literal{value: value, language: language}, _opts)
        when not is_nil(language) do
    "%RDF.Literal{value: #{inspect value}, language: #{inspect language}}"
  end

  def inspect(%RDF.Literal{value: value, datatype: datatype}, _opts) do
    "%RDF.Literal{value: #{inspect value}, datatype: ~I<#{datatype}>}"
  end
end

defimpl Inspect, for: RDF.Description do
  import Inspect.Algebra
  import RDF.InspectHelper

  def inspect(%RDF.Description{subject: subject, predications: predications}, opts) do
    doc =
      space("subject:", value_doc(subject, opts))
      |> line(predications_doc(predications, opts))
      |> nest(4)
    surround("#RDF.Description{", doc, "}")
  end
end

defimpl Inspect, for: RDF.Graph do
  import Inspect.Algebra
  import RDF.InspectHelper

  def inspect(%RDF.Graph{name: name, descriptions: descriptions}, opts) do
    doc =
      space("name:", value_doc(name, opts))
      |> line(descriptions_doc(descriptions, opts))
      |> nest(4)
    surround("#RDF.Graph{", doc, "}")
  end
end

defimpl Inspect, for: RDF.Dataset do
  import Inspect.Algebra
  import RDF.InspectHelper

  def inspect(%RDF.Dataset{name: name, graphs: graphs}, opts) do
    doc =
      space("name:", value_doc(name, opts))
      |> line(graphs_doc(graphs, opts))
      |> nest(4)
    surround("#RDF.Dataset{", doc, "}")
  end

  defp graphs_doc(graphs, opts) do
    graphs
    |> Enum.map(fn {_, graph}  -> to_doc(graph, opts) end)
    |> fold_doc(fn(graph, acc) -> line(graph, acc) end)
  end
end
