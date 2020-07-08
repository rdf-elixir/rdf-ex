defmodule RDF.BlankNode do
  @moduledoc """
  A RDF blank node (aka bnode) is a local node of a graph without an IRI.

  see <https://www.w3.org/TR/rdf11-primer/#section-blank-node>
  and <https://www.w3.org/TR/rdf11-concepts/#section-blank-nodes>
  """

  @type t :: %__MODULE__{
          value: String.t()
        }

  @enforce_keys [:value]
  defstruct [:value]

  @doc """
  Creates a `RDF.BlankNode`.
  """
  @spec new :: t
  def new,
    do: new(make_ref())

  @doc """
  Creates a `RDF.BlankNode` with a user-defined value for its identity.

  ## Examples

      iex> RDF.bnode(:foo)
      %RDF.BlankNode{value: "foo"}
  """
  @spec new(reference | String.t() | atom | integer) :: t
  def new(value)

  def new(value) when is_binary(value),
    do: %__MODULE__{value: value}

  def new(value) when is_reference(value),
    do: value |> :erlang.ref_to_list() |> to_string |> String.replace(~r/\<|\>/, "") |> new

  def new(value) when is_atom(value) or is_integer(value),
    do: value |> to_string |> new

  @doc """
  Tests for value equality of blank nodes.

  Returns `nil` when the given arguments are not comparable as blank nodes.
  """
  @spec equal_value?(t, t) :: boolean | nil
  def equal_value?(left, right)

  def equal_value?(%__MODULE__{value: left}, %__MODULE__{value: right}),
    do: left == right

  def equal_value?(_, _),
    do: nil

  defimpl String.Chars do
    def to_string(bnode), do: "_:#{bnode.value}"
  end
end
