defmodule RDF.Query.BGP.Matcher do
  @moduledoc """
  An interface for various BGP matching algorithm implementations.
  """

  alias RDF.Query.BGP

  @type solution :: map
  @type solutions :: [solution]

  @callback query(data :: RDF.Graph.t, bgp :: BGP.t, opts :: Keyword.t) :: solutions

  @callback query_stream(data :: RDF.Graph.t, bgp :: BGP.t, opts :: Keyword.t) :: Enumerable.t()


end
