defmodule RDF.Canonicalization.IsomorphicTest do
  use RDF.Test.Case

  describe "RDF.Dataset.isomorphic?/2" do
    test "isomorphic datasets" do
      dataset = Dataset.new([{~B<foo>, EX.p(), ~B<bar>}, {~B<bar>, EX.p(), 42}])
      isomorphic_graph = Graph.new([{~B<b1>, EX.p(), ~B<b2>}, {~B<b2>, EX.p(), 42}])

      assert Dataset.isomorphic?(dataset, dataset) == true

      assert Dataset.isomorphic?(dataset, Dataset.new(isomorphic_graph)) == true
      assert Dataset.isomorphic?(dataset, isomorphic_graph) == true
      assert Dataset.isomorphic?(isomorphic_graph, dataset) == true

      assert Dataset.isomorphic?(
               dataset,
               Graph.new([{~B<b1>, EX.p(), ~B<b2>}, {~B<b2>, EX.p(), 42}])
             ) == true
    end

    test "non-isomorphic datasets" do
      assert Dataset.isomorphic?(
               Dataset.new([{~B<foo>, EX.p(), ~B<bar>}, {~B<bar>, EX.p(), 42}]),
               Dataset.new([{~B<b1>, EX.p(), ~B<b2>}, {~B<b1>, EX.p(), 42}])
             ) == false
    end
  end

  describe "RDF.Graph.isomorphic?/1" do
    test "isomorphic graphs" do
      graph = Graph.new([{~B<foo>, EX.p(), ~B<bar>}, {~B<bar>, EX.p(), 42}])

      assert Graph.isomorphic?(graph, graph) == true

      assert Graph.isomorphic?(
               graph,
               Graph.new([{~B<b1>, EX.p(), ~B<b2>}, {~B<b2>, EX.p(), 42}])
             ) == true
    end

    test "non-isomorphic graphs" do
      assert Graph.isomorphic?(
               Graph.new([{~B<foo>, EX.p(), ~B<bar>}, {~B<bar>, EX.p(), 42}]),
               Graph.new([{~B<b1>, EX.p(), ~B<b2>}, {~B<b1>, EX.p(), 42}])
             ) == false
    end
  end

  @isomorphic_test_data "test/data/isomorphic"

  @isomorphic_test_data
  |> File.ls!()
  |> Enum.each(fn isomorphic_example ->
    path = Path.join(@isomorphic_test_data, isomorphic_example)
    [left, right] = path |> File.ls!() |> Enum.map(&Path.join(path, &1))
    @tag left: left, right: right
    test "isomorphic: " <> isomorphic_example, %{left: left, right: right} do
      assert RDF.Canonicalization.isomorphic?(
               RDF.read_file!(left),
               RDF.read_file!(right)
             )
    end
  end)

  @non_isomorphic_test_data "test/data/non-isomorphic"

  @non_isomorphic_test_data
  |> File.ls!()
  |> Enum.each(fn non_isomorphic_example ->
    path = Path.join(@non_isomorphic_test_data, non_isomorphic_example)
    [left, right] = path |> File.ls!() |> Enum.map(&Path.join(path, &1))
    @tag left: left, right: right
    test "non-isomorphic: " <> non_isomorphic_example, %{left: left, right: right} do
      refute RDF.Canonicalization.isomorphic?(
               RDF.read_file!(left),
               RDF.read_file!(right)
             )
    end
  end)
end
