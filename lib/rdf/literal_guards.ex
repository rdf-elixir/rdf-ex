defmodule RDF.Literal.Guards do
  @moduledoc """
  Guards for working with `RDF.Literal`s.

  These are useful for pattern matching on datatypes of literals, since
  Elixir doesn't allow function calls in pattern matching clauses, which means
  the qualified terms of a `RDF.Vocabulary.Namespace` can't be used.

  ## Examples

      defmodule M do
        import RDF.Literal.Guards

        def f(%RDF.Literal{datatype: datatype} = literal) when is_xsd_integer(datatype) do
          # ...
        end
      end

  """

  alias RDF.Datatype.NS.XSD

  @xsd_integer XSD.integer()
  @xsd_decimal XSD.decimal()
  @xsd_float XSD.float()
  @xsd_double XSD.double()
  @xsd_string XSD.string()
  @xsd_boolean XSD.boolean()
  @xsd_dateTime XSD.dateTime()
  @xsd_any_uri XSD.anyURI()
  @rdf_lang_string RDF.langString

  @doc """
  Returns `true` if the given datatype is `xsd:integer`; otherwise returns `false`.
  """
  defguard is_xsd_integer(datatype) when datatype == @xsd_integer

  @doc """
  Returns `true` if the given datatype is `xsd:decimal`; otherwise returns `false`.
  """
  defguard is_xsd_decimal(datatype) when datatype == @xsd_decimal

  @doc """
  Returns `true` if the given datatype is `xsd:float`; otherwise returns `false`.
  """
  defguard is_xsd_float(datatype) when datatype == @xsd_float

  @doc """
  Returns `true` if the given datatype is `xsd:double`; otherwise returns `false`.
  """
  defguard is_xsd_double(datatype) when datatype == @xsd_double

  @doc """
  Returns `true` if the given datatype is `xsd:string`; otherwise returns `false`.
  """
  defguard is_xsd_string(datatype) when datatype == @xsd_string
  @doc """
  Returns `true` if the given datatype is `xsd:boolean`; otherwise returns `false`.
  """
  defguard is_xsd_boolean(datatype) when datatype == @xsd_boolean

  @doc """
  Returns `true` if the given datatype is `xsd:dateTime`; otherwise returns `false`.
  """
  defguard is_xsd_datetime(datatype) when datatype == @xsd_dateTime

  @doc """
  Returns `true` if the given datatype is `xsd:anyURI`; otherwise returns `false`.
  """
  defguard is_xsd_any_uri(datatype)  when datatype == @xsd_any_uri

  @doc """
  Returns `true` if the given datatype is `rdf:langString`; otherwise returns `false`.
  """
  defguard is_rdf_lang_string(datatype) when datatype == @rdf_lang_string

end
