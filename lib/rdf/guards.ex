defmodule RDF.Guards do
  @moduledoc """
  A collection of guards.
  """

  import RDF.Utils.Guards

  @doc """
  Returns if the given value is an atom which could potentially be an `RDF.Vocabulary.Namespace` term.
  """
  defguard maybe_ns_term(term) when maybe_module(term)

  @doc """
  Returns if the given value is a triple, i.e. a tuple with three elements.
  """
  defguard is_triple(t) when is_tuple(t) and tuple_size(t) == 3
end
