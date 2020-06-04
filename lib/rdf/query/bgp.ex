defmodule RDF.Query.BGP do
  @moduledoc """
  An interface for various BGP algorithm implementations.
  """

  @type solution :: map
  @type solutions :: [solution]

  @callback query(triple_patterns :: [], data :: RDF.Data.t) :: solutions

end
