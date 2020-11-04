defmodule RDF.NTriples.EncoderTest do
  use ExUnit.Case, async: false

  alias RDF.NTriples

  doctest NTriples.Encoder

  alias RDF.Graph
  alias RDF.NS.XSD

  import RDF.Sigils

  use RDF.Vocabulary.Namespace

  defvocab EX, base_iri: "http://example.org/#", terms: [], strict: false

  test "stream_support?/0" do
    assert NTriples.Encoder.stream_support?()
  end

  describe "serializing a graph" do
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
           |> Enum.to_list()
           |> IO.iodata_to_binary() ==
             expected_result

    assert NTriples.Encoder.stream(graph, mode: :iodata)
           |> Enum.to_list()
           |> IO.iodata_to_binary() ==
             expected_result
  end
end
