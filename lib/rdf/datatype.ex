defmodule RDF.Datatype do
  alias RDF.Datatype.NS.XSD

  @callback id :: URI.t

  @callback convert(any, keyword) :: any

  @callback build_literal(any, keyword) :: RDF.Literal.t


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

  def for(id), do: @mapping[id]


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

      def new(value, opts),
        do: build_literal(convert(value, opts), opts)

      def build_literal(value, _),
        do: %Literal{value: value, datatype: @id}

      defoverridable [build_literal: 2]
    end
  end

end
