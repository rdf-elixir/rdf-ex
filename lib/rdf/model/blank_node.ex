defmodule RDF.BlankNode do
  @moduledoc """
  An RDF blank node (aka bnode) is a local node of a graph without an IRI.

  This module can also be used as `RDF.Resource.Generator` for the generation
  of random identifiers, which is using the `new/0` function.
  For the generation of value-based blank nodes, you can use `RDF.BlankNode.Generator`.

  see <https://www.w3.org/TR/rdf11-primer/#section-blank-node>
  and <https://www.w3.org/TR/rdf11-concepts/#section-blank-nodes>
  """

  @type t :: %__MODULE__{value: String.t()}

  @enforce_keys [:value]
  defstruct [:value]

  use RDF.Resource.Generator
  alias RDF.Resource.Generator

  @doc """
  Creates a random `RDF.BlankNode`.
  """
  @spec new :: t
  def new, do: new(:erlang.unique_integer([:positive]))

  @doc """
  Creates a `RDF.BlankNode` with a user-defined value for its identity.

  A `"_:"` prefix in a given string `value` will be automatically ignored.

  When given an integer as `value` it will be automatically converted to a
  string prefixed with `"b"`.

  ## Examples

      iex> RDF.BlankNode.new(:foo)
      %RDF.BlankNode{value: "foo"}

      iex> RDF.BlankNode.new("foo")
      %RDF.BlankNode{value: "foo"}

      iex> RDF.BlankNode.new("_:foo")
      %RDF.BlankNode{value: "foo"}

      iex> RDF.BlankNode.new(42)
      %RDF.BlankNode{value: "b42"}
  """
  @spec new(reference | String.t() | atom | integer) :: t
  def new(value)

  def new("_:" <> string) when is_binary(string), do: %__MODULE__{value: string}
  def new(string) when is_binary(string), do: %__MODULE__{value: string}
  def new(atom) when is_atom(atom), do: atom |> to_string() |> new()
  def new(integer) when is_integer(integer), do: new("b#{integer}")

  def new(ref) when is_reference(ref) do
    "#Ref<" <> value = ref |> :erlang.ref_to_list() |> to_string()
    value |> String.trim_trailing(">") |> new()
  end

  @doc """
  Returns the internal string representation of a blank node.
  """
  def value(%__MODULE__{} = bnode), do: bnode.value

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

  @impl RDF.Resource.Generator
  def generate(_), do: new()

  @impl RDF.Resource.Generator
  def generate(_, _) do
    raise(
      Generator.ConfigError,
      """
      Value-based resource generation is not supported by RDF.BlankNode.
      Use RDF.BlankNode.Generator or another generator.
      """
    )
  end

  defimpl String.Chars do
    def to_string(bnode), do: "_:#{bnode.value}"
  end
end
