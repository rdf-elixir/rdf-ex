defmodule RDF.CoreTest do
  use ExUnit.Case

  use RDF.Vocabulary.Namespace
  defvocab EX, base_uri: "http://example.com/", terms: [], strict: false

  alias RDF.NS.XSD

  doctest RDF

#  alias RDF.{Triple, Literal, BlankNode}

end
