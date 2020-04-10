defmodule RDF.InspectHelper do
  @moduledoc false

  import Inspect.Algebra


  def objects_doc(objects, opts) do
    objects
    |> Enum.map(fn {object, _}  -> to_doc(object, opts) end)
    |> fold_doc(fn(object, acc) -> line(object, acc) end)
  end

  def predications_doc(predications, opts) do
    predications
    |> Enum.map(fn {predicate, objects} ->
        to_doc(predicate, opts)
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
        to_doc(subject, opts)
        |> line(predications_doc(description.predications, opts))
        |> nest(4)
       end)
    |> fold_doc(fn(predication, acc) ->
        line(predication, acc)
       end)
  end

  def surround_doc(left, doc, right) do
    concat(concat(left, nest(doc, 1)), right)
  end
end

defimpl Inspect, for: RDF.IRI do
  def inspect(%RDF.IRI{value: value}, _opts) do
    "~I<#{value}>"
  end
end

defimpl Inspect, for: RDF.BlankNode do
  def inspect(%RDF.BlankNode{id: id}, _opts) do
    "~B<#{id}>"
  end
end

defimpl Inspect, for: RDF.Literal do
  def inspect(literal, _opts) do
    "%RDF.Literal{literal: #{inspect literal.literal}, valid: #{RDF.Literal.valid?(literal)}}"
  end
end

defimpl Inspect, for: RDF.Description do
  import Inspect.Algebra
  import RDF.InspectHelper

  def inspect(%RDF.Description{subject: subject, predications: predications}, opts) do
    doc =
      space("subject:", to_doc(subject, opts))
      |> line(predications_doc(predications, opts))
      |> nest(4)
    surround_doc("#RDF.Description{", doc, "}")
  end
end

defimpl Inspect, for: RDF.Graph do
  import Inspect.Algebra
  import RDF.InspectHelper

  def inspect(%RDF.Graph{name: name, descriptions: descriptions}, opts) do
    doc =
      space("name:", to_doc(name, opts))
      |> line(descriptions_doc(descriptions, opts))
      |> nest(4)
    surround_doc("#RDF.Graph{", doc, "}")
  end
end

defimpl Inspect, for: RDF.Dataset do
  import Inspect.Algebra
  import RDF.InspectHelper

  def inspect(%RDF.Dataset{name: name} = dataset, opts) do
    doc =
      space("name:", to_doc(name, opts))
      |> line(graphs_doc(RDF.Dataset.graphs(dataset), opts))
      |> nest(4)
    surround_doc("#RDF.Dataset{", doc, "}")
  end

  defp graphs_doc(graphs, opts) do
    graphs
    |> Enum.map(fn graph       -> to_doc(graph, opts) end)
    |> fold_doc(fn(graph, acc) -> line(graph, acc) end)
  end
end
