defmodule RDF.Serialization.WriterTest do
  use RDF.Test.Case

  doctest RDF.Serialization.Writer

  alias RDF.Serialization.Writer
  alias RDF.Turtle

  describe "file_mode/2" do
    test ":force" do
      assert Writer.file_mode(Turtle.Encoder, force: true) == ~w[write]a
    end

    test ":gzip without other :file_mode opts" do
      assert Writer.file_mode(Turtle.Encoder, gzip: true) == ~w[compressed write exclusive]a
    end

    test ":gzip with other :file_mode opts" do
      assert Writer.file_mode(Turtle.Encoder, gzip: true, file_mode: [:append]) ==
               ~w[compressed append]a
    end
  end
end
