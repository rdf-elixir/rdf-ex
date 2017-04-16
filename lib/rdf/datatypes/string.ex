defmodule RDF.String do
  use RDF.Datatype, id: RDF.Datatype.NS.XSD.string

  def convert(value, _), do: to_string(value)

end
