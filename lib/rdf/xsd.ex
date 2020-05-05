defmodule RDF.XSD do
  @moduledoc """
  An implementation of the XML Schema (XSD) datatype system for use within `RDF.Literal.Datatype` system.

  see <https://www.w3.org/TR/xmlschema-2/>
  """

  alias __MODULE__
  alias RDF.{IRI, Literal}

  @datatypes [
               XSD.Boolean,
               XSD.String,
               XSD.Date,
               XSD.Time,
               XSD.DateTime,
               XSD.AnyURI
             ]
             |> MapSet.new()
             |> MapSet.union(XSD.Numeric.datatypes())

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

  def facet(name) when is_atom(name), do: @facets_by_name[to_string(name)]
  def facet(name), do: @facets_by_name[name]

  @doc """
  The list of all XSD datatypes.
  """
  @spec datatypes() :: Enum.t()
  def datatypes(), do: @datatypes

  @datatypes_by_name Map.new(@datatypes, fn datatype -> {datatype.name(), datatype} end)
  @datatypes_by_iri Map.new(@datatypes, fn datatype -> {datatype.id(), datatype} end)

  def datatype_by_name(name) when is_atom(name), do: @datatypes_by_name[to_string(name)]
  def datatype_by_name(name), do: @datatypes_by_name[name]
  def datatype_by_iri(iri) when is_binary(iri), do: @datatypes_by_iri[IRI.new(iri)]
  def datatype_by_iri(%IRI{} = iri), do: @datatypes_by_iri[iri]

  @doc """
  Returns if a given datatype is a XSD datatype.
  """
  def datatype?(datatype), do: datatype in @datatypes

  @doc """
  Returns if a given argument is a `RDF.XSD.datatype` literal.
  """
  def literal?(%Literal{literal: %datatype{}}), do: datatype?(datatype)
  def literal?(%datatype{}), do: datatype?(datatype)
  def literal?(_), do: false

  @doc false
  def valid?(%datatype{} = datatype_literal), do: datatype.valid?(datatype_literal)

  for datatype <- @datatypes do
    defdelegate unquote(String.to_atom(datatype.name))(value), to: datatype, as: :new
    defdelegate unquote(String.to_atom(datatype.name))(value, opts), to: datatype, as: :new

    elixir_name = Macro.underscore(datatype.name)
    unless datatype.name == elixir_name do
      defdelegate unquote(String.to_atom(elixir_name))(value), to: datatype, as: :new
      defdelegate unquote(String.to_atom(elixir_name))(value, opts), to: datatype, as: :new
    end
  end

  defdelegate datetime(value), to: XSD.DateTime, as: :new
  defdelegate datetime(value, opts), to: XSD.DateTime, as: :new

  defdelegate unquote(true)(),  to: XSD.Boolean.Value
  defdelegate unquote(false)(), to: XSD.Boolean.Value
end
