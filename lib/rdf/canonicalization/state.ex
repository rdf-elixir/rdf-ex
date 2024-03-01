defmodule RDF.Canonicalization.State do
  @moduledoc """
  State of the `RDF.Canonicalization` algorithm.

  <https://www.w3.org/TR/rdf-canon/#canon-state>
  """

  alias RDF.Canonicalization.IdentifierIssuer
  alias RDF.Statement

  defstruct bnode_to_quads: nil,
            hash_to_bnodes: %{},
            canonical_issuer: IdentifierIssuer.canonical(),
            hash_algorithm: nil,
            hndq_call_limit: nil

  @type t :: %__MODULE__{}

  @default_hash_algorithm :sha256
  @default_hndq_call_limit 50

  def new(input, opts) do
    hash_algorithm = Keyword.get_lazy(opts, :hash_algorithm, &default_hash_algorithm/0)
    hndq_call_limit = Keyword.get_lazy(opts, :hndq_call_limit, &default_hndq_call_limit/0)

    %__MODULE__{
      bnode_to_quads: bnode_to_quads(input),
      hash_algorithm: hash_algorithm,
      hndq_call_limit: hndq_call_limit
    }
  end

  def max_calls(%RDF.Canonicalization.State{} = state) do
    state.hndq_call_limit * map_size(state.bnode_to_quads)
  end

  def default_hash_algorithm do
    Application.get_env(:rdf, :canon_hash_algorithm, @default_hash_algorithm)
  end

  def default_hndq_call_limit do
    Application.get_env(:rdf, :hndq_call_limit, @default_hndq_call_limit)
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
