defmodule RDF.Sigils do

  @doc ~S"""
  Handles the sigil `~I` for IRIs.

  ## Examples

      iex> import RDF.Sigils
      iex> ~I<http://example.com>
      RDF.uri("http://example.com")

  """
  defmacro sigil_I({:<<>>, _, [iri]}, []) when is_binary(iri),
    do: Macro.escape(RDF.uri(iri))

end
