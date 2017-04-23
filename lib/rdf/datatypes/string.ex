defmodule RDF.String do
  use RDF.Datatype, id: RDF.Datatype.NS.XSD.string


  def convert(value, _), do: to_string(value)


  def build_literal_by_lexical(lexical, opts) do
    build_literal(lexical, nil, opts)
  end

end
