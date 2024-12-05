defmodule RDF.Serialization.Reader do
  @moduledoc !"""
             General functions for reading a `RDF.Graph` or `RDF.Dataset` from a serialization file, stream or encoded-string.

             These functions are not intended for direct use, but instead via the automatically
             generated functions with the same name on a `RDF.Serialization.Format`, which
             implicitly use the proper `RDF.Serialization.Decoder` module.
             """

  alias RDF.{Serialization, Dataset, Graph}

  @default_file_mode ~w[read utf8]a
  @io_read_mode :eof

  @spec read_string(module, String.t(), keyword) :: {:ok, Graph.t() | Dataset.t()} | {:error, any}
  def read_string(decoder, content, opts \\ []) do
    decoder.decode(content, opts)
  end

  @spec read_string!(module, String.t(), keyword) :: Graph.t() | Dataset.t()
  def read_string!(decoder, content, opts \\ []) do
    decoder.decode!(content, opts)
  end

  @spec read_stream(module, Enumerable.t(), keyword) ::
          {:ok, Graph.t() | Dataset.t()} | {:error, any}
  def read_stream(decoder, stream, opts \\ []) do
    if decoder.stream_support?() do
      decoder.decode_from_stream(stream, opts)
    else
      raise "#{inspect(decoder)} does not support streaming"
    end
  end

  @spec read_stream!(module, Enumerable.t(), keyword) :: Graph.t() | Dataset.t()
  def read_stream!(decoder, stream, opts \\ []) do
    if decoder.stream_support?() do
      decoder.decode_from_stream!(stream, opts)
    else
      raise "#{inspect(decoder)} does not support streaming"
    end
  end

  @spec read_file(module, Path.t(), keyword) :: {:ok, Graph.t() | Dataset.t()} | {:error, any}
  def read_file(decoder, file, opts \\ []) do
    decoder
    |> Serialization.use_file_streaming!(opts)
    |> do_read_file(decoder, file, opts)
  end

  defp do_read_file(false, decoder, file, opts) do
    file
    |> File.open(file_mode(decoder, opts), &IO.read(&1, @io_read_mode))
    |> case do
      {:ok, {:error, error}} -> {:error, error}
      {:ok, :eof} -> decoder.decode("", opts)
      {:ok, content} -> decoder.decode(content, opts)
      {:error, error} -> {:error, error}
    end
  end

  defp do_read_file(true, decoder, file, opts) do
    file
    |> File.stream!(file_mode(decoder, opts))
    |> decoder.decode_from_stream(opts)
  rescue
    error in FunctionClauseError -> reraise error, __STACKTRACE__
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
    |> File.open!(file_mode(decoder, opts), &IO.read(&1, @io_read_mode))
    |> case do
      {:error, error} when is_tuple(error) -> error |> inspect() |> raise()
      {:error, error} -> raise(error)
      :eof -> decoder.decode!("", opts)
      content -> decoder.decode!(content, opts)
    end
  end

  defp do_read_file!(_stream_mode, decoder, file, opts) do
    file
    |> File.stream!(file_mode(decoder, opts))
    |> decoder.decode_from_stream!(opts)
  end

  @doc false
  def file_mode(_decoder, opts) do
    opts
    |> Keyword.get(:file_mode, @default_file_mode)
    |> List.wrap()
    |> set_gzip(Keyword.get(opts, :gzip))
  end

  defp set_gzip(file_mode, true), do: [:compressed | file_mode]
  defp set_gzip(file_mode, _), do: file_mode
end
