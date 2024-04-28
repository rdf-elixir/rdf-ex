defmodule RDF.TriG.EncoderTest do
  use ExUnit.Case, async: false

  alias RDF.TriG

  doctest TriG.Encoder

  alias RDF.{Dataset, Graph}
  alias RDF.NS
  alias RDF.NS.{RDFS, OWL}

  import RDF.Sigils

  use RDF.Vocabulary.Namespace

  defvocab EX, base_iri: "http://example.org/#", terms: [], strict: false

  describe "serializing a dataset" do
    test "an empty dataset is serialized to an empty string" do
      assert TriG.Encoder.encode!(Dataset.new(), prefixes: %{}) == ""
    end

    test "an empty named graph" do
      assert TriG.Encoder.encode!(Graph.new(name: EX.Graph) |> Dataset.new(), prefixes: %{}) ==
               """
               GRAPH <http://example.org/#Graph> {
               }
               """
    end

    test "default graph only" do
      assert TriG.Encoder.encode!(
               Dataset.new([
                 {EX.S1, EX.p1(), EX.O1},
                 {EX.S1, EX.p1(), EX.O2},
                 {EX.S1, EX.p2(), EX.O3},
                 {EX.S2, EX.p3(), EX.O4}
               ]),
               prefixes: %{}
             ) ==
               """
               <http://example.org/#S1>
                   <http://example.org/#p1> <http://example.org/#O1>, <http://example.org/#O2> ;
                   <http://example.org/#p2> <http://example.org/#O3> .

               <http://example.org/#S2>
                   <http://example.org/#p3> <http://example.org/#O4> .

               """
    end

    test "one named graph only" do
      assert TriG.Encoder.encode!(
               Dataset.new([
                 {EX.S1, EX.p1(), EX.O1, EX.Graph},
                 {EX.S1, EX.p1(), EX.O2, EX.Graph},
                 {EX.S1, EX.p2(), EX.O3, EX.Graph},
                 {EX.S2, EX.p3(), EX.O4, EX.Graph}
               ]),
               prefixes: %{}
             ) ==
               """
               GRAPH <http://example.org/#Graph> {
                   <http://example.org/#S1>
                       <http://example.org/#p1> <http://example.org/#O1>, <http://example.org/#O2> ;
                       <http://example.org/#p2> <http://example.org/#O3> .

                   <http://example.org/#S2>
                       <http://example.org/#p3> <http://example.org/#O4> .
               }
               """
    end

    test "multiple graphs" do
      assert TriG.Encoder.encode!(
               Dataset.new([
                 {EX.S1, EX.p1(), EX.O1, EX.Graph1},
                 {EX.S1, EX.p1(), EX.O2, EX.Graph2},
                 {EX.S1, EX.p2(), EX.O3, EX.Graph2},
                 {EX.S2, EX.p3(), EX.O4}
               ]),
               prefixes: %{}
             ) ==
               """
               <http://example.org/#S2>
                   <http://example.org/#p3> <http://example.org/#O4> .

               GRAPH <http://example.org/#Graph1> {
                   <http://example.org/#S1>
                       <http://example.org/#p1> <http://example.org/#O1> .
               }

               GRAPH <http://example.org/#Graph2> {
                   <http://example.org/#S1>
                       <http://example.org/#p1> <http://example.org/#O2> ;
                       <http://example.org/#p2> <http://example.org/#O3> .
               }
               """
    end

    test "statements and graph names with prefixed names" do
      assert TriG.Encoder.encode!(
               Dataset.new([
                 {EX.S1, EX.p1(), EX.O1, EX.Graph},
                 {EX.S1, EX.p1(), EX.O2, EX.Graph},
                 {EX.S1, EX.p2(), EX.O3},
                 {EX.S2, EX.p3(), EX.O4}
               ]),
               prefixes: %{
                 ex: EX,
                 xsd: NS.XSD
               }
             ) ==
               """
               @prefix ex: <#{to_string(EX.__base_iri__())}> .
               @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

               ex:S1
                   ex:p2 ex:O3 .

               ex:S2
                   ex:p3 ex:O4 .

               GRAPH ex:Graph {
                   ex:S1
                       ex:p1 ex:O1, ex:O2 .
               }
               """
    end

    test "when no prefixes are given, the prefixes from the given graph are used" do
      assert TriG.Encoder.encode!(
               Dataset.new([
                 Graph.new(
                   [
                     {EX.S1, EX.p1(), EX.O1},
                     {EX.S1, EX.p1(), EX.O2}
                   ],
                   name: EX.Graph,
                   prefixes: %{
                     "": EX
                   }
                 ),
                 Graph.new(
                   [
                     {EX.S1, EX.p2(), NS.XSD.integer()},
                     {EX.S2, EX.p3(), EX.O4}
                   ],
                   prefixes: [
                     xsd: NS.XSD
                   ]
                 )
               ])
             ) ==
               """
               @prefix : <#{to_string(EX.__base_iri__())}> .
               @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

               :S1
                   :p2 xsd:integer .

               :S2
                   :p3 :O4 .

               GRAPH :Graph {
                   :S1
                       :p1 :O1, :O2 .
               }
               """
    end

    test "with base_iri" do
      assert TriG.Encoder.encode!(
               Dataset.new([
                 {EX.S1, EX.p1(), EX.O1},
                 Graph.new(
                   [
                     {EX.S1, EX.p1(), EX.O1},
                     {EX.S1, EX.p1(), EX.O2}
                   ],
                   name: EX.Graph,
                   base_iri: EX.other()
                 )
               ]),
               prefixes: %{},
               base_iri: EX
             ) ==
               """
               @base <#{to_string(EX.__base_iri__())}> .

               <S1>
                   <p1> <O1> .

               GRAPH <Graph> {
                   <S1>
                       <p1> <O1>, <O2> .
               }
               """
    end

    test ":implicit_base option" do
      assert TriG.Encoder.encode!(
               Dataset.new([
                 {EX.S1, EX.p1(), EX.O1},
                 {EX.S1, EX.p1(), EX.O1, EX.Graph},
                 {EX.S1, EX.p1(), EX.O2, EX.Graph}
               ]),
               base_iri: EX,
               prefixes: %{},
               implicit_base: true
             ) ==
               """
               <S1>
                   <p1> <O1> .

               GRAPH <Graph> {
                   <S1>
                       <p1> <O1>, <O2> .
               }
               """
    end

    test ":base_description with a base IRI" do
      assert TriG.Encoder.encode!(
               Dataset.new([{EX.S1, EX.p1(), EX.O1, EX.Graph}]),
               base_iri: EX,
               prefixes: %{},
               base_description: %{EX.P2 => [EX.O2, EX.O3]}
             ) ==
               """
               @base <#{to_string(EX.__base_iri__())}> .

               <>
                   <P2> <O2>, <O3> .

               GRAPH <Graph> {
                   <S1>
                       <p1> <O1> .
               }
               """
    end

    test ":base_description without a base IRI" do
      assert Graph.new([{EX.S1, EX.p1(), EX.O1}], name: EX.Graph, prefixes: %{ex: EX})
             |> Dataset.new()
             |> TriG.Encoder.encode!(base_description: %{EX.P2 => [EX.O2, EX.O3]}) ==
               """
               @prefix ex: <#{to_string(EX.__base_iri__())}> .

               <>
                   ex:P2 ex:O2, ex:O3 .

               GRAPH ex:Graph {
                   ex:S1
                       ex:p1 ex:O1 .
               }
               """
    end

    test "when no prefixes are given and no prefixes are in the given graph the default_prefixes are used" do
      assert TriG.Encoder.encode!(Dataset.new({EX.S, EX.p(), NS.XSD.string(), EX.Graph})) ==
               """
               @prefix rdf: <#{to_string(RDF.__base_iri__())}> .
               @prefix rdfs: <#{to_string(RDFS.__base_iri__())}> .
               @prefix xsd: <#{to_string(NS.XSD.__base_iri__())}> .

               GRAPH <http://example.org/#Graph> {
                   <http://example.org/#S>
                       <http://example.org/#p> xsd:string .
               }
               """
    end

    test "statements with literals" do
      assert TriG.Encoder.encode!(
               Dataset.new([
                 {EX.S1, EX.p1(), ~L"foo", EX.Graph},
                 {EX.S1, EX.p1(), ~L"foo"en, EX.Graph},
                 {EX.S2, EX.p2(), RDF.literal("strange things", datatype: EX.custom()), EX.Graph}
               ]),
               prefixes: %{}
             ) ==
               """
               GRAPH <http://example.org/#Graph> {
                   <http://example.org/#S1>
                       <http://example.org/#p1> "foo"@en, "foo" .

                   <http://example.org/#S2>
                       <http://example.org/#p2> "strange things"^^<#{EX.custom()}> .
               }
               """
    end

    test "statements with blank nodes" do
      assert TriG.Encoder.encode!(
               Dataset.new([
                 {EX.S1, EX.p1(), [RDF.bnode(1), RDF.bnode("foo"), RDF.bnode(:bar)]},
                 {EX.S2, EX.p1(), [RDF.bnode(1), RDF.bnode("foo"), RDF.bnode(:bar)], EX.Graph}
               ]),
               prefixes: %{}
             ) ==
               """
               <http://example.org/#S1>
                   <http://example.org/#p1> _:b1, _:bar, _:foo .

               GRAPH <http://example.org/#Graph> {
                   <http://example.org/#S2>
                       <http://example.org/#p1> _:b1, _:bar, _:foo .
               }
               """
    end

    test "blank node cycles" do
      assert TriG.Encoder.encode!(
               Dataset.new([{~B<foo>, EX.p(), ~B<foo>}]),
               prefixes: %{}
             ) ==
               """
               _:foo
                   <http://example.org/#p> _:foo .

               """

      assert TriG.Encoder.encode!(
               Dataset.new([{~B<foo>, EX.p(), ~B<foo>, EX.Graph}]),
               prefixes: %{}
             ) ==
               """
               GRAPH <http://example.org/#Graph> {
                   _:foo
                       <http://example.org/#p> _:foo .
               }
               """

      assert TriG.Encoder.encode!(
               Dataset.new([
                 {~B<foo>, EX.p(), ~B<bar>, EX.Graph},
                 {~B<bar>, EX.p(), ~B<foo>, EX.Graph}
               ]),
               prefixes: %{}
             ) ==
               """
               GRAPH <http://example.org/#Graph> {
                   _:bar
                       <http://example.org/#p> _:foo .

                   _:foo
                       <http://example.org/#p> _:bar .
               }
               """

      assert TriG.Encoder.encode!(
               Dataset.new([{~B<foo>, EX.p(), ~B<bar>, EX.Graph}, {~B<bar>, EX.p(), ~B<foo>}]),
               prefixes: %{}
             ) ==
               """
               _:bar
                   <http://example.org/#p> _:foo .

               GRAPH <http://example.org/#Graph> {
                   _:foo
                       <http://example.org/#p> _:bar .
               }
               """

      assert TriG.Encoder.encode!(
               Dataset.new([
                 {~B<foo>, EX.p(), ~B<bar>, EX.Graph},
                 {~B<bar>, EX.p(), ~B<baz>},
                 {~B<baz>, EX.p(), ~B<foo>, EX.Graph}
               ]),
               prefixes: %{}
             ) ==
               """
               _:bar
                   <http://example.org/#p> _:baz .

               GRAPH <http://example.org/#Graph> {
                   _:baz
                       <http://example.org/#p> _:foo .

                   _:foo
                       <http://example.org/#p> _:bar .
               }
               """

      assert TriG.Encoder.encode!(
               Dataset.new([
                 {~B<foo>, EX.p1(), ~B<bar>, EX.Graph},
                 {~B<bar>, EX.p2(), ~B<baz>, EX.Graph},
                 {~B<baz>, EX.p3(), ~B<bar>}
               ]),
               prefixes: %{}
             ) ==
               """
               _:baz
                   <http://example.org/#p3> _:bar .

               GRAPH <http://example.org/#Graph> {
                   _:bar
                       <http://example.org/#p2> _:baz .

                   [
                       <http://example.org/#p1> _:bar
                   ] .
               }
               """
    end

    test "deeply embedded blank node descriptions" do
      assert TriG.Encoder.encode!(
               Dataset.new([
                 {~B<foo>, EX.p1(), ~B<bar>, EX.Graph},
                 {~B<bar>, EX.p2(), ~B<baz>, EX.Graph},
                 {~B<baz>, EX.p3(), 42, EX.Graph}
               ]),
               prefixes: %{}
             ) ==
               """
               GRAPH <http://example.org/#Graph> {
                   [
                       <http://example.org/#p1> [
                           <http://example.org/#p2> [
                               <http://example.org/#p3> 42
                           ]
                       ]
                   ] .
               }
               """
    end

    test "ordering of descriptions" do
      assert TriG.Encoder.encode!(
               Dataset.new([
                 {EX.__base_iri__(), RDF.type(), OWL.Ontology},
                 {EX.S1, RDF.type(), EX.O},
                 {EX.S2, RDF.type(), RDFS.Class},
                 {EX.S3, RDF.type(), RDF.Property},
                 {EX.__base_iri__(), RDF.type(), OWL.Ontology, EX.Graph},
                 {EX.S1, RDF.type(), EX.O, EX.Graph},
                 {EX.S2, RDF.type(), RDFS.Class, EX.Graph},
                 {EX.S3, RDF.type(), RDF.Property, EX.Graph}
               ]),
               base_iri: EX,
               prefixes: %{
                 rdf: RDF,
                 rdfs: RDFS,
                 owl: OWL
               }
             ) ==
               """
               @base <#{to_string(EX.__base_iri__())}> .

               @prefix owl: <#{to_string(OWL.__base_iri__())}> .
               @prefix rdf: <#{to_string(RDF.__base_iri__())}> .
               @prefix rdfs: <#{to_string(RDFS.__base_iri__())}> .

               <>
                   a owl:Ontology .

               <S2>
                   a rdfs:Class .

               <S1>
                   a <O> .

               <S3>
                   a rdf:Property .

               GRAPH <Graph> {
                   <>
                       a owl:Ontology .

                   <S2>
                       a rdfs:Class .

                   <S1>
                       a <O> .

                   <S3>
                       a rdf:Property .
               }
               """
    end

    test ":directive_style option" do
      assert TriG.Encoder.encode!(Dataset.new({EX.S, RDFS.subClassOf(), EX.O, EX.Graph}),
               prefixes: %{rdfs: RDFS.__base_iri__()},
               base_iri: EX,
               directive_style: :turtle
             ) ==
               """
               @base <#{to_string(EX.__base_iri__())}> .

               @prefix rdfs: <#{to_string(RDFS.__base_iri__())}> .

               GRAPH <Graph> {
                   <S>
                       rdfs:subClassOf <O> .
               }
               """

      assert TriG.Encoder.encode!(Dataset.new({EX.S, RDFS.subClassOf(), EX.O}),
               prefixes: %{rdfs: RDFS.__base_iri__()},
               base_iri: EX,
               directive_style: :sparql
             ) ==
               """
               BASE <#{to_string(EX.__base_iri__())}>

               PREFIX rdfs: <#{to_string(RDFS.__base_iri__())}>

               <S>
                   rdfs:subClassOf <O> .

               """
    end

    test ":content option" do
      opts = [
        prefixes: %{rdfs: RDFS},
        base_iri: EX
      ]

      dataset =
        Dataset.new([
          {EX.S, RDFS.subClassOf(), EX.O},
          {EX.S1, EX.p1(), EX.O1, EX.Graph}
        ])

      assert TriG.Encoder.encode!(dataset, Keyword.merge(opts, content: :triples)) ==
               """
               <S>
                   rdfs:subClassOf <O> .

               GRAPH <Graph> {
                   <S1>
                       <p1> <O1> .
               }
               """

      assert TriG.Encoder.encode!(dataset, Keyword.merge(opts, content: :graphs)) ==
               """
               <S>
                   rdfs:subClassOf <O> .

               GRAPH <Graph> {
                   <S1>
                       <p1> <O1> .
               }
               """

      assert TriG.Encoder.encode!(dataset, Keyword.merge(opts, content: :default_graph)) ==
               """
               <S>
                   rdfs:subClassOf <O> .
               """

      assert TriG.Encoder.encode!(dataset, Keyword.merge(opts, content: :named_graphs)) ==
               """
               GRAPH <Graph> {
                   <S1>
                       <p1> <O1> .
               }
               """

      assert TriG.Encoder.encode!(
               dataset,
               Keyword.merge(opts, content: [:named_graphs, "\n", :default_graph])
             ) ==
               """
               GRAPH <Graph> {
                   <S1>
                       <p1> <O1> .
               }

               <S>
                   rdfs:subClassOf <O> .
               """

      assert TriG.Encoder.encode!(dataset, Keyword.merge(opts, content: :prefixes)) ==
               """
               @prefix rdfs: <#{to_string(RDFS.__base_iri__())}> .

               """

      assert TriG.Encoder.encode!(dataset, Keyword.merge(opts, content: :base)) ==
               """
               @base <#{to_string(EX.__base_iri__())}> .

               """

      assert TriG.Encoder.encode!(
               dataset,
               Keyword.merge(opts, content: :directives, directive_style: :sparql)
             ) ==
               """
               BASE <#{to_string(EX.__base_iri__())}>

               PREFIX rdfs: <#{to_string(RDFS.__base_iri__())}>

               """

      assert TriG.Encoder.encode!(
               dataset,
               Keyword.merge(opts,
                 content: [
                   "# === HEADER ===\n\n",
                   :directives,
                   "\n# === NAMED GRAPHS ===\n\n",
                   :named_graphs,
                   "\n# === DEFAULT GRAPH ===\n\n",
                   :default_graph
                 ],
                 directive_style: :sparql
               )
             ) ==
               """
               # === HEADER ===

               BASE <#{to_string(EX.__base_iri__())}>

               PREFIX rdfs: <#{to_string(RDFS.__base_iri__())}>


               # === NAMED GRAPHS ===

               GRAPH <Graph> {
                   <S1>
                       <p1> <O1> .
               }

               # === DEFAULT GRAPH ===

               <S>
                   rdfs:subClassOf <O> .
               """

      assert_raise RuntimeError, "unknown TriG document element: :undefined", fn ->
        TriG.Encoder.encode!(dataset, content: :undefined)
      end
    end

    test ":indent option" do
      graph =
        Dataset.new([
          {EX.S, RDFS.subClassOf(), EX.O},
          {RDF.bnode("foo"), EX.p(), EX.O2, EX.Graph}
        ])

      assert TriG.Encoder.encode!(graph,
               indent: 2,
               prefixes: %{rdfs: RDFS},
               base_iri: EX
             ) ==
               """
                 @base <#{to_string(EX.__base_iri__())}> .

                 @prefix rdfs: <#{to_string(RDFS.__base_iri__())}> .

                 <S>
                     rdfs:subClassOf <O> .

                 GRAPH <Graph> {
                     [
                         <p> <O2>
                     ] .
                 }
               """
    end

    test "serializing a dataset with a pathological graph with an empty description" do
      description = RDF.description(EX.S)

      dataset =
        %Graph{Graph.new() | descriptions: %{description.subject => description}}
        |> Dataset.new()

      assert_raise Graph.EmptyDescriptionError, fn ->
        TriG.Encoder.encode!(dataset)
      end
    end
  end

  test "serializing a graph" do
    graph = EX.S |> EX.p(EX.O) |> RDF.graph()

    assert TriG.Encoder.encode!(graph) ==
             graph |> Dataset.new() |> TriG.Encoder.encode!()
  end

  test "serializing a description" do
    description = EX.S |> EX.p(EX.O)

    assert TriG.Encoder.encode!(description) ==
             description |> Dataset.new() |> TriG.Encoder.encode!()
  end

  describe "lists" do
    test "should generate literal list" do
      TriG.read_string!(
        ~s[@prefix ex: <http://example.com/> . GRAPH ex:Graph { ex:a ex:b ( "apple" "banana" ) . }]
      )
      |> assert_serialization(
        prefixes: %{ex: ~I<http://example.com/>},
        matches: [
          {~r[ex:a\s+ex:b\s+\("apple" "banana"\)\s+\.], "doesn't include the list as a TriG list"}
        ]
      )
    end

    test "should generate empty list" do
      TriG.read_string!(~s[@prefix ex: <http://example.com/> . GRAPH ex:Graph { ex:a ex:b () . }])
      |> assert_serialization(
        prefixes: %{ex: ~I<http://example.com/>},
        matches: [
          {~r[ex:a\s+ex:b\s+\(\)\s+\.], "doesn't include the list as a TriG list"}
        ]
      )
    end

    test "should generate empty list as subject" do
      TriG.read_string!(~s[@prefix ex: <http://example.com/> . () ex:a ex:b .])
      |> assert_serialization(
        prefixes: %{ex: ~I<http://example.com/>},
        matches: [
          {~r[\(\)\s+ex:a\s+ex:b\s+\.], "doesn't include the list as a TriG list"}
        ]
      )
    end

    test "should generate list as subject" do
      TriG.read_string!(~s[@prefix ex: <http://example.com/> . (ex:a) ex:b ex:c .])
      |> assert_serialization(
        prefixes: %{ex: ~I<http://example.com/>},
        matches: [
          {~r[\(ex:a\)\s+ex:b\s+ex:c\s+\.], "doesn't include the list as a TriG list"}
        ]
      )
    end

    test "should generate list of empties" do
      graph =
        TriG.read_string!(~s{@prefix ex: <http://example.com/> . [ex:listOf2Empties (() ())] .})

      serialization =
        assert_serialization(graph,
          prefixes: %{ex: ~I<http://example.com/>},
          matches: [
            {~r[\[\s*ex:listOf2Empties \(\(\) \(\)\)\s\]\s+\.],
             "doesn't include the list as a TriG list"}
          ]
        )

      refute String.contains?(serialization, to_string(RDF.first())),
             ~s[output\n\n#{serialization}\n\ncontains #{to_string(RDF.first())}]

      refute String.contains?(serialization, to_string(RDF.rest())),
             ~s[output\n\n#{serialization}\n\ncontains #{to_string(RDF.rest())}]
    end

    test "should generate list anon" do
      TriG.read_string!(
        ~s{@prefix ex: <http://example.com/> . [ex:twoAnons ([a ex:mother] [a ex:father])] .}
      )
      |> assert_serialization(
        prefixes: %{ex: ~I<http://example.com/>},
        matches: [
          {~r[\[\s*ex:twoAnons \(\[\s*a ex:mother\s*\]\s+\[\s*a ex:father\s*\]\s*\)\s*\]\s+\.],
           "doesn't include the list as a TriG list"}
        ]
      )
    end

    test "when one of the list nodes is referenced in other statements the whole list is not represented as a TriG list structure" do
      Dataset.new(
        ~B<Foo>
        |> RDF.first(EX.Foo)
        |> RDF.rest(~B<Bar>)
      )
      |> Dataset.add(
        ~B<Bar>
        |> RDF.first(EX.Bar)
        |> RDF.rest(RDF.nil())
      )
      |> Dataset.add({EX.Baz, EX.quux(), ~B<Bar>, EX.Graph})
      |> assert_serialization(
        prefixes: %{ex: EX.__base_iri__()},
        # TODO: provide a positive match
        neg_matches: [
          {~r[\(\s*ex:Foo\s+ex:Bar\s*\)], "does include the list as a TriG list"}
        ]
      )
    end

    test "when given an invalid list" do
      Graph.new(
        ~B<Foo>
        |> RDF.first(1)
        |> RDF.rest(EX.Foo)
      )
      |> assert_serialization(
        prefixes: %{ex: ~I<http://example.com/>},
        # TODO: provide a positive match
        neg_matches: [
          {~r[\[\s*_:Foo \(\(\) \(\)\)\]\s+\.], "does include the invalid list as a TriG list"}
        ]
      )
    end
  end

  defp assert_serialization(dataset, opts) do
    prefixes = Keyword.get(opts, :prefixes, %{})
    base_iri = Keyword.get(opts, :base_iri)
    matches = Keyword.get(opts, :matches, [])
    neg_matches = Keyword.get(opts, :neg_matches, [])

    assert {:ok, serialized} = TriG.write_string(dataset, prefixes: prefixes, base_iri: base_iri)

    matches
    |> Stream.map(fn
      {pattern, message} ->
        {pattern, ~s[output\n\n#{serialized}\n\n#{message}]}

      pattern ->
        {pattern, ~s[output\n\n#{serialized}\n\ndoesn't include #{inspect(pattern)}]}
    end)
    |> Enum.each(fn
      {%Regex{} = pattern, message} ->
        assert Regex.match?(pattern, serialized), message

      {contents, message} ->
        assert String.contains?(serialized, contents), message
    end)

    neg_matches
    |> Stream.map(fn
      {pattern, message} ->
        {pattern, ~s[output\n\n#{serialized}\n\n#{message}]}

      pattern ->
        {pattern, ~s[output\n\n#{serialized}\n\ndoes include #{inspect(pattern)}]}
    end)
    |> Enum.each(fn
      {%Regex{} = pattern, message} ->
        refute Regex.match?(pattern, serialized), message

      {contents, message} ->
        refute String.contains?(serialized, contents), message
    end)

    serialized
  end
end
