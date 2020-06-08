defmodule RDF.Query.BGP do
  @enforce_keys [:triple_patterns]
  defstruct [:triple_patterns]

  @type variable :: String.t
  @type triple_pattern :: {
                            subject :: variable | RDF.Term.t,
                            predicate :: variable | RDF.Term.t,
                            object :: variable | RDF.Term.t
                          }
  @type triple_patterns :: list(triple_pattern)

  @type t :: %__MODULE__{triple_patterns: triple_patterns}
end
