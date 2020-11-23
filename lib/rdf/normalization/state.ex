defmodule RDF.Normalization.State do
  @moduledoc """
  <https://json-ld.github.io/normalization/spec/#dfn-normalization-state>
  """

  #  use Agent # a Elixir 1.5 feature, which we actually don't require

  alias RDF.Normalization.IssueIdentifier
  alias RDF.{Data, Dataset, Graph, Description, Statement, BlankNode, NQuads}

  def start_link(data) do
    Agent.start_link(fn ->
      %{
        bnode_to_statements: init_bnode_to_statements(data),
        hash_to_bnodes: %{},
        canonical_issuer: IssueIdentifier.start_link("_:c14n") |> elem(1)
      }
    end)
  end

  def stop(state) do
    Agent.stop(state)
  end

  def bnode_to_statements(state), do: Agent.get(state, & &1.bnode_to_statements)
  def hash_to_bnodes(state), do: Agent.get(state, & &1.hash_to_bnodes)
  def canonical_issuer(state), do: Agent.get(state, & &1.canonical_issuer)

  def clear_hash_to_bnodes(state) do
    Agent.update(state, &Map.put(&1, :hash_to_bnodes, %{}))
  end

  def add_bnode_hash(state, bnode, hash) do
    Agent.update(state, fn map ->
      %{
        map
        | hash_to_bnodes:
            Map.update(
              map.hash_to_bnodes,
              hash,
              MapSet.new() |> MapSet.put(bnode),
              &MapSet.put(&1, bnode)
            )
      }
    end)
  end

  def delete_bnode_hash(state, hash) do
    Agent.update(state, fn map ->
      %{map | hash_to_bnodes: Map.delete(map.hash_to_bnodes, hash)}
    end)
  end

  # TODO: Problem this contains references to quads according to the spec 2.1)
  defp init_bnode_to_statements(data) do
    Enum.reduce(data, %{}, fn statement, bnode_to_statements ->
      statement
      |> Tuple.to_list()
      |> Enum.filter(&RDF.bnode?/1)
      |> Enum.reduce(bnode_to_statements, fn bnode, bnode_to_statements ->
        Map.update(bnode_to_statements, bnode, [statement], fn statements ->
          [statement | statements]
        end)
      end)
    end)
  end
end
