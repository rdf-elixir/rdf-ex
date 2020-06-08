defmodule RDF.Query.BGP.Matcher do
  @moduledoc """
  An interface for various BGP matching algorithm implementations.
  """

  @type variable :: String.t
  @type triple_pattern :: {
                            subject :: variable | RDF.Term.t,
                            predicate :: variable | RDF.Term.t,
                            object :: variable | RDF.Term.t
                          }
  @type triple_patterns :: list(triple_pattern)
  @type solution :: map
  @type solutions :: [solution]


  @callback query(triple_patterns :: [], data :: RDF.Graph.t, opts :: Keyword.t) :: solutions

  @callback query_stream(triple_patterns :: [], data :: RDF.Graph.t, opts :: Keyword.t) :: Enumerable.t()

end
