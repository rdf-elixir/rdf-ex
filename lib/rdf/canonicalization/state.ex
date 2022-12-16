defmodule RDF.Canonicalization.State do
  @moduledoc """
  State of the `RDF.Canonicalization` algorithm.

  <https://www.w3.org/community/reports/credentials/CG-FINAL-rdf-dataset-canonicalization-20221009/#canonicalization-state>
  """

  alias RDF.Canonicalization.IdentifierIssuer
  alias RDF.Statement

  defstruct bnode_to_quads: nil,
            hash_to_bnodes: %{},
            canonical_issuer: IdentifierIssuer.canonical()

  def new(input) do
    %__MODULE__{bnode_to_quads: bnode_to_quads(input)}
  end

  def issue_canonical_identifier(state, identifier) do
    {_issued_identifier, canonical_issuer} =
      IdentifierIssuer.issue_identifier(state.canonical_issuer, identifier)

    %{state | canonical_issuer: canonical_issuer}
  end

  defp bnode_to_quads(data) do
    Enum.reduce(data, %{}, fn quad, bnode_to_quads ->
      quad
      |> Statement.bnodes()
      |> Enum.reduce(bnode_to_quads, fn bnode, bnode_to_quads ->
        Map.update(bnode_to_quads, bnode, [quad], &[quad | &1])
      end)
    end)
  end

  def clear_hash_to_bnodes(state) do
    Map.put(state, :hash_to_bnodes, %{})
  end

  def add_bnode_hash(state, bnode, hash) do
    %{
      state
      | hash_to_bnodes:
          Map.update(state.hash_to_bnodes, hash, MapSet.new([bnode]), &MapSet.put(&1, bnode))
    }
  end

  def delete_bnode_hash(state, hash) do
    %{state | hash_to_bnodes: Map.delete(state.hash_to_bnodes, hash)}
  end
end
