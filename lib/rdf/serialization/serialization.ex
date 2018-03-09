defmodule RDF.Serialization do
  @moduledoc """
  General functions for working with RDF serializations.
  """

  @formats [
    RDF.Turtle,
    JSON.LD,
    RDF.NTriples,
    RDF.NQuads,
  ]

  @doc """
  The list of all known `RDF.Serialization.Format`s in the RDF.ex eco-system.

  Note: Not all known formats might be available to an application, see `available_formats/0`.

  ## Examples

      iex> RDF.Serialization.formats
      [RDF.Turtle, JSON.LD, RDF.NTriples, RDF.NQuads]

  """
  def formats, do: @formats

  @doc """
  The list of all available `RDF.Serialization.Format`s in an application.

  A known format might not be available in an application, when the format is
  implemented in an external library and this not specified as a Mix dependency
  of this application.

  ## Examples

      iex> RDF.Serialization.available_formats
      [RDF.Turtle, RDF.NTriples, RDF.NQuads]

  """
  def available_formats do
    Enum.filter @formats, &Code.ensure_loaded?/1
  end

  @doc """
  Returns the `RDF.Serialization.Format` with the given name, if available.

  ## Examples

      iex> RDF.Serialization.format(:turtle)
      RDF.Turtle
      iex> RDF.Serialization.format("turtle")
      RDF.Turtle
      iex> RDF.Serialization.format(:jsonld)
      nil  # unless json_ld is defined as a dependency of the application
  """
  def format(name)

  def format(name) when is_binary(name) do
    try do
      name
      |> String.to_existing_atom
      |> format()
    rescue
      ArgumentError -> nil
    end
  end

  def format(name) do
    format_where(fn format -> format.name == name end)
  end


  @doc """
  Returns the `RDF.Serialization.Format` with the given media type, if available.

  ## Examples

      iex> RDF.Serialization.format_by_media_type("text/turtle")
      RDF.Turtle
      iex> RDF.Serialization.format_by_media_type("application/ld+json")
      nil  # unless json_ld is defined as a dependency of the application
  """
  def format_by_media_type(media_type) do
    format_where(fn format -> format.media_type == media_type end)
  end

  @doc """
  Returns the proper `RDF.Serialization.Format` for the given file extension, if available.

  ## Examples

      iex> RDF.Serialization.format_by_extension("ttl")
      RDF.Turtle
      iex> RDF.Serialization.format_by_extension(".ttl")
      RDF.Turtle
      iex> RDF.Serialization.format_by_extension("jsonld")
      nil  # unless json_ld is defined as a dependency of the application
  """
  def format_by_extension(extension)

  def format_by_extension("." <> extension), do: format_by_extension(extension)

  def format_by_extension(extension) do
    format_where(fn format -> format.extension == extension end)
  end

  defp format_where(fun) do
    @formats
    |> Stream.filter(&Code.ensure_loaded?/1)
    |> Enum.find(fun)
  end


  @doc """
  Reads and decodes a serialized graph or dataset from a string.

  The format must be specified with the `format` option and a format name or the 
  `media_type` option and the media type of the format.

  It returns an `{:ok, data}` tuple, with `data` being the deserialized graph or
  dataset, or `{:error, reason}` if an error occurs.
  """
  def read_string(content, opts) do
    with {:ok, format} <- string_format(opts) do
      format.read_string(content, opts)
    end
  end

  @doc """
  Reads and decodes a serialized graph or dataset from a string.

  The format must be specified with the `format` option and a format name or the 
  `media_type` option and the media type of the format.

  As opposed to `read_string`, it raises an exception if an error occurs.
  """
  def read_string!(content, opts) do
    with {:ok, format} <- string_format(opts) do
      format.read_string!(content, opts)
    else
      {:error, error} -> raise error
    end
  end

  @doc """
  Reads and decodes a serialized graph or dataset from a file.

  The format can be specified with the `format` option and a format name or the 
  `media_type` option and the media type of the format. If none of these are 
  given, the format gets inferred from the extension of the given file name. 

  It returns an `{:ok, data}` tuple, with `data` being the deserialized graph or
  dataset, or `{:error, reason}` if an error occurs.
  """
  def read_file(file, opts \\ []) do
    with {:ok, format} <- file_format(file, opts) do
      format.read_file(file, opts)
    end
  end

  @doc """
  Reads and decodes a serialized graph or dataset from a file.

  The format can be specified with the `format` option and a format name or the 
  `media_type` option and the media type of the format. If none of these are 
  given, the format gets inferred from the extension of the given file name. 

  As opposed to `read_file`, it raises an exception if an error occurs.
  """
  def read_file!(file, opts \\ []) do
    with {:ok, format} <- file_format(file, opts) do
      format.read_file!(file, opts)
    else
      {:error, error} -> raise error
    end
  end

  @doc """
  Encodes and writes a graph or dataset to a string.

  The format must be specified with the `format` option and a format name or the 
  `media_type` option and the media type of the format.

  It returns an `{:ok, string}` tuple, with `string` being the serialized graph or
  dataset, or `{:error, reason}` if an error occurs.
  """
  def write_string(data, opts) do
    with {:ok, format} <- string_format(opts) do
      format.write_string(data, opts)
    end
  end

  @doc """
  Encodes and writes a graph or dataset to a string.

  The format must be specified with the `format` option and a format name or the 
  `media_type` option and the media type of the format.

  As opposed to `write_string`, it raises an exception if an error occurs.
  """
  def write_string!(data, opts) do
    with {:ok, format} <- string_format(opts) do
      format.write_string!(data, opts)
    else
      {:error, error} -> raise error
    end
  end

  @doc """
  Encodes and writes a graph or dataset to a file.

  The format can be specified with the `format` option and a format name or the
  `media_type` option and the media type of the format. If none of these are
  given, the format gets inferred from the extension of the given file name.

  Other available serialization-independent options:

  - `:force` - If not set to `true`, an error is raised when the given file
    already exists (default: `false`)
  - `:file_mode` - A list with the Elixir `File.open` modes to be used fior writing
    (default: `[:utf8, :write]`)

  It returns `:ok` if successfull or `{:error, reason}` if an error occurs.
  """
  def write_file(data, path, opts \\ []) do
    with {:ok, format} <- file_format(path, opts) do
      format.write_file(data, path, opts)
    end
  end

  @doc """
  Encodes and writes a graph or dataset to a file.

  The format can be specified with the `format` option and a format name or the
  `media_type` option and the media type of the format. If none of these are
  given, the format gets inferred from the extension of the given file name.

  See `write_file` for a list of other available options.

  As opposed to `write_file`, it raises an exception if an error occurs.
  """
  def write_file!(data, path, opts \\ []) do
    with {:ok, format} <- file_format(path, opts) do
      format.write_file!(data, path, opts)
    else
      {:error, error} -> raise error
    end
  end


  defp string_format(opts) do
    if format =
        (opts |> Keyword.get(:format) |> format()) ||
        (opts |> Keyword.get(:media_type) |> format_by_media_type())
    do
      {:ok, format}
    else
      {:error, "unable to detect serialization format"}
    end
  end

  defp file_format(filename, opts) do
    case string_format(opts) do
      {:ok, format} -> {:ok, format}
      _             -> format_by_file_name(filename)
    end
  end

  defp format_by_file_name(filename) do
    if format = filename |> Path.extname() |> format_by_extension() do
      {:ok, format}
    else
      {:error, "unable to detect serialization format"}
    end
  end

end
