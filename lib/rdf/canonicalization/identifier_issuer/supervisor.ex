defmodule RDF.Canonicalization.IdentifierIssuer.Supervisor do
  use DynamicSupervisor

  alias RDF.Canonicalization.IdentifierIssuer

  def start_link(init_arg \\ nil) do
    DynamicSupervisor.start_link(__MODULE__, init_arg)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one, max_restarts: 0)
  end

  def new_issuer(supervisor, prefix) do
    {:ok, issuer_pid} = DynamicSupervisor.start_child(supervisor, {IdentifierIssuer, prefix})
    issuer_pid
  end

  def copy_issuer(supervisor, issuer) do
    state = IdentifierIssuer.state(issuer)
    {:ok, issuer_pid} = DynamicSupervisor.start_child(supervisor, {IdentifierIssuer, state})
    issuer_pid
  end
end
