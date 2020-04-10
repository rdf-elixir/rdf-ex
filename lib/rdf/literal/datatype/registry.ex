# TODO: This registry should be managed automatically/dynamically and be extendable, to allow user-defined datatypes ...
defmodule RDF.Literal.Datatype.Registry do
  @moduledoc false

  alias RDF.Literal
  alias RDF.IRI

  @datatypes [
    RDF.LangString
    | Enum.map(XSD.datatypes(), &Literal.XSD.datatype_module_name/1)
  ]

  @mapping Map.new(@datatypes, fn datatype -> {RDF.IRI.new(datatype.id), datatype} end)

  @doc """
  The mapping of IRIs of datatypes to their `RDF.Literal.Datatype`.
  """
  @spec mapping :: %{IRI.t => Literal.Datatype.t}
  def mapping, do: @mapping

  @doc """
  The IRIs of all datatypes with a `RDF.Literal.Datatype` defined.
  """
  @spec ids :: [IRI.t]
  def ids, do: Map.keys(@mapping)

  @doc """
  All defined `RDF.Literal.Datatype` modules.
  """
  @spec datatypes :: Enum.t
  def datatypes, do: @datatypes

  @spec datatype?(module) :: boolean
  def datatype?(module), do: module in @datatypes

  @doc """
  Returns the `RDF.Literal.Datatype` for a directly datatype IRI or the datatype IRI of a `RDF.Literal`.
  """
  @spec get(Literal.t | IRI.t | String.t) :: Literal.Datatype.t
  def get(%Literal{} = literal), do: Literal.datatype(literal)
  def get(id) when is_binary(id), do: id |> IRI.new() |> get()
  def get(id), do: @mapping[id]

  @doc false
  def rdf_datatype(type) do
    if type in XSD.datatypes() do
      RDF.Literal.XSD.datatype_module_name(type)
    else
      type
    end
  end
end
