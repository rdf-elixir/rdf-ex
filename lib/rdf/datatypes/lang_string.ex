defmodule RDF.LangString do
  @moduledoc """
  `RDF.Datatype` for RDF langString.
  """

  use RDF.Datatype, id: RDF.uri("http://www.w3.org/1999/02/22-rdf-syntax-ns#langString")


  def build_literal(value, lexical, %{language: language} = opts) do
    %Literal{super(value, lexical, opts) | language: String.downcase(language)}
  end

  def build_literal(_, _, _) do
    raise ArgumentError, "datatype of rdf:langString requires a language"
  end


  def convert(value, _), do: to_string(value)


  def valid?(%Literal{language: nil}), do: false
  def valid?(literal), do: super(literal)


end
