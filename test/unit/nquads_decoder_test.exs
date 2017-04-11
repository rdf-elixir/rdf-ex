defmodule RDF.NQuads.DecoderTest do
  use ExUnit.Case, async: false

  doctest RDF.NQuads.Decoder

  alias RDF.{Dataset, TestData}

  import RDF.Sigils

  use RDF.Vocabulary.Namespace

  defvocab EX,
    base_uri: "http://example.org/#",
    terms: [], strict: false

  defvocab P,
    base_uri: "http://www.perceive.net/schemas/relationship/",
    terms: [], strict: false


  @w3c_nquads_test_suite Path.join(TestData.dir, "N-QUADS-TESTS")

  test "an empty string is deserialized to an empty graph" do
    assert RDF.NQuads.Decoder.decode!("") == Dataset.new
    assert RDF.NQuads.Decoder.decode!("  \n\r\r\n  ") == Dataset.new
  end

  test "decoding comments" do
    assert RDF.NQuads.Decoder.decode!("# just a comment") == Dataset.new

    assert RDF.NQuads.Decoder.decode!("""
      <http://example.org/#S> <http://example.org/#p> _:1 <http://example.org/#G>. # a comment
      """) == Dataset.new({EX.S, EX.p, RDF.bnode("1"), EX.G})

    assert RDF.NQuads.Decoder.decode!("""
      # a comment
      <http://example.org/#S> <http://example.org/#p> <http://example.org/#O> <http://example.org/#G>.
      """) == Dataset.new({EX.S, EX.p, EX.O, EX.G})

    assert RDF.NQuads.Decoder.decode!("""
      <http://example.org/#S> <http://example.org/#p> <http://example.org/#O> <http://example.org/#G>.
      # a comment
      """) == Dataset.new({EX.S, EX.p, EX.O, EX.G})

    assert RDF.NQuads.Decoder.decode!("""
      # Header line 1
      # Header line 2
      <http://example.org/#S1> <http://example.org/#p1> <http://example.org/#O1> <http://example.org/#G> .
      # 1st comment
      <http://example.org/#S1> <http://example.org/#p2> <http://example.org/#O2> . # 2nd comment
      # last comment
      """) == Dataset.new([
        {EX.S1, EX.p1, EX.O1, EX.G},
        {EX.S1, EX.p2, EX.O2},
      ])
  end

  test "empty lines" do
    assert RDF.NQuads.Decoder.decode!("""

      <http://example.org/#spiderman> <http://www.perceive.net/schemas/relationship/enemyOf> <http://example.org/#green_goblin> <http://example.org/graphs/spiderman> .
      """) == Dataset.new({EX.spiderman, P.enemyOf, EX.green_goblin, ~I<http://example.org/graphs/spiderman>})

    assert RDF.NQuads.Decoder.decode!("""
      <http://example.org/#spiderman> <http://www.perceive.net/schemas/relationship/enemyOf> <http://example.org/#green_goblin> <http://example.org/graphs/spiderman> .

      """) == Dataset.new({EX.spiderman, P.enemyOf, EX.green_goblin, ~I<http://example.org/graphs/spiderman>})

    assert RDF.NQuads.Decoder.decode!("""

      <http://example.org/#S1> <http://example.org/#p1> <http://example.org/#O1> .


      <http://example.org/#S1> <http://example.org/#p2> <http://example.org/#O2> <http://example.org/#G> .

      """) == Dataset.new([
        {EX.S1, EX.p1, EX.O1},
        {EX.S1, EX.p2, EX.O2, EX.G},
      ])
  end

  test "decoding a single statement with uris" do
    assert RDF.NQuads.Decoder.decode!("""
      <http://example.org/#spiderman> <http://www.perceive.net/schemas/relationship/enemyOf> <http://example.org/#green_goblin> .
      """) == Dataset.new({EX.spiderman, P.enemyOf, EX.green_goblin})

    assert RDF.NQuads.Decoder.decode!("""
      <http://example.org/#spiderman> <http://www.perceive.net/schemas/relationship/enemyOf> <http://example.org/#green_goblin> <http://example.org/graphs/spiderman>.
      """) == Dataset.new({EX.spiderman, P.enemyOf, EX.green_goblin, ~I<http://example.org/graphs/spiderman>})
  end

  test "decoding a single statement with a blank node" do
    assert RDF.NQuads.Decoder.decode!("""
      _:foo <http://example.org/#p> <http://example.org/#O> <http://example.org/#G> .
      """) == Dataset.new({RDF.bnode("foo"), EX.p, EX.O, EX.G})
    assert RDF.NQuads.Decoder.decode!("""
      <http://example.org/#S> <http://example.org/#p> _:1 <http://example.org/#G> .
      """) == Dataset.new({EX.S, EX.p, RDF.bnode("1"), EX.G})
    assert RDF.NQuads.Decoder.decode!("""
      _:foo <http://example.org/#p> _:bar <http://example.org/#G> .
      """) == Dataset.new({RDF.bnode("foo"), EX.p, RDF.bnode("bar"), EX.G})
    assert RDF.NQuads.Decoder.decode!("""
      <http://example.org/#S> <http://example.org/#p> _:1 _:G .
      """) == Dataset.new({EX.S, EX.p, RDF.bnode("1"), RDF.bnode("G")})
  end

  test "decoding a single statement with an untyped string literal" do
    assert RDF.NQuads.Decoder.decode!("""
      <http://example.org/#spiderman> <http://www.perceive.net/schemas/relationship/realname> "Peter Parker" <http://example.org/#G> .
      """) == Dataset.new({EX.spiderman, P.realname, RDF.literal("Peter Parker"), EX.G})
    assert RDF.NQuads.Decoder.decode!("""
      <http://example.org/#spiderman> <http://www.perceive.net/schemas/relationship/realname> "Peter Parker" .
      """) == Dataset.new({EX.spiderman, P.realname, RDF.literal("Peter Parker")})
  end

  test "decoding a single statement with a typed literal" do
    assert RDF.NQuads.Decoder.decode!("""
      <http://example.org/#spiderman> <http://example.org/#p> "42"^^<http://www.w3.org/2001/XMLSchema#integer> <http://example.org/#G> .
      """) == Dataset.new({EX.spiderman, EX.p, RDF.literal(42), EX.G})
    assert RDF.NQuads.Decoder.decode!("""
      <http://example.org/#spiderman> <http://example.org/#p> "42"^^<http://www.w3.org/2001/XMLSchema#integer> .
      """) == Dataset.new({EX.spiderman, EX.p, RDF.literal(42)})
  end

  test "decoding a single statement with a language tagged literal" do
    assert RDF.NQuads.Decoder.decode!("""
      <http://example.org/#S> <http://example.org/#p> "foo"@en <http://example.org/#G> .
      """) == Dataset.new({EX.S, EX.p, RDF.literal("foo", language: "en"), EX.G})
    assert RDF.NQuads.Decoder.decode!("""
      <http://example.org/#S> <http://example.org/#p> "foo"@en .
      """) == Dataset.new({EX.S, EX.p, RDF.literal("foo", language: "en")})
  end

  test "decoding multiple statements" do
    assert RDF.NQuads.Decoder.decode!("""
      <http://example.org/#S1> <http://example.org/#p1> <http://example.org/#O1> <http://example.org/#G> .
      <http://example.org/#S1> <http://example.org/#p2> <http://example.org/#O2> <http://example.org/#G> .
      """) == Dataset.new([
        {EX.S1, EX.p1, EX.O1, EX.G},
        {EX.S1, EX.p2, EX.O2, EX.G},
      ])
    assert RDF.NQuads.Decoder.decode!("""
      <http://example.org/#S1> <http://example.org/#p1> <http://example.org/#O1> <http://example.org/#G> .
      <http://example.org/#S1> <http://example.org/#p2> <http://example.org/#O2> <http://example.org/#G> .
      <http://example.org/#S2> <http://example.org/#p3> <http://example.org/#O3> <http://example.org/#G> .
      <http://example.org/#S2> <http://example.org/#p3> <http://example.org/#O3> .
      """) == Dataset.new([
        {EX.S1, EX.p1, EX.O1, EX.G},
        {EX.S1, EX.p2, EX.O2, EX.G},
        {EX.S2, EX.p3, EX.O3, EX.G},
        {EX.S2, EX.p3, EX.O3}
      ])
  end

  describe "the official W3C RDF 1.1 N-Quads Test Suite" do
    # from https://www.w3.org/2013/N-QuadsTests/

    ExUnit.Case.register_attribute __ENV__, :nq_test

    @w3c_nquads_test_suite
    |> File.ls!
    |> Enum.filter(fn (file) -> Path.extname(file) == ".nq" end)
    |> Enum.each(fn (file) ->
      @nq_test file: Path.join(@w3c_nquads_test_suite, file)
      if file |> String.contains?("-bad-") do
        test "Negative syntax test: #{file}", context do
          assert {:error, _} = RDF.NQuads.read_file(context.registered.nq_test[:file])
        end
      else
        test "Positive syntax test: #{file}", context do
          assert {:ok, %RDF.Dataset{}} = RDF.NQuads.read_file(context.registered.nq_test[:file])
        end
      end
    end)

  end

end
