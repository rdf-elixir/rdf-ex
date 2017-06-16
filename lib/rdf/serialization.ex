defmodule RDF.Serialization do

  @callback id :: URI.t
  @callback extension :: binary
  @callback content_type :: binary
  @callback options :: map

  @callback decoder :: module
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

      def read(file_or_content, opts \\ []),
        do: RDF.Reader.read(decoder(), file_or_content, opts)
      def read!(file_or_content, opts \\ []),
        do: RDF.Reader.read!(decoder(), file_or_content, opts)
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
