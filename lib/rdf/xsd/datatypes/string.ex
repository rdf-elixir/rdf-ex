defmodule RDF.XSD.String do
  @moduledoc """
  `RDF.XSD.Datatype` for `xsd:string`.

  See: <https://www.w3.org/TR/xmlschema11-2/#string>
  """

  @type valid_value :: String.t()

  use RDF.XSD.Datatype.Primitive,
    name: "string",
    id: RDF.Utils.Bootstrapping.xsd_iri("string")

  alias RDF.XSD

  def_applicable_facet XSD.Facets.MinLength
  def_applicable_facet XSD.Facets.MaxLength
  def_applicable_facet XSD.Facets.Length
  def_applicable_facet XSD.Facets.Pattern

  @doc false
  def min_length_conform?(min_length, value, _lexical) do
    String.length(value) >= min_length
  end

  @doc false
  def max_length_conform?(max_length, value, _lexical) do
    String.length(value) <= max_length
  end

  @doc false
  def length_conform?(length, value, _lexical) do
    String.length(value) == length
  end

  @doc false
  def pattern_conform?(pattern, value, _lexical) do
    XSD.Facets.Pattern.conform?(pattern, value)
  end

  @impl XSD.Datatype
  @spec lexical_mapping(String.t(), Keyword.t()) :: valid_value
  def lexical_mapping(lexical, _), do: to_string(lexical)

  @impl XSD.Datatype
  @spec elixir_mapping(any, Keyword.t()) :: value
  def elixir_mapping(value, _), do: to_string(value)

  @impl RDF.Literal.Datatype
  def do_cast(literal_or_iri)

  def do_cast(%RDF.IRI{value: value}), do: new(value)

  def do_cast(%datatype{} = literal) do
    cond do
      XSD.Decimal.datatype?(literal) ->
        try do
          literal.value
          |> Decimal.to_integer()
          |> XSD.Integer.new()
          |> cast()
        rescue
          _ ->
            default_canonical_cast(literal, datatype)
        end

      # we're catching XSD.Floats with this too
      XSD.Double.datatype?(datatype) ->
        cond do
          XSD.Numeric.negative_zero?(literal) ->
            new("-0")

          XSD.Numeric.zero?(literal) ->
            new("0")

          literal.value >= 0.000_001 and literal.value < 1_000_000 ->
            literal.value
            |> XSD.Decimal.new()
            |> cast()

          true ->
            default_canonical_cast(literal, datatype)
        end

      XSD.DateTime.datatype?(literal) ->
        literal
        |> XSD.DateTime.canonical_lexical_with_zone()
        |> new()

      XSD.Time.datatype?(literal) ->
        literal
        |> XSD.Time.canonical_lexical_with_zone()
        |> new()

      RDF.Literal.Datatype.Registry.xsd_datatype_struct?(datatype) ->
        default_canonical_cast(literal, datatype)

      true ->
        super(literal)
    end
  end

  defp default_canonical_cast(literal, datatype) do
    literal
    |> datatype.canonical_lexical()
    |> new()
  end
end
