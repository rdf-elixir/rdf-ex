defmodule RDF.NQuads.Encoder do
  @moduledoc false

  use RDF.Serialization.Encoder

  def encode(data, opts \\ []) do
    result =
      data
      |> Enum.reduce([], fn (statement, result) ->
           [statement(statement) | result]
         end)
      |> Enum.reverse
      |> Enum.join("\n")
    {:ok, (if result == "", do: result, else: result <> "\n")}
  end

  def statement({subject, predicate, object, nil}) do
    statement({subject, predicate, object})
  end

  def statement({subject, predicate, object, graph}) do
    "#{term(subject)} #{term(predicate)} #{term(object)} #{term(graph)} ."
  end

  def statement({subject, predicate, object}) do
    "#{term(subject)} #{term(predicate)} #{term(object)} ."
  end

  defdelegate term(value), to: RDF.NTriples.Encoder

end
