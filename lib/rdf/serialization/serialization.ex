defmodule RDF.Serialization do
  @moduledoc """
  Functions for working with RDF serializations generically.

  Besides some reflection functions regarding available serialization formats,
  this module includes the full serialization reader and writer API from the
  serialization format modules.
  As opposed to calling the reader and writer functions statically on the
  serialization format module, they can be used more dynamically on this module
  either by providing the format by name or media type with the `:format` option
  or in the case of the read and write function on files by relying on detection
  of the format by file extension.
  """

  alias RDF.{Dataset, Graph}

  @type format :: module

  @formats [
    RDF.Turtle,
    RDF.TriG,
    JSON.LD,
    RDF.NTriples,
    RDF.NQuads,
    RDF.XML
  ]

  @doc """
  The list of all known `RDF.Serialization.Format`s in the RDF.ex eco-system.

  Note: Not all known formats might be available to an application, see `available_formats/0`.

  ## Examples

      iex> RDF.Serialization.formats
      #{inspect(@formats)}

  """
  @spec formats :: [format]
  def formats, do: @formats

  @doc """
  The list of all available `RDF.Serialization.Format`s in an application.

  A known format might not be available in an application, when the format is
  implemented in an external library and this not specified as a Mix dependency
  of this application.

  ## Examples

      iex> RDF.Serialization.available_formats
      [RDF.Turtle, RDF.TriG, RDF.NTriples, RDF.NQuads]

  """
  @spec available_formats :: [format]
  def available_formats do
    Enum.filter(@formats, &Code.ensure_loaded?/1)
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
  @spec format(String.t() | atom) :: format | nil
  def format(name)

  def format(name) when is_binary(name) do
    name
    |> String.to_existing_atom()
    |> format()
  rescue
    ArgumentError -> nil
  end

  def format(name) do
    format_where(fn format -> format.name() == name end)
  end

  @doc """
  Returns the `RDF.Serialization.Format` with the given media type, if available.

  ## Examples

      iex> RDF.Serialization.format_by_media_type("text/turtle")
      RDF.Turtle
      iex> RDF.Serialization.format_by_media_type("application/ld+json")
      nil  # unless json_ld is defined as a dependency of the application
  """
  @spec format_by_media_type(String.t()) :: format | nil
  def format_by_media_type(media_type) do
    format_where(fn format -> format.media_type() == media_type end)
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
  @spec format_by_extension(String.t()) :: format | nil
  def format_by_extension(extension)

  def format_by_extension("." <> extension), do: format_by_extension(extension)

  def format_by_extension(extension) do
    format_where(fn format -> format.extension() == extension end)
  end

  defp format_where(fun) do
    @formats
    |> Stream.filter(&Code.ensure_loaded?/1)
    |> Enum.find(fun)
  end

  @doc """
  Deserializes a graph or dataset from a string.

  It returns an `{:ok, data}` tuple, with `data` being the deserialized graph or
  dataset, or `{:error, reason}` if an error occurs.

  The format must be specified with the `format` option and a format name or the
  `media_type` option and the media type of the format.

  Please refer to the documentation of the decoder of a RDF serialization format
  for format-specific options.
  """
  @spec read_string(String.t(), keyword) :: {:ok, Graph.t() | Dataset.t()} | {:error, any}
  def read_string(content, opts) do
    with {:ok, format} <- string_format(opts) do
      format.read_string(content, opts)
    end
  end

  @doc """
  Deserializes a graph or dataset from a string.

  As opposed to `read_string/2`, it raises an exception if an error occurs.

  The format must be specified with the `format` option and a format name or the
  `media_type` option and the media type of the format.

  Please refer to the documentation of the decoder of a RDF serialization format
  for format-specific options.
  """
  @spec read_string!(String.t(), keyword) :: Graph.t() | Dataset.t()
  def read_string!(content, opts) do
    case string_format(opts) do
      {:ok, format} -> format.read_string!(content, opts)
      {:error, error} -> raise error
    end
  end

  @doc """
  Deserializes a graph or dataset from a stream.

  It returns an `{:ok, data}` tuple, with `data` being the deserialized graph or
  dataset, or `{:error, reason}` if an error occurs.

  The format must be specified with the `format` option and a format name or the
  `media_type` option and the media type of the format.

  Please refer to the documentation of the decoder of a RDF serialization format
  for format-specific options.
  """
  @spec read_stream(Enumerable.t(), keyword) :: {:ok, Graph.t() | Dataset.t()} | {:error, any}
  def read_stream(stream, opts) do
    with {:ok, format} <- string_format(opts) do
      format.read_stream(stream, opts)
    end
  end

  @doc """
  Deserializes a graph or dataset from a stream.

  As opposed to `read_stream/2`, it raises an exception if an error occurs.

  The format must be specified with the `format` option and a format name or the
  `media_type` option and the media type of the format.

  Please refer to the documentation of the decoder of a RDF serialization format
  for format-specific options.
  """
  @spec read_stream!(Enumerable.t(), keyword) :: Graph.t() | Dataset.t()
  def read_stream!(stream, opts) do
    case string_format(opts) do
      {:ok, format} -> format.read_stream!(stream, opts)
      {:error, error} -> raise error
    end
  end

  @doc """
  Deserializes a graph or dataset from a file.

  It returns an `{:ok, data}` tuple, with `data` being the deserialized graph or
  dataset, or `{:error, reason}` if an error occurs.

  ## Options

  The format can be specified with the `format` option and a format name or the
  `media_type` option and the media type of the format. If none of these are 
  given, the format gets inferred from the extension of the given file name. 

  Other available serialization-independent options:

  - `:stream`: Allows to enable reading the data from a file directly via a
    stream (default: `false` on this function, `true` on the bang version)
  - `:gzip`: Allows to read directly from a gzipped file (default: `false`)
  - `:file_mode`: A list with the Elixir `File.open` modes to be used for reading
    (default: `[:read, :utf8]`)

  Please refer to the documentation of the decoder of a RDF serialization format
  for format-specific options.
  """
  @spec read_file(Path.t(), keyword) :: {:ok, Graph.t() | Dataset.t()} | {:error, any}
  def read_file(file, opts \\ []) do
    with {:ok, format} <- file_format(file, opts) do
      format.read_file(file, opts)
    end
  end

  @doc """
  Deserializes a graph or dataset from a file.

  As opposed to `read_file/2`, it raises an exception if an error occurs and
  defaults to `stream: true`.

  The format can be specified with the `format` option and a format name or the 
  `media_type` option and the media type of the format. If none of these are 
  given, the format gets inferred from the extension of the given file name. 

  See `read_file/3` for the available format-independent options.

  Please refer to the documentation of the decoder of a RDF serialization format
  for format-specific options.
  """
  @spec read_file!(Path.t(), keyword) :: Graph.t() | Dataset.t()
  def read_file!(file, opts \\ []) do
    case file_format(file, opts) do
      {:ok, format} -> format.read_file!(file, opts)
      {:error, error} -> raise error
    end
  end

  @doc """
  Serializes a RDF data structure to a string.

  It returns an `{:ok, string}` tuple, with `string` being the serialized graph or
  dataset, or `{:error, reason}` if an error occurs.

  The format must be specified with the `format` option and a format name or the
  `media_type` option and the media type of the format.

  Please refer to the documentation of the encoder of a RDF serialization format
  for format-specific options.
  """
  @spec write_string(RDF.Data.t(), keyword) :: {:ok, String.t()} | {:error, any}
  def write_string(data, opts) do
    with {:ok, format} <- string_format(opts) do
      format.write_string(data, opts)
    end
  end

  @doc """
  Serializes a RDF data structure to a string.

  As opposed to `write_string/2`, it raises an exception if an error occurs.

  The format must be specified with the `format` option and a format name or the
  `media_type` option and the media type of the format.

  Please refer to the documentation of the encoder of a RDF serialization format
  for format-specific options.
  """
  @spec write_string!(RDF.Data.t(), keyword) :: String.t()
  def write_string!(data, opts) do
    case string_format(opts) do
      {:ok, format} -> format.write_string!(data, opts)
      {:error, error} -> raise error
    end
  end

  @doc """
  Serializes a RDF data structure to a stream.

  The format must be specified with the `format` option and a format name or the
  `media_type` option and the media type of the format.

  Please refer to the documentation of the encoder of a RDF serialization format
  for format-specific options and what the stream emits.
  """
  @spec write_stream(RDF.Data.t(), keyword) :: Enumerable.t()
  def write_stream(data, opts) do
    case string_format(opts) do
      {:ok, format} -> format.write_stream(data, opts)
      {:error, error} -> raise error
    end
  end

  @doc """
  Serializes a RDF data structure to a file.

  It returns `:ok` if successful or `{:error, reason}` if an error occurs.

  ## Options

  The format can be specified with the `format` option and a format name or the
  `media_type` option and the media type of the format. If none of these are
  given, the format gets inferred from the extension of the given file name.

  Other available serialization-independent options:

  - `:stream`: Allows to enable writing the serialized data to the file directly
    via a stream. Possible values: `:string` or `:iodata` for writing to the file
    with a stream of strings respective IO lists, `true` if you want to use streams,
    but don't care for the exact method or `false` for not writing with
    a stream (default: `false` on this function, `:iodata` on the bang version)
  - `:gzip`: Allows to write directly to a gzipped file (default: `false`)
  - `:force`: If not set to `true`, an error is raised when the given file
    already exists (default: `false`)
  - `:file_mode`: A list with the Elixir `File.open` modes to be used for writing
    (default: `[:write, :exclusive]`)

  Please refer to the documentation of the encoder of a RDF serialization format
  for format-specific options.
  """
  @spec write_file(RDF.Data.t(), Path.t(), keyword) :: :ok | {:error, any}
  def write_file(data, path, opts \\ []) do
    with {:ok, format} <- file_format(path, opts) do
      format.write_file(data, path, opts)
    end
  end

  @doc """
  Serializes a RDF data structure to a file.

  As opposed to `write_file/3`, it raises an exception if an error occurs.

  See `write_file/3` for the available format-independent options.

  Please refer to the documentation of the encoder of a RDF serialization format
  for format-specific options.
  """
  @spec write_file!(RDF.Data.t(), Path.t(), keyword) :: :ok
  def write_file!(data, path, opts \\ []) do
    case file_format(path, opts) do
      {:ok, format} -> format.write_file!(data, path, opts)
      {:error, error} -> raise error
    end
  end

  defp string_format(opts) do
    if format =
         opts |> Keyword.get(:format) |> format() ||
           opts |> Keyword.get(:media_type) |> format_by_media_type() do
      {:ok, format}
    else
      {:error, "unable to detect serialization format"}
    end
  end

  defp file_format(filename, opts) do
    case string_format(opts) do
      {:ok, format} -> {:ok, format}
      _ -> format_by_file_name(filename)
    end
  end

  defp format_by_file_name(filename) do
    if format = filename |> Path.extname() |> format_by_extension() do
      {:ok, format}
    else
      {:error, "unable to detect serialization format"}
    end
  end

  @doc false
  def use_file_streaming(mod, opts) do
    case Keyword.get(opts, :stream) do
      nil ->
        false

      false ->
        false

      stream_mode ->
        if mod.stream_support?() do
          stream_mode
        else
          raise "#{inspect(mod)} does not support streams"
        end
    end
  end

  @doc false
  def use_file_streaming!(mod, opts) do
    case Keyword.get(opts, :stream) do
      nil ->
        mod.stream_support?()

      false ->
        false

      stream_mode ->
        if mod.stream_support?() do
          stream_mode
        else
          raise "#{inspect(mod)} does not support streams"
        end
    end
  end
end
