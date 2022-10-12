defmodule RDF.Serialization.Writer do
  @moduledoc !"""
             General functions for writing the statements of a RDF data structure to a file, string or stream.

             These functions are not intended for direct use, but instead via the automatically
             generated functions with the same name on a `RDF.Serialization.Format`, which
             implicitly use the proper `RDF.Serialization.Encoder` module.
             """

  alias RDF.Serialization

  @default_file_mode ~w[write exclusive]a
  @default_stream_mode :iodata

  @spec write_string(module, RDF.Data.t(), keyword) :: {:ok, String.t()} | {:error, any}
  def write_string(encoder, data, opts \\ []) do
    encoder.encode(data, opts)
  end

  @spec write_string!(module, RDF.Data.t(), keyword) :: String.t()
  def write_string!(encoder, data, opts \\ []) do
    encoder.encode!(data, opts)
  end

  @spec write_stream(module, RDF.Data.t(), keyword) :: Enumerable.t()
  def write_stream(encoder, data, opts \\ []) do
    if encoder.stream_support?() do
      encoder.stream(data, opts)
    else
      raise "#{inspect(encoder)} does not support streaming"
    end
  end

  @spec write_file(module, RDF.Data.t(), Path.t(), keyword) :: :ok | {:error, any}
  def write_file(encoder, data, path, opts \\ []) do
    encoder
    |> Serialization.use_file_streaming(opts)
    |> do_write_file(encoder, data, path, opts)

    :ok
  rescue
    error in FunctionClauseError -> reraise error, __STACKTRACE__
    error in RuntimeError -> {:error, error.message}
    error -> {:error, error}
  end

  defp do_write_file(false, encoder, data, path, opts) do
    with {:ok, encoded_string} <- encoder.encode(data, opts) do
      File.write(path, encoded_string, file_mode(encoder, opts))
    end
  end

  defp do_write_file(stream_mode, encoder, data, path, opts) do
    data
    |> encoder.stream(set_stream_mode(opts, stream_mode))
    |> Enum.into(File.stream!(path, file_mode(encoder, opts)))
  end

  @spec write_file!(module, RDF.Data.t(), Path.t(), keyword) :: :ok
  def write_file!(encoder, data, path, opts \\ []) do
    encoder
    |> Serialization.use_file_streaming!(opts)
    |> do_write_file!(encoder, data, path, opts)
  end

  defp do_write_file!(false, encoder, data, path, opts) do
    encoded_string = encoder.encode!(data, opts)
    File.write!(path, encoded_string, file_mode(encoder, opts))
  end

  defp do_write_file!(stream_mode, encoder, data, path, opts) do
    # credo:disable-for-lines:5 Credo.Check.Warning.UnusedEnumOperation
    data
    |> encoder.stream(set_stream_mode(opts, stream_mode))
    |> Enum.into(File.stream!(path, file_mode(encoder, opts)))

    :ok
  end

  defp set_stream_mode(opts, true), do: Keyword.put(opts, :mode, @default_stream_mode)
  defp set_stream_mode(opts, stream_mode), do: Keyword.put(opts, :mode, stream_mode)

  @doc false
  def file_mode(_encoder, opts) do
    opts
    |> Keyword.get(:file_mode, @default_file_mode)
    |> List.wrap()
    |> set_force(Keyword.get(opts, :force))
    |> set_gzip(Keyword.get(opts, :gzip))
  end

  defp set_force(file_mode, true), do: List.delete(file_mode, :exclusive)
  defp set_force(file_mode, _), do: file_mode

  defp set_gzip(file_mode, true), do: [:compressed | file_mode]
  defp set_gzip(file_mode, _), do: file_mode
end
