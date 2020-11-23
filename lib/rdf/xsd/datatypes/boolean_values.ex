defmodule RDF.XSD.Boolean.Value do
  @moduledoc !"""
             This module holds the two boolean value literals, so they can be accessed
             directly without needing to construct them every time.
             They can't be defined in the RDF.XSD.Boolean module, because we can not use
             the `RDF.XSD.Boolean.new` function without having it compiled first.
             """

  @xsd_true RDF.XSD.Boolean.new(true)
  @xsd_false RDF.XSD.Boolean.new(false)

  def unquote(true)(), do: @xsd_true
  def unquote(false)(), do: @xsd_false
end
