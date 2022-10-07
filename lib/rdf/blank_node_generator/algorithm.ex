defmodule RDF.BlankNode.Generator.Algorithm do
  @moduledoc """
  A behaviour for implementations of blank node identifier generation algorithms.

  The `RDF.BlankNode.Generator` executes such an algorithm and holds its state.
  """

  @doc """
  Returns the initial state of the algorithm.
  """
  @callback init(opts :: map) :: map

  @doc """
  Generates a blank node.

  An implementation should compute a blank node from the given state and return
  a tuple consisting of the generated blank node and the new state.
  """
  @callback generate(state :: map) :: {RDF.BlankNode.t(), map}

  @doc """
  Generates a blank node for a given string.

  Every call with the same string must return the same blank node.

  An implementation should compute a blank node for the given string from the
  given state and return a tuple consisting of the generated blank node and the
  new state.
  """
  @callback generate_for(value :: any, state :: map) :: {RDF.BlankNode.t(), map}
end
