defmodule RDF.Datatype do
  alias RDF.Literal
  alias RDF.Datatype.NS.XSD

  @callback id :: URI.t

  @callback convert(any, keyword) :: any

  @callback build_literal_by_value(binary, keyword) :: RDF.Literal.t
  @callback build_literal_by_lexical(binary, keyword) :: RDF.Literal.t
  @callback build_literal_(binary, any, keyword) :: RDF.Literal.t

  @callback canonicalize(RDF.Literal.t | any) :: binary



  # TODO: This mapping should be created dynamically and be extendable, to allow user-defined datatypes ...
  @mapping %{
    RDF.langString => RDF.LangString,
    XSD.string     => RDF.String,
    XSD.integer    => RDF.Integer,
    XSD.double     => RDF.Double,
    XSD.boolean    => RDF.Boolean,
# TODO:
#    XSD.date       => RDF.Date,
#    XSD.time       => RDF.Time,
#    XSD.dateTime   => RDF.DateTime,
  }

  def ids,     do: Map.keys(@mapping)
  def modules, do: Map.values(@mapping)

  def get(%Literal{datatype: id}), do: get(id)
  def get(id), do: @mapping[id]


  defmacro __using__(opts) do
    id = Keyword.fetch!(opts, :id)
    quote bind_quoted: [], unquote: true do
      @behaviour unquote(__MODULE__)

      alias RDF.Literal
      alias RDF.Datatype.NS.XSD

      @id unquote(id)
      def id, do: @id


      def new(value, opts \\ %{})

      def new(value, opts) when is_list(opts),
        do: new(value, Map.new(opts))

      def new(value, %{lexical: lexical} = opts),
        do: build_literal(lexical, value, opts)

      def new(nil, %{lexical: lexical} = opts),
        do: build_literal_by_lexical(lexical, opts)

      def new(value, opts) when is_binary(value),
        do: build_literal_by_lexical(value, opts)

      def new(value, opts),
        do: build_literal_by_value(convert(value, opts), opts)

# TODO:     def new!(value, opts \\ %{})


      def build_literal_by_value(value, opts) do
        build_literal(canonicalize(value), value, opts)
      end

      def build_literal_by_lexical(lexical, opts) do
        build_literal(lexical, convert(lexical, opts), opts)
      end

      def build_literal(lexical, value, _) do
        %Literal{lexical: lexical, value: value, datatype: @id}
      end


      def canonicalize(%Literal{value: value, lexical: nil}),
        do: canonicalize(value)

      def canonicalize(%Literal{lexical: lexical}),
        do: lexical

      def canonicalize(value),
        do: to_string(value)


      defoverridable [
        build_literal_by_value: 2,
        build_literal_by_lexical: 2,
        build_literal: 3,
        canonicalize: 1
      ]
    end
  end

end
