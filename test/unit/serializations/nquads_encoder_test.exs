defmodule RDF.NQuads.EncoderTest do
  use ExUnit.Case, async: false

  alias RDF.NQuads

  doctest NQuads.Encoder

  alias RDF.{Dataset, Graph}
  alias RDF.NS.XSD

  import RDF.Sigils
  import RDF.Test.Case, only: [stream_to_string: 1]

  use RDF.Vocabulary.Namespace

  defvocab EX, base_iri: "http://example.org/#", terms: [], strict: false

  test "stream_support?/0" do
    assert NQuads.Encoder.stream_support?()
  end

  describe "serializing a graph" do
    test "an empty graph is serialized to an empty string" do
      assert NQuads.Encoder.encode!(Graph.new()) == ""
    end

    test "graph name" do
      assert Graph.new({EX.S1, EX.p1(), EX.O1}) |> NQuads.Encoder.encode!() ==
               """
               <http://example.org/#S1> <http://example.org/#p1> <http://example.org/#O1> .
               """

      assert Graph.new({EX.S1, EX.p1(), EX.O1}, name: EX.Graph) |> NQuads.Encoder.encode!() ==
               """
               <http://example.org/#S1> <http://example.org/#p1> <http://example.org/#O1> <http://example.org/#Graph> .
               """
    end

    test "default_graph_name opt" do
      assert Graph.new({EX.S1, EX.p1(), EX.O1})
             |> NQuads.Encoder.encode!(default_graph_name: EX.Graph) ==
               """
               <http://example.org/#S1> <http://example.org/#p1> <http://example.org/#O1> <http://example.org/#Graph> .
               """

      assert Graph.new({EX.S1, EX.p1(), EX.O1}, name: EX.Graph)
             |> NQuads.Encoder.encode!(default_graph_name: nil) ==
               """
               <http://example.org/#S1> <http://example.org/#p1> <http://example.org/#O1> .
               """
    end

    test "statements with IRIs only" do
      assert NQuads.Encoder.encode!(
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
      assert NQuads.Encoder.encode!(
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
      assert NQuads.Encoder.encode!(
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
      assert NQuads.Encoder.encode!(
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
  end

  test "serializing a description" do
    description = EX.S1 |> EX.p1(EX.O1)

    assert NQuads.Encoder.encode!(description) ==
             """
             <http://example.org/#S1> <http://example.org/#p1> <http://example.org/#O1> .
             """

    assert NQuads.Encoder.encode!(description, default_graph_name: EX.Graph) ==
             """
             <http://example.org/#S1> <http://example.org/#p1> <http://example.org/#O1> <http://example.org/#Graph> .
             """
  end

  describe "serializing a dataset" do
    test "an empty dataset is serialized to an empty string" do
      assert NQuads.Encoder.encode!(Dataset.new()) == ""
    end

    test "statements with IRIs only" do
      assert NQuads.Encoder.encode!(
               Dataset.new([
                 {EX.S1, EX.p1(), EX.O1, EX.G},
                 {EX.S1, EX.p1(), EX.O2, EX.G},
                 {EX.S1, EX.p2(), EX.O3, EX.G},
                 {EX.S2, EX.p3(), EX.O4}
               ])
             ) ==
               """
               <http://example.org/#S2> <http://example.org/#p3> <http://example.org/#O4> .
               <http://example.org/#S1> <http://example.org/#p1> <http://example.org/#O1> <http://example.org/#G> .
               <http://example.org/#S1> <http://example.org/#p1> <http://example.org/#O2> <http://example.org/#G> .
               <http://example.org/#S1> <http://example.org/#p2> <http://example.org/#O3> <http://example.org/#G> .
               """
    end

    test "statements with literals" do
      assert NQuads.Encoder.encode!(
               Dataset.new([
                 {EX.S1, EX.p1(), ~L"foo", EX.G1},
                 {EX.S1, EX.p1(), ~L"foo"en, EX.G2},
                 {EX.S1, EX.p2(), 42, EX.G3},
                 {EX.S2, EX.p3(), RDF.literal("strange things", datatype: EX.custom()), EX.G3}
               ])
             ) ==
               """
               <http://example.org/#S1> <http://example.org/#p1> "foo" <http://example.org/#G1> .
               <http://example.org/#S1> <http://example.org/#p1> "foo"@en <http://example.org/#G2> .
               <http://example.org/#S1> <http://example.org/#p2> "42"^^<#{XSD.integer()}> <http://example.org/#G3> .
               <http://example.org/#S2> <http://example.org/#p3> "strange things"^^<#{EX.custom()}> <http://example.org/#G3> .
               """
    end

    test "statements with blank nodes" do
      assert NQuads.Encoder.encode!(
               Dataset.new([
                 {EX.S1, EX.p1(), RDF.bnode(1)},
                 {EX.S1, EX.p1(), RDF.bnode("foo"), EX.G},
                 {EX.S1, EX.p1(), RDF.bnode(:bar)}
               ])
             ) ==
               """
               <http://example.org/#S1> <http://example.org/#p1> _:b1 .
               <http://example.org/#S1> <http://example.org/#p1> _:bar .
               <http://example.org/#S1> <http://example.org/#p1> _:foo <http://example.org/#G> .
               """
    end
  end

  test ":sort option" do
    assert NQuads.Encoder.encode!(
             Dataset.new([
               {EX.S, EX.p(), EX.O},
               {EX.S, EX.p(), EX.O, EX.G},
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
             <http://example.org/#S> <http://example.org/#p> <http://example.org/#O> <http://example.org/#G> .
             <http://example.org/#S> <http://example.org/#p> _:b1 .
             """

    # example from the spec RDF Dataset Canonicalization spec: https://w3c.github.io/rdf-canon/spec/#serialization
    assert NQuads.Encoder.encode!(
             Graph.new([
               {~I<http://example.com/p>, ~I<http://example.com/q>, ~B<c14n0>},
               {~I<http://example.com/p>, ~I<http://example.com/r>, ~B<c14n1>},
               {~B<c14n0>, ~I<http://example.com/s>, ~I<http://example.com/u>},
               {~B<c14n1>, ~I<http://example.com/t>, ~I<http://example.com/u>}
             ]),
             sort: true
           ) ==
             """
             <http://example.com/p> <http://example.com/q> _:c14n0 .
             <http://example.com/p> <http://example.com/r> _:c14n1 .
             _:c14n0 <http://example.com/s> <http://example.com/u> .
             _:c14n1 <http://example.com/t> <http://example.com/u> .
             """
  end

  describe "stream/2" do
    test "a dataset" do
      dataset =
        Dataset.new([
          {EX.S1, EX.p1(), EX.O1},
          {EX.S2, EX.p2(), RDF.bnode("foo"), EX.G},
          {EX.S3, EX.p3(), ~L"foo"},
          {EX.S3, EX.p3(), ~L"foo"en, EX.G}
        ])

      expected_result = """
      <http://example.org/#S1> <http://example.org/#p1> <http://example.org/#O1> .
      <http://example.org/#S3> <http://example.org/#p3> "foo" .
      <http://example.org/#S2> <http://example.org/#p2> _:foo <http://example.org/#G> .
      <http://example.org/#S3> <http://example.org/#p3> "foo"@en <http://example.org/#G> .
      """

      assert NQuads.Encoder.stream(dataset, mode: :string)
             |> stream_to_string() ==
               expected_result

      assert NQuads.Encoder.stream(dataset, mode: :iodata)
             |> stream_to_string() ==
               expected_result
    end

    test "a graph" do
      expected_unnamed_graph_result = """
      <http://example.org/#S1> <http://example.org/#p1> <http://example.org/#O1> .
      """

      expected_named_graph_result = """
      <http://example.org/#S1> <http://example.org/#p1> <http://example.org/#O1> <http://example.org/#Graph> .
      """

      assert Graph.new({EX.S1, EX.p1(), EX.O1})
             |> NQuads.Encoder.stream(mode: :string)
             |> stream_to_string() ==
               expected_unnamed_graph_result

      assert Graph.new({EX.S1, EX.p1(), EX.O1})
             |> NQuads.Encoder.stream(mode: :iodata)
             |> stream_to_string() ==
               expected_unnamed_graph_result

      assert Graph.new({EX.S1, EX.p1(), EX.O1}, name: EX.Graph)
             |> NQuads.Encoder.stream(mode: :string)
             |> stream_to_string() ==
               expected_named_graph_result

      assert Graph.new({EX.S1, EX.p1(), EX.O1}, name: EX.Graph)
             |> NQuads.Encoder.stream(mode: :iodata)
             |> stream_to_string() ==
               expected_named_graph_result
    end
  end
end
