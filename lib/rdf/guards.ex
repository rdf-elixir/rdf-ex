defmodule RDF.Guards do
  defguard maybe_ns_term(term)
      when is_atom(term) and term not in [nil, true, false]
end
