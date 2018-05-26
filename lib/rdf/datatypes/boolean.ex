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

defmodule RDF.Boolean.Value do
  @moduledoc false

  # This module holds the two boolean value literals, so they can be accessed
  # directly without needing to construct them every time. They can't
  # be defined in the RDF.Boolean module, because we can not use the
  # `RDF.Boolean.new` function without having it compiled first.

  @xsd_true  RDF.Boolean.new(true)
  @xsd_false RDF.Boolean.new(false)

  def unquote(:true)(),  do: @xsd_true
  def unquote(:false)(), do: @xsd_false
end
