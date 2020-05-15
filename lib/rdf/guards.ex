defmodule RDF.Guards do
  import RDF.Utils.Guards

  defguard maybe_ns_term(term) when maybe_module(term)
end
