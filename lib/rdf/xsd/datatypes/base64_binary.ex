defmodule RDF.XSD.Base64Binary do
  @moduledoc """
  `RDF.XSD.Datatype` for `xsd:base64Binary`.

  See: <https://www.w3.org/TR/xmlschema11-2/#base64Binary>
  """

  @type valid_value :: binary()

  use RDF.XSD.Datatype.Primitive,
    name: "base64Binary",
    id: RDF.Utils.Bootstrapping.xsd_iri("base64Binary")

  alias RDF.XSD

  def_applicable_facet XSD.Facets.MinLength
  def_applicable_facet XSD.Facets.MaxLength
  def_applicable_facet XSD.Facets.Length
  def_applicable_facet XSD.Facets.Pattern

  @doc false
  def min_length_conform?(min_length, value, _lexical) do
    byte_size(value) >= min_length
  end

  @doc false
  def max_length_conform?(max_length, value, _lexical) do
    byte_size(value) <= max_length
  end

  @doc false
  def length_conform?(length, value, _lexical) do
    byte_size(value) == length
  end

  @doc false
  def pattern_conform?(pattern, value, _lexical) do
    XSD.Facets.Pattern.conform?(pattern, value)
  end

  @impl XSD.Datatype
  @spec lexical_mapping(String.t(), Keyword.t()) :: valid_value()
  def lexical_mapping(lexical, _) do
    case Base.decode64(lexical) do
      {:ok, value} ->
        value

      _ ->
        @invalid_value
    end
  end

  @impl XSD.Datatype
  @spec elixir_mapping(any, Keyword.t()) :: nil | valid_value()
  def elixir_mapping(value, _) when is_binary(value), do: value
  def elixir_mapping(_, _), do: @invalid_value

  @impl XSD.Datatype
  @spec canonical_mapping(valid_value()) :: String.t()
  def canonical_mapping(value), do: Base.encode64(value)

  @impl RDF.Literal.Datatype
  def do_cast(value)
  def do_cast(%XSD.String{} = xsd_string), do: new(xsd_string.value, as_value: true)
  def do_cast(literal), do: super(literal)
end
