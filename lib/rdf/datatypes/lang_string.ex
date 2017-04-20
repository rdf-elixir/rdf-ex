defmodule RDF.LangString do
  use RDF.Datatype, id: RDF.langString

  def convert(value, _) when is_binary(value), do: value

  def build_literal_by_lexical(lexical, %{language: language} = opts) do
    %Literal{
      lexical: lexical, value: lexical, datatype: @id,
      language: String.downcase(language)}
  end

  def build_literal_by_lexical(value, opts) do
    raise ArgumentError, "datatype of rdf:langString requires a language"
  end

end
