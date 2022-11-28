defmodule RDF.Canonicalization.State do
  @moduledoc """
  State of the `RDF.Canonicalization` algorithm.

  <https://www.w3.org/community/reports/credentials/CG-FINAL-rdf-dataset-canonicalization-20221009/#canonicalization-state>
  """

  alias RDF.Canonicalization.IdentifierIssuer
  alias RDF.Statement

  defstruct bnode_to_statements: nil,
            hash_to_bnodes: %{},
            canonical_issuer: IdentifierIssuer.canonical()

  def new(input) do
    %__MODULE__{bnode_to_statements: bnode_to_statements(input)}
  end

  def issue_canonical_identifier(state, identifier) do
    {issued_identifier, canonical_issuer} =
      IdentifierIssuer.issue_identifier(state.canonical_issuer, identifier)

    {issued_identifier, %{state | canonical_issuer: canonical_issuer}}
  end

  # ISSUE: "It seems that quads must be normalized, so that literals with different syntactic representations but the same semantic representations are merged, and that two graphs differing in the syntactic representation of a literal will produce the same set of blank node identifiers."
  defp bnode_to_statements(data) do
    Enum.reduce(data, %{}, fn statement, bnode_to_statements ->
      statement
      |> Statement.bnodes()
      |> Enum.reduce(bnode_to_statements, fn bnode, bnode_to_statements ->
        Map.update(bnode_to_statements, bnode, [statement], &[statement | &1])
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
