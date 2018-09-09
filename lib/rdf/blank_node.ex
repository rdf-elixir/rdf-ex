defmodule RDF.BlankNode do
  @moduledoc """
  A RDF blank node (aka bnode) is a local node of a graph without an IRI.

  see <https://www.w3.org/TR/rdf11-primer/#section-blank-node>
  and <https://www.w3.org/TR/rdf11-concepts/#section-blank-nodes>
  """

  @enforce_keys [:id]
  defstruct [:id]

  @type t :: module

  @doc """
  Creates a `RDF.BlankNode` with an arbitrary internal id.
  """
  def new,
    do: new(make_ref())

  @doc """
  Creates a `RDF.BlankNode` with a user-defined identity.

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


  @doc """
  Tests for value equality of blank nodes.

  Returns `nil` when the given arguments are not comparable as blank nodes.
  """
  def equal_value?(left, right)

  def equal_value?(%RDF.BlankNode{id: left}, %RDF.BlankNode{id: right}),
    do: left == right

  def equal_value?(_, _),
    do: nil


  defimpl String.Chars do
    def to_string(%RDF.BlankNode{id: id}), do: "_:#{id}"
  end

end
