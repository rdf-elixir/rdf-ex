defmodule RDF.NTriples.DecoderTest do
  use ExUnit.Case, async: false

  doctest RDF.NTriples.Decoder

  alias RDF.NTriples.Decoder
  alias RDF.Graph

  use RDF.Vocabulary.Namespace

  defvocab EX, base_iri: "http://example.org/#", terms: [], strict: false

  defvocab P, base_iri: "http://www.perceive.net/schemas/relationship/", terms: [], strict: false

  import RDF.Sigils
  import RDF.Test.Case, only: [string_to_stream: 1]

  test "stream_support?/0" do
    assert Decoder.stream_support?()
  end

  test "an empty string is deserialized to an empty graph" do
    assert Decoder.decode!("") == Graph.new()
    assert Decoder.decode!("  \n\r\r\n  ") == Graph.new()
  end

  test "decoding comments" do
    assert Decoder.decode!("# just a comment") == Graph.new()

    assert Decoder.decode!("""
           <http://example.org/#S> <http://example.org/#p> _:1 . # a comment
           """) == Graph.new({EX.S, EX.p(), RDF.bnode("1")})

    assert Decoder.decode!("""
           # a comment
           <http://example.org/#S> <http://example.org/#p> <http://example.org/#O> .
           """) == Graph.new({EX.S, EX.p(), EX.O})

    assert Decoder.decode!("""
           <http://example.org/#S> <http://example.org/#p> <http://example.org/#O> .
           # a comment
           """) == Graph.new({EX.S, EX.p(), EX.O})

    assert Decoder.decode!("""
           # Header line 1
           # Header line 2
           <http://example.org/#S1> <http://example.org/#p1> <http://example.org/#O1> .
           # 1st comment
           <http://example.org/#S1> <http://example.org/#p2> <http://example.org/#O2> . # 2nd comment
           # last comment
           """) ==
             Graph.new([
               {EX.S1, EX.p1(), EX.O1},
               {EX.S1, EX.p2(), EX.O2}
             ])
  end

  test "empty lines" do
    assert Decoder.decode!("""

           <http://example.org/#spiderman> <http://www.perceive.net/schemas/relationship/enemyOf> <http://example.org/#green_goblin> .
           """) == Graph.new({EX.spiderman(), P.enemyOf(), EX.green_goblin()})

    assert Decoder.decode!("""
           <http://example.org/#spiderman> <http://www.perceive.net/schemas/relationship/enemyOf> <http://example.org/#green_goblin> .

           """) == Graph.new({EX.spiderman(), P.enemyOf(), EX.green_goblin()})

    assert Decoder.decode!("""

           <http://example.org/#S1> <http://example.org/#p1> <http://example.org/#O1> .


           <http://example.org/#S1> <http://example.org/#p2> <http://example.org/#O2> .

           """) ==
             Graph.new([
               {EX.S1, EX.p1(), EX.O1},
               {EX.S1, EX.p2(), EX.O2}
             ])
  end

  test "decoding a single triple with iris" do
    assert Decoder.decode!("""
           <http://example.org/#spiderman> <http://www.perceive.net/schemas/relationship/enemyOf> <http://example.org/#green_goblin> .
           """) == Graph.new({EX.spiderman(), P.enemyOf(), EX.green_goblin()})
  end

  test "decoding a single triple with a blank node" do
    assert Decoder.decode!("""
           _:foo <http://example.org/#p> <http://example.org/#O> .
           """) == Graph.new({RDF.bnode("foo"), EX.p(), EX.O})

    assert Decoder.decode!("""
           <http://example.org/#S> <http://example.org/#p> _:1 .
           """) == Graph.new({EX.S, EX.p(), RDF.bnode("1")})

    assert Decoder.decode!("""
           _:foo <http://example.org/#p> _:bar .
           """) == Graph.new({RDF.bnode("foo"), EX.p(), RDF.bnode("bar")})
  end

  test "decoding a single triple with an untyped string literal" do
    assert Decoder.decode!("""
           <http://example.org/#spiderman> <http://www.perceive.net/schemas/relationship/realname> "Peter Parker" .
           """) == Graph.new({EX.spiderman(), P.realname(), RDF.literal("Peter Parker")})
  end

  test "decoding a single triple with a typed literal" do
    assert Decoder.decode!("""
           <http://example.org/#spiderman> <http://example.org/#p> "42"^^<http://www.w3.org/2001/XMLSchema#integer> .
           """) == Graph.new({EX.spiderman(), EX.p(), RDF.literal(42)})
  end

  test "decoding a single triple with a language tagged literal" do
    assert Decoder.decode!("""
           <http://example.org/#S> <http://example.org/#p> "foo"@en .
           """) == Graph.new({EX.S, EX.p(), RDF.literal("foo", language: "en")})
  end

  test "decoding multiple triples" do
    assert Decoder.decode!("""
           <http://example.org/#S1> <http://example.org/#p1> <http://example.org/#O1> .
           <http://example.org/#S1> <http://example.org/#p2> <http://example.org/#O2> .
           """) ==
             Graph.new([
               {EX.S1, EX.p1(), EX.O1},
               {EX.S1, EX.p2(), EX.O2}
             ])

    assert Decoder.decode!("""
           <http://example.org/#S1> <http://example.org/#p1> <http://example.org/#O1> .
           <http://example.org/#S1> <http://example.org/#p2> <http://example.org/#O2> .

           <http://example.org/#S2> <http://example.org/#p3> <http://example.org/#O3> .
           """) ==
             Graph.new([
               {EX.S1, EX.p1(), EX.O1},
               {EX.S1, EX.p2(), EX.O2},
               {EX.S2, EX.p3(), EX.O3}
             ])
  end

  test "decode_from_stream/2" do
    assert """
           <http://example.org/#S1> <http://example.org/#p1> <http://example.org/#O1> .

           <http://example.org/#S1> <http://example.org/#p2> _:foo .


           <http://example.org/#S2> <http://example.org/#p3> "foo"@en .
           """
           |> string_to_stream()
           |> Decoder.decode_from_stream() ==
             {:ok,
              Graph.new([
                {EX.S1, EX.p1(), EX.O1},
                {EX.S1, EX.p2(), ~B"foo"},
                {EX.S2, EX.p3(), ~L"foo"en}
              ])}
  end

  test "decode_from_stream!/2" do
    assert """
           <http://example.org/#S1> <http://example.org/#p1> <http://example.org/#O1> .

           <http://example.org/#S1> <http://example.org/#p2> _:foo .


           <http://example.org/#S2> <http://example.org/#p3> "foo"@en .
           """
           |> string_to_stream()
           |> Decoder.decode_from_stream!() ==
             Graph.new([
               {EX.S1, EX.p1(), EX.O1},
               {EX.S1, EX.p2(), ~B"foo"},
               {EX.S2, EX.p3(), ~L"foo"en}
             ])
  end
end
