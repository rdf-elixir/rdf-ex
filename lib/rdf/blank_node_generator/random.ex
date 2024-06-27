defmodule RDF.BlankNode.Generator.Random do
  @moduledoc """
  An implementation of a `RDF.BlankNode.Generator.Algorithm` which returns `RDF.BlankNode`s with random identifiers.

  The following options are supported when starting a `RDF.BlankNode.Generator`
  with this algorithm:

  - `prefix`: a string prepended to the generated blank node identifier

  """

  @behaviour RDF.BlankNode.Generator.Algorithm

  alias RDF.BlankNode

  @type state :: %{
          optional(:prefix) => String.t(),
          map: map
        }

  @impl BlankNode.Generator.Algorithm
  def init(%{prefix: prefix} = opts) do
    opts
    |> Map.delete(:prefix)
    |> init()
    |> Map.put(:prefix, prefix)
  end

  @impl BlankNode.Generator.Algorithm
  def init(_opts) do
    %{
      map: %{}
    }
  end

  @impl BlankNode.Generator.Algorithm
  def generate(state) do
    {state |> number() |> bnode(state), state}
  end

  @impl BlankNode.Generator.Algorithm
  def generate_for(value, %{map: map} = state) do
    case Map.get(map, value) do
      nil ->
        random = number(state)
        {bnode(random, state), %{state | map: Map.put(map, value, random)}}

      previous ->
        {bnode(previous, state), state}
    end
  end

  defp bnode(random, %{prefix: prefix}) do
    BlankNode.new(prefix <> random)
  end

  defp bnode(random, _state) do
    BlankNode.new(random)
  end

  defp number(_), do: :erlang.unique_integer([:positive]) |> to_string()
end
