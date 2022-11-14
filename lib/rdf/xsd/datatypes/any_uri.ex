defmodule RDF.XSD.AnyURI do
  @moduledoc """
  `RDF.XSD.Datatype` for `xsd:anyURI`.

  See: <http://www.w3.org/TR/xmlschema11-2/#anyURI>
  """

  @type valid_value :: URI.t()

  use RDF.XSD.Datatype.Primitive,
    name: "anyURI",
    id: RDF.Utils.Bootstrapping.xsd_iri("anyURI")

  alias RDF.{IRI, XSD}

  import RDF.Guards

  def_applicable_facet XSD.Facets.MinLength
  def_applicable_facet XSD.Facets.MaxLength
  def_applicable_facet XSD.Facets.Length
  def_applicable_facet XSD.Facets.Pattern

  @doc false
  def min_length_conform?(min_length, _value, lexical) do
    String.length(lexical) >= min_length
  end

  @doc false
  def max_length_conform?(max_length, _value, lexical) do
    String.length(lexical) <= max_length
  end

  @doc false
  def length_conform?(length, _value, lexical) do
    String.length(lexical) == length
  end

  @doc false
  def pattern_conform?(pattern, _value, lexical) do
    XSD.Facets.Pattern.conform?(pattern, lexical)
  end

  @impl XSD.Datatype
  @spec lexical_mapping(String.t(), Keyword.t()) :: valid_value
  def lexical_mapping(lexical, _), do: URI.parse(lexical)

  @impl XSD.Datatype
  @spec elixir_mapping(any, Keyword.t()) :: value
  def elixir_mapping(%URI{} = uri, _), do: uri
  def elixir_mapping(%IRI{} = iri, _), do: IRI.parse(iri)

  def elixir_mapping(value, _) when maybe_ns_term(value) do
    case RDF.Namespace.resolve_term(value) do
      {:ok, iri} -> IRI.parse(iri)
      _ -> @invalid_value
    end
  end

  def elixir_mapping(_, _), do: @invalid_value

  @impl RDF.Literal.Datatype
  def do_cast(%IRI{} = iri), do: new(iri.value)
  def do_cast(value), do: super(value)

  @impl RDF.Literal.Datatype
  def do_equal_value_different_datatypes?(left, right)

  def do_equal_value_different_datatypes?(%IRI{} = iri, any_uri),
    do: do_equal_value_different_datatypes?(any_uri, iri)

  def do_equal_value_different_datatypes?(any_uri, %IRI{value: iri}),
    do: lexical(any_uri) == iri

  def do_equal_value_different_datatypes?(left, right) when maybe_ns_term(left),
    do: do_equal_value_different_datatypes?(right, left)

  def do_equal_value_different_datatypes?(left, right) when maybe_ns_term(right) do
    case RDF.Namespace.resolve_term(right) do
      {:ok, iri} -> do_equal_value_different_datatypes?(left, iri)
      _ -> nil
    end
  end

  def do_equal_value_different_datatypes?(literal1, literal2),
    do: super(literal1, literal2)
end
