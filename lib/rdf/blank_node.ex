defmodule RDF.BlankNode do
  @moduledoc """
  """

  defstruct [:id]

  @type t :: module

  def new, do: %RDF.BlankNode{id: make_ref()}
  def new(id) when is_atom(id) or is_binary(id) or is_integer(id),
    do: %RDF.BlankNode{id: id}

end
