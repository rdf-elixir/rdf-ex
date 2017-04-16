defmodule RDF.Integer do
  use RDF.Datatype, id: RDF.Datatype.NS.XSD.integer

  def convert(value, _) when is_integer(value), do: value
  def convert(value, _) when is_binary(value),  do: String.to_integer(value)
  def convert(false, _), do: 0
  def convert(true, _),  do: 1

end
