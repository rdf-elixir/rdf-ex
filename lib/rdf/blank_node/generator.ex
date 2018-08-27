defmodule RDF.BlankNode.Generator do
  @moduledoc """
  A GenServer generates `RDF.BlankNode`s using a `RDF.BlankNode.Generator.Algorithm`.
  """

  use GenServer


  # Client API ###############################################################

  @doc """
  Starts a blank node generator linked to the current process.

  The state will be initialized according to the given `RDF.BlankNode.Generator.Algorithm`.
  """
  def start_link(generation_mod, init_opts \\ %{}) do
    GenServer.start_link(__MODULE__, {generation_mod, convert_opts(init_opts)})
  end

  @doc """
  Starts a blank node generator process without links (outside of a supervision tree).

  The state will be initialized according to the given `RDF.BlankNode.Generator.Algorithm`.
  """
  def start(generation_mod, init_opts \\ %{}) do
    GenServer.start(__MODULE__, {generation_mod, convert_opts(init_opts)})
  end

  defp convert_opts(nil), do: %{}
  defp convert_opts(opts) when is_list(opts), do: Map.new(opts)
  defp convert_opts(opts) when is_map(opts), do: opts


  @doc """
  Synchronously stops the blank node generator with the given `reason`.

  It returns `:ok` if the agent terminates with the given reason. If the agent
  terminates with another reason, the call will exit.

  This function keeps OTP semantics regarding error reporting.
  If the reason is any other than `:normal`, `:shutdown` or `{:shutdown, _}`, an
  error report will be logged.
  """
  def stop(pid, reason \\ :normal, timeout \\ :infinity) do
    GenServer.stop(pid, reason, timeout)
  end


  @doc """
  Generates a new blank node according to the `RDF.BlankNode.Generator.Algorithm` set up.
  """
  def generate(pid) do
    GenServer.call(pid, :generate)
  end


  @doc """
  Generates a blank node for a given string according to the `RDF.BlankNode.Generator.Algorithm` set up.
  """
  def generate_for(pid, string) do
    GenServer.call(pid, {:generate_for, string})
  end


  # Server Callbacks #########################################################

  @impl GenServer
  def init({generation_mod, init_opts}) do
    {:ok, {generation_mod, generation_mod.init(init_opts)}}
  end


  @impl GenServer
  def handle_call(:generate, _from, {generation_mod, state}) do
    with {bnode, new_state} = generation_mod.generate(state) do
      {:reply, bnode, {generation_mod, new_state}}
    end
  end

  @impl GenServer
  def handle_call({:generate_for, string}, _from, {generation_mod, state}) do
    with {bnode, new_state} = generation_mod.generate_for(string, state) do
      {:reply, bnode, {generation_mod, new_state}}
    end
  end

end
