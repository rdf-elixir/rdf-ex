defmodule RDF.Datatype do
  alias RDF.Literal
  alias RDF.Datatype.NS.XSD

  @callback id :: URI.t

  @callback lexical(RDF.Literal.t) :: any

  @callback canonical_lexical(any) :: binary

  @callback invalid_lexical(any) :: binary

  @callback canonical(RDF.Literal.t) :: RDF.Literal.t

  @doc """
  Converts a value into a proper native value.

  If an invalid value is given an implementation should call `super`, which
  by default currently just returns `nil`.

  Note: If a value is valid is determined by the lexical space of the implemented
    datatype, not by the Elixir semantics. For example, although `42`
    is a falsy value according to the Elixir semantics, this is not an element
    of the lexical value space of an `xsd:boolean`, so the `RDF.Boolean`
    implementation of this datatype calls `super`.
  """
  @callback convert(any, keyword) :: any

  @callback valid?(RDF.Literal.t) :: boolean

  @callback build_literal_by_value(binary, keyword) :: RDF.Literal.t
  @callback build_literal_by_lexical(binary, keyword) :: RDF.Literal.t
  @callback build_literal(any, binary, keyword) :: RDF.Literal.t


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
      def new(value, opts) when is_binary(value),
        do: build_literal_by_lexical(value, opts)
      def new(value, opts),
        do: build_literal_by_value(value, opts)

      def new!(value, opts \\ %{}) do
        literal = new(value, opts)
        if valid?(literal) do
          literal
        else
          raise ArgumentError, "#{inspect value} is not a valid #{inspect __MODULE__}"
        end
      end


      def build_literal_by_value(value, opts) do
        case convert(value, opts) do
          nil ->
            build_literal(nil, invalid_lexical(value), opts)
          converted_value ->
            build_literal(converted_value, nil, opts)
        end
      end

      def build_literal_by_lexical(lexical, opts) do
        case convert(lexical, opts) do
          nil ->
            build_literal(nil, lexical, opts)
          value ->
            if opts[:canonicalize] || lexical == canonical_lexical(value) do
              build_literal(value, nil, opts)
            else
              build_literal(value, lexical, opts)
            end
        end
      end

      def build_literal(value, lexical, %{canonicalize: true} = opts) do
        build_literal(value, lexical, Map.delete(opts, :canonicalize))
        |> canonical
      end

      def build_literal(value, lexical, opts) do
        %Literal{value: value, uncanonical_lexical: lexical, datatype: @id}
      end


      def convert(value, _), do: nil


      def lexical(%RDF.Literal{value: value, uncanonical_lexical: nil}) do
        canonical_lexical(value)
      end

      def lexical(%RDF.Literal{uncanonical_lexical: lexical}) do
        lexical
      end


      def canonical_lexical(value), do: to_string(value)

      def invalid_lexical(value), do: to_string(value)

      def canonical(%Literal{value:               nil} = literal), do: literal
      def canonical(%Literal{uncanonical_lexical: nil} = literal), do: literal
      def canonical(%Literal{} = literal) do
        %Literal{literal | uncanonical_lexical: nil}
      end

      def valid?(%Literal{value: nil}),    do: false
      def valid?(%Literal{datatype: @id}), do: true
      def valid?(_), do: false


      defoverridable [
        build_literal_by_value: 2,
        build_literal_by_lexical: 2,
        build_literal: 3,
        lexical: 1,
        canonical_lexical: 1,
        invalid_lexical: 1,
        convert: 2,
        valid?: 1,
      ]
    end
  end

end
