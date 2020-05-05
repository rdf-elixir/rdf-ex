defmodule RDF.XSD.AnyURI do
  @moduledoc """
  `RDF.XSD.Datatype` for XSD anyURIs.

  See: <http://www.w3.org/TR/xmlschema11-2/#anyURI>
  """

  @type valid_value :: URI.t()

  use RDF.XSD.Datatype.Primitive,
    name: "anyURI",
    id: RDF.Utils.Bootstrapping.xsd_iri("anyURI")

  @impl RDF.XSD.Datatype
  @spec lexical_mapping(String.t(), Keyword.t()) :: valid_value
  def lexical_mapping(lexical, _), do: URI.parse(lexical)

  @impl RDF.XSD.Datatype
  @spec elixir_mapping(any, Keyword.t()) :: value
  def elixir_mapping(%URI{} = uri, _), do: uri
  def elixir_mapping(_, _), do: @invalid_value
end
