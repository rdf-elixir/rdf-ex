defmodule RDF.Normalization.IssueIdentifier do
  @moduledoc """
  An identifier issuer is used to issue new blank node identifiers.

  This is an implementation of the _Issue Identifier Algorithm_ as specified at
  <https://json-ld.github.io/normalization/spec/#issue-identifier-algorithm>

  This algorithm issues a new blank node identifier for a given existing blank
  node identifier. It also updates state information that tracks the order in
  which new blank node identifiers were issued.
  """

  use GenServer

  # Client API

  def start_link(prefix, opts \\ []) do
    GenServer.start_link(__MODULE__, initial_state(prefix), opts)
  end

  def stop(pid, reason \\ :normal, timeout \\ :infinity) do
    GenServer.stop(pid, reason, timeout)
  end

  def copy(pid) do
    GenServer.start_link(__MODULE__, state(pid), [])
  end

  defp initial_state(prefix) do
    %{issued_identifiers: %{}, issue_order: [], counter: 0, prefix: prefix}
  end

  def state(pid) do
    GenServer.call(pid, :state)
  end


  @doc """
  Issues a new blank node identifier for a given existing blank node identifier.

  Details at <https://json-ld.github.io/normalization/spec/#issue-identifier-algorithm>
  """
  def issue_identifier(pid, identifier) do
    GenServer.call(pid, {:issue_identifier, identifier})
  end

  def issued_identifier(pid, identifier) do
    GenServer.call(pid, {:issued_identifier, identifier})
  end

  def issued?(pid, identifier) do
    GenServer.call(pid, {:issued?, identifier})
  end

  def issued(pid) do
    GenServer.call(pid, :issued)
  end


  # Server Callbacks

  def init(state) do
    {:ok, state}
  end

  def handle_call(:state, _, state) do
    {:reply, state, state}
  end

  def handle_call({:issue_identifier, identifier}, _,
        %{issued_identifiers: issued_identifiers, issue_order: issue_order,
          counter: counter, prefix: prefix} = state) do
    case issued_identifiers[identifier] do
      nil ->
        with issued_identifier = prefix <> to_string(counter) do
          {:reply, issued_identifier,
            %{state |
               issued_identifiers: Map.put(issued_identifiers, identifier, issued_identifier),
               issue_order: [identifier | issue_order], # TODO: Do we need this?
               counter: counter + 1
             }
          }
        end
      issued_identifier ->
        {:reply, issued_identifier, state}
    end
  end

  def handle_call({:issued_identifier, identifier}, _,
        %{issued_identifiers: issued_identifiers} = state) do
    {:reply, Map.get(issued_identifiers, identifier), state}
  end

  def handle_call({:issued?, identifier}, _,
        %{issued_identifiers: issued_identifiers} = state) do
    {:reply, Map.has_key?(issued_identifiers, identifier), state}
  end

  def handle_call(:issued, _,
        %{issued_identifiers: issued_identifiers} = state) do
    {:reply, Map.keys(issued_identifiers), state} # TODO: or issue_order?
  end

end
