defmodule RDF.Serialization.ParseHelper do
  @moduledoc false

  alias RDF.Datatype.NS.XSD

  @rdf_type RDF.uri("http://www.w3.org/1999/02/22-rdf-syntax-ns#type")
  def rdf_type, do: @rdf_type


  def to_uri_string({:iriref, line, value}), do: value

  def to_uri({:iriref, line, value}) do
    case URI.parse(value) do
      %URI{scheme: nil} -> {:error, line, "#{value} is not a valid URI"}
      parsed_uri -> {:ok, parsed_uri}
    end
  end

  def to_absolute_or_relative_uri({:iriref, line, value}) do
    case URI.parse(value) do
      uri = %URI{scheme: scheme} when not is_nil(scheme) -> uri
      _ -> {:relative_uri, value}
    end
  end


  def to_bnode({:blank_node_label, _line, value}), do: RDF.bnode(value)
  def to_bnode({:anon, _line}), do: RDF.bnode # TODO:

  def to_literal({:string_literal_quote, _line, value}),
    do: RDF.literal(value)
  def to_literal({:integer, _line, value}), do: RDF.literal(value)
  def to_literal({:decimal, _line, value}), do: RDF.literal(value)
  def to_literal({:double,  _line, value}), do: RDF.literal(value)
  def to_literal({:boolean,  _line, value}), do: RDF.literal(value)
  def to_literal({:string_literal_quote, _line, value}, {:language, language}),
    do: RDF.literal(value, language: language)
  def to_literal({:string_literal_quote, _line, value}, {:datatype, %URI{} = type}),
    do: RDF.literal(value, datatype: type)
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

end
