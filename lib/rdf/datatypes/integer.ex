defmodule RDF.Integer do
  @moduledoc """
  `RDF.Datatype` for XSD integer.
  """

  use RDF.Datatype, id: RDF.Datatype.NS.XSD.integer

  import RDF.Literal.Guards


  def convert(value, _) when is_integer(value), do: value

  def convert(value, opts) when is_binary(value) do
    case Integer.parse(value) do
      {integer, ""} -> integer
      {_, _}        -> super(value, opts)
      :error        -> super(value, opts)
    end
  end

  def convert(value, opts), do: super(value, opts)


  def cast(%RDF.Literal{datatype: datatype} = literal) do
    cond do
      not RDF.Literal.valid?(literal) ->
        nil

      is_xsd_integer(datatype) ->
        literal

      literal == RDF.false ->
        new(0)

      literal == RDF.true ->
        new(1)

      is_xsd_string(datatype) ->
        case Integer.parse(literal.value) do
          {value, _} -> new(value)
          _          -> nil
        end

      is_xsd_decimal(datatype) ->
        literal.value
        |> Decimal.round(0, :down)
        |> Decimal.to_integer()
        |> new()

      is_float(literal.value) and
          (is_xsd_double(datatype) or is_xsd_float(datatype)) ->
        literal.value
        |> trunc()
        |> new()

      true ->
        nil
    end
  end


  def equal_value?(left, right), do: RDF.Numeric.equal_value?(left, right)

end
