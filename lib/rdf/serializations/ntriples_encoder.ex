defmodule RDF.NTriples.Encoder do
  @moduledoc false

  use RDF.Serialization.Encoder

  alias RDF.{BlankNode, Dataset, Graph, IRI, XSD, Literal, Statement, Triple, LangString}

  @impl RDF.Serialization.Encoder
  @callback encode(Graph.t | Dataset.t, keyword | map) :: {:ok, String.t} | {:error, any}
  def encode(data, _opts \\ []) do
    result =
      data
      |> Enum.reduce([], fn (statement, result) ->
           [statement(statement) | result]
         end)
      |> Enum.reverse
      |> Enum.join("\n")
    {:ok, (if result == "", do: result, else: result <> "\n")}
  end

  @spec statement(Triple.t) :: String.t
  def statement({subject, predicate, object}) do
    "#{term(subject)} #{term(predicate)} #{term(object)} ."
  end

  @spec term(Statement.subject | Statement.predicate | Statement.object) :: String.t
  def term(%IRI{} = iri) do
    "<#{to_string(iri)}>"
  end

  def term(%Literal{literal: %LangString{} = lang_string}) do
    ~s["#{lang_string.value}"@#{lang_string.language}]
  end

  def term(%Literal{literal: %XSD.String{} = xsd_string}) do
    ~s["#{xsd_string.value}"]
  end

  def term(%Literal{} = literal) do
    ~s["#{Literal.lexical(literal)}"^^<#{to_string(Literal.datatype(literal))}>]
  end

  def term(%BlankNode{} = bnode) do
    to_string(bnode)
  end

end
