defmodule RDF.Literal.Datatype.Registry do
  @moduledoc false

  alias RDF.{Literal, IRI, XSD, Namespace}
  alias RDF.Literal.Datatype.Registry.Registration

  import RDF.Guards

  @core_datatypes [RDF.LangString | Enum.to_list(XSD.datatypes())]

  @doc """
  All core `RDF.Literal.Datatype` modules.
  """
  @spec core_datatypes :: Enum.t
  def core_datatypes, do: @core_datatypes

  @doc """
  Checks if the given module is core datatype.
  """
  @spec core_datatype?(module) :: boolean
  def core_datatype?(module), do: module in @core_datatypes

  @doc """
  Checks if the given module is a core datatype or a registered custom datatype implementing the `RDF.Literal.Datatype` behaviour.
  """
  @spec datatype?(module) :: boolean
  def datatype?(module) do
    core_datatype?(module) or implements_datatype_behaviour?(module)
  end

  @spec literal?(module) :: boolean
  def literal?(%Literal{}), do: true
  def literal?(%Literal.Generic{}), do: true
  def literal?(%datatype{}), do: datatype?(datatype)
  def literal?(_), do: false

  @doc """
  Returns the `RDF.Literal.Datatype` for a datatype IRI.
  """
  @spec datatype(Literal.t | IRI.t | String.t) :: Literal.Datatype.t
  def datatype(%Literal{} = literal), do: Literal.datatype(literal)
  def datatype(%IRI{} = id), do: id |> to_string() |> datatype()
  def datatype(id) when maybe_ns_term(id), do: id |> Namespace.resolve_term!() |> datatype()
  def datatype(id) when is_binary(id), do: Registration.datatype(id)

  defp implements_datatype_behaviour?(module) do
    module.module_info[:attributes]
    |> Keyword.get_values(:behaviour)
    |> List.flatten()
    |> Enum.member?(RDF.Literal.Datatype)
  end
end
