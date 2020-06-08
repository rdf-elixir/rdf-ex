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


  def variables(%__MODULE__{triple_patterns: triple_patterns}), do: variables(triple_patterns)

  def variables(triple_patterns) when is_list(triple_patterns) do
    triple_patterns
    |> Enum.reduce([], fn triple_pattern, vars -> variables(triple_pattern) ++ vars end)
    |> Enum.uniq()
  end

  def variables({s, p, o}) when is_atom(s) and is_atom(p) and is_atom(o), do: [s, p, o]
  def variables({s, p, _}) when is_atom(s) and is_atom(p), do: [s, p]
  def variables({s, _, o}) when is_atom(s) and is_atom(o), do: [s, o]
  def variables({_, p, o}) when is_atom(p) and is_atom(o), do: [p, o]
  def variables({s, _, _}) when is_atom(s), do: [s]
  def variables({_, p, _}) when is_atom(p), do: [p]
  def variables({_, _, o}) when is_atom(o), do: [o]

  def variables(_), do: []
end
