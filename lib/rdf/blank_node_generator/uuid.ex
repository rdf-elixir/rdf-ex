defmodule RDF.BlankNode.Generator.UUID do
  @moduledoc """
  An implementation of a `RDF.BlankNode.Generator.Algorithm` which returns `RDF.BlankNode`s with random UUID identifiers.
  """

  @behaviour RDF.BlankNode.Generator.Algorithm

  defstruct prefix: "b"

  @type t :: %__MODULE__{prefix: String.t()}

  alias RDF.BlankNode
  alias Uniq.UUID

  @doc """
  Creates a struct with the state of the algorithm.

  ## Options

  - `prefix`: a string prepended to the generated blank node identifier
  """
  def new(attrs \\ []) do
    struct(__MODULE__, attrs)
  end

  @impl BlankNode.Generator.Algorithm
  def generate(%__MODULE__{} = state) do
    {bnode(state, uuid()), state}
  end

  @impl BlankNode.Generator.Algorithm
  def generate_for(%__MODULE__{} = state, value) do
    {bnode(state, uuid_for(value)), state}
  end

  defp bnode(%__MODULE__{prefix: nil}, uuid), do: BlankNode.new(uuid)
  defp bnode(%__MODULE__{} = state, uuid), do: BlankNode.new(state.prefix <> uuid)

  defp uuid, do: UUID.uuid4(:hex) |> String.downcase()

  # 74fdf771-1a01-5e8f-a491-1c9e61f1adc6
  @uuid_namespace UUID.uuid5(:url, "https://rdf-elixir.dev/blank-node-generator/uuid")

  defp uuid_for(value) when is_binary(value),
    do: UUID.uuid5(@uuid_namespace, value, :hex) |> String.downcase()

  defp uuid_for(value),
    do: value |> :erlang.term_to_binary() |> uuid_for()
end
