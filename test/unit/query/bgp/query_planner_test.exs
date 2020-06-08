defmodule RDF.Query.BGP.QueryPlannerTest do
  use RDF.Test.Case

  alias RDF.Query.BGP.QueryPlanner

  describe "query_plan/1" do

    test "empty" do
      assert QueryPlanner.query_plan([]) == []
    end

    test "single" do
      assert QueryPlanner.query_plan([{:a, :b, :c}]) == [{:a, :b, :c}]
    end

    test "multiple connected" do
      assert QueryPlanner.query_plan([
               {:a, :b, :c},
               {:a, :d, ~L"foo"}
             ]) == [
               {:a, :d, ~L"foo"},
               {{:a}, :b, :c}
             ]

      assert QueryPlanner.query_plan([
               {:s, :p, :o},
               {:s2, :p2, :o2},
               {:s, :p, :o2},
               {:s4, :p4, ~L"foo"}
             ]) == [
               {:s4, :p4, ~L"foo"},
               {:s, :p, :o},
               {{:s}, {:p}, :o2},
               {:s2, :p2, {:o2}},
             ]
    end
  end
end
