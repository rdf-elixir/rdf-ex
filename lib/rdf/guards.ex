defmodule RDF.Guards do
  import RDF.Utils.Guards

  defguard maybe_ns_term(term) when maybe_module(term)

  defguard is_triple(t) when is_tuple(t) and tuple_size(t) == 3
end
