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
  @xsd_string RDF.Datatype.NS.XSD.string
  @rdf_lang_string RDF.langString

  def inspect(%RDF.Literal{value: value, language: language}, _opts) when not is_nil(language) do
    ~s[~L"#{value}"#{language}]
  end

  def inspect(%RDF.Literal{value: value, uncanonical_lexical: lexical, datatype: datatype}, _opts)
        when not is_nil(lexical) do
    "%RDF.Literal{value: #{inspect value}, lexical: #{inspect lexical}, datatype: ~I<#{datatype}>}"
  end

  def inspect(%RDF.Literal{value: value, datatype: datatype, language: language}, _opts) do
    case datatype do
      @xsd_string ->
        ~s[~L"#{value}"]
      @rdf_lang_string ->
        "%RDF.Literal{value: #{inspect value}, datatype: ~I<#{datatype}>, language: #{inspect language}}"
      _ ->
        "%RDF.Literal{value: #{inspect value}, datatype: ~I<#{datatype}>}"
    end
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
    surround("#RDF.Description{", doc, "}")
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
    surround("#RDF.Graph{", doc, "}")
  end
end

defimpl Inspect, for: RDF.Dataset do
  import Inspect.Algebra

  def inspect(%RDF.Dataset{name: name} = dataset, opts) do
    doc =
      space("name:", to_doc(name, opts))
      |> line(graphs_doc(RDF.Dataset.graphs(dataset), opts))
      |> nest(4)
    surround("#RDF.Dataset{", doc, "}")
  end

  defp graphs_doc(graphs, opts) do
    graphs
    |> Enum.map(fn graph       -> to_doc(graph, opts) end)
    |> fold_doc(fn(graph, acc) -> line(graph, acc) end)
  end
end
