defmodule RDF.XSD.Facets.Pattern do
  @moduledoc """
  `RDF.XSD.Facet` for `pattern`.

  `pattern` is a constraint on the value space of a datatype which is achieved
  by constraining the lexical space to literals which match each member of a
  set of regular expressions.
  The value of pattern  must be a set of regular expressions.

  see <https://www.w3.org/TR/xmlschema11-2/datatypes.html#rf-pattern>
  """

  use RDF.XSD.Facet, name: :pattern, type: String.t() | [String.t()]

  @doc !"""
       A generic implementation for the `pattern_conform?/3` on the datatypes.
       """
  def conform?(pattern, lexical)

  def conform?(patterns, lexical) when is_list(patterns) do
    Enum.any?(patterns, &conform?(&1, lexical))
  end

  def conform?(pattern, lexical) do
    RDF.XSD.Utils.Regex.matches?(lexical, pattern)
  end
end
