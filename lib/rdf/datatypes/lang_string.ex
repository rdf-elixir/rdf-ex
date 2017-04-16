defmodule RDF.LangString do
  use RDF.Datatype, id: RDF.langString

  def convert(value, _) when is_binary(value), do: value

  def build_literal(value, %{language: language} = opts) do
    %Literal{value: value, datatype: @id, language: String.downcase(language)}
  end

  def build_literal(value, opts) do
    raise ArgumentError, "datatype of rdf:langString requires a language"
  end

end
