defmodule RDF.Serialization do
  @moduledoc """
  A behaviour for RDF serialization formats.

  A `RDF.Serialization` for a format can be implemented like this

      defmodule SomeFormat do
        use RDF.Serialization
        import RDF.Sigils

        @id           ~I<http://example.com/some_format>
        @extension    "ext"
        @content_type "application/some-format"
      end

  When `@id`, `@extension` and `@content_type` module attributes are defined the
  resp. behaviour functions are generated automatically and return these values.

  Then you'll have to do the main work by implementing a
  `RDF.Serialization.Encoder` and a `RDF.Serialization.Decoder` for the format.

  By default it is assumed that these are defined in `Encoder` and `Decoder`
  moduler under the `RDF.Serialization` module of the format, i.e. in the example
  above in `SomeFormat.Encoder` and `SomeFormat.Decoder`. If you want them in
  another module, you'll have to override the `encoder/0` and/or `decoder/0`
  functions in your `RDF.Serialization` module.
  """

  @doc """
  An URI of the serialization format.
  """
  @callback id :: URI.t

  @doc """
  The usual file extension for the serialization format.
  """
  @callback extension :: binary

  @doc """
  The MIME type of the serialization format.
  """
  @callback content_type :: binary

  @doc """
  A map with the supported options of the `Encoder` and `Decoder` for the serialization format.
  """
  @callback options :: map

  @doc """
  The `RDF.Serialization.Decoder` module for the serialization format.
  """
  @callback decoder :: module

  @doc """
  The `RDF.Serialization.Encoder` module for the serialization format.
  """
  @callback encoder :: module


  defmacro __using__(_) do
    quote bind_quoted: [], unquote: true do
      @behaviour unquote(__MODULE__)

      @decoder __MODULE__.Decoder
      @encoder __MODULE__.Encoder

      def decoder, do: @decoder
      def encoder, do: @encoder

      def options, do: %{}

      defoverridable [decoder: 0, encoder: 0, options: 0]

      def read_string(content, opts \\ []),
        do: RDF.Reader.read_string(decoder(), content, opts)
      def read_string!(content, opts \\ []),
        do: RDF.Reader.read_string!(decoder(), content, opts)
      def read_file(file, opts \\ []),
        do: RDF.Reader.read_file(decoder(), file, opts)
      def read_file!(file, opts \\ []),
        do: RDF.Reader.read_file!(decoder(), file, opts)

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      if !Module.defines?(__MODULE__, {:id, 0}) &&
          Module.get_attribute(__MODULE__, :id) do
        def id, do: @id
      end
      if !Module.defines?(__MODULE__, {:extension, 0}) &&
          Module.get_attribute(__MODULE__, :extension) do
        def extension, do: @extension
      end
      if !Module.defines?(__MODULE__, {:content_type, 0}) &&
          Module.get_attribute(__MODULE__, :content_type) do
        def content_type, do: @content_type
      end
    end
  end

end
