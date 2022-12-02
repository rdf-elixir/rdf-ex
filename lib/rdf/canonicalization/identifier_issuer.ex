defmodule RDF.Canonicalization.IdentifierIssuer do
  @moduledoc """
  An identifier issuer is used to issue new blank node identifier.
  """

  use GenServer

  alias RDF.Canonicalization.IdentifierIssuer.State

  # API

  def start_link(state_or_prefix, opts \\ []) do
    GenServer.start_link(__MODULE__, state_or_prefix, opts)
  end

  def stop(pid, reason \\ :normal, timeout \\ :infinity) do
    GenServer.stop(pid, reason, timeout)
  end

  def state(pid), do: GenServer.call(pid, :state)
  def issue_identifier(pid, identifier), do: GenServer.call(pid, {:issue_identifier, identifier})
  def identifier(pid, identifier), do: GenServer.call(pid, {:identifier, identifier})
  def issued?(pid, identifier), do: GenServer.call(pid, {:issued?, identifier})
  def issued_identifiers(pid), do: GenServer.call(pid, :issued_identifiers)

  # Callbacks

  @impl true
  def init(%State{} = state), do: {:ok, state}
  def init(prefix), do: {:ok, State.new(prefix)}

  @impl true
  def handle_call(:state, _, state), do: {:reply, state, state}

  def handle_call({:issue_identifier, identifier}, _, state) do
    {issued_identifier, state} = State.issue_identifier(state, identifier)
    {:reply, issued_identifier, state}
  end

  def handle_call({:identifier, identifier}, _, state),
    do: {:reply, State.identifier(state, identifier), state}

  def handle_call({:issued?, identifier}, _, state),
    do: {:reply, State.issued?(state, identifier), state}

  def handle_call(:issued_identifiers, _, state),
    do: {:reply, State.issued_identifiers(state), state}
end
