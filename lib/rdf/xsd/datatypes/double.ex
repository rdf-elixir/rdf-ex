defmodule RDF.XSD.Double do
  @moduledoc """
  `RDF.XSD.Datatype` for `xsd:double`.

  See: <https://www.w3.org/TR/xmlschema11-2/#double>
  """

  @type special_values :: :positive_infinity | :negative_infinity | :nan
  @type valid_value :: float | special_values

  @special_values ~W[positive_infinity negative_infinity nan]a

  use RDF.XSD.Datatype.Primitive,
    name: "double",
    id: RDF.Utils.Bootstrapping.xsd_iri("double")

  alias RDF.XSD

  def_applicable_facet XSD.Facets.MinInclusive
  def_applicable_facet XSD.Facets.MaxInclusive
  def_applicable_facet XSD.Facets.MinExclusive
  def_applicable_facet XSD.Facets.MaxExclusive
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
  def pattern_conform?(pattern, _value, lexical) do
    XSD.Facets.Pattern.conform?(pattern, lexical)
  end

  @impl XSD.Datatype
  def lexical_mapping(lexical, opts)
  def lexical_mapping("." <> lexical, opts), do: lexical_mapping("0." <> lexical, opts)

  def lexical_mapping(lexical, opts) do
    case Float.parse(lexical) do
      {float, ""} ->
        float

      {float, "."} ->
        float

      {float, remainder} ->
        # 1.E-8 is not a valid Elixir float literal and consequently not fully parsed with Float.parse
        if RDF.Utils.Regex.match?(~r/^\.e?[\+\-]?\d+$/i, remainder) do
          lexical_mapping(to_string(float) <> String.trim_leading(remainder, "."), opts)
        else
          @invalid_value
        end

      :error ->
        case String.upcase(lexical) do
          "INF" -> :positive_infinity
          "-INF" -> :negative_infinity
          "NAN" -> :nan
          _ -> @invalid_value
        end
    end
  end

  @impl XSD.Datatype
  @spec elixir_mapping(valid_value | integer | any, Keyword.t()) :: value
  def elixir_mapping(value, _)
  def elixir_mapping(value, _) when is_float(value), do: value
  def elixir_mapping(value, _) when is_integer(value), do: :erlang.float(value)
  def elixir_mapping(value, _) when value in @special_values, do: value
  def elixir_mapping(_, _), do: @invalid_value

  @impl XSD.Datatype
  @spec init_valid_lexical(valid_value, XSD.Datatype.uncanonical_lexical(), Keyword.t()) ::
          XSD.Datatype.uncanonical_lexical()
  def init_valid_lexical(value, lexical, opts)
  def init_valid_lexical(value, nil, _) when is_atom(value), do: nil
  def init_valid_lexical(_, nil, _), do: nil
  def init_valid_lexical(_, lexical, _), do: lexical

  @impl XSD.Datatype
  @spec canonical_mapping(valid_value) :: String.t()
  def canonical_mapping(value)

  # Produces the exponential form of a float
  def canonical_mapping(float) when is_float(float) do
    # We can't use simple %f transformation due to special requirements from N3 tests in representation
    [i, f, e] =
      float
      |> float_to_string()
      |> String.split(~r/[\.e]/)

    # remove any trailing zeroes
    f =
      case String.replace(f, ~r/0*$/, "", global: false) do
        # ...but there must be a digit to the right of the decimal point
        "" -> "0"
        f -> f
      end

    e = String.trim_leading(e, "+")

    "#{i}.#{f}E#{e}"
  end

  def canonical_mapping(:nan), do: "NaN"
  def canonical_mapping(:positive_infinity), do: "INF"
  def canonical_mapping(:negative_infinity), do: "-INF"

  defp float_to_string(float) do
    :io_lib.format("~.15e", [float]) |> to_string()
  end

  @impl RDF.Literal.Datatype
  def do_cast(value)

  def do_cast(%XSD.String{} = xsd_string) do
    xsd_string.value |> new() |> canonical()
  end

  def do_cast(literal) do
    cond do
      XSD.Boolean.datatype?(literal) ->
        case literal.value do
          false -> new(0.0)
          true -> new(1.0)
        end

      XSD.Integer.datatype?(literal) ->
        new(literal.value)

      XSD.Decimal.datatype?(literal) ->
        literal.value
        |> Decimal.to_float()
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
end
