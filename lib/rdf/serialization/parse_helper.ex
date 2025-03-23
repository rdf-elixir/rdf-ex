defmodule RDF.Serialization.ParseHelper do
  @moduledoc false

  alias RDF.{IRI, BlankNode, Literal}

  @rdf_type RDF.Utils.Bootstrapping.rdf_iri("type")
  def rdf_type, do: @rdf_type

  def to_iri_string({:iriref, _line, value}), do: iri_unescape(value)

  def to_iri({:iriref, line, value}) do
    iri = IRI.new(iri_unescape(value))

    if IRI.valid?(iri) do
      {:ok, iri}
    else
      {:error, line, "#{value} is not a valid IRI"}
    end
  end

  def to_absolute_or_relative_iri({:iriref, line, value}) do
    iri = IRI.new(iri_unescape(value))

    cond do
      not IRI.absolute?(iri) -> {:relative_iri, value}
      IRI.valid?(iri) -> {:ok, iri}
      true -> RDF.IRI.InvalidError.exception("Invalid IRI #{inspect(iri)} at line #{line}")
    end
  end

  def to_bnode({:blank_node_label, _line, value}), do: BlankNode.new(value)
  def to_bnode({:anon, _line}), do: BlankNode.new()

  def to_literal({:string_literal_quote, _line, value}),
    do: value |> string_unescape |> Literal.new()

  def to_literal({:integer, _line, value}), do: Literal.new(value)
  def to_literal({:decimal, _line, value}), do: Literal.new(value)
  def to_literal({:double, _line, value}), do: Literal.new(value)
  def to_literal({:boolean, _line, value}), do: Literal.new(value)

  def to_literal({:string_literal_quote, _line, value}, {:language, language}),
    do: value |> string_unescape |> Literal.new(language: language)

  def to_literal({:string_literal_quote, _line, value}, {:datatype, %IRI{} = type}),
    do: value |> string_unescape |> Literal.new(datatype: type)

  def to_literal(string_literal_quote_ast, type),
    do: {string_literal_quote_ast, type}

  def integer(value), do: RDF.XSD.Integer.new(List.to_string(value))
  def decimal(value), do: RDF.XSD.Decimal.new(List.to_string(value))
  def double(value), do: RDF.XSD.Double.new(List.to_string(value))
  def boolean(~c"true"), do: true
  def boolean(~c"false"), do: false

  def to_langtag({:langtag, _line, value}), do: value
  def to_langtag({:"@prefix", 1}), do: "prefix"
  def to_langtag({:"@base", 1}), do: "base"

  def bnode_str(~c"_:" ++ value), do: List.to_string(value)
  def langtag_str(~c"@" ++ value), do: List.to_string(value)
  def quoted_content_str(value), do: value |> List.to_string() |> String.slice(1..-2//1)
  def long_quoted_content_str(value), do: value |> List.to_string() |> String.slice(3..-4//1)

  def prefix_ns(value), do: value |> List.to_string() |> String.slice(0..-2//1)

  def prefix_ln(value),
    do: value |> List.to_string() |> String.split(":", parts: 2) |> List.to_tuple()

  def string_unescape(string),
    do: string |> unescape_8digit_unicode_seq |> Macro.unescape_string(&string_unescape_map(&1))

  def iri_unescape(string),
    do: string |> unescape_8digit_unicode_seq |> Macro.unescape_string(&iri_unescape_map(&1))

  defp string_unescape_map(?b), do: ?\b
  defp string_unescape_map(?f), do: ?\f
  defp string_unescape_map(?n), do: ?\n
  defp string_unescape_map(?r), do: ?\r
  defp string_unescape_map(?t), do: ?\t
  defp string_unescape_map(?u), do: true
  defp string_unescape_map(:unicode), do: true
  defp string_unescape_map(e), do: e

  defp iri_unescape_map(?u), do: true
  defp iri_unescape_map(:unicode), do: true
  defp iri_unescape_map(e), do: e

  def unescape_8digit_unicode_seq(string) do
    String.replace(string, ~r/\\U([0-9]|[A-F]|[a-f]){2}(([0-9]|[A-F]|[a-f]){6})/, "\\u{\\2}")
  end

  def error_description(error_descriptor) when is_list(error_descriptor) do
    Enum.map_join(error_descriptor, &to_string/1)
  end

  def error_description(error_descriptor), do: inspect(error_descriptor)
end
