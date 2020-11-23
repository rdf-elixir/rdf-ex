defmodule RDF.Query.BGP.Matcher do
  @moduledoc !"""
             An interface for various BGP matching algorithm implementations.
             """

  alias RDF.Query.BGP
  alias RDF.Graph

  @type solution :: map
  @type solutions :: [solution]

  @callback execute(BGP.t(), Graph.t(), opts :: Keyword.t()) :: solutions

  @callback stream(BGP.t(), Graph.t(), opts :: Keyword.t()) :: Enumerable.t()
end
