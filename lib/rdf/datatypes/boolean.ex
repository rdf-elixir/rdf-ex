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
