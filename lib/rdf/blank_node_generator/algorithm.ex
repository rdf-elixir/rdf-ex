defmodule RDF.BlankNode.Generator.Algorithm do
  @moduledoc """
  A behaviour for implementations of blank node identifier generation algorithms.

  The `RDF.BlankNode.Generator` executes such an algorithm and holds its state.
  """

  @type type :: module
  @type t :: struct

  alias RDF.BlankNode

  @doc """
  Generates a blank node.

  An implementation should compute a blank node from the given state and return
  a tuple consisting of the generated blank node and the new state.
  """
  @callback generate(t()) :: {BlankNode.t(), t()}

  @doc """
  Generates a blank node for a given string.

  Every call with the same string must return the same blank node.

  An implementation should compute a blank node for the given value from the
  given state and return a tuple consisting of the generated blank node and the
  new state.
  """
  @callback generate_for(t(), value :: any) :: {BlankNode.t(), t()}
end
