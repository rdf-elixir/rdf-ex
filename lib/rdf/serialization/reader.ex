defmodule RDF.Serialization.Reader do
  @moduledoc """
  General functions for reading a `RDF.Graph` or `RDF.Dataset` from a serialization file or encoded-string.

  You probably won't use these functions directly, but instead use the automatically
  generated functions with same name on a `RDF.Serialization.Format`, which implicitly
  use the proper `RDF.Serialization.Decoder` module.
  """

  alias RDF.{Dataset, Graph}

  @doc """
  Reads and decodes a serialized graph or dataset from a string.

  It returns an `{:ok, data}` tuple, with `data` being the deserialized graph or
  dataset, or `{:error, reason}` if an error occurs.
  """
  @spec read_string(module, String.t, keyword) :: {:ok, Graph.t | Dataset.t} | {:error, any}
  def read_string(decoder, content, opts \\ []) do
    decoder.decode(content, opts)
  end

  @doc """
  Reads and decodes a serialized graph or dataset from a string.

  As opposed to `read_string`, it raises an exception if an error occurs.
  """
  @spec read_string!(module, String.t, keyword) :: Graph.t | Dataset.t
  def read_string!(decoder, content, opts \\ []) do
    decoder.decode!(content, opts)
  end

  @doc """
  Reads and decodes a serialized graph or dataset from a file.

  It returns an `{:ok, data}` tuple, with `data` being the deserialized graph or
  dataset, or `{:error, reason}` if an error occurs.
  """
  @spec read_file(module, Path.t, keyword) :: {:ok, Graph.t | Dataset.t} | {:error, any}
  def read_file(decoder, file, opts \\ []) do
    case File.read(file) do
      {:ok,   content} -> read_string(decoder, content, opts)
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Reads and decodes a serialized graph or dataset from a file.

  As opposed to `read_file`, it raises an exception if an error occurs.
  """
  @spec read_file!(module, Path.t, keyword) :: Graph.t | Dataset.t
  def read_file!(decoder, file, opts \\ []) do
    with content = File.read!(file) do
      read_string!(decoder, content, opts)
    end
  end
end
