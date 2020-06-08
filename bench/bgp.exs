defmodule NS do
  use RDF.Vocabulary.Namespace

  defvocab MF,
           base_iri: "http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#",
           terms: [], strict: false

  defvocab RDFT,
           base_iri: "http://www.w3.org/ns/rdftest#",
           terms: [], strict: false
end

alias NS.{MF, RDFT}
alias RDF.NS.RDFS
alias RDF.Query.BGP

test_graph = RDF.Turtle.read_file!("test/data/TURTLE-TESTS/manifest.ttl", base: "http://www.w3.org/2013/TurtleTests/")


all_query = %BGP{triple_patterns: [{:s, :p, :o}]}
Benchee.run(%{
  "take 1 from BGP.Simple" => fn -> BGP.Simple.query_stream(test_graph, all_query) |> Enum.take(1) end,
  "take 1 from BGP.Stream" => fn -> BGP.Stream.query_stream(test_graph, all_query) |> Enum.take(1) end,
})


# rdft:approval rdft:Approved - count: 287
approved_query = %BGP{triple_patterns: [
  {:test_case, RDFT.approval, RDF.iri(RDFT.Approved)},
  {:test_case, MF.name, :name},
  {:test_case, RDFS.comment, :comment},
]}

# rdft:approval rdft:Proposed - count: 4
proposed_query = %BGP{triple_patterns: [
  {:test_case, RDFT.approval, RDF.iri(RDFT.Proposed)},
  {:test_case, MF.name, :name},
  {:test_case, RDFS.comment, :comment},
]}

Benchee.run(%{
  "APPROVED from BGP.Simple" => fn -> BGP.Simple.query(test_graph, approved_query) end,
  "PROPOSED from BGP.Simple" => fn -> BGP.Simple.query(test_graph, proposed_query) end,

  "APPROVED from BGP.Stream (consumed)" => fn -> BGP.Stream.query(test_graph, approved_query) end,
  "PROPOSED from BGP.Stream (consumed)" => fn -> BGP.Stream.query(test_graph, proposed_query) end,
  "APPROVED from BGP.Stream (unconsumed)" => fn -> BGP.Stream.query_stream(test_graph, approved_query) end,
  "PROPOSED from BGP.Stream (unconsumed)" => fn -> BGP.Stream.query_stream(test_graph, proposed_query) end,
  "APPROVED from BGP.Stream (1 consumed)" => fn -> BGP.Stream.query_stream(test_graph, approved_query) |> Enum.take(1) end
})
