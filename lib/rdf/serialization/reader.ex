defmodule RDF.Serialization.Reader do
  @moduledoc """
  General functions for reading a `RDF.Graph` or `RDF.Dataset` from a serialization file or encoded-string.

  If no base IRI is provided with the `base` option on any of these functions,
  the `RDF.IRI.default_base/0` is used.

  You probably won't use these functions directly, but instead use the automatically
  generated functions with same name on a `RDF.Serialization.Format`, which implicitly
  use the proper `RDF.Serialization.Decoder` module.
  """


  @doc """
  Reads and decodes a serialized graph or dataset from a string.

  It returns an `{:ok, data}` tuple, with `data` being the deserialized graph or
  dataset, or `{:error, reason}` if an error occurs.
  """
  def read_string(decoder, content, opts \\ []) do
    decoder.decode(content, with_base(opts))
  end

  @doc """
  Reads and decodes a serialized graph or dataset from a string.

  As opposed to `read_string`, it raises an exception if an error occurs.
  """
  def read_string!(decoder, content, opts \\ []) do
    decoder.decode!(content, with_base(opts))
  end

  @doc """
  Reads and decodes a serialized graph or dataset from a file.

  It returns an `{:ok, data}` tuple, with `data` being the deserialized graph or
  dataset, or `{:error, reason}` if an error occurs.
  """
  def read_file(decoder, file, opts \\ []) do
    case File.read(file) do
      {:ok,   content} -> read_string(decoder, content, with_base(opts))
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Reads and decodes a serialized graph or dataset from a file.

  As opposed to `read_file`, it raises an exception if an error occurs.
  """
  def read_file!(decoder, file, opts \\ []) do
    with content = File.read!(file) do
      read_string!(decoder, content, with_base(opts))
    end
  end

  defp with_base(opts) do
    cond do
      Keyword.has_key?(opts, :base) -> opts
      base = RDF.IRI.default_base() -> Keyword.put(opts, :base, base)
      true                          -> opts
    end
  end

end
