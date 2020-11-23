defmodule RDF.Utils.Guards do
  defguard is_ordinary_atom(term)
           when is_atom(term) and term not in [nil, true, false]

  defguard maybe_module(term) when is_ordinary_atom(term)
end
