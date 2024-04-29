defmodule RDF.Turtle.EncoderTest do
  use ExUnit.Case, async: false

  alias RDF.Turtle

  doctest Turtle.Encoder

  alias RDF.{Graph, PrefixMap}
  alias RDF.NS
  alias RDF.NS.{RDFS, OWL}

  import RDF.Sigils

  use RDF.Vocabulary.Namespace

  defvocab EX, base_iri: "http://example.org/#", terms: [], strict: false

  describe "serializing a graph" do
    test "an empty graph is serialized to an empty string" do
      assert Turtle.Encoder.encode!(Graph.new(), prefixes: %{}) == ""
    end

    test "statements with IRIs only" do
      assert Turtle.Encoder.encode!(
               Graph.new([
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

    test "statements with prefixed names" do
      assert Turtle.Encoder.encode!(
               Graph.new([
                 {EX.S1, EX.p1(), EX.O1},
                 {EX.S1, EX.p1(), EX.O2},
                 {EX.S1, EX.p2(), EX.O3},
                 {EX.S2, EX.p3(), EX.O4}
               ]),
               prefixes: %{
                 ex: EX.__base_iri__(),
                 xsd: NS.XSD.__base_iri__()
               }
             ) ==
               """
               @prefix ex: <#{to_string(EX.__base_iri__())}> .
               @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

               ex:S1
                   ex:p1 ex:O1, ex:O2 ;
                   ex:p2 ex:O3 .

               ex:S2
                   ex:p3 ex:O4 .
               """
    end

    test "when no prefixes are given, the prefixes from the given graph are used" do
      assert Turtle.Encoder.encode!(
               Graph.new(
                 [
                   {EX.S1, EX.p1(), EX.O1},
                   {EX.S1, EX.p1(), EX.O2},
                   {EX.S1, EX.p2(), NS.XSD.integer()},
                   {EX.S2, EX.p3(), EX.O4}
                 ],
                 prefixes: %{
                   "": EX.__base_iri__(),
                   xsd: NS.XSD.__base_iri__()
                 }
               )
             ) ==
               """
               @prefix : <#{to_string(EX.__base_iri__())}> .
               @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

               :S1
                   :p1 :O1, :O2 ;
                   :p2 xsd:integer .

               :S2
                   :p3 :O4 .
               """
    end

    test "when no base IRI is given, the base IRI from the given graph is used" do
      assert Turtle.Encoder.encode!(
               Graph.new([{EX.S1, EX.p1(), EX.O1}],
                 base_iri: EX.__base_iri__()
               ),
               prefixes: %{}
             ) ==
               """
               @base <#{to_string(EX.__base_iri__())}> .

               <S1>
                   <p1> <O1> .
               """

      base_without_hash = "http://example.com/foo"

      assert Turtle.Encoder.encode!(
               Graph.new(
                 [
                   {
                     RDF.iri(base_without_hash <> "#S1"),
                     RDF.iri(base_without_hash <> "#p1"),
                     RDF.iri(base_without_hash <> "#O1")
                   }
                 ],
                 base_iri: base_without_hash
               ),
               prefixes: %{}
             ) ==
               """
               @base <#{base_without_hash}> .

               <#S1>
                   <#p1> <#O1> .
               """
    end

    test "when a base IRI is given, it is used instead of the base IRI of the given graph" do
      assert Turtle.Encoder.encode!(
               Graph.new([{EX.S1, EX.p1(), EX.O1}],
                 base_iri: EX.other()
               ),
               base_iri: EX,
               prefixes: %{}
             ) ==
               """
               @base <#{to_string(EX.__base_iri__())}> .

               <S1>
                   <p1> <O1> .
               """
    end

    test ":implicit_base option" do
      assert Turtle.Encoder.encode!(
               Graph.new([{EX.S1, EX.p1(), EX.O1}],
                 base_iri: EX.other()
               ),
               prefixes: %{},
               base_iri: EX,
               implicit_base: true
             ) ==
               """
               <S1>
                   <p1> <O1> .
               """

      assert Turtle.Encoder.encode!(
               Graph.new([{EX.S1, EX.p1(), EX.O1}],
                 base_iri: EX
               ),
               prefixes: %{},
               implicit_base: true
             ) ==
               """
               <S1>
                   <p1> <O1> .
               """
    end

    test ":base_description with a base IRI" do
      assert Turtle.Encoder.encode!(
               Graph.new([{EX.S1, EX.p1(), EX.O1}]),
               prefixes: %{},
               base_iri: EX,
               base_description: %{EX.P2 => [EX.O2, EX.O3]}
             ) ==
               """
               @base <#{to_string(EX.__base_iri__())}> .

               <>
                   <P2> <O2>, <O3> .

               <S1>
                   <p1> <O1> .
               """

      assert Turtle.Encoder.encode!(
               Graph.new([{EX.S1, EX.p1(), EX.O1}],
                 base_iri: EX
               ),
               prefixes: %{},
               base_description: %{EX.P2 => [EX.O2, EX.O3]}
             ) ==
               """
               @base <#{to_string(EX.__base_iri__())}> .

               <>
                   <P2> <O2>, <O3> .

               <S1>
                   <p1> <O1> .
               """
    end

    test ":base_description without a base IRI" do
      assert Turtle.Encoder.encode!(
               Graph.new([{EX.S1, EX.p1(), EX.O1}],
                 prefixes: %{ex: EX}
               ),
               base_description: %{EX.P2 => [EX.O2, EX.O3]}
             ) ==
               """
               @prefix ex: <#{to_string(EX.__base_iri__())}> .

               <>
                   ex:P2 ex:O2, ex:O3 .

               ex:S1
                   ex:p1 ex:O1 .
               """
    end

    test "when no prefixes are given and no prefixes are in the given graph the default_prefixes are used" do
      assert Turtle.Encoder.encode!(Graph.new({EX.S, EX.p(), NS.XSD.string()})) ==
               """
               @prefix rdf: <#{to_string(RDF.__base_iri__())}> .
               @prefix rdfs: <#{to_string(RDFS.__base_iri__())}> .
               @prefix xsd: <#{to_string(NS.XSD.__base_iri__())}> .

               <http://example.org/#S>
                   <http://example.org/#p> xsd:string .
               """
    end

    test "statements with empty prefixed names" do
      assert Turtle.Encoder.encode!(Graph.new({EX.S, EX.p(), EX.O}),
               prefixes: %{"" => EX.__base_iri__()}
             ) ==
               """
               @prefix : <#{to_string(EX.__base_iri__())}> .

               :S
                   :p :O .
               """

      assert Turtle.Encoder.encode!(Graph.new({EX.S, EX.p(), EX.O}),
               prefixes: PrefixMap.new("": EX.__base_iri__())
             ) ==
               """
               @prefix : <#{to_string(EX.__base_iri__())}> .

               :S
                   :p :O .
               """
    end

    test "statements with literals" do
      assert Turtle.Encoder.encode!(
               Graph.new([
                 {EX.S1, EX.p1(), ~L"foo"},
                 {EX.S1, EX.p1(), ~L"foo"en},
                 {EX.S2, EX.p2(), RDF.literal("strange things", datatype: EX.custom())}
               ]),
               prefixes: %{}
             ) ==
               """
               <http://example.org/#S1>
                   <http://example.org/#p1> "foo"@en, "foo" .

               <http://example.org/#S2>
                   <http://example.org/#p2> "strange things"^^<#{EX.custom()}> .
               """
    end

    test "statements with blank nodes" do
      assert Turtle.Encoder.encode!(
               Graph.new([
                 {EX.S1, EX.p1(), [RDF.bnode(1), RDF.bnode("foo"), RDF.bnode(:bar)]},
                 {EX.S2, EX.p1(), [RDF.bnode(1), RDF.bnode("foo"), RDF.bnode(:bar)]}
               ]),
               prefixes: %{}
             ) ==
               """
               <http://example.org/#S1>
                   <http://example.org/#p1> _:b1, _:bar, _:foo .

               <http://example.org/#S2>
                   <http://example.org/#p1> _:b1, _:bar, _:foo .
               """
    end

    test "blank node cycles" do
      assert Turtle.Encoder.encode!(
               Graph.new([{~B<foo>, EX.p(), ~B<foo>}]),
               prefixes: %{}
             ) ==
               """
               _:foo
                   <http://example.org/#p> _:foo .
               """

      assert Turtle.Encoder.encode!(
               Graph.new([{~B<foo>, EX.p(), ~B<bar>}, {~B<bar>, EX.p(), ~B<foo>}]),
               prefixes: %{}
             ) ==
               """
               _:bar
                   <http://example.org/#p> _:foo .

               _:foo
                   <http://example.org/#p> _:bar .
               """

      assert Turtle.Encoder.encode!(
               Graph.new([
                 {~B<foo>, EX.p(), ~B<bar>},
                 {~B<bar>, EX.p(), ~B<baz>},
                 {~B<baz>, EX.p(), ~B<foo>}
               ]),
               prefixes: %{}
             ) ==
               """
               _:bar
                   <http://example.org/#p> _:baz .

               _:baz
                   <http://example.org/#p> _:foo .

               _:foo
                   <http://example.org/#p> _:bar .
               """

      assert Turtle.Encoder.encode!(
               Graph.new([
                 {~B<foo>, EX.p1(), ~B<bar>},
                 {~B<bar>, EX.p2(), ~B<baz>},
                 {~B<baz>, EX.p3(), ~B<bar>}
               ]),
               prefixes: %{}
             ) ==
               """
               _:bar
                   <http://example.org/#p2> _:baz .

               _:baz
                   <http://example.org/#p3> _:bar .

               [
                   <http://example.org/#p1> _:bar
               ] .
               """
    end

    test "deeply embedded blank node descriptions" do
      assert Turtle.Encoder.encode!(
               Graph.new([
                 {~B<foo>, EX.p1(), ~B<bar>},
                 {~B<bar>, EX.p2(), ~B<baz>},
                 {~B<baz>, EX.p2(), EX.O},
                 {~B<baz>, EX.p3(), [42, 23, 3.14]}
               ]),
               prefixes: %{}
             ) ==
               """
               [
                   <http://example.org/#p1> [
                       <http://example.org/#p2> [
                           <http://example.org/#p2> <http://example.org/#O> ;
                           <http://example.org/#p3> 23, 42, 3.14E0
                       ]
                   ]
               ] .
               """
    end

    test "ordering of descriptions" do
      assert Turtle.Encoder.encode!(
               Graph.new([
                 {EX.__base_iri__(), RDF.type(), OWL.Ontology},
                 {EX.S1, RDF.type(), EX.O},
                 {EX.S2, RDF.type(), RDFS.Class},
                 {EX.S3, RDF.type(), RDF.Property}
               ]),
               base_iri: EX.__base_iri__(),
               prefixes: %{
                 rdf: RDF.__base_iri__(),
                 rdfs: RDFS.__base_iri__(),
                 owl: OWL.__base_iri__()
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
               """
    end

    test ":directive_style option" do
      assert Turtle.Encoder.encode!(Graph.new({EX.S, RDFS.subClassOf(), EX.O}),
               prefixes: %{rdfs: RDFS.__base_iri__()},
               base_iri: EX.__base_iri__(),
               directive_style: :turtle
             ) ==
               """
               @base <#{to_string(EX.__base_iri__())}> .

               @prefix rdfs: <#{to_string(RDFS.__base_iri__())}> .

               <S>
                   rdfs:subClassOf <O> .
               """

      assert Turtle.Encoder.encode!(Graph.new({EX.S, RDFS.subClassOf(), EX.O}),
               prefixes: %{rdfs: RDFS.__base_iri__()},
               base_iri: EX.__base_iri__(),
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
      graph =
        Graph.new({EX.S, RDFS.subClassOf(), EX.O},
          prefixes: %{rdfs: RDFS.__base_iri__()},
          base_iri: EX.__base_iri__()
        )

      assert Turtle.Encoder.encode!(graph, content: :triples) ==
               """
               <S>
                   rdfs:subClassOf <O> .
               """

      assert Turtle.Encoder.encode!(graph, content: :prefixes) ==
               """
               @prefix rdfs: <#{to_string(RDFS.__base_iri__())}> .
               """

      assert Turtle.Encoder.encode!(graph, content: :base) ==
               """
               @base <#{to_string(EX.__base_iri__())}> .
               """

      assert Turtle.Encoder.encode!(graph, content: :directives, directive_style: :sparql) ==
               """
               BASE <#{to_string(EX.__base_iri__())}>

               PREFIX rdfs: <#{to_string(RDFS.__base_iri__())}>
               """

      assert Turtle.Encoder.encode!(graph,
               content: [
                 "# === HEADER ===\n\n",
                 :directives,
                 "\n# === TRIPLES ===\n\n",
                 :triples
               ],
               directive_style: :sparql
             ) ==
               """
               # === HEADER ===

               BASE <#{to_string(EX.__base_iri__())}>

               PREFIX rdfs: <#{to_string(RDFS.__base_iri__())}>

               # === TRIPLES ===

               <S>
                   rdfs:subClassOf <O> .
               """

      assert_raise RuntimeError, "unknown Turtle document element: :undefined", fn ->
        Turtle.Encoder.encode!(graph, content: :undefined)
      end
    end

    test ":indent option" do
      graph =
        Graph.new(
          [
            {EX.S, RDFS.subClassOf(), EX.O},
            {RDF.bnode("foo"), EX.p(), EX.O2}
          ],
          prefixes: %{rdfs: RDFS.__base_iri__()},
          base_iri: EX.__base_iri__()
        )

      assert Turtle.Encoder.encode!(graph, indent: 2) ==
               """
                 @base <#{to_string(EX.__base_iri__())}> .

                 @prefix rdfs: <#{to_string(RDFS.__base_iri__())}> .

                 <S>
                     rdfs:subClassOf <O> .

                 [
                     <p> <O2>
                 ] .
               """
    end

    test ":no_object_lists option" do
      assert Turtle.Encoder.encode!(
               Graph.new([
                 {EX.S1, EX.p1(), EX.O1},
                 {EX.S1, EX.p1(), EX.O2},
                 {EX.S1, EX.p2(), "foo"}
               ]),
               prefixes: %{
                 ex: EX.__base_iri__(),
                 xsd: NS.XSD.__base_iri__()
               },
               no_object_lists: true
             ) ==
               """
               @prefix ex: <#{to_string(EX.__base_iri__())}> .
               @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

               ex:S1
                   ex:p1 ex:O1 ;
                   ex:p1 ex:O2 ;
                   ex:p2 "foo" .
               """

      assert Graph.new([
               {~B<foo>, EX.p1(), ~B<bar>},
               {~B<bar>, EX.p2(), ~B<baz>},
               {~B<baz>, EX.p2(), EX.O},
               {~B<baz>, EX.p3(), [42, 23, 3.14]}
             ])
             |> Turtle.Encoder.encode!(
               prefixes: %{},
               no_object_lists: true
             ) ==
               """
               [
                   <http://example.org/#p1> [
                       <http://example.org/#p2> [
                           <http://example.org/#p2> <http://example.org/#O> ;
                           <http://example.org/#p3> 23 ;
                           <http://example.org/#p3> 42 ;
                           <http://example.org/#p3> 3.14E0
                       ]
                   ]
               ] .
               """

      assert Graph.new(
               ~B<Foo>
               |> RDF.first(EX.Foo)
               |> RDF.rest(~B<Bar>)
             )
             |> Graph.add(
               ~B<Bar>
               |> RDF.first(EX.Bar)
               |> RDF.rest(~B<Baz>)
             )
             |> Graph.add(
               ~B<Baz>
               |> RDF.first(~B<BazEmbedded>)
               |> RDF.rest(RDF.nil())
             )
             |> Graph.add([
               {EX.Foo, EX.p1(), [1, 2, 3]},
               {~B<BazEmbedded>, EX.p2(), [EX.Foo, EX.Bar]}
             ])
             |> Turtle.Encoder.encode!(
               prefixes: %{},
               no_object_lists: true
             ) ==
               """
               <http://example.org/#Foo>
                   <http://example.org/#p1> 1 ;
                   <http://example.org/#p1> 2 ;
                   <http://example.org/#p1> 3 .

               (
                   <http://example.org/#Foo>
                   <http://example.org/#Bar>
                   [
                       <http://example.org/#p2> <http://example.org/#Bar> ;
                       <http://example.org/#p2> <http://example.org/#Foo>
                   ]
               )
                   a <http://www.w3.org/1999/02/22-rdf-syntax-ns#List> .
               """

      # a case with RDF-star annotations in tested also in turtle_star_encoder_test.exs
    end

    test "serializing a pathological graph with an empty description" do
      description = RDF.description(EX.S)
      graph = %Graph{Graph.new() | descriptions: %{description.subject => description}}

      assert_raise Graph.EmptyDescriptionError, fn ->
        Turtle.Encoder.encode!(graph)
      end
    end
  end

  describe "serializing a description" do
    test "a non-empty description" do
      description = EX.S |> EX.p(EX.O)

      assert Turtle.Encoder.encode!(description) ==
               description |> Graph.new() |> Turtle.Encoder.encode!()
    end

    test "an empty description" do
      description = RDF.description(EX.S)

      assert Turtle.Encoder.encode!(description) |> String.trim() ==
               """
               @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
               @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
               @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
               """
               |> String.trim()
    end
  end

  test "a named graph is not encoded as TriG graph" do
    assert Turtle.Encoder.encode!(
             Graph.new([{EX.S1, EX.p1(), EX.O1}]),
             prefixes: %{},
             name: EX.Graph
           ) ==
             """
             <http://example.org/#S1>
                 <http://example.org/#p1> <http://example.org/#O1> .
             """
  end

  %{
    "full IRIs without base" => %{
      input: "<http://a/b> <http://a/c> <http://a/d> .",
      matches: [~r(<http://a/b>\s+<http://a/c>\s+<http://a/d>\s+\.)]
    },
    "relative IRIs with base" => %{
      input: "<http://a/b> <http://a/c> <http://a/d> .",
      matches: [~r(@base\s+<http://a/>\s+\.), ~r(<b>\s+<c>\s+<d>\s+\.)m],
      base_iri: "http://a/"
    },
    "pname IRIs with prefix" => %{
      input: "<http://example.com/b> <http://example.com/c> <http://example.com/d> .",
      matches: [
        ~r(@prefix\s+ex:\s+<http://example.com/>\s+\.),
        ~r(ex:b\s+ex:c\s+ex:d\s+\.)
      ],
      prefixes: %{ex: "http://example.com/"}
    },
    "pname IRIs with empty prefix" => %{
      input: "<http://example.com/b> <http://example.com/c> <http://example.com/d> .",
      matches: [
        ~r(@prefix\s+:\s+<http://example.com/>\s+\.),
        ~r(:b\s+:c\s+:d\s+\.)
      ],
      prefixes: %{"" => "http://example.com/"}
    },
    "object list" => %{
      input: "@prefix ex: <http://example.com/> . ex:b ex:c ex:d, ex:e .",
      matches: [
        ~r(@prefix\s+ex:\s+<http://example.com/>\s+\.),
        ~r(ex:b\s+ex:c\s+ex:[de],\s++ex:[de]\s+\.)m
      ],
      prefixes: %{"ex" => "http://example.com/"}
    },
    "property list" => %{
      input: "@prefix ex: <http://example.com/> . ex:b ex:c ex:d; ex:e ex:f .",
      matches: [
        ~r(@prefix\s+ex:\s+<http://example.com/>\s+\.),
        ~r(ex:b\s+ex:c\s+ex:d\s+;),
        ~r(\s++ex:e\s+ex:f\s+\.)
      ],
      prefixes: %{"ex" => "http://example.com/"}
    },
    "reuses BNode labels by default" => %{
      input: "@prefix ex: <http://example.com/> . _:a ex:b _:a .",
      matches: [~r(\s*_:a\s+ex:b\s+_:a\s+\.)],
      prefixes: %{"ex" => "http://example.com/"}
    },
    "bare anon" => %{
      input: "@prefix ex: <http://example.com/> . [ex:a ex:b] .",
      matches: [~r(^\[\s*ex:a\s+ex:b\s\]\s+\.)m],
      prefixes: %{"ex" => "http://example.com/"}
    },
    "anon as subject" => %{
      input: "@prefix ex: <http://example.com/> . [ex:a ex:b] ex:c ex:d .",
      matches: [
        ~r(\[\s*ex:a\s+ex:b\s*;)m,
        ~r(\sex:c\s+ex:d\s*\]\s+\.)m
      ],
      prefixes: %{"ex" => "http://example.com/"}
    },
    "anon as object" => %{
      input: "@prefix ex: <http://example.com/> . ex:a ex:b [ex:c ex:d] .",
      matches: [~r(ex:a\s+ex:b\s+\[\s*ex:c\s+ex:d\s*\]\s+\.)],
      neg_matches: [~r(_:\w+\s+\s*ex:c\s+ex:d\s+\.)],
      prefixes: %{"ex" => "http://example.com/"}
    },

    #    "generated BNodes with :unique_bnodes" => %{
    #      input: "@prefix ex: <http://example.com/> . _:a ex:b _:a .",
    #      matches: [~r(^\s+*_:g\w+\s+ex:b\s+_:g\w+\s+\.$)],
    #      unique_bnodes: true
    #    },
    #    "standard prefixes" => %{
    #      input: """
    #        <a> a <http://xmlns.com/foaf/0.1/Person>;
    #          <http://purl.org/dc/terms/title> "Person" .
    #      """,
    #      matches: [
    #        ~r(^@prefix foaf: <http://xmlns.com/foaf/0.1/> \.$),
    #        ~r(^@prefix dc: <http://purl.org/dc/terms/> \.$),
    #        ~r(^<a> a foaf:Person;$),
    #        ~r(dc:title "Person" \.$),
    #      ],
    #      standard_prefixes: true, prefixes: %{}
    #    }
    "order properties" => %{
      input: """
        @prefix ex: <http://example.com/> .
        @prefix dc: <http://purl.org/dc/elements/1.1/> .
        @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
        ex:b ex:c ex:d .
        ex:b dc:title "title" .
        ex:b a ex:class .
        ex:b rdfs:label "label" .
      """,
      matches: [
        ~r(ex:b\s+a\s+ex:class\s*;)m,
        ~r(ex:class\s*;\s+rdfs:label\s+"label")m,
        ~r("label"\s*;\s++ex:c\s+ex:d)m,
        ~r(ex:d\s*;\s+dc:title\s+"title"\s+\.)m
      ],
      prefixes: %{
        "ex" => "http://example.com/",
        "dc" => "http://purl.org/dc/elements/1.1/",
        "rdfs" => "http://www.w3.org/2000/01/rdf-schema#"
      }
    }
  }
  |> Enum.each(fn {name, data} ->
    @tag data: data
    test name, %{data: data} do
      assert_serialization(Turtle.read_string!(data.input), Keyword.new(data))
    end
  end)

  describe "lists" do
    test "should generate literal list" do
      Turtle.read_string!(
        ~s[@prefix ex: <http://example.com/> . ex:a ex:b ( "apple" "banana" ) .]
      )
      |> assert_serialization(
        prefixes: %{ex: ~I<http://example.com/>},
        matches: [
          {~r[ex:a\s+ex:b\s+\("apple" "banana"\)\s+\.],
           "doesn't include the list as a Turtle list"}
        ]
      )
    end

    test "should generate empty list" do
      Turtle.read_string!(~s[@prefix ex: <http://example.com/> . ex:a ex:b () .])
      |> assert_serialization(
        prefixes: %{ex: ~I<http://example.com/>},
        matches: [
          {~r[ex:a\s+ex:b\s+\(\)\s+\.], "doesn't include the list as a Turtle list"}
        ]
      )
    end

    test "should generate empty list as subject" do
      Turtle.read_string!(~s[@prefix ex: <http://example.com/> . () ex:a ex:b .])
      |> assert_serialization(
        prefixes: %{ex: ~I<http://example.com/>},
        matches: [
          {~r[\(\)\s+ex:a\s+ex:b\s+\.], "doesn't include the list as a Turtle list"}
        ]
      )
    end

    test "should generate list as subject" do
      Turtle.read_string!(~s[@prefix ex: <http://example.com/> . (ex:a) ex:b ex:c .])
      |> assert_serialization(
        prefixes: %{ex: ~I<http://example.com/>},
        matches: [
          {~r[\(ex:a\)\s+ex:b\s+ex:c\s+\.], "doesn't include the list as a Turtle list"}
        ]
      )
    end

    test "should generate list of empties" do
      graph =
        Turtle.read_string!(~s{@prefix ex: <http://example.com/> . [ex:listOf2Empties (() ())] .})

      serialization =
        assert_serialization(graph,
          prefixes: %{ex: ~I<http://example.com/>},
          matches: [
            {~r[\[\s*ex:listOf2Empties \(\(\) \(\)\)\s\]\s+\.],
             "doesn't include the list as a Turtle list"}
          ]
        )

      refute String.contains?(serialization, to_string(RDF.first())),
             ~s[output\n\n#{serialization}\n\ncontains #{to_string(RDF.first())}]

      refute String.contains?(serialization, to_string(RDF.rest())),
             ~s[output\n\n#{serialization}\n\ncontains #{to_string(RDF.rest())}]
    end

    test "should generate list anon" do
      Turtle.read_string!(
        ~s{@prefix ex: <http://example.com/> . [ex:twoAnons ([a ex:mother] [a ex:father])] .}
      )
      |> assert_serialization(
        prefixes: %{ex: ~I<http://example.com/>},
        matches: [
          {~r[\[\s*ex:twoAnons \(\[\s*a ex:mother\s*\]\s+\[\s*a ex:father\s*\]\s*\)\s*\]\s+\.],
           "doesn't include the list as a Turtle list"}
        ]
      )
    end

    # TODO: Why should this test from RDF.rb work? Why should the `a owl:Class` statements about the list nodes be ignored?
    #    test "should generate owl:unionOf list" do
    #      Turtle.read_string!("""
    #        @prefix ex: <http://example.com/> .
    #        @prefix owl: <http://www.w3.org/2002/07/owl#> .
    #        @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
    #        @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
    #        ex:a rdfs:domain [
    #          a owl:Class;
    #          owl:unionOf [
    #            a owl:Class;
    #            rdf:first ex:b;
    #            rdf:rest [
    #              a owl:Class;
    #              rdf:first ex:c;
    #              rdf:rest rdf:nil
    #            ]
    #          ]
    #        ] .
    #        """)
    #      |> assert_serialization(
    #            prefixes: %{
    #              ex:   ~I<http://example.com/>,
    #              rdf:  RDF.NS.RDF.__base_iri__,
    #              rdfs: RDFS.__base_iri__,
    #              owl:  OWL.__base_iri__,
    #            },
    #            matches: [
    #              {~r[ex:a\s+rdfs:domain \[\s+a owl:Class;\s+owl:unionOf\s+\(ex:b\s+ex:c\)\s*\]\s*\.],
    #                "doesn't include the list as a Turtle list"}
    #            ]
    #         )
    #
    #    end

    test "when one of the list nodes is referenced in other statements the whole list is not represented as a Turtle list structure" do
      Graph.new(
        ~B<Foo>
        |> RDF.first(EX.Foo)
        |> RDF.rest(~B<Bar>)
      )
      |> Graph.add(
        ~B<Bar>
        |> RDF.first(EX.Bar)
        |> RDF.rest(RDF.nil())
      )
      |> Graph.add({EX.Baz, EX.quux(), ~B<Bar>})
      |> assert_serialization(
        prefixes: %{ex: EX.__base_iri__()},
        # TODO: provide a positive match
        neg_matches: [
          {~r[\(\s*ex:Foo\s+ex:Bar\s*\)], "does include the list as a Turtle list"}
        ]
      )
    end

    test "list with embedded blank node description" do
      assert Graph.new(
               ~B<Foo>
               |> RDF.first(EX.Foo)
               |> RDF.rest(~B<Bar>)
             )
             |> Graph.add(
               ~B<Bar>
               |> RDF.first(EX.Bar)
               |> RDF.rest(~B<Baz>)
             )
             |> Graph.add(
               ~B<Baz>
               |> RDF.first(~B<BazEmbedded>)
               |> RDF.rest(RDF.nil())
             )
             |> Graph.add([
               {EX.Foo, EX.p1(), 42},
               {~B<BazEmbedded>, EX.p2(), [EX.Foo, EX.Bar]}
             ])
             |> Turtle.Encoder.encode!() ==
               """
               @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
               @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
               @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

               <http://example.org/#Foo>
                   <http://example.org/#p1> 42 .

               (<http://example.org/#Foo> <http://example.org/#Bar> [
                   <http://example.org/#p2> <http://example.org/#Bar>, <http://example.org/#Foo>
               ])
                   a rdf:List .
               """
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
          {~r[\[\s*_:Foo \(\(\) \(\)\)\]\s+\.], "does include the invalid list as a Turtle list"}
        ]
      )
    end
  end

  describe "literals" do
    test "plain literals with newlines embedded are encoded with long quotes" do
      Turtle.read_string!(~s[<http://a> <http:/b> """testing string parsing in Turtle.
           """ .])
      |> assert_serialization(matches: [~s["""testing string parsing in Turtle.\n]])
    end

    test "plain literals escaping" do
      Turtle.read_string!(~s[<http://a> <http:/b> """string with " escaped quote marks""" .])
      |> assert_serialization(
        matches: [
          ~r[string with \\" escaped quote mark]
        ]
      )
    end

    test "backslash-escaping" do
      EX.S
      |> EX.p("\\")
      |> assert_serialization(matches: [~s["\\\\"]])

      EX.S
      |> EX.p("\\\\")
      |> assert_serialization(matches: [~s["\\\\\\\\"]])
    end

    test "language-tagged literals with newlines embedded are encoded with long quotes" do
      Turtle.read_string!(~s[<http://a> <http:/b> """testing string parsing in Turtle.
           """@en .])
      |> assert_serialization(matches: [~s["""testing string parsing in Turtle.\n]])
    end

    test "language-tagged literals escaping" do
      Turtle.read_string!(~s[<http://a> <http:/b> """string with " escaped quote marks"""@en .])
      |> assert_serialization(
        matches: [
          ~r[string with \\" escaped quote mark]
        ]
      )
    end

    test "language tagged literals specifies language for literal with language" do
      Turtle.read_string!(~s[<http://a> <http:/b> "string"@en .])
      |> assert_serialization(matches: [~r["string"@en]])
    end

    test "typed literals" do
      Turtle.read_string!(
        ~s[@prefix xsd: <http://www.w3.org/2001/XMLSchema#> . <http://a> <http:/b> "http://foo/"^^xsd:anyURI .]
      )
      |> assert_serialization(
        matches: [
          ~r["http://foo/"\^\^<http://www.w3.org/2001/XMLSchema#anyURI> \.]
        ]
      )
    end

    test "escaping in typed literals" do
      EX.S
      |> EX.p(RDF.literal("\\ \"", datatype: EX.DT))
      |> assert_serialization(matches: [~s["\\\\ \\""^^<http://example.org/#DT>]])
    end

    test "typed literals use declared prefixes" do
      Turtle.read_string!(
        ~s[@prefix xsd: <http://www.w3.org/2001/XMLSchema#> . <http://a> <http:/b> "http://foo/"^^xsd:anyURI .]
      )
      |> assert_serialization(
        matches: [
          ~r[@prefix xsd: <http://www.w3.org/2001/XMLSchema#> \.],
          ~r["http://foo/"\^\^xsd:anyURI \.]
        ],
        prefixes: %{xsd: NS.XSD.__base_iri__()}
      )
    end

    test "valid booleans" do
      [
        {true, "true ."},
        {"true", "true ."},
        {"1", ~s["1"^^<http://www.w3.org/2001/XMLSchema#boolean> .]},
        {false, "false ."},
        {"false", "false ."},
        {"0", ~s["0"^^<http://www.w3.org/2001/XMLSchema#boolean> .]}
      ]
      |> Enum.each(fn {value, output} ->
        Graph.new({EX.S, EX.p(), RDF.XSD.boolean(value)})
        |> assert_serialization(matches: [output])
      end)
    end

    test "invalid booleans" do
      [
        {"string", ~s{"string"^^<http://www.w3.org/2001/XMLSchema#boolean>}},
        {"42", ~s{"42"^^<http://www.w3.org/2001/XMLSchema#boolean>}},
        {"TrUe", ~s{"TrUe"^^<http://www.w3.org/2001/XMLSchema#boolean>}},
        {"FaLsE", ~s{"FaLsE"^^<http://www.w3.org/2001/XMLSchema#boolean>}}
      ]
      |> Enum.each(fn {value, output} ->
        Graph.new({EX.S, EX.p(), RDF.XSD.boolean(value)})
        |> assert_serialization(matches: [output])
      end)
    end

    test "valid integers" do
      [
        {0, "0 ."},
        {"0", "0 ."},
        {1, "1 ."},
        {"1", "1 ."},
        {-1, "-1 ."},
        {"-1", "-1 ."},
        {10, "10 ."},
        {"10", "10 ."},
        {"0010", ~s{"0010"^^<http://www.w3.org/2001/XMLSchema#integer>}}
      ]
      |> Enum.each(fn {value, output} ->
        Graph.new({EX.S, EX.p(), RDF.XSD.integer(value)})
        |> assert_serialization(matches: [output])
      end)
    end

    test "invalid integers" do
      [
        {"string", ~s{"string"^^<http://www.w3.org/2001/XMLSchema#integer>}},
        {"true", ~s{"true"^^<http://www.w3.org/2001/XMLSchema#integer>}}
      ]
      |> Enum.each(fn {value, output} ->
        Graph.new({EX.S, EX.p(), RDF.XSD.integer(value)})
        |> assert_serialization(matches: [output])
      end)
    end

    test "valid decimals" do
      [
        {1.0, "1.0 ."},
        {"1.0", "1.0 ."},
        {0.1, "0.1 ."},
        {"0.1", "0.1 ."},
        {-1, "-1.0 ."},
        {"-1", ~s{"-1"^^<http://www.w3.org/2001/XMLSchema#decimal>}},
        {10.02, "10.02 ."},
        {"10.02", "10.02 ."},
        {"010.020", ~s{"010.020"^^<http://www.w3.org/2001/XMLSchema#decimal>}}
      ]
      |> Enum.each(fn {value, output} ->
        Graph.new({EX.S, EX.p(), RDF.XSD.decimal(value)})
        |> assert_serialization(matches: [output])
      end)
    end

    test "invalid decimals" do
      [
        {"string", ~s{"string"^^<http://www.w3.org/2001/XMLSchema#decimal> .}},
        {"true", ~s{"true"^^<http://www.w3.org/2001/XMLSchema#decimal> .}}
      ]
      |> Enum.each(fn {value, output} ->
        Graph.new({EX.S, EX.p(), RDF.XSD.decimal(value)})
        |> assert_serialization(matches: [output])
      end)
    end

    test "valid doubles" do
      [
        {1.0e1, "1.0E1 ."},
        {0.1e1, "1.0E0 ."},
        {"1.0E1", "1.0E1 ."},
        {"1.0e1", "1.0e1 ."},
        {"0.1e1", "0.1e1 ."},
        {10.02e1, "1.002E2 ."},
        {"10.02e1", "10.02e1 ."},
        {"010.020", ~s{"010.020"^^<http://www.w3.org/2001/XMLSchema#double> .}},
        {14, "1.4E1 ."},
        {-1, "-1.0E0 ."},
        {"-1", ~s{"-1"^^<http://www.w3.org/2001/XMLSchema#double> .}}
      ]
      |> Enum.each(fn {value, output} ->
        Graph.new({EX.S, EX.p(), RDF.XSD.double(value)})
        |> assert_serialization(matches: [output])
      end)
    end

    test "invalid doubles" do
      [
        {"string", ~s{"string"^^<http://www.w3.org/2001/XMLSchema#double>}},
        {"true", ~s{"true"^^<http://www.w3.org/2001/XMLSchema#double>}}
      ]
      |> Enum.each(fn {value, output} ->
        Graph.new({EX.S, EX.p(), RDF.XSD.double(value)})
        |> assert_serialization(matches: [output])
      end)
    end
  end

  test "don't encode IRIs as prefixed names when they will be non-conform" do
    assert {
             ~I<http://dbpedia.org/resource/(Ah,_the_Apple_Trees)_When_the_World_Was_Young>,
             ~I<http://dbpedia.org/ontology/wikiPageWikiLink>,
             ~I<http://dbpedia.org/resource/Bob_Dylan>
           }
           |> Graph.new()
           |> Turtle.Encoder.encode!(prefixes: [dbr: ~I<http://dbpedia.org/resource/>]) ==
             """
             @prefix dbr: <http://dbpedia.org/resource/> .

             <http://dbpedia.org/resource/(Ah,_the_Apple_Trees)_When_the_World_Was_Young>
                 <http://dbpedia.org/ontology/wikiPageWikiLink> dbr:Bob_Dylan .
             """

    assert {
             ~I<http://dbpedia.org/resource/Counterfeit²>,
             ~I<http://dbpedia.org/ontology/wikiPageWikiLink>,
             ~I<http://dbpedia.org/resource/Bob_Dylan>
           }
           |> Graph.new()
           |> Turtle.Encoder.encode!(prefixes: [dbr: ~I<http://dbpedia.org/resource/>]) ==
             """
             @prefix dbr: <http://dbpedia.org/resource/> .

             <http://dbpedia.org/resource/Counterfeit²>
                 <http://dbpedia.org/ontology/wikiPageWikiLink> dbr:Bob_Dylan .
             """
  end

  defp assert_serialization(graph, opts) do
    prefixes = Keyword.get(opts, :prefixes, %{})
    base_iri = Keyword.get(opts, :base_iri)
    matches = Keyword.get(opts, :matches, [])
    neg_matches = Keyword.get(opts, :neg_matches, [])

    assert {:ok, serialized} = Turtle.write_string(graph, prefixes: prefixes, base_iri: base_iri)

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
