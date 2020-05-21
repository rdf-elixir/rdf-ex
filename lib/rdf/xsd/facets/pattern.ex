defmodule RDF.XSD.Facets.Pattern do
  use RDF.XSD.Facet, name: :pattern, type: String.t | [String.t]

  @doc !"""
  A generic implementation for the `pattern_conform?/3` on the datatypes.
  """
  def conform?(pattern, lexical)

  def conform?(patterns, lexical) when is_list(patterns) do
    Enum.any?(patterns, &(conform?(&1, lexical)))
  end

  def conform?(pattern, lexical) do
    RDF.XSD.Utils.Regex.matches?(lexical, pattern)
  end
end
