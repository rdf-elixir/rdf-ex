defmodule RDF.XSD.Integer do
  @moduledoc """
  `RDF.XSD.Datatype` for XSD integers.

  Although the XSD spec defines integers as derived from `xsd:decimal` we implement
  it here as a primitive datatype for simplicity and performance reasons.
  """

  @type valid_value :: integer

  use RDF.XSD.Datatype.Primitive,
    name: "integer",
    id: RDF.Utils.Bootstrapping.xsd_iri("integer"),
    register: false # core datatypes don't need to be registered

  def_applicable_facet RDF.XSD.Facets.MinInclusive
  def_applicable_facet RDF.XSD.Facets.MaxInclusive

  def min_inclusive_conform?(min_inclusive, value, _lexical) do
    value >= min_inclusive
  end

  def max_inclusive_conform?(max_inclusive, value, _lexical) do
    value <= max_inclusive
  end

  @impl RDF.XSD.Datatype
  def lexical_mapping(lexical, _) do
    case Integer.parse(lexical) do
      {integer, ""} -> integer
      {_, _} -> @invalid_value
      :error -> @invalid_value
    end
  end

  @impl RDF.XSD.Datatype
  @spec elixir_mapping(valid_value | any, Keyword.t()) :: value
  def elixir_mapping(value, _)
  def elixir_mapping(value, _) when is_integer(value), do: value
  def elixir_mapping(_, _), do: @invalid_value

  @impl RDF.Literal.Datatype
  def do_cast(value)

  def do_cast(%RDF.XSD.Boolean{value: false}), do: new(0)
  def do_cast(%RDF.XSD.Boolean{value: true}), do: new(1)

  def do_cast(%RDF.XSD.String{} = xsd_string) do
    xsd_string.value |> new() |> canonical()
  end

  def do_cast(%RDF.XSD.Decimal{} = xsd_decimal) do
    xsd_decimal.value
    |> Decimal.round(0, :down)
    |> Decimal.to_integer()
    |> new()
  end

  def do_cast(%datatype{value: value})
      when datatype in [RDF.XSD.Double, RDF.XSD.Float] and is_float(value) do
    value
    |> trunc()
    |> new()
  end

  def do_cast(literal_or_value), do: super(literal_or_value)

  def equal_value?(left, right), do: RDF.XSD.Numeric.equal_value?(left, right)

  @impl RDF.Literal.Datatype
  def compare(left, right), do: RDF.XSD.Numeric.compare(left, right)

  @doc """
  The number of digits in the XML Schema canonical form of the literal value.
  """
  @spec digit_count(RDF.XSD.Literal.t()) :: non_neg_integer | nil
  def digit_count(%datatype{} = literal) do
    if derived?(literal) and datatype.valid?(literal) do
      literal
      |> datatype.canonical()
      |> datatype.lexical()
      |> String.replace("-", "")
      |> String.length()
    end
  end
end
