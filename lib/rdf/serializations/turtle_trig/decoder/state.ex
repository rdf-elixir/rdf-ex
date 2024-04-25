defmodule RDF.TurtleTriG.Decoder.State do
  @moduledoc !"The internal state of the `RDF.Turtle.Decoder` and `RDF.TriG.Decoder`."

  defstruct base_iri: nil, namespaces: %{}, bnode_counter: 0

  alias RDF.BlankNode

  def add_namespace(%__MODULE__{namespaces: namespaces} = state, ns, iri) do
    %__MODULE__{state | namespaces: Map.put(namespaces, ns, iri)}
  end

  def ns(%__MODULE__{namespaces: namespaces}, prefix) do
    namespaces[prefix]
  end

  def next_bnode(%__MODULE__{bnode_counter: bnode_counter} = state) do
    {BlankNode.new("b#{bnode_counter}"), %__MODULE__{state | bnode_counter: bnode_counter + 1}}
  end
end
