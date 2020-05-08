defmodule RDF.XSD.AnyURI do
  @moduledoc """
  `RDF.XSD.Datatype` for XSD anyURIs.

  See: <http://www.w3.org/TR/xmlschema11-2/#anyURI>
  """

  @type valid_value :: URI.t()

  alias RDF.IRI

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

  @impl RDF.Literal.Datatype
  def do_cast(%IRI{} = iri), do: new(iri.value)
  def do_cast(value), do: super(value)

  @impl RDF.Literal.Datatype
  def do_equal_value?(literal1, literal2)

  def do_equal_value?(%IRI{} = iri, %__MODULE__{} = any_uri),
    do: do_equal_value?(any_uri, iri)

  def do_equal_value?(%__MODULE__{} = any_uri, %IRI{value: iri}),
    do: lexical(any_uri) == iri

  def do_equal_value?(literal1, literal2), do: super(literal1, literal2)
end
