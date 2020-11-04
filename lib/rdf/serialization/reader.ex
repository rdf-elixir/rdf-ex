defmodule RDF.Serialization.Reader do
  @moduledoc !"""
             General functions for reading a `RDF.Graph` or `RDF.Dataset` from a serialization file, stream or encoded-string.

             These functions are not intended for direct use, but instead via the automatically
             generated functions with the same name on a `RDF.Serialization.Format`, which
             implicitly use the proper `RDF.Serialization.Decoder` module.
             """

  alias RDF.{Dataset, Graph}

  @spec read_string(module, String.t(), keyword) :: {:ok, Graph.t() | Dataset.t()} | {:error, any}
  def read_string(decoder, content, opts \\ []) do
    decoder.decode(content, opts)
  end

  @spec read_string!(module, String.t(), keyword) :: Graph.t() | Dataset.t()
  def read_string!(decoder, content, opts \\ []) do
    decoder.decode!(content, opts)
  end

  @spec read_stream(module, Enumerable.t(), keyword) :: Graph.t() | Dataset.t()
  def read_stream(decoder, stream, opts \\ []) do
    if decoder.stream_support?() do
      decoder.decode_from_stream(stream, opts)
    else
      raise "#{inspect(decoder)} does not support streaming"
    end
  end

  @spec read_file(module, Path.t(), keyword) :: {:ok, Graph.t() | Dataset.t()} | {:error, any}
  def read_file(decoder, file, opts \\ []) do
    case File.read(file) do
      {:ok, content} -> read_string(decoder, content, opts)
      {:error, reason} -> {:error, reason}
    end
  end

  @spec read_file!(module, Path.t(), keyword) :: Graph.t() | Dataset.t()
  def read_file!(decoder, file, opts \\ []) do
    content = File.read!(file)
    read_string!(decoder, content, opts)
  end
end
