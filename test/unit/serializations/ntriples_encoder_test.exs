defmodule RDF.NTriples.EncoderTest do
  use ExUnit.Case, async: false

  alias RDF.NTriples

  doctest NTriples.Encoder

  alias RDF.Graph
  alias RDF.NS.XSD

  import RDF.Sigils
  import RDF.Test.Case, only: [stream_to_string: 1]

  use RDF.Vocabulary.Namespace

  defvocab EX, base_iri: "http://example.org/#", terms: [], strict: false

  test "stream_support?/0" do
    assert NTriples.Encoder.stream_support?()
  end

  describe "encode/2" do
    test "an empty graph is serialized to an empty string" do
      assert NTriples.Encoder.encode!(Graph.new()) == ""
    end

    test "statements with IRIs only" do
      assert NTriples.Encoder.encode!(
               Graph.new([
                 {EX.S1, EX.p1(), EX.O1},
                 {EX.S1, EX.p1(), EX.O2},
                 {EX.S1, EX.p2(), EX.O3},
                 {EX.S2, EX.p3(), EX.O4}
               ])
             ) ==
               """
               <http://example.org/#S1> <http://example.org/#p1> <http://example.org/#O1> .
               <http://example.org/#S1> <http://example.org/#p1> <http://example.org/#O2> .
               <http://example.org/#S1> <http://example.org/#p2> <http://example.org/#O3> .
               <http://example.org/#S2> <http://example.org/#p3> <http://example.org/#O4> .
               """
    end

    test "statements with literals" do
      assert NTriples.Encoder.encode!(
               Graph.new([
                 {EX.S1, EX.p1(), ~L"foo"},
                 {EX.S1, EX.p1(), ~L"foo"en},
                 {EX.S1, EX.p2(), 42},
                 {EX.S2, EX.p3(), RDF.literal("strange things", datatype: EX.custom())}
               ])
             ) ==
               """
               <http://example.org/#S1> <http://example.org/#p1> "foo"@en .
               <http://example.org/#S1> <http://example.org/#p1> "foo" .
               <http://example.org/#S1> <http://example.org/#p2> "42"^^<#{XSD.integer()}> .
               <http://example.org/#S2> <http://example.org/#p3> "strange things"^^<#{EX.custom()}> .
               """
    end

    # jcs v0.2 behaves differently on OTP < 25
    if String.to_integer(System.otp_release()) >= 25 do
      test "statements with rdf:JSON literals" do
        assert NTriples.Encoder.encode!(
                 Graph.new([
                   {EX.S1, EX.p1(), RDF.json(42)},
                   {EX.S1, EX.p1(), RDF.json(3.14)},
                   {EX.S1, EX.p1(), RDF.json(true)},
                   {EX.S1, EX.p1(), RDF.json("foo", as_value: true)}
                 ])
               ) ==
                 """
                 <http://example.org/#S1> <http://example.org/#p1> "\\"foo\\""^^<http://www.w3.org/1999/02/22-rdf-syntax-ns#JSON> .
                 <http://example.org/#S1> <http://example.org/#p1> "3.14"^^<http://www.w3.org/1999/02/22-rdf-syntax-ns#JSON> .
                 <http://example.org/#S1> <http://example.org/#p1> "42"^^<http://www.w3.org/1999/02/22-rdf-syntax-ns#JSON> .
                 <http://example.org/#S1> <http://example.org/#p1> "true"^^<http://www.w3.org/1999/02/22-rdf-syntax-ns#JSON> .
                 """
      end
    end

    test "statements with blank nodes" do
      assert NTriples.Encoder.encode!(
               Graph.new([
                 {EX.S1, EX.p1(), RDF.bnode(1)},
                 {EX.S1, EX.p1(), RDF.bnode("foo")},
                 {EX.S1, EX.p1(), RDF.bnode(:bar)}
               ])
             ) ==
               """
               <http://example.org/#S1> <http://example.org/#p1> _:b1 .
               <http://example.org/#S1> <http://example.org/#p1> _:bar .
               <http://example.org/#S1> <http://example.org/#p1> _:foo .
               """
    end

    test "string escaping" do
      assert NTriples.Encoder.encode!(
               Graph.new([
                 {EX.S, EX.p(), ~s["foo"\n\r"bar"]},
                 {EX.S, EX.p(), RDF.literal(~s["foo"\n\r"bar"], language: "en")}
               ])
             ) ==
               """
               <http://example.org/#S> <http://example.org/#p> "\\"foo\\"\\n\\r\\"bar\\""@en .
               <http://example.org/#S> <http://example.org/#p> "\\"foo\\"\\n\\r\\"bar\\"" .
               """
    end

    test ":sort option" do
      assert NTriples.Encoder.encode!(
               Graph.new([
                 {EX.S, EX.p(), EX.O},
                 {EX.S, EX.p(), RDF.bnode(1)},
                 {EX.S, EX.p(), ~L"foo"},
                 {EX.S, EX.p(), ~L"foo"en},
                 {EX.S, EX.p(), RDF.literal("strange things", datatype: EX.custom())}
               ]),
               sort: true
             ) ==
               """
               <http://example.org/#S> <http://example.org/#p> "foo" .
               <http://example.org/#S> <http://example.org/#p> "foo"@en .
               <http://example.org/#S> <http://example.org/#p> "strange things"^^<http://example.org/#custom> .
               <http://example.org/#S> <http://example.org/#p> <http://example.org/#O> .
               <http://example.org/#S> <http://example.org/#p> _:b1 .
               """
    end
  end

  describe "stream/2" do
    graph =
      Graph.new([
        {EX.S1, EX.p1(), EX.O1},
        {EX.S2, EX.p2(), RDF.bnode("foo")},
        {EX.S3, EX.p3(), ~L"foo"},
        {EX.S3, EX.p3(), ~L"foo"en}
      ])

    expected_result = """
    <http://example.org/#S1> <http://example.org/#p1> <http://example.org/#O1> .
    <http://example.org/#S2> <http://example.org/#p2> _:foo .
    <http://example.org/#S3> <http://example.org/#p3> "foo"@en .
    <http://example.org/#S3> <http://example.org/#p3> "foo" .
    """

    assert NTriples.Encoder.stream(graph, mode: :string)
           |> stream_to_string() ==
             expected_result

    assert NTriples.Encoder.stream(graph, mode: :iodata)
           |> stream_to_string() ==
             expected_result
  end
end
