defmodule RDF.BlankNode.Generator.Increment do
  @moduledoc """
  An implementation of a `RDF.BlankNode.Generator.Algorithm` which returns `RDF.BlankNode`s with incremented identifiers.
  """

  @behaviour RDF.BlankNode.Generator.Algorithm

  defstruct prefix: "b", map: %{}, counter: 0

  @type t :: %__MODULE__{
          prefix: String.t(),
          map: map,
          counter: pos_integer
        }

  alias RDF.BlankNode

  @doc """
  Creates a struct with the state of the algorithm.

  ## Options

  - `prefix`: a string prepended to the generated blank node identifier
  - `counter`: the number from which the incremented counter starts
  """
  def new(opts \\ []) do
    struct(__MODULE__, opts)
  end

  @impl BlankNode.Generator.Algorithm
  def generate(%__MODULE__{counter: counter} = state) do
    {bnode(state, counter), %{state | counter: counter + 1}}
  end

  @impl BlankNode.Generator.Algorithm
  def generate_for(%__MODULE__{map: map, counter: counter} = state, value) do
    case Map.get(map, value) do
      nil ->
        {bnode(state, counter),
         %{state | map: Map.put(map, value, counter), counter: counter + 1}}

      previous ->
        {bnode(state, previous), state}
    end
  end

  defp bnode(%__MODULE__{prefix: nil}, counter) do
    BlankNode.new(counter)
  end

  defp bnode(%__MODULE__{} = state, counter) do
    BlankNode.new(state.prefix <> Integer.to_string(counter))
  end
end
