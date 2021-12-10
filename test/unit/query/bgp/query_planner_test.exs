defmodule RDF.Query.BGP.QueryPlannerTest do
  use RDF.Query.Test.Case

  import RDF.QueryPlannerHelper

  alias RDF.Query.BGP.QueryPlanner

  test "empty" do
    assert QueryPlanner.query_plan([]) == []
  end

  test "single" do
    assert QueryPlanner.query_plan([tp(1, {1, 1, 1})]) == [tp(1, {1, 1, 1})]
  end

  test "multiple connected" do
    assert QueryPlanner.query_plan([tp(1, {:o, 0, 0}), tp(2, {0, 0, :o})]) == [
             tp(2, {0, 0, :o}),
             tp(1, {{:o}, 0, 0})
           ]

    assert QueryPlanner.query_plan([tp(1, {:a, 1, 1}), tp(2, {:a, 1, 0})]) == [
             tp(2, {:a, 1, 0}),
             tp(1, {{:a}, 1, 1})
           ]

    assert QueryPlanner.query_plan([
             tp(1, {:s, :p, 1}),
             tp(2, {1, 1, :o2}),
             tp(3, {:s, :p, :o2}),
             tp(4, {1, 1, 0})
           ]) == [
             tp(4, {1, 1, 0}),
             tp(1, {:s, :p, 1}),
             tp(3, {{:s}, {:p}, :o2}),
             tp(2, {1, 1, {:o2}})
           ]
  end

  test "deeply nested quoted triples" do
    assert QueryPlanner.query_plan([
             {:c, :d, ~L"foo"},
             {{EX.S, EX.p(), EX.O}, :b, :c}
           ]) == [
             {{EX.S, EX.p(), EX.O}, :b, :c},
             {{:c}, :d, ~L"foo"}
           ]

    assert QueryPlanner.query_plan([
             {
               {{:a, :b, ~B"c"}, :d, :e},
               :f,
               {{{:g, :h, {RDF.iri(EX.I), :j, ~L"k"}}, :m, :n}, :o, :p}
             },
             # This similar pattern contains a duplicate and should be prioritized
             {
               {{:a1, :b1, ~B"c"}, :d1, :a1},
               :f1,
               {{{:g1, :h1, {RDF.iri(EX.I), :j1, ~L"k"}}, :m1, :n1}, :o1, :p}
             }
           ]) == [
             {
               {{:a1, :b1, ~B"c"}, :d1, :a1},
               :f1,
               {{{:g1, :h1, {RDF.iri(EX.I), :j1, ~L"k"}}, :m1, :n1}, :o1, :p}
             },
             {
               {{:a, :b, ~B"c"}, :d, :e},
               :f,
               {{{:g, :h, {RDF.iri(EX.I), :j, ~L"k"}}, :m, :n}, :o, {:p}}
             }
           ]

    assert QueryPlanner.query_plan([
             {
               {{:a, :b, ~B"c"}, :d, :e},
               :f,
               {{{:g, :h, {RDF.iri(EX.I), :j, ~L"k"}}, :m, :n}, :o, :p}
             },
             {
               {{:a, :b, ~B"c"}, :d, :e},
               :f,
               {{{:g, :h, {RDF.iri(EX.I), :j, ~L"k"}}, :m, :n}, :o, :a}
             }
           ]) == [
             {
               {{:a, :b, ~B"c"}, :d, :e},
               :f,
               {{{:g, :h, {RDF.iri(EX.I), :j, ~L"k"}}, :m, :n}, :o, :a}
             },
             {
               {{{:a}, {:b}, ~B"c"}, {:d}, {:e}},
               {:f},
               {{{{:g}, {:h}, {RDF.iri(EX.I), {:j}, ~L"k"}}, {:m}, {:n}}, {:o}, :p}
             }
           ]
  end

  test "all possible combinations" do
    Enum.each(all_combinations(), fn {left, right} ->
      if left |> better?(right) do
        assert match?([^left, _], QueryPlanner.query_plan([left, right])),
               "#{inspect(left)} should have been prioritized over #{inspect(right)}, but wasn't"
      end
    end)
  end

  def tp(_, {0, 0, 0}), do: {EX.s(), EX.p(), ~L"o"}
  def tp(i, {0, 0, o}), do: {EX.s(), EX.p(), tp_var(:o, o, i)}
  def tp(i, {0, p, 0}), do: {EX.s(), tp_var(:p, p, i), ~L"o"}
  def tp(i, {s, 0, 0}), do: {tp_var(:s, s, i), EX.p(), ~L"o"}
  def tp(i, {0, p, o}), do: {EX.s(), tp_var(:p, p, i), tp_var(:o, o, i)}
  def tp(i, {s, 0, o}), do: {tp_var(:s, s, i), EX.p(), tp_var(:o, o, i)}
  def tp(i, {s, p, 0}), do: {tp_var(:s, s, i), tp_var(:p, p, i), ~L"o"}
  def tp(i, {s, p, o}), do: {tp_var(:s, s, i), tp_var(:p, p, i), tp_var(:o, o, i)}

  defp tp_var(pos, 1, i), do: String.to_atom("#{to_string(pos)}_#{i}")
  defp tp_var(_, var, _), do: var
end
