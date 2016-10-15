defmodule RDF.RDFS do
  @moduledoc """
  The RDFS vocabulary.

  See <https://www.w3.org/TR/rdf-schema/>
  """

  # TODO: This should be a strict vocabulary and loaded from a file.
  use RDF.Vocabulary, base_uri: "http://www.w3.org/2000/01/rdf-schema#"

end
