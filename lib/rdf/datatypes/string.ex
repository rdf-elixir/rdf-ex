defmodule RDF.String do
  @moduledoc """
  `RDF.Datatype` for XSD string.
  """

  use RDF.Datatype, id: RDF.Datatype.NS.XSD.string

  alias RDF.Datatype.NS.XSD


  def new(value, opts) when is_list(opts),
    do: new(value, Map.new(opts))
  def new(value, %{language: language} = opts) when not is_nil(language),
    do: RDF.LangString.new!(value, opts)
  def new(value, opts),
    do: super(value, opts)

  def new!(value, opts) when is_list(opts),
    do: new!(value, Map.new(opts))
  def new!(value, %{language: language} = opts) when not is_nil(language),
    do: RDF.LangString.new!(value, opts)
  def new!(value, opts),
    do: super(value, opts)


  def build_literal_by_lexical(lexical, opts) do
    build_literal(lexical, nil, opts)
  end


  def convert(value, _), do: to_string(value)


  def cast(%RDF.IRI{value: value}), do: new(value)

  def cast(%RDF.Literal{datatype: datatype} = literal) do
    cond do
      not RDF.Literal.valid?(literal) ->
        nil

      datatype == XSD.string ->
        literal

      datatype == XSD.decimal ->
        try do
          literal.value
          |> Decimal.to_integer()
          |> RDF.Integer.new()
          |> cast()
        rescue
         _ ->
           literal.value
           |> RDF.Decimal.canonical_lexical()
           |> new()
        end

      datatype in [XSD.double, XSD.float] ->
        cond do
          RDF.Numeric.negative_zero?(literal) ->
            new("-0")

          RDF.Numeric.zero?(literal) ->
            new("0")

          literal.value >= 0.000_001 and literal.value < 1000000 ->
            literal.value
            |> RDF.Decimal.new()
            |> cast()

          true ->
            literal.value
            |> RDF.Double.canonical_lexical()
            |> new()
        end

      datatype == XSD.dateTime ->
        literal
        |> RDF.DateTime.canonical_lexical_with_zone()
        |> new()

      datatype == XSD.time ->
        literal
        |> RDF.Time.canonical_lexical_with_zone()
        |> new()

      true ->
        literal
        |> RDF.Literal.canonical()
        |> RDF.Literal.lexical()
        |> new()
    end
  end

end
