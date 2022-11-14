defmodule RDF.BlankNode.Generator do
  @moduledoc """
  A GenServer which generates `RDF.BlankNode`s using a `RDF.BlankNode.Generator.Algorithm`.

  This module implements the `RDF.Resource.Generator` behaviour.
  The only `RDF.Resource.Generator` configuration it requires is the process
  identifier. The actual configuration of the behaviour of this generator
  is done on the GenServer itself via `start_link/1` and `start/1`.
  """

  use GenServer
  use RDF.Resource.Generator

  # Client API ###############################################################

  @doc """
  Starts a blank node generator linked to the current process.

  The `RDF.BlankNode.Generator.Algorithm` implementation is the only required
  keyword option, which must be given with the `:algorithm` key or, if no other
  options are required, can be given directly (instead of a keyword list).
  The remaining options are used as the configuration for `init/1` of the
  respective `RDF.BlankNode.Generator.Algorithm` implementation.

  If you want to pass `GenServer.start_link/3` options, you'll can provide
  two separate keyword lists as a tuple with the first being the `RDF.BlankNode.Generator`
  configuration and the second the `GenServer.start_link/3` options.
  """
  def start_link(algorithm) when is_atom(algorithm) do
    start_link({[algorithm: algorithm], []})
  end

  def start_link({algorithm, gen_server_opts}) when is_atom(algorithm) do
    start_link({[algorithm: algorithm], gen_server_opts})
  end

  def start_link({init_opts, gen_server_opts}) do
    {algorithm, init_opts} = Keyword.pop!(init_opts, :algorithm)
    GenServer.start_link(__MODULE__, {algorithm, Map.new(init_opts)}, gen_server_opts)
  end

  def start_link(init_opts), do: start_link({init_opts, []})

  @doc """
  Starts a blank node generator process without links (outside of a supervision tree).

  The options are handled the same as `start_link/1`.
  """
  def start(algorithm) when is_atom(algorithm) do
    start({[algorithm: algorithm], []})
  end

  def start({algorithm, gen_server_opts}) when is_atom(algorithm) do
    start({[algorithm: algorithm], gen_server_opts})
  end

  def start({init_opts, gen_server_opts}) do
    {algorithm, init_opts} = Keyword.pop!(init_opts, :algorithm)
    GenServer.start(__MODULE__, {algorithm, Map.new(init_opts)}, gen_server_opts)
  end

  def start(init_opts), do: start({init_opts, []})

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
  def init({generation_mod, init_opts}) do
    {:ok, {generation_mod, generation_mod.init(init_opts)}}
  end

  @impl GenServer
  def handle_call(:generate, _from, {generation_mod, state}) do
    {bnode, new_state} = generation_mod.generate(state)
    {:reply, bnode, {generation_mod, new_state}}
  end

  @impl GenServer
  def handle_call({:generate_for, string}, _from, {generation_mod, state}) do
    {bnode, new_state} = generation_mod.generate_for(string, state)
    {:reply, bnode, {generation_mod, new_state}}
  end
end
