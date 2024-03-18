defmodule RDF.Serialization.Format do
  @moduledoc """
  A behaviour for RDF serialization formats.

  A serialization format can be implemented like this

      defmodule SomeFormat do
        use RDF.Serialization.Format
        import RDF.Sigils

        @id         ~I<http://example.com/some_format>
        @name       :some_format
        @extension  "ext"
        @media_type "application/some-format"
      end

  When `@id`, `@name`, `@extension` and `@media_type` module attributes are
  defined the resp. behaviour functions are generated automatically and return
  these values.

  Then you'll have to do the main work by implementing a
  `RDF.Serialization.Encoder` and a `RDF.Serialization.Decoder` for the format.

  By default, it is assumed that these are defined in `Encoder` and `Decoder`
  modules under the `RDF.Serialization.Format` module of the format, i.e. in the
  example above in `SomeFormat.Encoder` and `SomeFormat.Decoder`. If you want
  them in another module, you'll have to override the `encoder/0` and/or
  `decoder/0` functions in your `RDF.Serialization.Format` module.
  """

  alias RDF.{Dataset, Graph}
  alias RDF.Serialization.{Reader, Writer}

  @doc """
  An IRI of the serialization format.
  """
  @callback id :: RDF.IRI.t()

  @doc """
  The name atom of the serialization format.
  """
  @callback name :: atom

  @doc """
  The usual file extension for the serialization format.
  """
  @callback extension :: String.t()

  @doc """
  The MIME type of the serialization format.
  """
  @callback media_type :: String.t()

  @doc """
  The `RDF.Serialization.Decoder` module for the serialization format.
  """
  @callback decoder :: module

  @doc """
  The `RDF.Serialization.Encoder` module for the serialization format.
  """
  @callback encoder :: module

  defmacro __using__(_) do
    # credo:disable-for-next-line Credo.Check.Refactor.LongQuoteBlocks
    quote bind_quoted: [], unquote: true do
      @behaviour unquote(__MODULE__)

      @decoder __MODULE__.Decoder
      @encoder __MODULE__.Encoder

      @impl unquote(__MODULE__)
      def decoder, do: @decoder

      @impl unquote(__MODULE__)
      def encoder, do: @encoder

      defoverridable unquote(__MODULE__)

      @decoder_doc_ref """
      See the [module documentation of the decoder](`#{@decoder}`) for the
      available format-specific options, all of which can be used in this
      function and will be passed them through to the decoder.
      """

      @doc """
      Deserializes a graph or dataset from a string.

      It returns an `{:ok, data}` tuple, with `data` being the deserialized graph or
      dataset, or `{:error, reason}` if an error occurs.

      #{@decoder_doc_ref}
      """
      @spec read_string(String.t(), keyword) :: {:ok, Graph.t() | Dataset.t()} | {:error, any}
      def read_string(content, opts \\ []), do: Reader.read_string(decoder(), content, opts)

      @doc """
      Deserializes a graph or dataset from a string.

      As opposed to `read_string/2`, it raises an exception if an error occurs.

      #{@decoder_doc_ref}
      """
      @spec read_string!(String.t(), keyword) :: Graph.t() | Dataset.t()
      def read_string!(content, opts \\ []), do: Reader.read_string!(decoder(), content, opts)

      @doc """
      Deserializes a graph or dataset from a stream.

      It returns an `{:ok, data}` tuple, with `data` being the deserialized graph or
      dataset, or `{:error, reason}` if an error occurs.

      #{@decoder_doc_ref}
      """
      @spec read_stream(Enumerable.t(), keyword) :: {:ok, Graph.t() | Dataset.t()} | {:error, any}
      def read_stream(stream, opts \\ []), do: Reader.read_stream(decoder(), stream, opts)

      @doc """
      Deserializes a graph or dataset from a stream.

      As opposed to `read_stream/2`, it raises an exception if an error occurs.

      #{@decoder_doc_ref}
      """
      @spec read_stream!(Enumerable.t(), keyword) :: Graph.t() | Dataset.t()
      def read_stream!(stream, opts \\ []), do: Reader.read_stream!(decoder(), stream, opts)

      @doc """
      Deserializes a graph or dataset from a file.

      It returns an `{:ok, data}` tuple, with `data` being the deserialized graph or
      dataset, or `{:error, reason}` if an error occurs.

      ## Options

      General serialization-independent options:

      - `:stream`: Allows to enable reading the data from a file directly via a
      stream (default: `false` on this function, `true` on the bang version)
      - `:gzip`: Allows to read directly from a gzipped file (default: `false`)
      - `:file_mode`: A list with the Elixir `File.open` modes to be used for reading
        (default: `[:read, :utf8]`)

      #{@decoder_doc_ref}
      """
      @spec read_file(Path.t(), keyword) :: {:ok, Graph.t() | Dataset.t()} | {:error, any}
      def read_file(file, opts \\ []), do: Reader.read_file(decoder(), file, opts)

      @doc """
      Deserializes a graph or dataset from a file.

      As opposed to `read_file/2`, it raises an exception if an error occurs and
      defaults to `stream: true`.

      See `read_file/3` for the available format-independent options.

      #{@decoder_doc_ref}
      """
      @spec read_file!(Path.t(), keyword) :: Graph.t() | Dataset.t()
      def read_file!(file, opts \\ []), do: Reader.read_file!(decoder(), file, opts)

      @encoder_doc_ref """
      See the [module documentation of the encoder](`#{@encoder}`) for the
      available format-specific options, all of which can be used in this
      function and will be passed them through to the encoder.
      """

      @doc """
      Serializes an RDF data structure to a string.

      It returns an `{:ok, string}` tuple, with `string` being the serialized graph or
      dataset, or `{:error, reason}` if an error occurs.

      #{@encoder_doc_ref}
      """
      @spec write_string(RDF.Data.t(), keyword) :: {:ok, String.t()} | {:error, any}
      def write_string(data, opts \\ []), do: Writer.write_string(encoder(), data, opts)

      @doc """
      Serializes an RDF data structure to a string.

      As opposed to `write_string/2`, it raises an exception if an error occurs.

      #{@encoder_doc_ref}
      """
      @spec write_string!(RDF.Data.t(), keyword) :: String.t()
      def write_string!(data, opts \\ []), do: Writer.write_string!(encoder(), data, opts)

      if @encoder.stream_support?() do
        @doc """
        Serializes an RDF data structure to a stream.

        #{@encoder_doc_ref}
        """
        @spec write_stream(RDF.Data.t(), keyword) :: Enumerable.t()
        def write_stream(data, opts \\ []), do: Writer.write_stream(encoder(), data, opts)
      end

      @doc """
      Serializes an RDF data structure to a file.

      It returns `:ok` if successful or `{:error, reason}` if an error occurs.

      ## Options

      General serialization-independent options:

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

      #{@encoder_doc_ref}
      """
      @spec write_file(RDF.Data.t(), Path.t(), keyword) :: :ok | {:error, any}
      def write_file(data, path, opts \\ []), do: Writer.write_file(encoder(), data, path, opts)

      @doc """
      Serializes an RDF data structure to a file.

      As opposed to `write_file/3`, it raises an exception if an error occurs.

      See `write_file/3` for the available format-independent options.

      #{@encoder_doc_ref}
      """
      @spec write_file!(RDF.Data.t(), Path.t(), keyword) :: :ok
      def write_file!(data, path, opts \\ []), do: Writer.write_file!(encoder(), data, path, opts)

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      if !Module.defines?(__MODULE__, {:id, 0}) &&
           Module.get_attribute(__MODULE__, :id) do
        @impl unquote(__MODULE__)
        def id, do: @id
      end

      if !Module.defines?(__MODULE__, {:name, 0}) &&
           Module.get_attribute(__MODULE__, :name) do
        @impl unquote(__MODULE__)
        def name, do: @name
      end

      if !Module.defines?(__MODULE__, {:extension, 0}) &&
           Module.get_attribute(__MODULE__, :extension) do
        @impl unquote(__MODULE__)
        def extension, do: @extension
      end

      if !Module.defines?(__MODULE__, {:media_type, 0}) &&
           Module.get_attribute(__MODULE__, :media_type) do
        @impl unquote(__MODULE__)
        def media_type, do: @media_type
      end
    end
  end
end
