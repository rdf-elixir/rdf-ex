defmodule RDF.Datatype do
  @moduledoc """
  A behaviour for natively supported literal datatypes.

  A `RDF.Datatype` implements the foundational functions for the lexical form,
  the validation, conversion and canonicalization of typed `RDF.Literal`s.
  """

  alias RDF.Literal
  alias RDF.Datatype.NS.XSD

  @doc """
  The URI of the datatype.
  """
  @callback id :: URI.t

  @doc """
  Produces the lexical form of a `RDF.Literal`.
  """
  @callback lexical(literal :: RDF.Literal.t) :: any

  @doc """
  Produces the lexical form of a value.
  """
  @callback canonical_lexical(any) :: binary

  @doc """
  Produces the lexical form of an invalid value of a typed Literal.

  The default implementation of the `_using__` macro just returns `to_string`
  representation of the value.
  """
  @callback invalid_lexical(any) :: binary

  @doc """
  Produces the canonical form of a `RDF.Literal`.
  """
  @callback canonical(literal :: RDF.Literal.t) :: RDF.Literal.t

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

  @doc """
  Determines if the value of a `RDF.Literal` is a member of lexical value space of its datatype.
  """
  @callback valid?(literal :: RDF.Literal.t) :: boolean


  @lang_string RDF.uri("http://www.w3.org/1999/02/22-rdf-syntax-ns#langString")

  # TODO: This mapping should be created dynamically and be extendable, to allow user-defined datatypes ...
  @mapping %{
    @lang_string => RDF.LangString,
    XSD.string   => RDF.String,
    XSD.integer  => RDF.Integer,
    XSD.double   => RDF.Double,
    XSD.boolean  => RDF.Boolean,
    XSD.date     => RDF.Date,
    XSD.time     => RDF.Time,
    XSD.dateTime => RDF.DateTime,
  }

  @doc """
  The mapping of URIs of datatypes to their `RDF.Datatype`.
  """
  def mapping, do: @mapping

  @doc """
  The URIs of all datatypes with a `RDF.Datatype` defined.
  """
  def ids,     do: Map.keys(@mapping)

  @doc """
  All defined `RDF.Datatype` modules.
  """
  def modules, do: Map.values(@mapping)

  @doc """
  Returns the `RDF.Datatype` for a directly datatype URI or the datatype URI of a `RDF.Literal`.
  """
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
