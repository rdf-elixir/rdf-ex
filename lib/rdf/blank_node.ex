defmodule RDF.BlankNode do
  @moduledoc """
  An RDF blank node, also known as an anonymous or unlabeled node.

  see <https://www.w3.org/TR/rdf11-primer/#section-blank-node>
  and <https://www.w3.org/TR/rdf11-concepts/#section-blank-nodes>
  """

  defstruct [:id]

  @type t :: module

  def new,
    do: new(make_ref())
  def new(id) when is_binary(id),
    do: %RDF.BlankNode{id: id}
  def new(id) when is_reference(id),
    do: id |> :erlang.ref_to_list |> to_string |> String.replace(~r/\<|\>/, "") |> new
  def new(id) when is_atom(id) or is_integer(id),
    do: id |> to_string |> new

end
