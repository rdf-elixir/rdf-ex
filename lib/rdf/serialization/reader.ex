defmodule RDF.Serialization.Reader do
  @moduledoc !"""
             General functions for reading a `RDF.Graph` or `RDF.Dataset` from a serialization file, stream or encoded-string.

             These functions are not intended for direct use, but instead via the automatically
             generated functions with the same name on a `RDF.Serialization.Format`, which
             implicitly use the proper `RDF.Serialization.Decoder` module.
             """

  alias RDF.{Serialization, Dataset, Graph}

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
    decoder
    |> Serialization.use_file_streaming(opts)
    |> do_read_file(decoder, file, opts)
  end

  defp do_read_file(false, decoder, file, opts) do
    case File.read(file) do
      {:ok, content} -> decoder.decode(content, opts)
      {:error, reason} -> {:error, reason}
    end
  end

  defp do_read_file(true, decoder, file, opts) do
    {:ok,
     file
     |> File.stream!()
     |> decoder.decode_from_stream(opts)}
  rescue
    error in RuntimeError -> {:error, error.message}
    error -> {:error, error}
  end

  @spec read_file!(module, Path.t(), keyword) :: Graph.t() | Dataset.t()
  def read_file!(decoder, file, opts \\ []) do
    decoder
    |> Serialization.use_file_streaming!(opts)
    |> do_read_file!(decoder, file, opts)
  end

  defp do_read_file!(false, decoder, file, opts) do
    file
    |> File.read!()
    |> decoder.decode!(opts)
  end

  defp do_read_file!(true, decoder, file, opts) do
    file
    |> File.stream!()
    |> decoder.decode_from_stream(opts)
  end
end
