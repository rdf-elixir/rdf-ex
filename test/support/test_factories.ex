defmodule RDF.TestFactories do
  @moduledoc """
  Test factories.
  """

  import RDF.Sigils
  alias RDF.{Dataset, Graph, Description, XSD}
  alias RDF.TestVocabularyNamespaces.EX

  @compile {:no_warn_undefined, RDF.TestVocabularyNamespaces.EX}

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

  ###############################
  # RDF.Graph

  def graph, do: unnamed_graph()

  def unnamed_graph, do: Graph.new()

  def named_graph(name \\ EX.GraphName), do: Graph.new(name: name)

  ###############################
  # RDF.Dataset

  def dataset, do: unnamed_dataset()

  def unnamed_dataset, do: Dataset.new()

  def named_dataset(name \\ EX.DatasetName), do: Dataset.new(name: name)

  ###############################
  # RDF.Star

  @star_statement {@statement, EX.ap(), EX.ao()}
  def star_statement(), do: @star_statement

  @empty_annotation_description Description.new(@statement)
  def empty_annotation_description(), do: @empty_annotation_description

  @annotation_description Description.new(@statement, init: {EX.ap(), EX.ao()})
  def annotation_description(), do: @annotation_description

  @description_with_quoted_triple_object Description.new(EX.As, init: {EX.ap(), @statement})
  def description_with_quoted_triple_object(), do: @description_with_quoted_triple_object

  @graph_with_annotation Graph.new(init: @annotation_description)
  def graph_with_annotation(), do: @graph_with_annotation

  @graph_with_quoted_triples Graph.new(
                               init: [
                                 @annotation_description,
                                 @description_with_quoted_triple_object
                               ]
                             )
  def graph_with_quoted_triples(), do: @graph_with_quoted_triples

  @dataset_with_annotation Dataset.new(init: @annotation_description)
  def dataset_with_annotation(), do: @dataset_with_annotation
end
