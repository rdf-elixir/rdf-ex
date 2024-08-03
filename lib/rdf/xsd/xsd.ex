defmodule RDF.XSD do
  @moduledoc """
  An implementation of the XML Schema (XSD) datatype system for use within `RDF.Literal.Datatype` system.

  It consists of

  - `RDF.XSD.Datatype`: a more specialized `RDF.Literal.Datatype` behaviour for XSD datatypes
  - `RDF.XSD.Datatype.Primitive`: macros for the definition of `RDF.Literal.Datatype` and
    `RDF.XSD.Datatype` implementations for primitive XSD datatypes
  - `RDF.XSD.Datatype.Restriction`: macros for the definition of `RDF.Literal.Datatype` and
    `RDF.XSD.Datatype` implementations for derived XSD datatypes
  - `RDF.XSD.Facet`: a behaviour for XSD facets which can be used to constrain values on
    datatype derivations

  see <https://www.w3.org/TR/xmlschema11-2/>
  """

  import RDF.Utils.Guards

  alias __MODULE__

  @facets [
    XSD.Facets.MinInclusive,
    XSD.Facets.MaxInclusive
  ]

  @doc """
  The list of all XSD facets.
  """
  @spec facets() :: Enum.t()
  def facets(), do: @facets

  @facets_by_name Map.new(@facets, fn facet -> {facet.name(), facet} end)

  @doc """
  Get a `RDF.XSD.Facet` by its name.
  """
  def facet(name)
  def facet(name) when is_ordinary_atom(name), do: @facets_by_name[to_string(name)]
  def facet(name), do: @facets_by_name[name]

  @doc """
  Returns if the given value is a `RDF.XSD.Datatype` struct or `RDF.Literal` with a `RDF.XSD.Datatype`.
  """
  defdelegate datatype?(value), to: RDF.Literal.Datatype.Registry, as: :xsd_datatype?

  for datatype <- RDF.Literal.Datatype.Registry.builtin_xsd_datatypes() do
    defdelegate unquote(String.to_atom(datatype.name()))(value), to: datatype, as: :new
    defdelegate unquote(String.to_atom(datatype.name()))(value, opts), to: datatype, as: :new

    elixir_name = Macro.underscore(datatype.name())

    unless datatype.name() == elixir_name do
      defdelegate unquote(String.to_atom(elixir_name))(value), to: datatype, as: :new
      defdelegate unquote(String.to_atom(elixir_name))(value, opts), to: datatype, as: :new
    end
  end

  defdelegate datetime(value), to: XSD.DateTime, as: :new
  defdelegate datetime(value, opts), to: XSD.DateTime, as: :new

  defdelegate unquote(true)(), to: XSD.Boolean.Value
  defdelegate unquote(false)(), to: XSD.Boolean.Value
end
