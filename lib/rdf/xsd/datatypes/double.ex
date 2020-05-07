defmodule RDF.XSD.Double do
  @moduledoc """
  `RDF.XSD.Datatype` for XSD doubles.
  """

  @type special_values :: :positive_infinity | :negative_infinity | :nan
  @type valid_value :: float | special_values

  use RDF.XSD.Datatype.Primitive,
    name: "double",
    id: RDF.Utils.Bootstrapping.xsd_iri("double"),
    register: false # core datatypes don't need to be registered

  @special_values ~W[positive_infinity negative_infinity nan]a

  @impl RDF.XSD.Datatype
  def lexical_mapping(lexical, opts) do
    case Float.parse(lexical) do
      {float, ""} ->
        float

      {float, remainder} ->
        # 1.E-8 is not a valid Elixir float literal and consequently not fully parsed with Float.parse
        if Regex.match?(~r/^\.e?[\+\-]?\d+$/i, remainder) do
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

  @impl RDF.XSD.Datatype
  @spec elixir_mapping(valid_value | integer | any, Keyword.t()) :: value
  def elixir_mapping(value, _)
  def elixir_mapping(value, _) when is_float(value), do: value
  def elixir_mapping(value, _) when is_integer(value), do: value / 1
  def elixir_mapping(value, _) when value in @special_values, do: value
  def elixir_mapping(_, _), do: @invalid_value

  @impl RDF.XSD.Datatype
  @spec init_valid_lexical(valid_value, RDF.XSD.Datatype.uncanonical_lexical(), Keyword.t()) ::
          RDF.XSD.Datatype.uncanonical_lexical()
  def init_valid_lexical(value, lexical, opts)
  def init_valid_lexical(value, nil, _) when is_atom(value), do: nil
  def init_valid_lexical(value, nil, _), do: decimal_form(value)
  def init_valid_lexical(_, lexical, _), do: lexical

  defp decimal_form(float), do: to_string(float)

  @impl RDF.XSD.Datatype
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

  if List.to_integer(:erlang.system_info(:otp_release)) >= 21 do
    defp float_to_string(float) do
      :io_lib.format("~.15e", [float])
      |> to_string()
    end
  else
    defp float_to_string(float) do
      :io_lib.format("~.15e", [float])
      |> List.first()
      |> to_string()
    end
  end

  @impl RDF.Literal.Datatype
  def do_cast(value)

  def do_cast(%RDF.XSD.Boolean{value: false}), do: new(0.0)
  def do_cast(%RDF.XSD.Boolean{value: true}), do: new(1.0)

  def do_cast(%RDF.XSD.String{} = xsd_string) do
    xsd_string.value |> new() |> canonical()
  end

  def do_cast(%RDF.XSD.Integer{} = xsd_integer) do
    new(xsd_integer.value)
  end

  def do_cast(%RDF.XSD.Decimal{} = xsd_decimal) do
    xsd_decimal.value
    |> Decimal.to_float()
    |> new()
  end

  def do_cast(literal_or_value), do: super(literal_or_value)

  def equal_value?(left, right), do: RDF.XSD.Numeric.equal_value?(left, right)

  @impl RDF.Literal.Datatype
  def compare(left, right), do: RDF.XSD.Numeric.compare(left, right)
end
