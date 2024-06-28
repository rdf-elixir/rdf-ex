defmodule RDF.BlankNode.Generator do
  @moduledoc """
  A GenServer which generates `RDF.BlankNode`s using a `RDF.BlankNode.Generator.Algorithm`.

  This module implements the `RDF.Resource.Generator` behaviour.
  The only `RDF.Resource.Generator` configuration it requires is the process
  identifier. The actual configuration of the behaviour of this generator
  is done on the GenServer itself via `start_link/2` or `start/2`.
  """

  use GenServer
  use RDF.Resource.Generator

  # Client API ###############################################################

  @doc """
  Starts a blank node generator linked to the current process.

  The `RDF.BlankNode.Generator.Algorithm` can be given either as a respective
  struct or just the module, in which case a struct is created implicitly
  with the default values of its fields.
  """
  def start_link(algorithm, opts \\ [])

  def start_link(algorithm, opts) when is_atom(algorithm) do
    start_link(struct(algorithm), opts)
  end

  def start_link({algorithm, opts}, []) do
    start_link(algorithm, opts)
  end

  def start_link(%_algorithm{} = algorithm_struct, opts) do
    GenServer.start_link(__MODULE__, algorithm_struct, opts)
  end

  @doc """
  Starts a blank node generator process without links (outside a supervision tree).

  The options are handled the same as `start_link/1`.
  """
  def start(algorithm, opts \\ [])

  def start(algorithm, opts) when is_atom(algorithm) do
    start(struct(algorithm), opts)
  end

  def start(%_algorithm{} = algorithm_struct, opts) do
    GenServer.start(__MODULE__, algorithm_struct, opts)
  end

  @doc """
  Synchronously stops the blank node generator with the given `reason`.

  It returns `:ok` if the GenServer terminates with the given reason.
  If the GenServer terminates with another reason, the call will exit.

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
  @impl RDF.Resource.Generator
  def generate(pid) do
    GenServer.call(pid, :generate)
  end

  @impl RDF.Resource.Generator
  def generate(pid, value) do
    generate_for(pid, value)
  end

  @impl RDF.Resource.Generator
  def generator_config(_, config) do
    Keyword.get(config, :pid) ||
      raise ArgumentError, "missing required :pid argument for RDF.BlankNode.Generator"
  end

  @doc """
  Generates a blank node for a given value according to the `RDF.BlankNode.Generator.Algorithm` set up.
  """
  def generate_for(pid, value) do
    GenServer.call(pid, {:generate_for, value})
  end

  # Server Callbacks #########################################################

  @impl GenServer
  def init(algorithm_struct) do
    {:ok, algorithm_struct}
  end

  @impl GenServer
  def handle_call(:generate, _from, %algorithm{} = state) do
    {bnode, new_state} = algorithm.generate(state)
    {:reply, bnode, new_state}
  end

  @impl GenServer
  def handle_call({:generate_for, string}, _from, %algorithm{} = state) do
    {bnode, new_state} = algorithm.generate_for(state, string)
    {:reply, bnode, new_state}
  end
end
