defmodule RDF.Query.BGP.SimpleTest do
  use RDF.Query.Test.Case

  import RDF.Query.BGP.Simple, only: [execute: 2]

  @example_graph Graph.new([
                   {EX.s1(), EX.p1(), EX.o1()},
                   {EX.s1(), EX.p2(), EX.o2()},
                   {EX.s3(), EX.p3(), EX.o2()}
                 ])

  test "empty bgp" do
    assert bgp_struct() |> execute(@example_graph) == [%{}]
  end

  test "single {s ?p ?o}" do
    assert bgp_struct({EX.s1(), :p, :o}) |> execute(@example_graph) ==
             [
               %{p: EX.p1(), o: EX.o1()},
               %{p: EX.p2(), o: EX.o2()}
             ]
  end

  test "single {?s ?p o}" do
    assert bgp_struct({:s, :p, EX.o2()}) |> execute(@example_graph) ==
             [
               %{s: EX.s3(), p: EX.p3()},
               %{s: EX.s1(), p: EX.p2()}
             ]
  end

  test "single {?s p ?o}" do
    assert bgp_struct({:s, EX.p3(), :o}) |> execute(@example_graph) ==
             [%{s: EX.s3(), o: EX.o2()}]
  end

  test "with no solutions" do
    assert bgp_struct({:a, :b, :c}) |> execute(Graph.new()) == []
  end

  test "with solutions on one triple pattern but none on another one" do
    example_graph =
      Graph.new([
        {EX.x(), EX.y(), EX.z()},
        {EX.y(), EX.y(), EX.z()}
      ])

    assert bgp_struct([
             {:a, EX.p1(), ~L"unmatched"},
             {:a, EX.y(), EX.z()}
           ])
           |> execute(example_graph) == []
  end

  test "repeated variable: {?a ?a ?b}" do
    example_graph =
      Graph.new([
        {EX.y(), EX.y(), EX.x()},
        {EX.x(), EX.y(), EX.y()},
        {EX.y(), EX.x(), EX.y()}
      ])

    assert bgp_struct({:a, :a, :b}) |> execute(example_graph) ==
             [%{a: EX.y(), b: EX.x()}]
  end

  test "repeated variable: {?a ?b ?a}" do
    example_graph =
      Graph.new([
        {EX.y(), EX.y(), EX.x()},
        {EX.x(), EX.y(), EX.y()},
        {EX.y(), EX.x(), EX.y()}
      ])

    assert bgp_struct({:a, :b, :a}) |> execute(example_graph) ==
             [%{a: EX.y(), b: EX.x()}]
  end

  test "repeated variable: {?b ?a ?a}" do
    example_graph =
      Graph.new([
        {EX.y(), EX.y(), EX.x()},
        {EX.x(), EX.y(), EX.y()},
        {EX.y(), EX.x(), EX.y()}
      ])

    assert bgp_struct({:b, :a, :a}) |> execute(example_graph) ==
             [%{a: EX.y(), b: EX.x()}]
  end

  test "repeated variable: {?a ?a ?a}" do
    example_graph =
      Graph.new([
        {EX.y(), EX.y(), EX.x()},
        {EX.x(), EX.y(), EX.y()},
        {EX.y(), EX.x(), EX.y()},
        {EX.y(), EX.y(), EX.y()}
      ])

    assert bgp_struct({:a, :a, :a}) |> execute(example_graph) == [%{a: EX.y()}]
  end

  test "two connected triple patterns with a match" do
    assert execute(
             bgp_struct([
               {EX.s1(), :p, :o},
               {EX.s3(), :p2, :o}
             ]),
             @example_graph
           ) == [
             %{
               p: EX.p2(),
               p2: EX.p3(),
               o: EX.o2()
             }
           ]

    assert bgp_struct([
             {EX.s1(), :p, :o1},
             {EX.s1(), :p, :o2}
           ])
           |> execute(@example_graph) ==
             [
               %{
                 p: EX.p1(),
                 o1: EX.o1(),
                 o2: EX.o1()
               },
               %{
                 p: EX.p2(),
                 o1: EX.o2(),
                 o2: EX.o2()
               }
             ]

    assert bgp_struct([
             {EX.s1(), EX.p1(), :o},
             {EX.s3(), :p, :o}
           ])
           |> execute(
             Graph.new([
               {EX.s1(), EX.p1(), EX.o1()},
               {EX.s3(), EX.p2(), EX.o2()},
               {EX.s3(), EX.p3(), EX.o1()}
             ])
           ) == [%{p: EX.p3(), o: EX.o1()}]
  end

  test "a triple pattern with dependent variables from separate triple patterns" do
    assert bgp_struct([
             {EX.s1(), EX.p1(), :o},
             {EX.s2(), :p, EX.o2()},
             {:s, :p, :o}
           ])
           |> execute(
             Graph.new([
               {EX.s1(), EX.p1(), EX.o1()},
               {EX.s2(), EX.p2(), EX.o2()},
               {EX.s3(), EX.p2(), EX.o1()}
             ])
           ) == [
             %{
               s: EX.s3(),
               p: EX.p2(),
               o: EX.o1()
             }
           ]
  end

  test "when no solutions" do
    assert bgp_struct({EX.s(), EX.p(), :o}) |> execute(@example_graph) == []
  end

  test "multiple triple patterns with a constant unmatched triple has no solutions" do
    assert bgp_struct([
             {EX.s1(), :p, :o},
             {EX.s(), EX.p(), EX.o()}
           ])
           |> execute(@example_graph) == []
  end

  test "independent triple patterns lead to cross-products" do
    assert bgp_struct([
             {EX.s1(), :p1, :o},
             {:s, :p2, EX.o2()}
           ])
           |> execute(@example_graph) == [
             %{
               p1: EX.p1(),
               o: EX.o1(),
               s: EX.s3(),
               p2: EX.p3()
             },
             %{
               p1: EX.p2(),
               o: EX.o2(),
               s: EX.s3(),
               p2: EX.p3()
             },
             %{
               p1: EX.p1(),
               o: EX.o1(),
               s: EX.s1(),
               p2: EX.p2()
             },
             %{
               p1: EX.p2(),
               o: EX.o2(),
               s: EX.s1(),
               p2: EX.p2()
             }
           ]
  end

  test "blank nodes behave like variables, but don't appear in the solution" do
    assert bgp_struct([
             {EX.s1(), :p, RDF.bnode("o")},
             {EX.s3(), :p2, RDF.bnode("o")}
           ])
           |> execute(@example_graph) == [%{p: EX.p2(), p2: EX.p3()}]
  end

  test "cross-product with blank nodes" do
    assert bgp_struct([
             {EX.s1(), :p1, :o},
             {RDF.bnode("s"), :p2, EX.o2()}
           ])
           |> execute(@example_graph) ==
             [
               %{
                 p1: EX.p1(),
                 o: EX.o1(),
                 p2: EX.p3()
               },
               %{
                 p1: EX.p2(),
                 o: EX.o2(),
                 p2: EX.p3()
               },
               %{
                 p1: EX.p1(),
                 o: EX.o1(),
                 p2: EX.p2()
               },
               %{
                 p1: EX.p2(),
                 o: EX.o2(),
                 p2: EX.p2()
               }
             ]
  end
end
