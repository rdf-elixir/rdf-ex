defmodule RDF.Double do
  use RDF.Datatype, id: RDF.Datatype.NS.XSD.double

  def convert(value, _) when is_float(value),   do: value
  def convert(value, _) when is_integer(value), do: value / 1
  def convert(value, _) when is_binary(value),  do: String.to_float(value)
#  def convert(false, _), do: 0.0
#  def convert(true, _),  do: 1.0

end
