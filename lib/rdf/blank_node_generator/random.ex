defmodule RDF.BlankNode.Generator.Random do
  @moduledoc """
  An implementation of a `RDF.BlankNode.Generator.Algorithm` which returns `RDF.BlankNode`s with random identifiers.

  Note, although this generator is faster than the `RDF.BlankNode.Generator.UUID` generator,
  which also produces random identifiers, the random identifiers produced by
  `RDF.BlankNode.Generator.Random` are not unique across multiple application runs,
  since they are based on numbers returned by `:erlang.unique_integer/1`.
  """

  @behaviour RDF.BlankNode.Generator.Algorithm

  defstruct prefix: "b", map: %{}

  @type t :: %__MODULE__{
          prefix: String.t(),
          map: map
        }

  alias RDF.BlankNode

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
    {bnode(state, number(state)), state}
  end

  @impl BlankNode.Generator.Algorithm
  def generate_for(%__MODULE__{map: map} = state, value) do
    case Map.get(map, value) do
      nil ->
        random = number(state)
        {bnode(state, random), %{state | map: Map.put(map, value, random)}}

      previous ->
        {bnode(state, previous), state}
    end
  end

  defp bnode(%__MODULE__{prefix: nil}, random) do
    BlankNode.new(random)
  end

  defp bnode(%__MODULE__{} = state, random) do
    BlankNode.new(state.prefix <> random)
  end

  defp number(_), do: :erlang.unique_integer([:positive]) |> Integer.to_string()
end
