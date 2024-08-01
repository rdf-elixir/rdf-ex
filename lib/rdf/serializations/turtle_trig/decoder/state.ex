defmodule RDF.TurtleTriG.Decoder.State do
  @moduledoc !"The internal state of the `RDF.Turtle.Decoder` and `RDF.TriG.Decoder`."

  defstruct base_iri: nil, namespaces: %{}, bnode_gen: nil

  alias RDF.BlankNode

  @default_turtle_trig_decoder_bnode_gen :uuid

  def default_bnode_gen do
    Application.get_env(
      :rdf,
      :turtle_trig_decoder_bnode_gen,
      @default_turtle_trig_decoder_bnode_gen
    )
  end

  def new(base_iri, opts \\ []) do
    %__MODULE__{
      base_iri: base_iri,
      bnode_gen: opts |> Keyword.get(:bnode_gen) |> bnode_generator()
    }
  end

  defp bnode_generator(nil) do
    if bnode_gen = default_bnode_gen(), do: bnode_generator(bnode_gen)
  end

  defp bnode_generator(:uuid), do: bnode_generator(BlankNode.Generator.UUID)
  defp bnode_generator(:random), do: bnode_generator(BlankNode.Generator.Random)
  defp bnode_generator(:increment), do: bnode_generator(BlankNode.Generator.Increment)
  defp bnode_generator(algorithm) when is_atom(algorithm), do: struct(algorithm)
  defp bnode_generator(algorithm_struct) when is_struct(algorithm_struct), do: algorithm_struct

  def add_namespace(%__MODULE__{namespaces: namespaces} = state, ns, iri) do
    %__MODULE__{state | namespaces: Map.put(namespaces, ns, iri)}
  end

  def ns(%__MODULE__{namespaces: namespaces}, prefix) do
    namespaces[prefix]
  end

  def next_bnode(%__MODULE__{bnode_gen: %algorithm{}} = state) do
    {bnode, bnode_gen} = algorithm.generate(state.bnode_gen)
    {bnode, %__MODULE__{state | bnode_gen: bnode_gen}}
  end
end
