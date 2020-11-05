defmodule RDF.Serialization.ReaderTest do
  use RDF.Test.Case

  doctest RDF.Serialization.Reader

  alias RDF.Serialization.Reader
  alias RDF.Turtle

  describe "file_mode/2" do
    test ":gzip without other :file_mode opts" do
      assert Reader.file_mode(Turtle.Decoder, gzip: true) == ~w[compressed read utf8]a
    end

    test ":gzip with other :file_mode opts" do
      assert Reader.file_mode(Turtle.Decoder, gzip: true, file_mode: [:charlist]) ==
               ~w[compressed charlist]a
    end
  end
end
