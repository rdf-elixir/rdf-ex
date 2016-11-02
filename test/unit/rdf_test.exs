defmodule RDF.CoreTest do
  use ExUnit.Case

  defmodule EX, do: use RDF.Vocabulary, base_uri: "http://example.com/"

  doctest RDF

#  alias RDF.{Triple, Literal, BlankNode}

end
