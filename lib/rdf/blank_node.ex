defmodule RDF.BlankNode do
  @moduledoc """
  A RDF blank node (aka bnode) is a local node of a graph without an URI.

  see <https://www.w3.org/TR/rdf11-primer/#section-blank-node>
  and <https://www.w3.org/TR/rdf11-concepts/#section-blank-nodes>
  """

  defstruct [:id]

  @type t :: module

  @doc """
  Generator function for `RDF.BlankNode`s.
  """
  def new,
    do: new(make_ref())

  @doc """
  Generator function for `RDF.BlankNode`s with a user-defined identity.

  ## Examples

      iex> RDF.bnode(:foo)
      %RDF.BlankNode{id: "foo"}
  """
  def new(id)

  def new(id) when is_binary(id),
    do: %RDF.BlankNode{id: id}

  def new(id) when is_reference(id),
    do: id |> :erlang.ref_to_list |> to_string |> String.replace(~r/\<|\>/, "") |> new

  def new(id) when is_atom(id) or is_integer(id),
    do: id |> to_string |> new
end

defimpl String.Chars, for: RDF.BlankNode do
  def to_string(%RDF.BlankNode{id: id}) do
    "_:#{id}"
  end
end
