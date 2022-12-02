defmodule RDF.Canonicalization.IdentifierIssuerTest do
  use RDF.Test.Case

  doctest RDF.Canonicalization.IdentifierIssuer

  alias RDF.Canonicalization.IdentifierIssuer

  test "new_issuer/1" do
    {:ok, sv_pid} = start_supervised(IdentifierIssuer.Supervisor)

    assert issuer1 = IdentifierIssuer.Supervisor.new_issuer(sv_pid, "issuer1")
    assert is_pid(issuer1)

    assert IdentifierIssuer.state(issuer1) == IdentifierIssuer.State.new("issuer1")
    assert IdentifierIssuer.issue_identifier(issuer1, "foo") == "issuer10"
    assert IdentifierIssuer.issue_identifier(issuer1, "foo") == "issuer10"
    assert IdentifierIssuer.identifier(issuer1, "foo") == "issuer10"

    assert issuer2 = IdentifierIssuer.Supervisor.new_issuer(sv_pid, "issuer2")
    assert IdentifierIssuer.issue_identifier(issuer2, "foo") == "issuer20"
    assert IdentifierIssuer.issue_identifier(issuer1, "foo") == "issuer10"

    assert issuer3 = IdentifierIssuer.Supervisor.copy_issuer(sv_pid, issuer1)
    assert IdentifierIssuer.identifier(issuer3, "foo") == "issuer10"
    assert IdentifierIssuer.issue_identifier(issuer3, "bar") == "issuer11"
    assert IdentifierIssuer.issued?(issuer3, "bar")
    refute IdentifierIssuer.issued?(issuer1, "bar")
  end
end
