defmodule RDF.Boolean do
  @moduledoc """
  `RDF.Datatype` for XSD boolean.
  """

  use RDF.Datatype, id: RDF.Datatype.NS.XSD.boolean

  import RDF.Literal.Guards


  def convert(value, _) when is_boolean(value), do: value

  def convert(value, opts) when is_binary(value) do
    with normalized_value = String.downcase(value) do
      cond do
        normalized_value in ~W[true 1]  -> true
        normalized_value in ~W[false 0] -> false
        true ->
          super(value, opts)
      end
    end
  end

  def convert(1, _), do: true
  def convert(0, _), do: false

  def convert(value, opts), do: super(value, opts)


  def cast(%RDF.Literal{datatype: datatype} = literal) do
    cond do
      not RDF.Literal.valid?(literal) ->
        nil

      is_xsd_boolean(datatype) ->
        literal

      is_xsd_string(datatype) ->
        literal.value
        |> new()
        |> canonical()
        |> validate_cast()

      is_xsd_decimal(datatype) ->
        !Decimal.equal?(literal.value, 0)
        |> new()

      RDF.Numeric.type?(datatype) ->
        literal.value not in [0, 0.0, :nan]
        |> new()

      true ->
        nil
    end
  end


  @doc """
  Returns `RDF.true` if the effective boolean value of the given argument is `RDF.false`, or `RDF.false` if it is `RDF.true`.

  Otherwise it returns `nil`.

  ## Examples

      iex> RDF.Boolean.fn_not(RDF.true)
      RDF.false
      iex> RDF.Boolean.fn_not(RDF.false)
      RDF.true

      iex> RDF.Boolean.fn_not(true)
      RDF.false
      iex> RDF.Boolean.fn_not(false)
      RDF.true

      iex> RDF.Boolean.fn_not(42)
      RDF.false
      iex> RDF.Boolean.fn_not("")
      RDF.true

      iex> RDF.Boolean.fn_not(nil)
      nil

  see <https://www.w3.org/TR/xpath-functions/#func-not>
  """
  def fn_not(value) do
    case ebv(value) do
      %RDF.Literal{value: true}  -> RDF.Boolean.Value.false
      %RDF.Literal{value: false} -> RDF.Boolean.Value.true
      nil                        -> nil
    end
  end

  @doc """
  Returns the logical `AND` of the effective boolean value of the given arguments.

  It returns `nil` if only one argument is `nil` and the other argument is
  `RDF.true` and `RDF.false` if the other argument is `RDF.false`.

  ## Examples

      iex> RDF.Boolean.logical_and(RDF.true, RDF.true)
      RDF.true
      iex> RDF.Boolean.logical_and(RDF.true, RDF.false)
      RDF.false

      iex> RDF.Boolean.logical_and(RDF.true, nil)
      nil
      iex> RDF.Boolean.logical_and(nil, RDF.false)
      RDF.false
      iex> RDF.Boolean.logical_and(nil, nil)
      nil

  see <https://www.w3.org/TR/sparql11-query/#func-logical-and>

  """
  def logical_and(left, right) do
    case ebv(left) do
      %RDF.Literal{value: false} ->
        RDF.false

      %RDF.Literal{value: true}  ->
        case ebv(right) do
          %RDF.Literal{value: true}  -> RDF.true
          %RDF.Literal{value: false} -> RDF.false
          nil                        -> nil
        end

      nil ->
        if match?(%RDF.Literal{value: false}, ebv(right)) do
          RDF.false
        end
    end
  end

  @doc """
  Returns the logical `OR` of the effective boolean value of the given arguments.

  It returns `nil` if only one argument is `nil` and the other argument is
  `RDF.false` and `RDF.true` if the other argument is `RDF.true`.

  ## Examples

      iex> RDF.Boolean.logical_or(RDF.true, RDF.false)
      RDF.true
      iex> RDF.Boolean.logical_or(RDF.false, RDF.false)
      RDF.false

      iex> RDF.Boolean.logical_or(RDF.true, nil)
      RDF.true
      iex> RDF.Boolean.logical_or(nil, RDF.false)
      nil
      iex> RDF.Boolean.logical_or(nil, nil)
      nil

  see <https://www.w3.org/TR/sparql11-query/#func-logical-or>

  """
  def logical_or(left, right) do
    case ebv(left) do
      %RDF.Literal{value: true} ->
        RDF.true

      %RDF.Literal{value: false}  ->
        case ebv(right) do
          %RDF.Literal{value: true}  -> RDF.true
          %RDF.Literal{value: false} -> RDF.false
          nil                        -> nil
        end

      nil ->
        if match?(%RDF.Literal{value: true}, ebv(right)) do
          RDF.true
        end
    end
  end


  @xsd_boolean RDF.Datatype.NS.XSD.boolean

  @doc """
  Returns an Effective Boolean Value (EBV).

  The Effective Boolean Value is an algorithm to coerce values to a `RDF.Boolean`.

  It is specified and used in the SPARQL query language and is based upon XPath's
  `fn:boolean`. Other than specified in these specs any value which can not be
  converted into a boolean results in `nil`.

  see
  - <https://www.w3.org/TR/xpath-31/#id-ebv>
  - <https://www.w3.org/TR/sparql11-query/#ebv>

  """
  def ebv(value)

  def ebv(true),  do: RDF.Boolean.Value.true
  def ebv(false), do: RDF.Boolean.Value.false

  def ebv(%RDF.Literal{value: nil, datatype: @xsd_boolean}), do: RDF.Boolean.Value.false
  def ebv(%RDF.Literal{datatype: @xsd_boolean} = literal),   do: literal

  def ebv(%RDF.Literal{datatype: datatype} = literal) do
    cond do
      RDF.Numeric.type?(datatype) ->
        if RDF.Literal.valid?(literal) and
            not (literal.value == 0 or literal.value == :nan),
          do: RDF.Boolean.Value.true,
        else: RDF.Boolean.Value.false

      RDF.Literal.plain?(literal) ->
        if String.length(literal.value) == 0,
          do: RDF.Boolean.Value.false,
        else: RDF.Boolean.Value.true

      true ->
        nil
    end
  end

  def ebv(value) when is_binary(value) or is_number(value) do
    value |> RDF.Literal.new() |> ebv()
  end

  def ebv(_), do: nil

  @doc """
  Alias for `ebv/1`.
  """
  def effective(value), do: ebv(value)

end

defmodule RDF.Boolean.Value do
  @moduledoc !"""
  This module holds the two boolean value literals, so they can be accessed
  directly without needing to construct them every time. They can't
  be defined in the RDF.Boolean module, because we can not use the
  `RDF.Boolean.new` function without having it compiled first.
  """

  @xsd_true  RDF.Boolean.new(true)
  @xsd_false RDF.Boolean.new(false)

  def unquote(:true)(),  do: @xsd_true
  def unquote(:false)(), do: @xsd_false
end
