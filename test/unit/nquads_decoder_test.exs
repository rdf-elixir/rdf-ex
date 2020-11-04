defmodule RDF.NQuads.DecoderTest do
  use ExUnit.Case, async: false

  doctest RDF.NQuads.Decoder

  alias RDF.NQuads.Decoder
  alias RDF.Dataset

  import RDF.Sigils

  use RDF.Vocabulary.Namespace

  defvocab EX, base_iri: "http://example.org/#", terms: [], strict: false

  defvocab P, base_iri: "http://www.perceive.net/schemas/relationship/", terms: [], strict: false

  import RDF.Sigils
  import RDF.Test.Case, only: [string_to_stream: 1]

  test "stream_support?/0" do
    assert Decoder.stream_support?()
  end

  test "an empty string is deserialized to an empty graph" do
    assert Decoder.decode!("") == Dataset.new()
    assert Decoder.decode!("  \n\r\r\n  ") == Dataset.new()
  end

  test "decoding comments" do
    assert Decoder.decode!("# just a comment") == Dataset.new()

    assert Decoder.decode!("""
           <http://example.org/#S> <http://example.org/#p> _:1 <http://example.org/#G>. # a comment
           """) == Dataset.new({EX.S, EX.p(), RDF.bnode("1"), EX.G})

    assert Decoder.decode!("""
           # a comment
           <http://example.org/#S> <http://example.org/#p> <http://example.org/#O> <http://example.org/#G>.
           """) == Dataset.new({EX.S, EX.p(), EX.O, EX.G})

    assert Decoder.decode!("""
           <http://example.org/#S> <http://example.org/#p> <http://example.org/#O> <http://example.org/#G>.
           # a comment
           """) == Dataset.new({EX.S, EX.p(), EX.O, EX.G})

    assert Decoder.decode!("""
           # Header line 1
           # Header line 2
           <http://example.org/#S1> <http://example.org/#p1> <http://example.org/#O1> <http://example.org/#G> .
           # 1st comment
           <http://example.org/#S1> <http://example.org/#p2> <http://example.org/#O2> . # 2nd comment
           # last comment
           """) ==
             Dataset.new([
               {EX.S1, EX.p1(), EX.O1, EX.G},
               {EX.S1, EX.p2(), EX.O2}
             ])
  end

  test "empty lines" do
    assert Decoder.decode!("""

           <http://example.org/#spiderman> <http://www.perceive.net/schemas/relationship/enemyOf> <http://example.org/#green_goblin> <http://example.org/graphs/spiderman> .
           """) ==
             Dataset.new(
               {EX.spiderman(), P.enemyOf(), EX.green_goblin(),
                ~I<http://example.org/graphs/spiderman>}
             )

    assert Decoder.decode!("""
           <http://example.org/#spiderman> <http://www.perceive.net/schemas/relationship/enemyOf> <http://example.org/#green_goblin> <http://example.org/graphs/spiderman> .

           """) ==
             Dataset.new(
               {EX.spiderman(), P.enemyOf(), EX.green_goblin(),
                ~I<http://example.org/graphs/spiderman>}
             )

    assert Decoder.decode!("""

           <http://example.org/#S1> <http://example.org/#p1> <http://example.org/#O1> .


           <http://example.org/#S1> <http://example.org/#p2> <http://example.org/#O2> <http://example.org/#G> .

           """) ==
             Dataset.new([
               {EX.S1, EX.p1(), EX.O1},
               {EX.S1, EX.p2(), EX.O2, EX.G}
             ])
  end

  test "decoding a single statement with iris" do
    assert Decoder.decode!("""
           <http://example.org/#spiderman> <http://www.perceive.net/schemas/relationship/enemyOf> <http://example.org/#green_goblin> .
           """) == Dataset.new({EX.spiderman(), P.enemyOf(), EX.green_goblin()})

    assert Decoder.decode!("""
           <http://example.org/#spiderman> <http://www.perceive.net/schemas/relationship/enemyOf> <http://example.org/#green_goblin> <http://example.org/graphs/spiderman>.
           """) ==
             Dataset.new(
               {EX.spiderman(), P.enemyOf(), EX.green_goblin(),
                ~I<http://example.org/graphs/spiderman>}
             )
  end

  test "decoding a single statement with a blank node" do
    assert Decoder.decode!("""
           _:foo <http://example.org/#p> <http://example.org/#O> <http://example.org/#G> .
           """) == Dataset.new({RDF.bnode("foo"), EX.p(), EX.O, EX.G})

    assert Decoder.decode!("""
           <http://example.org/#S> <http://example.org/#p> _:1 <http://example.org/#G> .
           """) == Dataset.new({EX.S, EX.p(), RDF.bnode("1"), EX.G})

    assert Decoder.decode!("""
           _:foo <http://example.org/#p> _:bar <http://example.org/#G> .
           """) == Dataset.new({RDF.bnode("foo"), EX.p(), RDF.bnode("bar"), EX.G})

    assert Decoder.decode!("""
           <http://example.org/#S> <http://example.org/#p> _:1 _:G .
           """) == Dataset.new({EX.S, EX.p(), RDF.bnode("1"), RDF.bnode("G")})
  end

  test "decoding a single statement with an untyped string literal" do
    assert Decoder.decode!("""
           <http://example.org/#spiderman> <http://www.perceive.net/schemas/relationship/realname> "Peter Parker" <http://example.org/#G> .
           """) == Dataset.new({EX.spiderman(), P.realname(), RDF.literal("Peter Parker"), EX.G})

    assert Decoder.decode!("""
           <http://example.org/#spiderman> <http://www.perceive.net/schemas/relationship/realname> "Peter Parker" .
           """) == Dataset.new({EX.spiderman(), P.realname(), RDF.literal("Peter Parker")})
  end

  test "decoding a single statement with a typed literal" do
    assert Decoder.decode!("""
           <http://example.org/#spiderman> <http://example.org/#p> "42"^^<http://www.w3.org/2001/XMLSchema#integer> <http://example.org/#G> .
           """) == Dataset.new({EX.spiderman(), EX.p(), RDF.literal(42), EX.G})

    assert Decoder.decode!("""
           <http://example.org/#spiderman> <http://example.org/#p> "42"^^<http://www.w3.org/2001/XMLSchema#integer> .
           """) == Dataset.new({EX.spiderman(), EX.p(), RDF.literal(42)})
  end

  test "decoding a single statement with a language tagged literal" do
    assert Decoder.decode!("""
           <http://example.org/#S> <http://example.org/#p> "foo"@en <http://example.org/#G> .
           """) == Dataset.new({EX.S, EX.p(), RDF.literal("foo", language: "en"), EX.G})

    assert Decoder.decode!("""
           <http://example.org/#S> <http://example.org/#p> "foo"@en .
           """) == Dataset.new({EX.S, EX.p(), RDF.literal("foo", language: "en")})
  end

  test "decoding multiple statements" do
    assert Decoder.decode!("""
           <http://example.org/#S1> <http://example.org/#p1> <http://example.org/#O1> <http://example.org/#G> .
           <http://example.org/#S1> <http://example.org/#p2> <http://example.org/#O2> <http://example.org/#G> .
           """) ==
             Dataset.new([
               {EX.S1, EX.p1(), EX.O1, EX.G},
               {EX.S1, EX.p2(), EX.O2, EX.G}
             ])

    assert Decoder.decode!("""
           <http://example.org/#S1> <http://example.org/#p1> <http://example.org/#O1> <http://example.org/#G> .
           <http://example.org/#S1> <http://example.org/#p2> <http://example.org/#O2> <http://example.org/#G> .
           <http://example.org/#S2> <http://example.org/#p3> <http://example.org/#O3> <http://example.org/#G> .

           <http://example.org/#S2> <http://example.org/#p3> <http://example.org/#O3> .
           """) ==
             Dataset.new([
               {EX.S1, EX.p1(), EX.O1, EX.G},
               {EX.S1, EX.p2(), EX.O2, EX.G},
               {EX.S2, EX.p3(), EX.O3, EX.G},
               {EX.S2, EX.p3(), EX.O3}
             ])
  end

  test "decode_from_stream/2" do
    assert """
           <http://example.org/#S1> <http://example.org/#p1> <http://example.org/#O1> <http://example.org/#G> .
           <http://example.org/#S1> <http://example.org/#p2> <http://example.org/#O2> <http://example.org/#G> .
           <http://example.org/#S2> <http://example.org/#p3> _:foo <http://example.org/#G> .


           <http://example.org/#S2> <http://example.org/#p3> "foo"@en .
           """
           |> string_to_stream()
           |> Decoder.decode_from_stream() ==
             Dataset.new([
               {EX.S1, EX.p1(), EX.O1, EX.G},
               {EX.S1, EX.p2(), EX.O2, EX.G},
               {EX.S2, EX.p3(), ~B"foo", EX.G},
               {EX.S2, EX.p3(), ~L"foo"en}
             ])
  end
end
