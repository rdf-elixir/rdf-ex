defmodule RDF.NQuads.Encoder do
  @moduledoc false

  use RDF.Serialization.Encoder

  alias RDF.{Dataset, Graph, Quad, Statement, Triple}

  @impl RDF.Serialization.Encoder
  @callback encode(Graph.t() | Dataset.t(), keyword | map) :: {:ok, String.t()} | {:error, any}
  def encode(data, _opts \\ []) do
    result =
      data
      |> Enum.reduce([], fn statement, result -> [statement(statement) | result] end)
      |> Enum.reverse()
      |> Enum.join("\n")

    {:ok, if(result == "", do: result, else: "#{result}\n")}
  end

  @spec statement({Statement.subject(), Statement.predicate(), Statement.object(), nil}) ::
          String.t()
  def statement({subject, predicate, object, nil}) do
    statement({subject, predicate, object})
  end

  @spec statement(Quad.t()) :: String.t()
  def statement({subject, predicate, object, graph}) do
    "#{term(subject)} #{term(predicate)} #{term(object)} #{term(graph)} ."
  end

  @spec statement(Triple.t()) :: String.t()
  def statement({subject, predicate, object}) do
    "#{term(subject)} #{term(predicate)} #{term(object)} ."
  end

  defdelegate term(value), to: RDF.NTriples.Encoder
end
