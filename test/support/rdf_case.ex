defmodule RDF.Test.Case do
  @moduledoc """
  Common `ExUnit.CaseTemplate` for RDF tests including test data.
  """

  use ExUnit.CaseTemplate

  alias RDF.{Dataset, Graph, Description, IRI}
  import RDF, only: [iri: 1]

  using do
    quote do
      alias RDF.{
        Dataset,
        Graph,
        Description,
        IRI,
        BlankNode,
        Literal,
        XSD,
        PrefixMap,
        PropertyMap,
        NS
      }

      alias RDF.NS.{RDFS, OWL}
      alias RDF.TestVocabularyNamespaces.{EX, FOAF}

      @compile {:no_warn_undefined, RDF.TestVocabularyNamespaces.EX}
      @compile {:no_warn_undefined, RDF.TestVocabularyNamespaces.FOAF}

      import RDF, only: [literal: 1, bnode: 1]
      import RDF.Namespace.IRI
      import RDF.Sigils
      import RDF.Graph
      import RDF.Test.Assertions

      import RDF.TestFactories
      import unquote(__MODULE__)
    end
  end

  def order_independent({:ok, %RDF.Query.BGP{triple_patterns: triple_patterns}}),
    do: {:ok, %RDF.Query.BGP{triple_patterns: Enum.sort(triple_patterns)}}

  def order_independent({:ok, elements}), do: {:ok, Enum.sort(elements)}
  def order_independent(elements), do: Enum.sort(elements)

  defmacro assert_order_independent({:==, _, [left, right]}) do
    quote do
      assert order_independent(unquote(left)) == order_independent(unquote(right))
    end
  end

  def string_to_stream(string) do
    {:ok, pid} = StringIO.open(string)
    IO.binstream(pid, :line)
  end

  def stream_to_string(stream) do
    stream
    |> Enum.to_list()
    |> IO.iodata_to_binary()
  end

  ###############################
  # RDF.Description

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

  def unnamed_graph?(%Graph{name: nil}), do: true
  def unnamed_graph?(_), do: false

  def named_graph?(%Graph{name: %IRI{}}), do: true
  def named_graph?(_), do: false
  def named_graph?(%Graph{name: name}, name), do: true
  def named_graph?(_, _), do: false

  def empty_graph?(%Graph{descriptions: descriptions}),
    do: descriptions == %{}

  def graph_includes_statement?(graph, {subject, _, _} = statement) do
    subject = if is_tuple(subject), do: subject, else: iri(subject)

    graph.descriptions
    |> Map.get(subject, %{})
    |> Enum.member?(statement)
  end

  ###############################
  # RDF.Dataset

  def unnamed_dataset?(%Dataset{name: nil}), do: true
  def unnamed_dataset?(_), do: false

  def named_dataset?(%Dataset{name: %IRI{}}), do: true
  def named_dataset?(_), do: false
  def named_dataset?(%Dataset{name: name}, name), do: true
  def named_dataset?(_, _), do: false

  def empty_dataset?(%Dataset{graphs: graphs}), do: graphs == %{}

  def dataset_includes_statement?(dataset, {_, _, _} = statement) do
    dataset
    |> Dataset.default_graph()
    |> graph_includes_statement?(statement)
  end

  def dataset_includes_statement?(dataset, {subject, predicate, objects, nil}),
    do: dataset_includes_statement?(dataset, {subject, predicate, objects})

  def dataset_includes_statement?(
        dataset,
        {subject, predicate, objects, graph_context}
      ) do
    dataset.graphs
    |> Map.get(iri(graph_context))
    |> graph_includes_statement?({subject, predicate, objects})
  end
end
