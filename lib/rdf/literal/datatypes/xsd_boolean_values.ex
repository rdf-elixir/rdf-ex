defmodule RDF.XSD.Boolean.Value do
  @moduledoc !"""
  This module holds the two boolean value literals, so they can be accessed
  directly without needing to construct them every time.
  """

  @xsd_true  RDF.XSD.Boolean.new(true)
  @xsd_false RDF.XSD.Boolean.new(false)

  def unquote(:true)(),  do: @xsd_true
  def unquote(:false)(), do: @xsd_false
end
