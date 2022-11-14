defmodule RDF.Query.BGP.StreamStarTest do
  use RDF.Query.Test.Case

  import RDF.Query.BGP.Stream, only: [execute: 2]

  @example_graph Graph.new([
                   {{EX.qs1(), EX.qp(), EX.qo1()}, EX.p1(), EX.o1()},
                   {{EX.qs1(), EX.qp(), EX.qo1()}, EX.p2(), {EX.qs2(), EX.qp(), EX.qo2()}},
                   {EX.s3(), EX.p3(), {EX.qs2(), EX.qp(), EX.qo2()}}
                 ])

  test "quoted triples in results" do
    assert bgp_struct({{EX.qs1(), EX.qp(), EX.qo1()}, :p, :o}) |> execute(@example_graph) ==
             [
               %{p: EX.p1(), o: EX.o1()},
               %{p: EX.p2(), o: {EX.qs2(), EX.qp(), EX.qo2()}}
             ]

    assert bgp_struct({:s, :p, {EX.qs2(), EX.qp(), EX.qo2()}}) |> execute(@example_graph) ==
             [
               %{s: {EX.qs1(), EX.qp(), EX.qo1()}, p: EX.p2()},
               %{s: EX.s3(), p: EX.p3()}
             ]

    assert bgp_struct({:s, EX.p2(), :o}) |> execute(@example_graph) ==
             [%{s: {EX.qs1(), EX.qp(), EX.qo1()}, o: {EX.qs2(), EX.qp(), EX.qo2()}}]
  end

  test "connected triple patterns with quoted triples" do
    assert bgp_struct([
             {EX.s(), EX.p(), :o},
             {{EX.qs(), EX.qp(), EX.qo()}, :p, :o}
           ])
           |> execute(
             Graph.new([
               {EX.s(), EX.p(), EX.o()},
               {{EX.qs(), EX.qp(), EX.qo()}, EX.p2(), EX.o()}
             ])
           ) == [
             %{
               p: EX.p2(),
               o: EX.o()
             }
           ]
  end

  test "triple patterns connected via a shared quoted triple" do
    assert bgp_struct([
             {:s, EX.p1(), EX.o1()},
             {:s, EX.p2(), {EX.qs2(), EX.qp(), EX.qo2()}}
           ])
           |> execute(@example_graph) ==
             [%{s: {EX.qs1(), EX.qp(), EX.qo1()}}]
  end

  test "variables in quoted triples on subject position" do
    assert bgp_struct({{:s, EX.qp(), EX.qo1()}, EX.p1(), EX.o1()}) |> execute(@example_graph) ==
             [%{s: EX.qs1()}]

    assert bgp_struct({{EX.qs1(), :p, EX.qo1()}, EX.p1(), EX.o1()}) |> execute(@example_graph) ==
             [%{p: EX.qp()}]

    assert bgp_struct({{EX.qs1(), EX.qp(), :o}, EX.p1(), EX.o1()}) |> execute(@example_graph) ==
             [%{o: EX.qo1()}]

    assert bgp_struct({{:s, :p, EX.qo1()}, EX.p1(), EX.o1()}) |> execute(@example_graph) ==
             [%{s: EX.qs1(), p: EX.qp()}]

    assert bgp_struct({{:s, EX.qp(), :o}, EX.p1(), EX.o1()}) |> execute(@example_graph) ==
             [%{s: EX.qs1(), o: EX.qo1()}]

    assert bgp_struct({{EX.qs1(), :p, :o}, EX.p1(), EX.o1()}) |> execute(@example_graph) ==
             [%{p: EX.qp(), o: EX.qo1()}]

    assert bgp_struct({{:s, :p, :o}, EX.p1(), EX.o1()}) |> execute(@example_graph) ==
             [%{s: EX.qs1(), p: EX.qp(), o: EX.qo1()}]
  end

  test "variables in quoted triples on object position" do
    assert bgp_struct({EX.s3(), EX.p3(), {:s, EX.qp(), EX.qo2()}}) |> execute(@example_graph) ==
             [%{s: EX.qs2()}]

    assert bgp_struct({EX.s3(), EX.p3(), {EX.qs2(), :p, EX.qo2()}}) |> execute(@example_graph) ==
             [%{p: EX.qp()}]

    assert bgp_struct({EX.s3(), EX.p3(), {EX.qs2(), EX.qp(), :o}}) |> execute(@example_graph) ==
             [%{o: EX.qo2()}]

    assert bgp_struct({EX.s3(), EX.p3(), {:s, :p, EX.qo2()}}) |> execute(@example_graph) == [
             %{s: EX.qs2(), p: EX.qp()}
           ]

    assert bgp_struct({EX.s3(), EX.p3(), {:s, EX.qp(), :o}}) |> execute(@example_graph) == [
             %{s: EX.qs2(), o: EX.qo2()}
           ]

    assert bgp_struct({EX.s3(), EX.p3(), {EX.qs2(), :p, :o}}) |> execute(@example_graph) == [
             %{p: EX.qp(), o: EX.qo2()}
           ]

    assert bgp_struct({EX.s3(), EX.p3(), {:s, :p, :o}}) |> execute(@example_graph) == [
             %{s: EX.qs2(), p: EX.qp(), o: EX.qo2()}
           ]

    # when the outer predicate is a variable
    assert bgp_struct({EX.s3(), :p, {:qs, EX.qp(), EX.qo2()}}) |> execute(@example_graph) ==
             [%{qs: EX.qs2(), p: EX.p3()}]

    assert bgp_struct({EX.s3(), :p, {EX.qs2(), :qp, :qo}}) |> execute(@example_graph) == [
             %{qp: EX.qp(), qo: EX.qo2(), p: EX.p3()}
           ]
  end

  test "variables in quoted triples on subject and object position" do
    assert bgp_struct({{:s1, EX.qp(), EX.qo1()}, EX.p2(), {:s2, EX.qp(), EX.qo2()}})
           |> execute(@example_graph) ==
             [%{s1: EX.qs1(), s2: EX.qs2()}]

    assert bgp_struct({{:s1, :p, EX.qo1()}, EX.p2(), {:s2, :p, EX.qo2()}})
           |> execute(@example_graph) ==
             [%{s1: EX.qs1(), s2: EX.qs2(), p: EX.qp()}]

    assert bgp_struct({{:s1, :p, :o1}, EX.p2(), {:s2, :p, :o2}})
           |> execute(@example_graph) ==
             [%{s1: EX.qs1(), o1: EX.qo1(), s2: EX.qs2(), o2: EX.qo2(), p: EX.qp()}]

    assert bgp_struct({{:s, EX.qp(), EX.qo1()}, EX.p2(), {:s, EX.qp(), EX.qo2()}})
           |> execute(@example_graph) ==
             []

    assert bgp_struct({{:s1, :p, EX.qo1()}, :p, {:s2, EX.qp(), EX.qo2()}})
           |> execute(@example_graph) ==
             []
  end

  test "triple patterns with interdependent variables" do
    assert bgp_struct([
             {{:qs1, :qp, EX.qo1()}, EX.p1(), EX.o1()},
             {:s, :p, {:qs2, :qp, EX.qo2()}}
           ])
           |> execute(@example_graph) ==
             [
               %{
                 qs1: EX.qs1(),
                 qs2: EX.qs2(),
                 qp: EX.qp(),
                 s: {EX.qs1(), EX.qp(), EX.qo1()},
                 p: EX.p2()
               },
               %{qs1: EX.qs1(), qs2: EX.qs2(), qp: EX.qp(), s: EX.s3(), p: EX.p3()}
             ]

    assert bgp_struct([
             {{:qs1, :qp, EX.qo1()}, :p, :o},
             {EX.s3(), EX.p3(), {:qs2, :qp, EX.qo2()}}
           ])
           |> execute(@example_graph) ==
             [
               %{qs1: EX.qs1(), qs2: EX.qs2(), qp: EX.qp(), o: EX.o1(), p: EX.p1()},
               %{
                 qs1: EX.qs1(),
                 qs2: EX.qs2(),
                 qp: EX.qp(),
                 o: {EX.qs2(), EX.qp(), EX.qo2()},
                 p: EX.p2()
               }
             ]

    assert bgp_struct([
             {{EX.qs1(), EX.qp(), :qo1}, EX.p1(), :o},
             {{EX.qs1(), EX.qp(), :qo1}, EX.p2(), {:qs2, EX.qp(), EX.qo2()}},
             {:s, EX.p3(), {:qs2, EX.qp(), EX.qo2()}}
           ])
           |> execute(@example_graph) ==
             [
               %{
                 s: EX.s3(),
                 o: EX.o1(),
                 qs2: EX.qs2(),
                 qo1: EX.qo1()
               }
             ]

    assert bgp_struct([
             {:qt, EX.p1(), :o},
             {:qt, EX.p2(), {:qs2, EX.qp(), EX.qo2()}},
             {:s, EX.p3(), {:qs2, EX.qp(), EX.qo2()}}
           ])
           |> execute(@example_graph) ==
             [
               %{
                 s: EX.s3(),
                 o: EX.o1(),
                 qs2: EX.qs2(),
                 qt: {EX.qs1(), EX.qp(), EX.qo1()}
               }
             ]

    assert bgp_struct([
             {:qt, EX.p1(), :o},
             {:qt, EX.p2(), {:qs2, EX.qp(), EX.qo2()}},
             {:s, EX.p3(), {:qs2, EX.qp(), EX.qo2()}},
             {
               {{:qs3, EX.b(), ~B"c"}, EX.d(), :qo3},
               EX.f(),
               {{{EX.g(), EX.h(), {:s, EX.j(), ~L"k"}}, EX.m(), EX.n()}, EX.o(), EX.p()}
             }
           ])
           |> execute(
             Graph.add(@example_graph, {
               {{EX.a(), EX.b(), ~B"c"}, EX.d(), EX.e()},
               EX.f(),
               {{{EX.g(), EX.h(), {EX.s3(), EX.j(), ~L"k"}}, EX.m(), EX.n()}, EX.o(), EX.p()}
             })
           ) ==
             [
               %{
                 s: EX.s3(),
                 o: EX.o1(),
                 qs2: EX.qs2(),
                 qs3: EX.a(),
                 qo3: EX.e(),
                 qt: {EX.qs1(), EX.qp(), EX.qo1()}
               }
             ]

    {
      {{:a, :b, ~B"c"}, :d, :e},
      :f,
      {{{:g, :h, {EX.s3(), :j, ~L"k"}}, :m, :n}, :o, :p}
    }
  end

  test "blank nodes in quoted triple patterns" do
    assert bgp_struct({{:s, EX.qp(), ~B"o"}, EX.p1(), EX.o1()})
           |> execute(@example_graph) ==
             [%{s: EX.qs1()}]

    assert bgp_struct({:s, EX.p3(), {~B"s", ~B"p", ~B"o"}})
           |> execute(@example_graph) ==
             [%{s: EX.s3()}]

    assert bgp_struct([
             {~B"s", EX.p3(), ~B"quoted triple"},
             {
               {{EX.a(), EX.b(), ~B"c"}, EX.d(), EX.e()},
               EX.f(),
               {{{EX.g(), EX.h(), {~B"s", EX.j(), ~L"k"}}, EX.m(), :n}, EX.o(), EX.p()}
             }
           ])
           |> execute(
             Graph.add(@example_graph, {
               {{EX.a(), EX.b(), ~B"c"}, EX.d(), EX.e()},
               EX.f(),
               {{{EX.g(), EX.h(), {EX.s3(), EX.j(), ~L"k"}}, EX.m(), EX.n()}, EX.o(), EX.p()}
             })
           ) ==
             [%{n: EX.n()}]
  end
end
