defmodule RDF.BlankNode.Increment do
  @moduledoc """
  An implementation of a `RDF.BlankNode.Generator.Algorithm` which returns `RDF.BlankNode`s with incremented identifiers.

  The following options are supported when starting a `RDF.BlankNode.Generator`
  with this algorithm:

  - `prefix`: a string prepended to the generated blank node identifier
  - `start_value`: the number from which the incremented counter starts

  """

  @behaviour RDF.BlankNode.Generator.Algorithm

  alias RDF.BlankNode

  @impl BlankNode.Generator.Algorithm
  def init(%{prefix: prefix} = opts) do
    opts
    |> Map.delete(:prefix)
    |> init()
    |> Map.put(:prefix, prefix)
  end

  @impl BlankNode.Generator.Algorithm
  def init(opts) do
    %{
      map: %{},
      counter: Map.get(opts, :start_value, 0)
    }
  end

  @impl BlankNode.Generator.Algorithm
  # @spec generate(map) :: {RDF.BlankNode.t, map}
  def generate(%{counter: counter} = state) do
    {bnode(counter, state), %{state | counter: counter + 1}}
  end

  @impl BlankNode.Generator.Algorithm
  def generate_for(value, %{map: map, counter: counter} = state) do
    case Map.get(map, value) do
      nil ->
        {bnode(counter, state),
          %{state | map: Map.put(map, value, counter), counter: counter + 1}}
      previous ->
        {bnode(previous, state), state}
    end
  end

  defp bnode(counter, %{prefix: prefix}) do
    BlankNode.new(prefix <> Integer.to_string(counter))
  end

  defp bnode(counter, _) do
    BlankNode.new(counter)
  end

end
