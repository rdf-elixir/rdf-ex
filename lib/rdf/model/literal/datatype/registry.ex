defmodule RDF.Literal.Datatype.Registry do
  @moduledoc """
  Registry of literal datatypes.
  """

  alias RDF.{Literal, IRI, XSD, Namespace}
  alias RDF.Literal.Datatype.Registry.Registration

  import RDF.Guards
  import RDF.Utils.Guards

  @primitive_numeric_datatypes [
    RDF.XSD.Integer,
    RDF.XSD.Decimal,
    RDF.XSD.Double
  ]

  @builtin_numeric_datatypes @primitive_numeric_datatypes ++
                               [
                                 RDF.XSD.Long,
                                 RDF.XSD.Int,
                                 RDF.XSD.Short,
                                 RDF.XSD.Byte,
                                 RDF.XSD.NonNegativeInteger,
                                 RDF.XSD.PositiveInteger,
                                 RDF.XSD.UnsignedLong,
                                 RDF.XSD.UnsignedInt,
                                 RDF.XSD.UnsignedShort,
                                 RDF.XSD.UnsignedByte,
                                 RDF.XSD.NonPositiveInteger,
                                 RDF.XSD.NegativeInteger,
                                 RDF.XSD.Float
                               ]

  @builtin_xsd_datatypes [
                           XSD.Boolean,
                           XSD.String,
                           XSD.Date,
                           XSD.Time,
                           XSD.DateTime,
                           XSD.AnyURI,
                           XSD.Base64Binary
                         ] ++ @builtin_numeric_datatypes

  @builtin_datatypes [RDF.LangString | @builtin_xsd_datatypes]

  @doc """
  Returns a list of all builtin `RDF.Literal.Datatype` modules.
  """
  @spec builtin_datatypes :: [RDF.Literal.Datatype.t()]
  def builtin_datatypes, do: @builtin_datatypes

  @doc """
  Checks if the given module is a builtin datatype.

  Note: This doesn't include `RDF.Literal.Generic`.
  """
  @spec builtin_datatype?(module) :: boolean
  def builtin_datatype?(module)

  for datatype <- @builtin_datatypes do
    def builtin_datatype?(unquote(datatype)), do: true
  end

  def builtin_datatype?(_), do: false

  @doc """
  Checks if the given module is a builtin datatype or a registered custom datatype implementing the `RDF.Literal.Datatype` behaviour.
  """
  @spec datatype?(Literal.t() | Literal.Datatype.literal() | module) :: boolean
  def datatype?(value)

  # We assume literals were created properly which means they have a proper RDF.Literal.Datatype
  def datatype?(%Literal{}), do: true
  def datatype?(value), do: datatype_struct?(value)

  @doc false
  @spec datatype_struct?(Literal.Datatype.literal() | module) :: boolean
  def datatype_struct?(value)

  def datatype_struct?(%datatype{}), do: datatype_struct?(datatype)

  def datatype_struct?(Literal.Generic), do: true

  def datatype_struct?(module) when maybe_module(module) do
    builtin_datatype?(module) or is_rdf_literal_datatype?(module)
  end

  def datatype_struct?(_), do: false

  @doc """
  Returns a list of all builtin `RDF.XSD.Datatype` modules.
  """
  @spec builtin_xsd_datatypes :: [RDF.Literal.Datatype.t()]
  def builtin_xsd_datatypes, do: @builtin_xsd_datatypes

  @doc false
  @spec builtin_xsd_datatype?(module) :: boolean
  def builtin_xsd_datatype?(module)

  for datatype <- @builtin_xsd_datatypes do
    def builtin_xsd_datatype?(unquote(datatype)), do: true
  end

  def builtin_xsd_datatype?(_), do: false

  @doc """
  Checks if the given module is a builtin XSD datatype or a registered custom datatype implementing the `RDF.XSD.Datatype` behaviour.
  """
  @spec xsd_datatype?(Literal.t() | XSD.Datatype.literal() | module) :: boolean
  def xsd_datatype?(value)
  def xsd_datatype?(%Literal{literal: datatype_struct}), do: xsd_datatype?(datatype_struct)
  def xsd_datatype?(value), do: xsd_datatype_struct?(value)

  @doc false
  @spec xsd_datatype_struct?(RDF.Literal.t() | XSD.Datatype.literal() | module) :: boolean
  def xsd_datatype_struct?(value)

  def xsd_datatype_struct?(%datatype{}), do: xsd_datatype_struct?(datatype)

  def xsd_datatype_struct?(module) when maybe_module(module) do
    builtin_xsd_datatype?(module) or is_xsd_datatype?(module)
  end

  def xsd_datatype_struct?(_), do: false

  @doc """
  Returns a list of all numeric datatype modules.
  """
  @spec builtin_numeric_datatypes() :: [RDF.Literal.Datatype.t()]
  def builtin_numeric_datatypes(), do: @builtin_numeric_datatypes

  @doc """
  The set of all primitive numeric datatypes.
  """
  @spec primitive_numeric_datatypes() :: [RDF.Literal.Datatype.t()]
  def primitive_numeric_datatypes(), do: @primitive_numeric_datatypes

  @doc false
  @spec builtin_numeric_datatype?(module) :: boolean
  def builtin_numeric_datatype?(module)

  for datatype <- @builtin_numeric_datatypes do
    def builtin_numeric_datatype?(unquote(datatype)), do: true
  end

  def builtin_numeric_datatype?(_), do: false

  @doc """
  Returns if a given literal or datatype has or is a numeric datatype.
  """
  @spec numeric_datatype?(RDF.Literal.t() | RDF.XSD.Datatype.t() | any) :: boolean
  def numeric_datatype?(literal)
  def numeric_datatype?(%RDF.Literal{literal: literal}), do: numeric_datatype?(literal)
  def numeric_datatype?(%datatype{}), do: numeric_datatype?(datatype)

  def numeric_datatype?(datatype) when maybe_module(datatype) do
    builtin_numeric_datatype?(datatype) or
      (xsd_datatype?(datatype) and
         Enum.any?(@primitive_numeric_datatypes, fn numeric_primitive ->
           datatype.derived_from?(numeric_primitive)
         end))
  end

  def numeric_datatype?(_), do: false

  @doc """
  Returns the `RDF.Literal.Datatype` for a datatype IRI.
  """
  @spec datatype(Literal.t() | IRI.t() | String.t()) :: Literal.Datatype.t()
  def datatype(%Literal{} = literal), do: literal.literal.__struct__
  def datatype(%IRI{} = id), do: id |> to_string() |> datatype()
  def datatype(id) when maybe_ns_term(id), do: id |> Namespace.resolve_term!() |> datatype()
  def datatype(id) when is_binary(id), do: Registration.datatype(id)

  @doc """
  Returns the `RDF.XSD.Datatype` for a datatype IRI.
  """
  @spec xsd_datatype(Literal.t() | IRI.t() | String.t()) :: XSD.Datatype.t()
  def xsd_datatype(id) do
    datatype = datatype(id)

    if datatype && is_xsd_datatype?(datatype) do
      datatype
    end
  end

  # TODO: Find a better/faster solution for checking datatype modules which includes unknown custom datatypes.
  # Although checking for the presence of a function via __info__(:functions) is
  # the fastest way to reflect a module type on average over the positive and negative
  # case (being roughly comparable to a map access), we would still have to rescue
  # from an UndefinedFunctionError since its raised by trying to access __info__
  # on plain (non-module) atoms, so we can do the check by rescuing in the first place.
  # Although the positive is actually faster than the __info__(:functions) check,
  # the negative is more than 7 times slower.
  # (Properly checking for the behaviour attribute with module_info[:attributes]
  # is more than 200 times slower.)

  # credo:disable-for-lines:1 Credo.Check.Readability.PredicateFunctionNames
  defp is_rdf_literal_datatype?(module) do
    module.__rdf_literal_datatype_indicator__()
  rescue
    UndefinedFunctionError -> false
  end

  # credo:disable-for-lines:1 Credo.Check.Readability.PredicateFunctionNames
  defp is_xsd_datatype?(module) do
    module.__xsd_datatype_indicator__()
  rescue
    UndefinedFunctionError -> false
  end
end
