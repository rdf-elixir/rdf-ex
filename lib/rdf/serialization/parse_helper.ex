defmodule RDF.Serialization.ParseHelper do
  @moduledoc false

  alias RDF.IRI
  alias RDF.Datatype.NS.XSD

  @rdf_type RDF.iri("http://www.w3.org/1999/02/22-rdf-syntax-ns#type")
  def rdf_type, do: @rdf_type


  def to_iri_string({:iriref, _line, value}), do: value |> iri_unescape

  def to_iri({:iriref, line, value}) do
    with iri = RDF.iri(iri_unescape(value)) do
      if IRI.valid?(iri) do
        {:ok, iri}
      else
        {:error, line, "#{value} is not a valid IRI"}
      end
    end
  end

  def to_absolute_or_relative_iri({:iriref, _line, value}) do
    with iri = RDF.iri(iri_unescape(value)) do
      if IRI.absolute?(iri) do
        iri
      else
        {:relative_iri, value}
      end
    end
  end


  def to_bnode({:blank_node_label, _line, value}), do: RDF.bnode(value)
  def to_bnode({:anon, _line}), do: RDF.bnode

  def to_literal({:string_literal_quote, _line, value}),
    do: value |> string_unescape |> RDF.literal
  def to_literal({:integer, _line, value}), do: RDF.literal(value)
  def to_literal({:decimal, _line, value}), do: RDF.literal(value)
  def to_literal({:double,  _line, value}), do: RDF.literal(value)
  def to_literal({:boolean,  _line, value}), do: RDF.literal(value)
  def to_literal({:string_literal_quote, _line, value}, {:language, language}),
    do: value |> string_unescape |> RDF.literal(language: language)
  def to_literal({:string_literal_quote, _line, value}, {:datatype, %IRI{} = type}),
    do: value |> string_unescape |> RDF.literal(datatype: type)
  def to_literal(string_literal_quote_ast, type),
    do: {string_literal_quote_ast, type}

  def integer(value),   do: RDF.Integer.new(List.to_string(value))
  def decimal(value),   do: RDF.Literal.new(List.to_string(value), datatype: XSD.decimal)
  def double(value),    do: RDF.Double.new(List.to_string(value))
  def boolean('true'),  do: true
  def boolean('false'), do: false

  def to_langtag({:langtag, _line, value}), do: value
  def to_langtag({:"@prefix", 1}), do: "prefix"
  def to_langtag({:"@base", 1}),   do: "base"

  def bnode_str('_:' ++ value),       do: List.to_string(value)
  def langtag_str('@' ++ value),      do: List.to_string(value)
  def quoted_content_str(value),      do: value |> List.to_string |> String.slice(1..-2)
  def long_quoted_content_str(value), do: value |> List.to_string |> String.slice(3..-4)

  def prefix_ns(value), do: value |> List.to_string |> String.slice(0..-2)
  def prefix_ln(value), do: value |> List.to_string |> String.split(":", parts: 2) |> List.to_tuple


  def string_unescape(string),
    do: string |> unescape_8digit_unicode_seq |> Macro.unescape_string(&string_unescape_map(&1))
  def iri_unescape(string),
    do: string |> unescape_8digit_unicode_seq |> Macro.unescape_string(&iri_unescape_map(&1))

  defp string_unescape_map(?b),  do: ?\b
  defp string_unescape_map(?f),  do: ?\f
  defp string_unescape_map(?n),  do: ?\n
  defp string_unescape_map(?r),  do: ?\r
  defp string_unescape_map(?t),  do: ?\t
  defp string_unescape_map(?u),  do: true
  defp string_unescape_map(:unicode),  do: true
  defp string_unescape_map(e),   do: e

  defp iri_unescape_map(?u),  do: true
  defp iri_unescape_map(:unicode),  do: true
  defp iri_unescape_map(e),   do: e

  def unescape_8digit_unicode_seq(string) do
    String.replace(string, ~r/\\U([0-9]|[A-F]|[a-f]){2}(([0-9]|[A-F]|[a-f]){6})/, "\\u{\\2}")
  end
end
