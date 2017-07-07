defmodule RDF.URI.Helper do
  @moduledoc """
  Some helpers functions for working with URIs.

  These functions should be part of a dedicated RDF.IRI implementation.
  """


  @doc """
  Resolves a relative IRI against a base IRI.

  as specified in [section 5.1 Establishing a Base URI of RFC3986](http://tools.ietf.org/html/rfc3986#section-5.1).
  Only the basic algorithm in [section 5.2 of RFC3986](http://tools.ietf.org/html/rfc3986#section-5.2)
  is used; neither Syntax-Based Normalization nor Scheme-Based Normalization are performed.

  Characters additionally allowed in IRI references are treated in the same way that unreserved
  characters are treated in URI references, per [section 6.5 of RFC3987](http://tools.ietf.org/html/rfc3987#section-6.5)
  """
  def absolute_iri(value, base_iri) do
    case URI.parse(value) do
      # absolute?
      uri = %URI{scheme: scheme} when not is_nil(scheme) -> uri
      # relative
      _ when is_nil(base_iri) -> nil
      _ -> URI.merge(base_iri, value)
    end
  end

end
