defmodule RDF.Serialization.Writer do
  @moduledoc !"""
             General functions for writing the statements of a RDF data structure to a file, string or stream.

             These functions are not intended for direct use, but instead via the automatically
             generated functions with the same name on a `RDF.Serialization.Format`, which
             implicitly use the proper `RDF.Serialization.Encoder` module.
             """

  @default_file_mode ~w[write exclusive]a

  @spec write_string(module, RDF.Data.t(), keyword) :: {:ok, String.t()} | {:error, any}
  def write_string(encoder, data, opts \\ []) do
    encoder.encode(data, opts)
  end

  @spec write_string!(module, RDF.Data.t(), keyword) :: String.t()
  def write_string!(encoder, data, opts \\ []) do
    encoder.encode!(data, opts)
  end

  @spec write_file(module, RDF.Data.t(), Path.t(), keyword) :: :ok | {:error, any}
  def write_file(encoder, data, path, opts \\ []) do
    with {:ok, encoded_string} <- write_string(encoder, data, opts) do
      File.write(path, encoded_string, file_mode(encoder, opts))
    end
  end

  @spec write_file!(module, RDF.Data.t(), Path.t(), keyword) :: :ok
  def write_file!(encoder, data, path, opts \\ []) do
    encoded_string = write_string!(encoder, data, opts)
    File.write!(path, encoded_string, file_mode(encoder, opts))
  end

  defp file_mode(_encoder, opts) do
    file_mode = Keyword.get(opts, :file_mode, @default_file_mode)

    if Keyword.get(opts, :force) do
      List.delete(file_mode, :exclusive)
    else
      file_mode
    end
  end
end
