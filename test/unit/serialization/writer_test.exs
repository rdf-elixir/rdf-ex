defmodule RDF.Serialization.WriterTest do
  use RDF.Test.Case

  doctest RDF.Serialization.Writer

  alias RDF.Serialization.Writer
  alias RDF.Turtle

  defmodule FailingEncoder do
    use RDF.Serialization.Encoder

    @impl true
    def encode(_data, _opts \\ []), do: {:error, :encoding_failed}
  end

  defp file(name), do: System.tmp_dir!() |> Path.join(name)

  describe "write_file/4" do
    test "errors of the encoder are propagated" do
      file = file("writer_test.ttl")
      if File.exists?(file), do: File.rm(file)

      assert Writer.write_file(FailingEncoder, RDF.graph(), file) == {:error, :encoding_failed}
      refute File.exists?(file)
    end
  end

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
