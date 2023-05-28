defmodule RDF.TestVocabularyNamespaces do
  @moduledoc """
  Test `RDF.Vocabulary.Namespace`s used in tests.
  """

  use RDF.Vocabulary.Namespace

  defvocab EX,
    base_iri: "http://example.com/",
    terms: [],
    strict: false

  defvocab FOAF,
    base_iri: "http://xmlns.com/foaf/0.1/",
    terms: [],
    strict: false
end
