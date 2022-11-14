defmodule RDF.XSD.Integer do
  @moduledoc """
  `RDF.XSD.Datatype` for `xsd:integer`.

  Although the XSD spec defines integers as derived from `xsd:decimal` we implement
  it here as a primitive datatype for simplicity and performance reasons.

  See: <https://www.w3.org/TR/xmlschema11-2/#integer>
  """

  @type valid_value :: integer

  use RDF.XSD.Datatype.Primitive,
    name: "integer",
    id: RDF.Utils.Bootstrapping.xsd_iri("integer")

  alias RDF.XSD

  def_applicable_facet XSD.Facets.MinInclusive
  def_applicable_facet XSD.Facets.MaxInclusive
  def_applicable_facet XSD.Facets.MinExclusive
  def_applicable_facet XSD.Facets.MaxExclusive
  def_applicable_facet XSD.Facets.TotalDigits
  def_applicable_facet XSD.Facets.Pattern

  @doc false
  def min_inclusive_conform?(min_inclusive, value, _lexical) do
    value >= min_inclusive
  end

  @doc false
  def max_inclusive_conform?(max_inclusive, value, _lexical) do
    value <= max_inclusive
  end

  @doc false
  def min_exclusive_conform?(min_exclusive, value, _lexical) do
    value > min_exclusive
  end

  @doc false
  def max_exclusive_conform?(max_exclusive, value, _lexical) do
    value < max_exclusive
  end

  @doc false
  def total_digits_conform?(total_digits, value, _lexical) do
    digit_count(value) <= total_digits
  end

  @doc false
  def pattern_conform?(pattern, _value, lexical) do
    XSD.Facets.Pattern.conform?(pattern, lexical)
  end

  @impl XSD.Datatype
  def lexical_mapping(lexical, _) do
    case Integer.parse(lexical) do
      {integer, ""} -> integer
      {_, _} -> @invalid_value
      :error -> @invalid_value
    end
  end

  @impl XSD.Datatype
  @spec elixir_mapping(valid_value | any, Keyword.t()) :: value
  def elixir_mapping(value, _)
  def elixir_mapping(value, _) when is_integer(value), do: value
  def elixir_mapping(_, _), do: @invalid_value

  @impl RDF.Literal.Datatype
  def do_cast(value)

  def do_cast(%XSD.String{} = xsd_string) do
    xsd_string.value |> new() |> canonical()
  end

  def do_cast(literal) do
    cond do
      XSD.Boolean.datatype?(literal) ->
        case literal.value do
          false -> new(0)
          true -> new(1)
        end

      XSD.Decimal.datatype?(literal) ->
        literal.value
        |> Decimal.round(0, :down)
        |> Decimal.to_integer()
        |> new()

      # we're catching the XSD.Floats with this too
      is_float(literal.value) and XSD.Double.datatype?(literal) ->
        literal.value
        |> trunc()
        |> new()

      true ->
        super(literal)
    end
  end

  @impl RDF.Literal.Datatype
  def do_equal_value_same_or_derived_datatypes?(left, right),
    do: XSD.Numeric.do_equal_value?(left, right)

  @impl RDF.Literal.Datatype
  def do_equal_value_different_datatypes?(left, right),
    do: XSD.Numeric.do_equal_value?(left, right)

  @impl RDF.Literal.Datatype
  def do_compare(left, right), do: XSD.Numeric.do_compare(left, right)

  @doc """
  The number of digits in the XML Schema canonical form of the literal value.
  """
  @spec digit_count(RDF.Literal.t() | integer) :: non_neg_integer | nil
  def digit_count(%datatype{} = literal) do
    if datatype?(literal) and datatype.valid?(literal) do
      literal
      |> datatype.value()
      |> digit_count()
    end
  end

  def digit_count(integer) when is_integer(integer) do
    integer |> Integer.digits() |> length()
  end
end
