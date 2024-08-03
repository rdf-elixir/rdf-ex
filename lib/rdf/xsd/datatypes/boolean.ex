defmodule RDF.XSD.Boolean do
  @moduledoc """
  `RDF.XSD.Datatype` for `xsd:boolean`.

  See: <https://www.w3.org/TR/xmlschema11-2/#boolean>
  """

  @type valid_value :: boolean
  @type input_value :: RDF.Literal.t() | valid_value | number | String.t() | any

  use RDF.XSD.Datatype.Primitive,
    name: "boolean",
    id: RDF.Utils.Bootstrapping.xsd_iri("boolean")

  alias RDF.XSD

  def_applicable_facet XSD.Facets.Pattern

  @doc false
  def pattern_conform?(pattern, _value, lexical) do
    XSD.Facets.Pattern.conform?(pattern, lexical)
  end

  @impl XSD.Datatype
  def lexical_mapping(lexical, _) do
    cond do
      lexical in ~W[true 1] -> true
      lexical in ~W[false 0] -> false
      true -> @invalid_value
    end
  end

  @impl XSD.Datatype
  @spec elixir_mapping(valid_value | integer | any, Keyword.t()) :: value
  def elixir_mapping(value, _)
  def elixir_mapping(value, _) when is_boolean(value), do: value
  def elixir_mapping(1, _), do: true
  def elixir_mapping(0, _), do: false
  def elixir_mapping(_, _), do: @invalid_value

  @impl RDF.Literal.Datatype
  def do_cast(value)

  def do_cast(%XSD.String{} = xsd_string) do
    xsd_string.value |> new() |> canonical()
  end

  def do_cast(literal) do
    cond do
      XSD.Decimal.datatype?(literal) ->
        !Decimal.equal?(literal.value, 0) |> new()

      XSD.Numeric.datatype?(literal) ->
        new(literal.value not in [0, 0.0, -0.0, :nan])

      true ->
        super(literal)
    end
  end

  @doc """
  Returns an Effective Boolean Value (EBV).

  The Effective Boolean Value is an algorithm to coerce values to a `RDF.XSD.Boolean`.

  It is specified and used in the SPARQL query language and is based upon XPath's
  `fn:boolean`. Other than specified in these specs any value which can not be
  converted into a boolean results in `nil`.

  see
  - <https://www.w3.org/TR/xpath-31/#id-ebv>
  - <https://www.w3.org/TR/sparql11-query/#ebv>

  """
  @spec ebv(input_value) :: RDF.Literal.t() | nil
  def ebv(value)

  def ebv(%RDF.Literal{literal: literal}), do: ebv(literal)

  def ebv(true), do: XSD.Boolean.Value.true()
  def ebv(false), do: XSD.Boolean.Value.false()

  def ebv(%__MODULE__{value: nil}), do: XSD.Boolean.Value.false()
  def ebv(%__MODULE__{} = value), do: literal(value)

  def ebv(%XSD.String{} = string) do
    if String.length(string.value) == 0,
      do: XSD.Boolean.Value.false(),
      else: XSD.Boolean.Value.true()
  end

  def ebv(%datatype{} = literal) do
    if XSD.Numeric.datatype?(datatype) do
      if datatype.valid?(literal) and
           not (datatype.value(literal) == 0 or datatype.value(literal) == :nan),
         do: XSD.Boolean.Value.true(),
         else: XSD.Boolean.Value.false()
    end
  end

  def ebv(value) when is_binary(value) or is_number(value) do
    value |> RDF.Literal.coerce() |> ebv()
  end

  def ebv(_), do: nil

  @doc """
  Alias for `ebv/1`.
  """
  @spec effective(input_value) :: RDF.Literal.t() | nil
  def effective(value), do: ebv(value)

  @doc """
  Returns `RDF.XSD.true` if the effective boolean value of the given argument is `RDF.XSD.false`, or `RDF.XSD.false` if it is `RDF.XSD.true`.

  Otherwise, it returns `nil`.

  ## Examples

      iex> RDF.XSD.Boolean.fn_not(RDF.XSD.true)
      RDF.XSD.false
      iex> RDF.XSD.Boolean.fn_not(RDF.XSD.false)
      RDF.XSD.true

      iex> RDF.XSD.Boolean.fn_not(true)
      RDF.XSD.false
      iex> RDF.XSD.Boolean.fn_not(false)
      RDF.XSD.true

      iex> RDF.XSD.Boolean.fn_not(42)
      RDF.XSD.false
      iex> RDF.XSD.Boolean.fn_not("")
      RDF.XSD.true

      iex> RDF.XSD.Boolean.fn_not(nil)
      nil

  see <https://www.w3.org/TR/xpath-functions/#func-not>
  """
  @spec fn_not(input_value) :: t() | nil
  def fn_not(value)
  def fn_not(%RDF.Literal{literal: literal}), do: fn_not(literal)

  def fn_not(value) do
    case ebv(value) do
      %RDF.Literal{literal: %__MODULE__{value: true}} -> XSD.Boolean.Value.false()
      %RDF.Literal{literal: %__MODULE__{value: false}} -> XSD.Boolean.Value.true()
      nil -> nil
    end
  end

  @doc """
  Returns the logical `AND` of the effective boolean value of the given arguments.

  It returns `nil` if only one argument is `nil` and the other argument is
  `RDF.XSD.true` and `RDF.XSD.false` if the other argument is `RDF.XSD.false`.

  ## Examples

      iex> RDF.XSD.Boolean.logical_and(RDF.XSD.true, RDF.XSD.true)
      RDF.XSD.true
      iex> RDF.XSD.Boolean.logical_and(RDF.XSD.true, RDF.XSD.false)
      RDF.XSD.false

      iex> RDF.XSD.Boolean.logical_and(RDF.XSD.true, nil)
      nil
      iex> RDF.XSD.Boolean.logical_and(nil, RDF.XSD.false)
      RDF.XSD.false
      iex> RDF.XSD.Boolean.logical_and(nil, nil)
      nil

  see <https://www.w3.org/TR/sparql11-query/#func-logical-and>

  """
  @spec logical_and(input_value, input_value) :: t() | nil
  def logical_and(left, right)
  def logical_and(%RDF.Literal{literal: left}, right), do: logical_and(left, right)
  def logical_and(left, %RDF.Literal{literal: right}), do: logical_and(left, right)

  def logical_and(left, right) do
    case ebv(left) do
      %RDF.Literal{literal: %__MODULE__{value: false}} ->
        XSD.Boolean.Value.false()

      %RDF.Literal{literal: %__MODULE__{value: true}} ->
        case ebv(right) do
          %RDF.Literal{literal: %__MODULE__{value: true}} -> XSD.Boolean.Value.true()
          %RDF.Literal{literal: %__MODULE__{value: false}} -> XSD.Boolean.Value.false()
          nil -> nil
        end

      nil ->
        if match?(%RDF.Literal{literal: %__MODULE__{value: false}}, ebv(right)) do
          XSD.Boolean.Value.false()
        end
    end
  end

  @doc """
  Returns the logical `OR` of the effective boolean value of the given arguments.

  It returns `nil` if only one argument is `nil` and the other argument is
  `RDF.XSD.false` and `RDF.XSD.true` if the other argument is `RDF.XSD.true`.

  ## Examples

      iex> RDF.XSD.Boolean.logical_or(RDF.XSD.true, RDF.XSD.false)
      RDF.XSD.true
      iex> RDF.XSD.Boolean.logical_or(RDF.XSD.false, RDF.XSD.false)
      RDF.XSD.false

      iex> RDF.XSD.Boolean.logical_or(RDF.XSD.true, nil)
      RDF.XSD.true
      iex> RDF.XSD.Boolean.logical_or(nil, RDF.XSD.false)
      nil
      iex> RDF.XSD.Boolean.logical_or(nil, nil)
      nil

  see <https://www.w3.org/TR/sparql11-query/#func-logical-or>

  """
  @spec logical_or(input_value, input_value) :: t() | nil
  def logical_or(left, right)
  def logical_or(%RDF.Literal{literal: left}, right), do: logical_or(left, right)
  def logical_or(left, %RDF.Literal{literal: right}), do: logical_or(left, right)

  def logical_or(left, right) do
    case ebv(left) do
      %RDF.Literal{literal: %__MODULE__{value: true}} ->
        XSD.Boolean.Value.true()

      %RDF.Literal{literal: %__MODULE__{value: false}} ->
        case ebv(right) do
          %RDF.Literal{literal: %__MODULE__{value: true}} -> XSD.Boolean.Value.true()
          %RDF.Literal{literal: %__MODULE__{value: false}} -> XSD.Boolean.Value.false()
          nil -> nil
        end

      nil ->
        if match?(%RDF.Literal{literal: %__MODULE__{value: true}}, ebv(right)) do
          XSD.Boolean.Value.true()
        end
    end
  end
end
