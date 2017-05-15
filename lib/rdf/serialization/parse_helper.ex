defmodule RDF.Serialization.ParseHelper do
  @moduledoc false

  def to_uri({:iriref, line, value}) do
    case URI.parse(value) do
      %URI{scheme: nil} -> {:error, line, "#{value} is not a valid URI"}
      parsed_uri -> {:ok, parsed_uri}
    end
  end

  def to_bnode({:blank_node_label, _line, value}), do: RDF.bnode(value)

  def to_literal({:string_literal_quote, _line, value}),
    do: RDF.literal(value)
  def to_literal({:string_literal_quote, _line, value}, type),
    do: RDF.literal(value, [type])

  def to_langtag({:langtag, _line, value}), do: value

  def bnode_str('_:' ++ value),  do: List.to_string(value)
  def langtag_str('@' ++ value), do: List.to_string(value)
  def quoted_content_str(value), do: value |> List.to_string |> String.slice(1..-2)

end
