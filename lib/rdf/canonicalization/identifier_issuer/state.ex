defmodule RDF.Canonicalization.IdentifierIssuer.State do
  @moduledoc """
  State of a `RDF.Canonicalization.IdentifierIssuer`.

  <https://www.w3.org/community/reports/credentials/CG-FINAL-rdf-dataset-canonicalization-20221009/#blank-node-identifier-issuer-state>
  """

  defstruct issued_identifiers: %{},
            issue_order: [],
            identifier_counter: 0,
            identifier_prefix: nil

  def new(prefix) do
    %__MODULE__{identifier_prefix: prefix}
  end

  def canonical, do: new("_:c14n")

  @doc """
  Issues a new blank node identifier for a given existing blank node identifier.

  See <https://www.w3.org/community/reports/credentials/CG-FINAL-rdf-dataset-canonicalization-20221009/#issue-identifier>
  """
  def issue_identifier(state, existing_identifier) do
    if issued_identifier = state.issued_identifiers[existing_identifier] do
      {issued_identifier, state}
    else
      issued_identifier = state.identifier_prefix <> Integer.to_string(state.identifier_counter)

      {issued_identifier,
       %{
         state
         | issued_identifiers:
             Map.put(state.issued_identifiers, existing_identifier, issued_identifier),
           issue_order: [existing_identifier | state.issue_order],
           identifier_counter: state.identifier_counter + 1
       }}
    end
  end

  def identifier(state, identifier) do
    Map.get(state.issued_identifiers, identifier)
  end

  def issued?(state, identifier) do
    Map.has_key?(state.issued_identifiers, identifier)
  end

  def issued_identifiers(state) do
    Enum.reverse(state.issue_order)
  end
end
