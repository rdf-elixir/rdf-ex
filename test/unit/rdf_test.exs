defmodule RDFTest do
  use ExUnit.Case

  use RDF.Vocabulary.Namespace
  defvocab EX, base_uri: "http://example.com/", terms: [], strict: false

  alias RDF.NS.XSD

  doctest RDF

end
