defmodule RDF.Boolean do
  @moduledoc """
  `RDF.Datatype` for XSD boolean.
  """

  use RDF.Datatype, id: RDF.Datatype.NS.XSD.boolean


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

end
