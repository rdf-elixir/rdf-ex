defmodule RDF.XSD.String do
  @moduledoc """
  `RDF.XSD.Datatype` for XSD strings.
  """

  @type valid_value :: String.t()

  use RDF.XSD.Datatype.Primitive,
    name: "string",
    id: RDF.Utils.Bootstrapping.xsd_iri("string")

  @impl RDF.XSD.Datatype
  @spec lexical_mapping(String.t(), Keyword.t()) :: valid_value
  def lexical_mapping(lexical, _), do: to_string(lexical)

  @impl RDF.XSD.Datatype
  @spec elixir_mapping(any, Keyword.t()) :: value
  def elixir_mapping(value, _), do: to_string(value)

  @impl RDF.Literal.Datatype
  def do_cast(value)

  def do_cast(%RDF.XSD.Decimal{} = xsd_decimal) do
    try do
      xsd_decimal.value
      |> Decimal.to_integer()
      |> RDF.XSD.Integer.new()
      |> cast()
    rescue
      _ ->
        default_canonical_cast(xsd_decimal, RDF.XSD.Decimal)
    end
  end

  def do_cast(%datatype{} = xsd_double) when datatype in [RDF.XSD.Double, RDF.XSD.Float] do
    cond do
      RDF.XSD.Numeric.negative_zero?(xsd_double) ->
        new("-0")

      RDF.XSD.Numeric.zero?(xsd_double) ->
        new("0")

      xsd_double.value >= 0.000_001 and xsd_double.value < 1_000_000 ->
        xsd_double.value
        |> RDF.XSD.Decimal.new()
        |> cast()

      true ->
        default_canonical_cast(xsd_double, datatype)
    end
  end

  def do_cast(%RDF.XSD.DateTime{} = xsd_datetime) do
    xsd_datetime
    |> RDF.XSD.DateTime.canonical_lexical_with_zone()
    |> new()
  end

  def do_cast(%RDF.XSD.Time{} = xsd_time) do
    xsd_time
    |> RDF.XSD.Time.canonical_lexical_with_zone()
    |> new()
  end

  def do_cast(%datatype{} = literal) do
    if RDF.XSD.datatype?(datatype) do
      default_canonical_cast(literal, datatype)
    end
  end

  def do_cast(literal_or_value), do: super(literal_or_value)

  defp default_canonical_cast(literal, datatype) do
    literal
    |> datatype.canonical_lexical()
    |> new()
  end
end
