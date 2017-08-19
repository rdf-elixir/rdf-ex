hash = %{"http://example.com/foo/bar" => RDF.uri("http://example.com/foo/bar")}

Benchee.run(%{
  "URI.parse" => fn ->
    RDF.uri("http://example.com/foo/bar")
  end,
  "RDF.IRI.new" => fn ->
    RDF.IRI.new("http://example.com/foo/bar")
  end,
  "RDF.IRI.new!" => fn ->
    RDF.IRI.new!("http://example.com/foo/bar")
  end,
  "hash lookup" => fn ->
    hash["http://example.com/foo/bar"]
  end,
})


Benchee.run(%{
  "bare uri" => fn ->
    RDF.uri("http://example.com/foo/bar")
  end,
  "bare triple" => fn ->
    RDF.triple({RDF.uri("http://example.com/foo/bar"),
                RDF.uri("http://example.com/foo/baz"),
                RDF.uri("http://example.com/foo/quux")
    })
  end,
  "Graph with triple" => fn ->
    RDF.Graph.new(
      RDF.triple({RDF.uri("http://example.com/foo/bar"),
                  RDF.uri("http://example.com/foo/baz"),
                  RDF.uri("http://example.com/foo/quux")
      })
    )
  end,
})

Benchee.run(%{
  "1_000_000 bare uris" => fn ->
    for i <- 1..1_000_000 do
      RDF.uri("http://example.com/foo/bar#{i}")
    end
  end,
  "1_000_000 bare triples" => fn ->
    for i <- 1..1_000_000 do
      RDF.triple({RDF.uri("http://example.com/foo/bar#{i}"),
                  RDF.uri("http://example.com/foo/baz#{i}"),
                  RDF.uri("http://example.com/foo/quux#{i}")
      })
    end
  end,
  "Graph with 1_000_000 triples" => fn ->
    Enum.reduce 1..1_000_000, RDF.Graph.new(), fn i, graph ->
      RDF.Graph.add graph,
        RDF.triple({RDF.uri("http://example.com/foo/bar#{i}"),
                    RDF.uri("http://example.com/foo/baz#{i}"),
                    RDF.uri("http://example.com/foo/quux#{i}")
        })
    end
  end,
})


IO.puts "\n\nErlang Term Info (Memory Consumption)"

uris =
  for i <- 1..1_000_000 do
    RDF.uri("http://example.com/foo/bar#{i}")
  end
IO.puts "1_000_000 bare uris: #{:erlang_term.byte_size(uris)}"

triples =
  for i <- 1..1_000_000 do
    RDF.triple({RDF.uri("http://example.com/foo/bar#{i}"),
                RDF.uri("http://example.com/foo/baz#{i}"),
                RDF.uri("http://example.com/foo/quux#{i}")
    })
  end
IO.puts "1_000_000 bare triples: #{:erlang_term.byte_size(triples)}"

graph =
  Enum.reduce 1..1_000_000, RDF.Graph.new(), fn i, graph ->
    RDF.Graph.add graph,
      RDF.triple({RDF.uri("http://example.com/foo/bar#{i}"),
                  RDF.uri("http://example.com/foo/baz#{i}"),
                  RDF.uri("http://example.com/foo/quux#{i}")
      })
  end
IO.puts "Graph with 1_000_000 triples: #{:erlang_term.byte_size(graph)}"
