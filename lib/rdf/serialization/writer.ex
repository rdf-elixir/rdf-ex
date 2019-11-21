defmodule RDF.Serialization.Writer do
  @moduledoc """
  General functions for writing the statements of a `RDF.Graph` or `RDF.Dataset` to a serialization file or string.

  You probably won't use these functions directly, but instead use the automatically
  generated functions with same name on a `RDF.Serialization.Format`, which implicitly
  use the proper `RDF.Serialization.Encoder` module.
  """


  @doc """
  Encodes and writes a graph or dataset to a string.

  It returns an `{:ok, string}` tuple, with `string` being the serialized graph or
  dataset, or `{:error, reason}` if an error occurs.
  """
  def write_string(encoder, data, opts \\ []) do
    encoder.encode(data, opts)
  end

  @doc """
  Encodes and writes a graph or dataset to a string.

  As opposed to `write_string`, it raises an exception if an error occurs.
  """
  def write_string!(encoder, data, opts \\ []) do
    encoder.encode!(data, opts)
  end

  @doc """
  Encodes and writes a graph or dataset to a file.

  General available serialization-independent options:

  - `:force` - If not set to `true`, an error is raised when the given file
    already exists (default: `false`)
  - `:file_mode` - A list with the Elixir `File.open` modes to be used for writing
    (default: `[:write, :exclusive]`)

  It returns `:ok` if successful or `{:error, reason}` if an error occurs.
  """
  def write_file(encoder, data, path, opts \\ []) do
    with {:ok, encoded_string} <- write_string(encoder, data, opts) do
      File.write(path, encoded_string, file_mode(encoder, opts))
    end
  end

  @doc """
  Encodes and writes a graph or dataset to a file.

  See `write_file` for a list of available options.

  As opposed to `write_file`, it raises an exception if an error occurs.
  """
  def write_file!(encoder, data, path, opts \\ []) do
    with encoded_string = write_string!(encoder, data, opts) do
      File.write!(path, encoded_string, file_mode(encoder, opts))
    end
  end

  defp file_mode(_encoder, opts) do
    with file_mode = Keyword.get(opts, :file_mode, ~w[write exclusive]a) do
      if Keyword.get(opts, :force) do
        List.delete(file_mode, :exclusive)
      else
        file_mode
      end
    end
  end
end
