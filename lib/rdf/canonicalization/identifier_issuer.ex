defmodule RDF.Canonicalization.IdentifierIssuer do
  @moduledoc """
  An identifier issuer is used to issue new blank node identifier.

  See <https://www.w3.org/TR/rdf-canon/#bn-issuer-state>
  """

  defstruct id: nil,
            issued_identifiers: %{},
            issue_order: [],
            identifier_counter: 0,
            identifier_prefix: nil

  def new(prefix) do
    %__MODULE__{id: create_id(), identifier_prefix: prefix}
  end

  def canonical, do: new("c14n")

  def copy(issuer), do: %__MODULE__{issuer | id: create_id()}

  defp create_id, do: :erlang.unique_integer()

  @doc """
  Issues a new blank node identifier for a given existing blank node identifier.

  See <https://www.w3.org/TR/rdf-canon/#issue-identifier>
  """
  def issue_identifier(issuer, existing_identifier) do
    if issued_identifier = issuer.issued_identifiers[existing_identifier] do
      {issued_identifier, issuer}
    else
      issued_identifier = issuer.identifier_prefix <> Integer.to_string(issuer.identifier_counter)

      {issued_identifier,
       %{
         issuer
         | issued_identifiers:
             Map.put(issuer.issued_identifiers, existing_identifier, issued_identifier),
           issue_order: [existing_identifier | issuer.issue_order],
           identifier_counter: issuer.identifier_counter + 1
       }}
    end
  end

  def identifier(issuer, identifier) do
    Map.get(issuer.issued_identifiers, identifier)
  end

  def issued?(issuer, identifier) do
    Map.has_key?(issuer.issued_identifiers, identifier)
  end

  def issued_identifiers(state) do
    Enum.reverse(state.issue_order)
  end
end
