defmodule RDF.NTriples.Encoder do
  @moduledoc false

  use RDF.Serialization.Encoder

  alias RDF.{BlankNode, Dataset, Graph, IRI, Literal, Statement, Triple}

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

  def term(%Literal{value: value, language: language}) when not is_nil(language) do
    ~s["#{value}"@#{language}]
  end

  def term(%Literal{value: value, language: language}) when not is_nil(language) do
    ~s["#{value}"@#{language}]
  end

  def term(%Literal{datatype: datatype} = literal) when is_xsd_string(datatype) do
    ~s["#{Literal.lexical(literal)}"]
  end

  def term(%Literal{datatype: datatype} = literal) do
    ~s["#{Literal.lexical(literal)}"^^<#{to_string(datatype)}>]
  end

  def term(%BlankNode{} = bnode) do
    to_string(bnode)
  end

end
