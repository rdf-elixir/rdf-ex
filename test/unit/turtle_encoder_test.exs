defmodule RDF.Turtle.EncoderTest do
  use ExUnit.Case, async: false

  alias RDF.Turtle

  doctest Turtle.Encoder

  alias RDF.Graph
  alias RDF.NS.{XSD, RDFS, OWL}

  import RDF.Sigils

  use RDF.Vocabulary.Namespace

  defvocab EX,
    base_iri: "http://example.org/#",
    terms: [], strict: false


  describe "serializing a graph" do
    test "an empty graph is serialized to an empty string" do
      assert Turtle.Encoder.encode!(Graph.new, prefixes: %{}) == ""
    end

    test "statements with IRIs only" do
      assert Turtle.Encoder.encode!(Graph.new([
                {EX.S1, EX.p1, EX.O1},
                {EX.S1, EX.p1, EX.O2},
                {EX.S1, EX.p2, EX.O3},
                {EX.S2, EX.p3, EX.O4},
              ]), prefixes: %{}) ==
              """
              <http://example.org/#S1>
                  <http://example.org/#p1> <http://example.org/#O1>, <http://example.org/#O2> ;
                  <http://example.org/#p2> <http://example.org/#O3> .

              <http://example.org/#S2>
                  <http://example.org/#p3> <http://example.org/#O4> .
              """
    end

    test "statements with prefixed names" do
      assert Turtle.Encoder.encode!(Graph.new([
                {EX.S1, EX.p1, EX.O1},
                {EX.S1, EX.p1, EX.O2},
                {EX.S1, EX.p2, EX.O3},
                {EX.S2, EX.p3, EX.O4},
              ]), prefixes: %{
                ex: EX.__base_iri__,
                xsd: XSD.__base_iri__
              }) ==
              """
              @prefix ex: <#{to_string(EX.__base_iri__)}> .
              @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

              ex:S1
                  ex:p1 ex:O1, ex:O2 ;
                  ex:p2 ex:O3 .

              ex:S2
                  ex:p3 ex:O4 .
              """
    end

    test "when no prefixes are given, the prefixes from the given graph are used" do
      assert Turtle.Encoder.encode!(Graph.new([
               {EX.S1, EX.p1, EX.O1},
               {EX.S1, EX.p1, EX.O2},
               {EX.S1, EX.p2, XSD.integer},
               {EX.S2, EX.p3, EX.O4},
             ], prefixes: %{
               "": EX.__base_iri__,
               xsd: XSD.__base_iri__
             })) ==
               """
               @prefix : <#{to_string(EX.__base_iri__)}> .
               @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

               :S1
                   :p1 :O1, :O2 ;
                   :p2 xsd:integer .

               :S2
                   :p3 :O4 .
               """
    end

    test "when no base IRI is given, the base IRI from the given graph is used" do
      assert Turtle.Encoder.encode!(Graph.new([{EX.S1, EX.p1, EX.O1}], prefixes: %{},
               base_iri: EX.__base_iri__)) ==
               """
               @base <#{to_string(EX.__base_iri__)}> .
               <S1>
                   <p1> <O1> .
               """
    end

    test "when a base IRI is given, it has used instead of the base IRI of the given graph" do
      assert Turtle.Encoder.encode!(Graph.new([{EX.S1, EX.p1, EX.O1}], prefixes: %{},
               base_iri: EX.other), base_iri: EX.__base_iri__) ==
               """
               @base <#{to_string(EX.__base_iri__)}> .
               <S1>
                   <p1> <O1> .
               """
    end

    test "when no prefixes are given and no prefixes are in the given graph the default_prefixes are used" do
      assert Turtle.Encoder.encode!(Graph.new({EX.S, EX.p, XSD.string})) ==
               """
               @prefix rdf: <#{to_string(RDF.__base_iri__)}> .
               @prefix rdfs: <#{to_string(RDFS.__base_iri__)}> .
               @prefix xsd: <#{to_string(XSD.__base_iri__)}> .

               <http://example.org/#S>
                   <http://example.org/#p> xsd:string .
               """
    end

    test "statements with empty prefixed names" do
      assert Turtle.Encoder.encode!(Graph.new({EX.S, EX.p, EX.O}),
              prefixes: %{"" => EX.__base_iri__}) ==
              """
              @prefix : <#{to_string(EX.__base_iri__)}> .

              :S
                  :p :O .
              """
    end

    test "statements with literals" do
      assert Turtle.Encoder.encode!(Graph.new([
                {EX.S1, EX.p1, ~L"foo"},
                {EX.S1, EX.p1, ~L"foo"en},
                {EX.S2, EX.p2, RDF.literal("strange things", datatype: EX.custom)},
              ]), prefixes: %{}) ==
              """
              <http://example.org/#S1>
                  <http://example.org/#p1> "foo"@en, "foo" .

              <http://example.org/#S2>
                  <http://example.org/#p2> "strange things"^^<#{EX.custom}> .
              """
    end

    test "statements with blank nodes" do
      assert Turtle.Encoder.encode!(Graph.new([
                {EX.S1, EX.p1, [RDF.bnode(1), RDF.bnode("foo"), RDF.bnode(:bar)]},
                {EX.S2, EX.p1, [RDF.bnode(1), RDF.bnode("foo"), RDF.bnode(:bar)]},
              ]), prefixes: %{}) ==
              """
              <http://example.org/#S1>
                  <http://example.org/#p1> _:1, _:bar, _:foo .

              <http://example.org/#S2>
                  <http://example.org/#p1> _:1, _:bar, _:foo .
              """
    end

    test "ordering of descriptions" do
      assert Turtle.Encoder.encode!(Graph.new([
                {EX.__base_iri__, RDF.type, OWL.Ontology},
                {EX.S1, RDF.type, EX.O},
                {EX.S2, RDF.type, RDFS.Class},
                {EX.S3, RDF.type, RDF.Property},
              ]),
                base_iri: EX.__base_iri__,
                prefixes: %{
                  rdf:  RDF.__base_iri__,
                  rdfs: RDFS.__base_iri__,
                  owl:  OWL.__base_iri__,
                }) ==
              """
              @base <#{to_string(EX.__base_iri__)}> .
              @prefix rdf: <#{to_string(RDF.__base_iri__)}> .
              @prefix rdfs: <#{to_string(RDFS.__base_iri__)}> .
              @prefix owl: <#{to_string(OWL.__base_iri__)}> .

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
  end


  describe "prefixed_name/2" do
    setup do
      {:ok,
        prefixes: %{
          RDF.iri(EX.__base_iri__) => "ex",
          ~I<http://example.org/>  => "ex2"
        }
      }
    end

    test "hash iri with existing prefix", %{prefixes: prefixes} do
      assert Turtle.Encoder.prefixed_name(EX.foo, prefixes) ==
              "ex:foo"
    end

    test "hash iri namespace without name", %{prefixes: prefixes} do
      assert Turtle.Encoder.prefixed_name(RDF.iri(EX.__base_iri__), prefixes) ==
              "ex:"
    end

    test "hash iri with non-existing prefix" do
      refute Turtle.Encoder.prefixed_name(EX.foo, %{})
    end

    test "slash iri with existing prefix", %{prefixes: prefixes} do
      assert Turtle.Encoder.prefixed_name(~I<http://example.org/foo>, prefixes) ==
              "ex2:foo"
    end

    test "slash iri namespace without name", %{prefixes: prefixes} do
      assert Turtle.Encoder.prefixed_name(~I<http://example.org/>, prefixes) ==
              "ex2:"
    end

    test "slash iri with non-existing prefix" do
      refute Turtle.Encoder.prefixed_name(~I<http://example.org/foo>, %{})
    end
  end


  %{
    "full IRIs without base" => %{
      input: "<http://a/b> <http://a/c> <http://a/d> .",
      matches: [~r(<http://a/b>\s+<http://a/c>\s+<http://a/d>\s+\.)],
    },
    "relative IRIs with base" => %{
      input: "<http://a/b> <http://a/c> <http://a/d> .",
      matches: [ ~r(@base\s+<http://a/>\s+\.), ~r(<b>\s+<c>\s+<d>\s+\.)m],
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
      matches:  [
        ~r(@prefix\s+:\s+<http://example.com/>\s+\.),
        ~r(:b\s+:c\s+:d\s+\.)
      ],
      prefixes: %{"" => "http://example.com/"}
    },
    "object list" => %{
      input: "@prefix ex: <http://example.com/> . ex:b ex:c ex:d, ex:e .",
      matches: [
        ~r(@prefix\s+ex:\s+<http://example.com/>\s+\.),
        ~r(ex:b\s+ex:c\s+ex:[de],\s++ex:[de]\s+\.)m,
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
        "ex"   => "http://example.com/",
        "dc"   => "http://purl.org/dc/elements/1.1/",
        "rdfs" => "http://www.w3.org/2000/01/rdf-schema#",
      }
    },
  }
  |> Enum.each(fn {name, data} ->
      @tag data: data
      test name, %{data: data} do
        assert_serialization Turtle.read_string!(data.input), Keyword.new(data)
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
            {~r[ex:a\s+ex:b\s+\("apple" "banana"\)\s+\.], "doesn't include the list as a Turtle list"}
           ]
         )
    end

    test "should generate empty list" do
      Turtle.read_string!(
        ~s[@prefix ex: <http://example.com/> . ex:a ex:b () .]
      )
      |> assert_serialization(
           prefixes: %{ex: ~I<http://example.com/>},
           matches: [
            {~r[ex:a\s+ex:b\s+\(\)\s+\.], "doesn't include the list as a Turtle list"}
           ]
         )
    end

    test "should generate empty list as subject" do
      Turtle.read_string!(
        ~s[@prefix ex: <http://example.com/> . () ex:a ex:b .]
      )
      |> assert_serialization(
           prefixes: %{ex: ~I<http://example.com/>},
           matches: [
            {~r[\(\)\s+ex:a\s+ex:b\s+\.], "doesn't include the list as a Turtle list"}
           ]
         )
    end

    test "should generate list as subject" do
      Turtle.read_string!(
        ~s[@prefix ex: <http://example.com/> . (ex:a) ex:b ex:c .]
      )
      |> assert_serialization(
           prefixes: %{ex: ~I<http://example.com/>},
           matches: [
            {~r[\(ex:a\)\s+ex:b\s+ex:c\s+\.], "doesn't include the list as a Turtle list"}
           ]
         )
    end

    test "should generate list of empties" do
      graph = Turtle.read_string!(
        ~s{@prefix ex: <http://example.com/> . [ex:listOf2Empties (() ())] .}
      )
      serialization =
        assert_serialization graph,
           prefixes: %{ex: ~I<http://example.com/>},
           matches: [
            {~r[\[\s*ex:listOf2Empties \(\(\) \(\)\)\s\]\s+\.], "doesn't include the list as a Turtle list"}
           ]

      refute String.contains?(serialization, to_string(RDF.first)),
            ~s[output\n\n#{serialization}\n\ncontains #{to_string(RDF.first)}]
      refute String.contains?(serialization, to_string(RDF.rest)),
            ~s[output\n\n#{serialization}\n\ncontains #{to_string(RDF.rest)}]
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
           |> RDF.rest(~B<Bar>))
      |> Graph.add(
           ~B<Bar>
           |> RDF.first(EX.Bar)
           |> RDF.rest(RDF.nil))
      |> Graph.add({EX.Baz, EX.quux, ~B<Bar>})
      |> assert_serialization(
           prefixes: %{ex: EX.__base_iri__},
           # TODO: provide a positive match
           neg_matches: [
            {~r[\(\s*ex:Foo\s+ex:Bar\s*\)], "does include the list as a Turtle list"}
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
            {~r[\[\s*_:Foo \(\(\) \(\)\)\]\s+\.], "does include the invalid list as a Turtle list"}
           ]
         )
    end
  end


  describe "literals" do
    test "plain literals with newlines embedded are encoded with long quotes" do
      Turtle.read_string!(
        ~s[<http://a> <http:/b> """testing string parsing in Turtle.
           """ .]
      )
      |> assert_serialization(
           matches: [~s["""testing string parsing in Turtle.\n]]
         )
    end

    test "plain literals escaping" do
      Turtle.read_string!(
        ~s[<http://a> <http:/b> """string with " escaped quote marks""" .]
      )
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

    test "typed literals use declared prefixes" do
      Turtle.read_string!(
        ~s[@prefix xsd: <http://www.w3.org/2001/XMLSchema#> . <http://a> <http:/b> "http://foo/"^^xsd:anyURI .]
      )
      |> assert_serialization(
           matches: [
            ~r[@prefix xsd: <http://www.w3.org/2001/XMLSchema#> \.],
            ~r["http://foo/"\^\^xsd:anyURI \.]
           ],
           prefixes: %{xsd: XSD.__base_iri__}
         )
    end

    test "valid booleans" do
      [
        {true,    "true ."},
        {"true",  "true ."},
        {"1",     "true ."},
        {false,   "false ."},
        {"false", "false ."},
        {"0",     "false ."},
      ]
      |> Enum.each(fn {value, output} ->
          Graph.new({EX.S, EX.p, RDF.Boolean.new(value)})
          |> assert_serialization(matches: [output])
         end)
    end

    test "invalid booleans" do
      [
        {"string", ~s{"string"^^<http://www.w3.org/2001/XMLSchema#boolean>}},
        {"42",     ~s{"42"^^<http://www.w3.org/2001/XMLSchema#boolean>}},
        {"TrUe",   ~s{"TrUe"^^<http://www.w3.org/2001/XMLSchema#boolean>}},
        {"FaLsE",  ~s{"FaLsE"^^<http://www.w3.org/2001/XMLSchema#boolean>}},
      ]
      |> Enum.each(fn {value, output} ->
          Graph.new({EX.S, EX.p, RDF.Boolean.new(value)})
          |> assert_serialization(matches: [output])
         end)
    end

    test "valid integers" do
      [
        {0,      "0 ."},
        {"0",    "0 ."},
        {1,      "1 ."},
        {"1",    "1 ."},
        {-1,     "-1 ."},
        {"-1",   "-1 ."},
        {10,     "10 ."},
        {"10",   "10 ."},
        {"0010", "10 ."},
      ]
      |> Enum.each(fn {value, output} ->
          Graph.new({EX.S, EX.p, RDF.Integer.new(value)})
          |> assert_serialization(matches: [output])
         end)
    end

    test "invalid integers" do
      [
        {"string", ~s{"string"^^<http://www.w3.org/2001/XMLSchema#integer>}},
        {"true",   ~s{"true"^^<http://www.w3.org/2001/XMLSchema#integer>}},
      ]
      |> Enum.each(fn {value, output} ->
          Graph.new({EX.S, EX.p, RDF.Integer.new(value)})
          |> assert_serialization(matches: [output])
         end)
    end

    test "valid decimals" do
      [
        {1.0,       "1.0 ."},
        {"1.0",     "1.0 ."},
        {0.1,       "0.1 ."},
        {"0.1",     "0.1 ."},
        {-1,        "-1.0 ."},
        {"-1",      "-1.0 ."},
        {10.02,     "10.02 ."},
        {"10.02",   "10.02 ."},
        {"010.020", "10.02 ."},
      ]
      |> Enum.each(fn {value, output} ->
          Graph.new({EX.S, EX.p, RDF.Literal.new(value, datatype: XSD.decimal)})
          |> assert_serialization(matches: [output])
         end)
    end

    test "invalid decimals" do
      [
        {"string", ~s{"string"^^<http://www.w3.org/2001/XMLSchema#decimal>}},
        {"true",   ~s{"true"^^<http://www.w3.org/2001/XMLSchema#decimal>}},
      ]
      |> Enum.each(fn {value, output} ->
          Graph.new({EX.S, EX.p, RDF.Literal.new(value, datatype: XSD.decimal)})
          |> assert_serialization(matches: [output])
         end)
    end

    test "valid doubles" do
      [
        {1.0e1,       "1.0E1 ."},
        {"1.0e1",     "1.0E1 ."},
        {0.1e1,       "1.0E0 ."},
        {"0.1e1",     "1.0E0 ."},
        {10.02e1,     "1.002E2 ."},
        {"10.02e1",   "1.002E2 ."},
        {"010.020",   "1.002E1 ."},
        {14,          "1.4E1 ."},
        {-1,          "-1.0E0 ."},
        {"-1",        "-1.0E0 ."},
      ]
      |> Enum.each(fn {value, output} ->
          Graph.new({EX.S, EX.p, RDF.Double.new(value)})
          |> assert_serialization(matches: [output])
         end)
    end

    test "invalid doubles" do
      [
        {"string", ~s{"string"^^<http://www.w3.org/2001/XMLSchema#double>}},
        {"true",   ~s{"true"^^<http://www.w3.org/2001/XMLSchema#double>}},
      ]
      |> Enum.each(fn {value, output} ->
          Graph.new({EX.S, EX.p, RDF.Double.new(value)})
          |> assert_serialization(matches: [output])
         end)
    end
  end


  describe "W3C test suite roundtrip" do
    @tag skip: "TODO: We need a Graph isomorphism comparison to implement this."
    test "..."
  end


  defp assert_serialization(graph, opts) do
    with prefixes    = Keyword.get(opts, :prefixes, %{}),
         base_iri    = Keyword.get(opts, :base_iri),
         matches     = Keyword.get(opts, :matches, []),
         neg_matches = Keyword.get(opts, :neg_matches, [])
    do
      assert {:ok, serialized} =
                Turtle.write_string(graph, prefixes: prefixes, base_iri: base_iri)

      matches
      |> Stream.map(fn
           {pattern, message} ->
              {pattern, ~s[output\n\n#{serialized}\n\n#{message}]}
           pattern            ->
              {pattern, ~s[output\n\n#{serialized}\n\ndoesn't include #{inspect pattern}]}
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
           pattern            ->
              {pattern, ~s[output\n\n#{serialized}\n\ndoes include #{inspect pattern}]}
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
end
