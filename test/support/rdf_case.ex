defmodule RDF.Test.Case do
  use ExUnit.CaseTemplate

  alias RDF.{Dataset, Graph, Description}
  import RDF, only: [uri: 1]

  defmodule EX, do:
    use RDF.Vocabulary, base_uri: "http://example.com/"

  using do
    quote do
      alias RDF.{Dataset, Graph, Description}
      alias EX

      import RDF, only: [uri: 1, literal: 1, bnode: 1]
      import RDF.Test.Case
    end
  end

  ###############################
  # RDF.Description

  def description,          do: Description.new(EX.Subject)
  def description(content), do: Description.add(description(), content)

  def description_of_subject(%Description{subject: subject}, subject),
    do: true
  def description_of_subject(_, _),
    do: false

  def empty_description(%Description{predications: predications}),
    do: predications == %{}

  def description_includes_predication(desc, {predicate, object}) do
    desc.predications
    |> Map.get(predicate, %{})
    |> Enum.member?({object, nil})
  end

  ###############################
  # RDF.Graph

  def graph, do: unnamed_graph()

  def unnamed_graph, do: Graph.new

  def named_graph(name \\ EX.GraphName), do: Graph.new(name)

  def unnamed_graph?(%Graph{name: nil}), do: true
  def unnamed_graph?(_),                 do: false

  def named_graph?(%Graph{name: %URI{}}),     do: true
  def named_graph?(_),                        do: false
  def named_graph?(%Graph{name: name}, name), do: true
  def named_graph?(_, _),                     do: false

  def empty_graph?(%Graph{descriptions: descriptions}),
    do: descriptions == %{}

  def graph_includes_statement?(graph, statement = {subject, _, _}) do
    graph.descriptions
    |> Map.get(uri(subject), %{})
    |> Enum.member?(statement)
  end

end
