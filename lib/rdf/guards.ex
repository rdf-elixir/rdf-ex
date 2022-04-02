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

  @doc """
  Returns if the given value is a quad, i.e. a tuple with four elements.
  """
  defguard is_quad(q) when is_tuple(q) and tuple_size(q) == 4

  @doc """
  Returns if the given value is a triple or a quad
  in terms of `is_triple/1` and `is_quad/1`.
  """
  defguard is_statement(s) when is_triple(s) or is_quad(s)
end
