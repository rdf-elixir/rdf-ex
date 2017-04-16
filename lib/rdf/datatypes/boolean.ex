defmodule RDF.Boolean do
  use RDF.Datatype, id: RDF.Datatype.NS.XSD.boolean

  def convert(value, _) when is_boolean(value), do: value
  def convert(value, _) when is_integer(value), do: value == 1
  def convert(value, _) when is_binary(value),  do: String.downcase(value) == "true"

end
