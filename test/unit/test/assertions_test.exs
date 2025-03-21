defmodule RDF.Test.AssertionsTest do
  use RDF.Test.Case

  describe "assert_rdf_isomorphic/2" do
    test "performs isomorphism check" do
      graph1 = Graph.new([{~B<foo>, EX.p(), ~B<bar>}])
      graph2 = Graph.new([{~B<b1>, EX.p(), ~B<b2>}])

      assert_rdf_isomorphic graph1, graph2
      assert_rdf_isomorphic Dataset.new(graph1), graph2
      assert_rdf_isomorphic graph1, Dataset.new(graph2)
      assert_rdf_isomorphic Dataset.new(graph1), Dataset.new(graph2)
    end

    test "shows correct diff for graph vs graph" do
      graph1 = Graph.new([{~B<foo>, EX.p(), ~B<bar>}, {~B<bar>, EX.p(), 42}])
      graph2 = Graph.new([{~B<b1>, EX.p(), ~B<b2>}, {~B<b1>, EX.p(), 43}])

      assert_diff_error(graph1, graph2,
        left: graph1,
        right: graph2
      )
    end

    test "extracts single graph from dataset for better diff" do
      graph = Graph.new([{~B<foo>, EX.p(), ~B<bar>}, {~B<bar>, EX.p(), 42}])
      dataset = Dataset.new(graph)
      different_graph = Graph.new([{~B<b1>, EX.p(), ~B<b2>}, {~B<b1>, EX.p(), 43}])

      assert_diff_error(dataset, different_graph,
        left: graph,
        right: different_graph
      )

      assert_diff_error(different_graph, dataset,
        left: different_graph,
        right: graph
      )
    end

    test "shows dataset structure when multiple graphs" do
      graph = Graph.new([{~B<foo>, EX.p(), ~B<bar>}])

      multi_graph_dataset =
        Dataset.new()
        |> Dataset.add(Graph.new([{~B<foo>, EX.p(), ~B<bar>}], name: EX.Graph1))
        |> Dataset.add(Graph.new([{~B<bar>, EX.p(), ~B<baz>}], name: EX.Graph2))

      assert_diff_error(multi_graph_dataset, graph,
        left: multi_graph_dataset,
        right: graph
      )
    end
  end

  def assert_diff_error(left, right, opts \\ []) do
    try do
      assert_rdf_isomorphic left, right
      flunk("Expected assert_rdf_isomorphic to fail, but it passed")
    rescue
      error in [ExUnit.AssertionError] ->
        assert error.message =~ "RDF data is not isomorphic"
        assert error.left == Keyword.get(opts, :left)
        assert error.right == Keyword.get(opts, :right)
        error
    end
  end
end
