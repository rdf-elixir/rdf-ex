defmodule RDF.Integer do
  @moduledoc """
  `RDF.Datatype` for XSD integer.
  """

  use RDF.Datatype, id: RDF.Datatype.NS.XSD.integer


  def convert(value, _) when is_integer(value), do: value

  def convert(value, opts) when is_binary(value) do
    case Integer.parse(value) do
      {integer, ""} -> integer
      {_, _}        -> super(value, opts)
      :error        -> super(value, opts)
    end
  end

  def convert(value, opts), do: super(value, opts)

  def equal_value?(left, right), do: RDF.Numeric.equal_value?(left, right)

end
