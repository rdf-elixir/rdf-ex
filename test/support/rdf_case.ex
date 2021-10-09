defmodule RDF.Test.Case do
  use ExUnit.CaseTemplate

  use RDF.Vocabulary.Namespace
  defvocab EX, base_iri: "http://example.com/", terms: [], strict: false

  defvocab FOAF, base_iri: "http://xmlns.com/foaf/0.1/", terms: [], strict: false

  alias RDF.{Dataset, Graph, Description, IRI, XSD}
  import RDF, only: [iri: 1]
  import RDF.Sigils

  using do
    quote do
      alias RDF.{Dataset, Graph, Description, IRI, XSD, PrefixMap, PropertyMap, NS}
      alias RDF.NS.{RDFS, OWL}
      alias unquote(__MODULE__).{EX, FOAF}

      import RDF, only: [iri: 1, literal: 1, bnode: 1]
      import unquote(__MODULE__)

      import RDF.Sigils

      @compile {:no_warn_undefined, RDF.Test.Case.EX}
      @compile {:no_warn_undefined, RDF.Test.Case.FOAF}
    end
  end

  # TODO: Remove this when we dropped support for Elixir versions < 1.10
  def struct_not_allowed_as_input_error do
    if Version.match?(System.version(), "~> 1.10") do
      FunctionClauseError
    else
      ArgumentError
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

  @iri ~I<http://example.com/Foo>
  @bnode ~B<foo>
  @valid_literal ~L"foo"
  @invalid_literal XSD.integer("foo")

  ###############################
  # RDF.Statement

  @statement {RDF.iri(EX.S), RDF.iri(EX.P), RDF.literal("Foo")}
  def statement(), do: @statement

  @coercible_statement {EX.S, EX.P, "Foo"}
  def coercible_statement(), do: @coercible_statement

  @valid_triple {RDF.iri(EX.S), EX.p(), RDF.iri(EX.O)}
  def valid_triple(), do: @valid_triple

  @valid_triples [
    @valid_triple,
    {@iri, @iri, @iri},
    {@bnode, @iri, @iri},
    {@iri, @iri, @bnode},
    {@bnode, @iri, @bnode},
    {@iri, @iri, @valid_literal},
    {@bnode, @iri, @valid_literal},
    {@iri, @iri, @invalid_literal},
    {@bnode, @iri, @invalid_literal}
  ]

  def valid_triples(), do: @valid_triples

  @valid_star_triples [
    {@valid_triple, @iri, @iri},
    {@iri, @iri, @valid_triple}
  ]

  def valid_star_triples(), do: @valid_star_triples

  @valid_quads [
    {@iri, @iri, @iri, @iri},
    {@bnode, @iri, @iri, @iri},
    {@iri, @iri, @bnode, @iri},
    {@bnode, @iri, @bnode, @iri},
    {@iri, @iri, @valid_literal, @iri},
    {@bnode, @iri, @valid_literal, @iri},
    {@iri, @iri, @invalid_literal, @iri},
    {@bnode, @iri, @invalid_literal, @iri}
  ]
  def valid_quads(), do: @valid_quads

  @valid_star_quads [
    {@valid_triple, @iri, @iri, @iri},
    {@iri, @iri, @valid_triple, @iri}
  ]

  def valid_star_quads(), do: @valid_star_quads

  @invalid_triples [
    {@iri, @bnode, @iri},
    {@valid_literal, @iri, @iri},
    {@iri, @valid_literal, @iri}
  ]

  def invalid_triples, do: @invalid_triples

  @invalid_quads [
    {@iri, @bnode, @iri, @iri},
    {@iri, @iri, @iri, @bnode},
    {@valid_literal, @iri, @iri, @iri},
    {@iri, @valid_literal, @iri, @iri},
    {@iri, @iri, @iri, @valid_literal}
  ]

  def invalid_quads(), do: @invalid_quads

  ###############################
  # RDF.Description

  def description, do: Description.new(EX.Subject)
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

  def unnamed_graph, do: Graph.new()

  def named_graph(name \\ EX.GraphName), do: Graph.new(name: name)

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

  def dataset, do: unnamed_dataset()

  def unnamed_dataset, do: Dataset.new()

  def named_dataset(name \\ EX.DatasetName), do: Dataset.new(name: name)

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
    |> Map.get(iri(graph_context), named_graph(graph_context))
    |> graph_includes_statement?({subject, predicate, objects})
  end

  ###############################
  # RDF.Star annotations

  @star_statement {@statement, EX.ap(), EX.ao()}
  def star_statement(), do: @star_statement

  @empty_annotation Description.new(@statement)
  def empty_annotation(), do: @empty_annotation

  @annotation Description.new(@statement, init: {EX.ap(), EX.ao()})
  def annotation(), do: @annotation

  @object_annotation Description.new(EX.As, init: {EX.ap(), @statement})
  def object_annotation(), do: @object_annotation

  @graph_with_annotation Graph.new(init: @annotation)
  def graph_with_annotation(), do: @graph_with_annotation

  @graph_with_annotations Graph.new(init: [@annotation, @object_annotation])
  def graph_with_annotations(), do: @graph_with_annotations
end
