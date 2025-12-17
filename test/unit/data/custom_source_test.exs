defmodule CustomDataSourceTest do
  use RDF.Test.Case

  @s RDF.iri(EX.S)
  @s1 RDF.iri(EX.S1)
  @s2 RDF.iri(EX.S2)
  @p RDF.iri(EX.p())
  @q RDF.iri(EX.q())
  @o1 RDF.iri(EX.O1)
  @g RDF.iri(EX.G)

  defp external(), do: External.new()
  defp empty_external(), do: External.new(RDF.graph())

  defp minimal_description() do
    MinimalDescription.new(@s, EX.S |> EX.p(@o1) |> EX.q("literal"))
  end

  defp empty_minimal_description(), do: MinimalDescription.new(@s)

  defp minimal_graph() do
    MinimalGraph.new(RDF.graph([{EX.S1, EX.p(), EX.O1}, {EX.S2, EX.q(), "literal"}]))
  end

  defp empty_minimal_graph(), do: MinimalGraph.new()

  defp minimal_dataset() do
    MinimalDataset.new(
      RDF.dataset([{EX.S1, EX.p(), EX.O1, nil}, {EX.S2, EX.q(), "literal", EX.G}])
    )
  end

  defp empty_minimal_dataset(), do: MinimalDataset.new()

  describe "RDF.Data.reduce/3" do
    test "External" do
      result =
        RDF.Data.reduce(external(), [], fn stmt, acc -> [stmt | acc] end)

      assert MapSet.new(result) ==
               MapSet.new([
                 {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42)},
                 {~I<http://example.com/S>, ~I<http://example.com/q>, ~I<http://example.com/O>}
               ])
    end

    test "MinimalDescription" do
      assert RDF.Data.reduce(minimal_description(), 0, fn _stmt, acc -> acc + 1 end) == 2
    end

    test "MinimalGraph" do
      assert RDF.Data.reduce(minimal_graph(), 0, fn _stmt, acc -> acc + 1 end) == 2
    end

    test "MinimalDataset" do
      assert RDF.Data.reduce(minimal_dataset(), 0, fn _stmt, acc -> acc + 1 end) == 2
    end
  end

  describe "RDF.Data.reduce/2" do
    test "MinimalDescription" do
      {s, p, _o} = RDF.Data.reduce(minimal_description(), fn stmt, _acc -> stmt end)
      assert s == @s
      assert p in [@p, @q]
    end

    test "MinimalGraph" do
      {s, _p, _o} = RDF.Data.reduce(minimal_graph(), fn stmt, _acc -> stmt end)
      assert s in [@s1, @s2]
    end

    test "MinimalDataset" do
      {s, _p, _o, _g} = RDF.Data.reduce(minimal_dataset(), fn stmt, _acc -> stmt end)
      assert s in [@s1, @s2]
    end

    test "raises on empty data" do
      assert_raise Enum.EmptyError, fn ->
        RDF.Data.reduce(empty_minimal_description(), fn stmt, _acc -> stmt end)
      end
    end
  end

  describe "RDF.Data.reduce_while/3" do
    test "MinimalDescription" do
      result =
        RDF.Data.reduce_while(minimal_description(), nil, fn {s, p, _o}, _acc ->
          if p == @p, do: {:halt, s}, else: {:cont, nil}
        end)

      assert result == @s
    end

    test "MinimalGraph" do
      result =
        RDF.Data.reduce_while(minimal_graph(), 0, fn _stmt, acc ->
          if acc >= 1, do: {:halt, acc}, else: {:cont, acc + 1}
        end)

      assert result == 1
    end

    test "MinimalDataset" do
      result =
        RDF.Data.reduce_while(minimal_dataset(), 0, fn _stmt, acc ->
          {:cont, acc + 1}
        end)

      assert result == 2
    end
  end

  test "RDF.Data.each/2" do
    {:ok, agent} = Agent.start_link(fn -> 0 end)

    assert RDF.Data.each(minimal_description(), fn _stmt ->
             Agent.update(agent, &(&1 + 1))
           end) == :ok

    assert Agent.get(agent, & &1) == 2
    Agent.stop(agent)
  end

  describe "RDF.Data.map/2" do
    test "MinimalDescription" do
      assert RDF.Data.map(minimal_description(), fn {s, _p, o} -> {s, EX.new(), o} end) ==
               MinimalDescription.new(
                 @s,
                 RDF.description(EX.S, init: [{EX.new(), EX.O1}, {EX.new(), "literal"}])
               )

      assert RDF.Data.map(minimal_description(), fn {_s, p, o} -> {@s1, p, o} end) ==
               MinimalDescription.new(
                 @s1,
                 RDF.description(EX.S1, init: [{EX.p(), EX.O1}, {EX.q(), "literal"}])
               )

      assert RDF.Data.map(minimal_description(), fn {_s, p, o} -> {RDF.iri("#{p}"), p, o} end) ==
               MinimalGraph.new(
                 RDF.graph([
                   {@p, EX.p(), EX.O1},
                   {@q, EX.q(), "literal"}
                 ])
               )
    end

    test "MinimalGraph" do
      assert RDF.Data.map(minimal_graph(), fn {s, _p, o} -> {s, EX.new(), o} end) ==
               %MinimalGraph{
                 data: RDF.graph([{EX.S1, EX.new(), EX.O1}, {EX.S2, EX.new(), "literal"}])
               }

      assert RDF.Data.map(minimal_graph(), fn {s, p, o} -> {s, p, o, s} end) ==
               MinimalDataset.new(
                 RDF.dataset([
                   {EX.S1, EX.p(), EX.O1, EX.S1},
                   {EX.S2, EX.q(), "literal", EX.S2}
                 ])
               )
    end

    test "MinimalDataset" do
      assert RDF.Data.map(minimal_dataset(), fn {s, _p, o, g} -> {s, EX.new(), o, g} end) ==
               MinimalDataset.new(
                 RDF.dataset([{EX.S1, EX.new(), EX.O1, nil}, {EX.S2, EX.new(), "literal", EX.G}])
               )

      single_graph_dataset = MinimalDataset.new(RDF.dataset({EX.S, EX.p(), EX.O}))

      assert RDF.Data.map(single_graph_dataset, fn {_s, p, o, g} -> {@s1, p, o, g} end) ==
               MinimalDataset.new(RDF.dataset({EX.S1, EX.p(), EX.O}))
    end
  end

  describe "RDF.Data.map_reduce/3" do
    test "MinimalDescription" do
      {result, count} =
        RDF.Data.map_reduce(minimal_description(), 0, fn {s, _p, o}, acc ->
          {{s, EX.new(), o}, acc + 1}
        end)

      assert result ==
               MinimalDescription.new(
                 @s,
                 RDF.description(EX.S, init: [{EX.new(), EX.O1}, {EX.new(), "literal"}])
               )

      assert count == 2
    end

    test "MinimalGraph" do
      {result, count} =
        RDF.Data.map_reduce(minimal_graph(), 0, fn {s, _p, o}, acc ->
          {{s, EX.new(), o}, acc + 1}
        end)

      assert result ==
               %MinimalGraph{
                 data: RDF.graph([{EX.S1, EX.new(), EX.O1}, {EX.S2, EX.new(), "literal"}])
               }

      assert count == 2
    end

    test "MinimalDataset" do
      {result, count} =
        RDF.Data.map_reduce(minimal_dataset(), 0, fn {s, _p, o, g}, acc ->
          {{s, EX.new(), o, g}, acc + 1}
        end)

      assert result ==
               MinimalDataset.new(
                 RDF.dataset([{EX.S1, EX.new(), EX.O1, nil}, {EX.S2, EX.new(), "literal", EX.G}])
               )

      assert count == 2
    end
  end

  test "RDF.Data.filter/2" do
    assert RDF.Data.filter(minimal_description(), fn {_s, p, _o} -> p == @p end) ==
             MinimalDescription.new(@s, RDF.description(EX.S, init: {EX.p(), EX.O1}))

    assert RDF.Data.filter(minimal_graph(), fn {s, _p, _o} -> s == @s1 end) ==
             %MinimalGraph{data: RDF.graph({EX.S1, EX.p(), EX.O1})}

    assert RDF.Data.filter(minimal_dataset(), fn {s, _p, _o, _g} -> s == @s1 end) ==
             MinimalDataset.new(RDF.dataset({EX.S1, EX.p(), EX.O1, nil}))
  end

  test "RDF.Data.reject/2" do
    assert RDF.Data.reject(minimal_description(), fn {_s, p, _o} -> p == @p end) ==
             MinimalDescription.new(@s, RDF.description(EX.S, init: {EX.q(), "literal"}))

    assert RDF.Data.reject(minimal_graph(), fn {s, _p, _o} -> s == @s1 end) ==
             %MinimalGraph{data: RDF.graph({EX.S2, EX.q(), "literal"})}

    assert RDF.Data.reject(minimal_dataset(), fn {s, _p, _o, _g} -> s == @s1 end) ==
             MinimalDataset.new(RDF.dataset({EX.S2, EX.q(), "literal", EX.G}))
  end

  test "RDF.Data.take/2" do
    assert %MinimalDescription{} = result = RDF.Data.take(minimal_description(), 1)
    assert RDF.Data.statement_count(result) == 1

    assert %MinimalGraph{} = result = RDF.Data.take(minimal_graph(), 1)
    assert RDF.Data.statement_count(result) == 1

    assert %MinimalDataset{} = result = RDF.Data.take(minimal_dataset(), 1)
    assert RDF.Data.statement_count(result) == 1
  end

  test "RDF.Data.delete/2" do
    assert RDF.Data.delete(minimal_description(), {@s, @p, @o1}) ==
             MinimalDescription.new(@s, RDF.description(EX.S, init: {EX.q(), "literal"}))

    assert RDF.Data.delete(minimal_graph(), {EX.S1, EX.p(), EX.O1}) ==
             %MinimalGraph{data: RDF.graph({EX.S2, EX.q(), "literal"})}

    assert RDF.Data.delete(minimal_dataset(), {@s1, @p, @o1, nil}) ==
             MinimalDataset.new(RDF.dataset({EX.S2, EX.q(), "literal", EX.G}))
  end

  describe "RDF.Data.pop/1" do
    test "MinimalDescription" do
      {stmt, remaining} = RDF.Data.pop(minimal_description())
      assert elem(stmt, 0) == @s
      assert %MinimalDescription{} = remaining
      assert RDF.Data.statement_count(remaining) == 1

      assert RDF.Data.pop(empty_minimal_description()) == {nil, empty_minimal_description()}
    end

    test "MinimalGraph" do
      {stmt, remaining} = RDF.Data.pop(minimal_graph())
      assert tuple_size(stmt) == 3
      assert %MinimalGraph{} = remaining
      assert RDF.Data.statement_count(remaining) == 1

      assert RDF.Data.pop(empty_minimal_graph()) == {nil, empty_minimal_graph()}
    end

    test "MinimalDataset" do
      {stmt, remaining} = RDF.Data.pop(minimal_dataset())
      assert tuple_size(stmt) == 4
      assert %MinimalDataset{} = remaining
      assert RDF.Data.statement_count(remaining) == 1

      assert RDF.Data.pop(empty_minimal_dataset()) == {nil, empty_minimal_dataset()}
    end
  end

  test "RDF.Data.merge/1" do
    graph1 = MinimalGraph.new(RDF.graph({EX.S1, EX.p(), EX.O1}))
    graph2 = MinimalGraph.new(RDF.graph({EX.S2, EX.q(), EX.O2}))

    assert RDF.Data.merge([graph1, graph2]) ==
             %MinimalGraph{
               data: RDF.graph([{EX.S1, EX.p(), EX.O1}, {EX.S2, EX.q(), EX.O2}])
             }

    assert RDF.Data.merge([]) == RDF.graph()
  end

  describe "RDF.Data.merge/2" do
    test "External" do
      external1 = External.new(RDF.graph({EX.S1, EX.p(), 1}))
      external2 = External.new(RDF.graph({EX.S2, EX.p(), 2}))
      result = RDF.Data.merge(external1, external2)

      assert %External{} = result
      assert RDF.Data.statement_count(result) == 2
    end

    test "MinimalGraph" do
      other = MinimalGraph.new(RDF.graph({EX.S3, EX.r(), EX.O3}))
      result = RDF.Data.merge(minimal_graph(), other)

      assert result ==
               %MinimalGraph{
                 data:
                   RDF.graph([
                     {EX.S1, EX.p(), EX.O1},
                     {EX.S2, EX.q(), "literal"},
                     {EX.S3, EX.r(), EX.O3}
                   ])
               }

      named_graph = MinimalGraph.new(RDF.graph({EX.S3, EX.r(), EX.O3}, name: EX.G), name: @g)

      assert RDF.Data.merge(minimal_graph(), named_graph) ==
               MinimalDataset.new(
                 RDF.dataset([
                   {EX.S1, EX.p(), EX.O1, nil},
                   {EX.S2, EX.q(), "literal", nil},
                   {EX.S3, EX.r(), EX.O3, EX.G}
                 ])
               )
    end

    test "MinimalDataset" do
      other = MinimalDataset.new(RDF.dataset({EX.S3, EX.r(), EX.O3, EX.G2}))
      result = RDF.Data.merge(minimal_dataset(), other)

      assert result ==
               MinimalDataset.new(
                 RDF.dataset([
                   {EX.S1, EX.p(), EX.O1, nil},
                   {EX.S2, EX.q(), "literal", EX.G},
                   {EX.S3, EX.r(), EX.O3, EX.G2}
                 ])
               )
    end
  end

  test "RDF.Data.statements/1" do
    assert MapSet.new(RDF.Data.statements(external())) ==
             MapSet.new([
               {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42)},
               {~I<http://example.com/S>, ~I<http://example.com/q>, ~I<http://example.com/O>}
             ])

    assert MapSet.new(RDF.Data.statements(minimal_description())) ==
             MapSet.new([{@s, @p, @o1}, {@s, @q, RDF.literal("literal")}])

    assert MapSet.new(RDF.Data.statements(minimal_graph())) ==
             MapSet.new([{@s1, @p, @o1}, {@s2, @q, RDF.literal("literal")}])

    assert MapSet.new(RDF.Data.statements(minimal_dataset())) ==
             MapSet.new([{@s1, @p, @o1, nil}, {@s2, @q, RDF.literal("literal"), @g}])
  end

  test "RDF.Data.triples/1" do
    assert MapSet.new(RDF.Data.triples(minimal_description())) ==
             MapSet.new([{@s, @p, @o1}, {@s, @q, RDF.literal("literal")}])

    assert MapSet.new(RDF.Data.triples(minimal_graph())) ==
             MapSet.new([{@s1, @p, @o1}, {@s2, @q, RDF.literal("literal")}])

    assert MapSet.new(RDF.Data.triples(minimal_dataset())) ==
             MapSet.new([{@s1, @p, @o1}, {@s2, @q, RDF.literal("literal")}])
  end

  test "RDF.Data.quads/1" do
    assert MapSet.new(RDF.Data.quads(external())) ==
             MapSet.new([
               {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42), nil},
               {~I<http://example.com/S>, ~I<http://example.com/q>, ~I<http://example.com/O>, nil}
             ])

    assert MapSet.new(RDF.Data.quads(minimal_description())) ==
             MapSet.new([{@s, @p, @o1, nil}, {@s, @q, RDF.literal("literal"), nil}])

    assert MapSet.new(RDF.Data.quads(minimal_graph())) ==
             MapSet.new([{@s1, @p, @o1, nil}, {@s2, @q, RDF.literal("literal"), nil}])

    assert MapSet.new(RDF.Data.quads(minimal_dataset())) ==
             MapSet.new([
               {@s1, @p, @o1, nil},
               {@s2, @q, RDF.literal("literal"), @g}
             ])
  end

  test "RDF.Data.default_graph/1" do
    assert RDF.Data.default_graph(minimal_description()) ==
             MinimalGraph.new(RDF.graph(minimal_description().data))

    assert RDF.Data.default_graph(minimal_graph()) == minimal_graph()

    assert RDF.Data.default_graph(minimal_dataset()) ==
             MinimalGraph.new(RDF.graph({EX.S1, EX.p(), EX.O1}))
  end

  describe "RDF.Data.graph/2" do
    test "External" do
      assert RDF.Data.graph(external(), nil) ==
               RDF.graph([
                 {~I<http://example.com/S>, ~I<http://example.com/p>, 42},
                 {~I<http://example.com/S>, ~I<http://example.com/q>, ~I<http://example.com/O>}
               ])
    end

    test "MinimalDescription with matching graph name" do
      assert RDF.Data.graph(minimal_description(), nil) ==
               MinimalGraph.new(RDF.graph(minimal_description().data))
    end

    test "MinimalDescription with non-matching graph name" do
      assert RDF.Data.graph(minimal_description(), @g) ==
               %MinimalGraph{name: @g, data: RDF.graph()}
    end

    test "MinimalGraph with matching graph name" do
      assert RDF.Data.graph(minimal_graph(), nil) == minimal_graph()
    end

    test "MinimalGraph with non-matching graph name" do
      assert RDF.Data.graph(minimal_graph(), @g) ==
               %MinimalGraph{name: @g, data: RDF.graph()}
    end

    test "MinimalDataset" do
      assert RDF.Data.graph(minimal_dataset(), @g) ==
               MinimalGraph.new(RDF.graph({EX.S2, EX.q(), "literal"}, name: EX.G), name: @g)
    end
  end

  test "RDF.Data.graph/3" do
    assert RDF.Data.graph(minimal_description(), nil, :default) ==
             MinimalGraph.new(RDF.graph(minimal_description().data))

    assert RDF.Data.graph(minimal_description(), @g) == %MinimalGraph{name: @g, data: RDF.graph()}
    assert RDF.Data.graph(minimal_description(), @g, :default) == :default

    assert RDF.Data.graph(minimal_graph(), nil, :default) == minimal_graph()
    assert RDF.Data.graph(minimal_graph(), @g, nil) == nil
    assert RDF.Data.graph(minimal_graph(), @g, :default) == :default

    assert RDF.Data.graph(minimal_dataset(), @g, nil) ==
             MinimalGraph.new(RDF.graph({EX.S2, EX.q(), "literal"}, name: EX.G), name: @g)

    assert RDF.Data.graph(minimal_dataset(), EX.NonExistent, nil) == nil
    assert RDF.Data.graph(minimal_dataset(), EX.NonExistent, :default) == :default
  end

  test "RDF.Data.graphs/1" do
    assert RDF.Data.graphs(external()) == [external()]

    assert RDF.Data.graphs(minimal_description()) == [
             MinimalGraph.new(RDF.graph(minimal_description().data))
           ]

    assert RDF.Data.graphs(minimal_graph()) == [minimal_graph()]

    assert MapSet.new(RDF.Data.graphs(minimal_dataset())) ==
             MapSet.new([
               MinimalGraph.new(RDF.graph({EX.S1, EX.p(), EX.O1})),
               MinimalGraph.new(RDF.graph({EX.S2, EX.q(), "literal"}, name: EX.G), name: @g)
             ])
  end

  test "RDF.Data.graph_names/1" do
    assert RDF.Data.graph_names(minimal_description()) == [nil]
    assert RDF.Data.graph_names(minimal_graph()) == [nil]
    assert RDF.Data.graph_names(MinimalGraph.new(RDF.graph(), name: @g)) == [@g]
    assert MapSet.new(RDF.Data.graph_names(minimal_dataset())) == MapSet.new([nil, @g])
  end

  test "RDF.Data.descriptions/1" do
    assert RDF.Data.descriptions(external()) == [
             RDF.description(~I<http://example.com/S>, init: [{EX.p(), 42}, {EX.q(), EX.O}])
           ]

    assert RDF.Data.descriptions(minimal_description()) == [minimal_description()]

    assert RDF.Data.descriptions(minimal_graph()) == [
             %MinimalDescription{
               subject: @s1,
               data: RDF.description(EX.S1, init: {EX.p(), EX.O1})
             },
             %MinimalDescription{
               subject: @s2,
               data: RDF.description(EX.S2, init: {EX.q(), "literal"})
             }
           ]

    assert RDF.Data.descriptions(minimal_dataset()) == [
             %MinimalDescription{
               subject: @s1,
               data: RDF.description(EX.S1, init: {EX.p(), EX.O1})
             },
             %MinimalDescription{
               subject: @s2,
               data: RDF.description(EX.S2, init: {EX.q(), "literal"})
             }
           ]
  end

  describe "RDF.Data.description/2,3" do
    test "External" do
      assert RDF.Data.description(external(), ~I<http://example.com/S>) ==
               RDF.description(~I<http://example.com/S>,
                 init: [
                   {~I<http://example.com/p>, 42},
                   {~I<http://example.com/q>, ~I<http://example.com/O>}
                 ]
               )
    end

    test "MinimalDescription" do
      assert RDF.Data.description(minimal_description(), @s) == minimal_description()

      assert RDF.Data.description(minimal_description(), EX.Other) ==
               MinimalDescription.new(EX.Other)

      assert RDF.Data.description(minimal_description(), EX.Other, :default) == :default
    end

    test "MinimalGraph" do
      assert RDF.Data.description(minimal_graph(), @s1) ==
               %MinimalDescription{
                 subject: @s1,
                 data: RDF.description(EX.S1, init: {EX.p(), EX.O1})
               }

      assert RDF.Data.description(minimal_graph(), EX.Other, nil) == nil
      assert RDF.Data.description(minimal_graph(), EX.Other, :default) == :default
    end

    test "MinimalDataset" do
      assert RDF.Data.description(minimal_dataset(), @s1) ==
               %MinimalDescription{
                 subject: @s1,
                 data: RDF.description(EX.S1, init: {EX.p(), EX.O1})
               }

      assert RDF.Data.description(minimal_dataset(), EX.Other) == MinimalDescription.new(EX.Other)
      assert RDF.Data.description(minimal_dataset(), EX.Other, :default) == :default
    end
  end

  test "RDF.Data.subjects/1" do
    assert RDF.Data.subjects(minimal_description()) == [@s]
    assert MapSet.new(RDF.Data.subjects(minimal_graph())) == MapSet.new([@s1, @s2])
    assert MapSet.new(RDF.Data.subjects(minimal_dataset())) == MapSet.new([@s1, @s2])
  end

  test "RDF.Data.predicates/1" do
    assert MapSet.new(RDF.Data.predicates(minimal_description())) == MapSet.new([@p, @q])
    assert MapSet.new(RDF.Data.predicates(minimal_graph())) == MapSet.new([@p, @q])
    assert MapSet.new(RDF.Data.predicates(minimal_dataset())) == MapSet.new([@p, @q])
  end

  test "RDF.Data.objects/1" do
    assert MapSet.new(RDF.Data.objects(minimal_description())) ==
             MapSet.new([@o1, RDF.literal("literal")])

    assert MapSet.new(RDF.Data.objects(minimal_graph())) ==
             MapSet.new([@o1, RDF.literal("literal")])

    assert MapSet.new(RDF.Data.objects(minimal_dataset())) ==
             MapSet.new([@o1, RDF.literal("literal")])
  end

  test "RDF.Data.object_resources/1" do
    assert RDF.Data.object_resources(minimal_description()) == [@o1]
    assert RDF.Data.object_resources(minimal_graph()) == [@o1]
    assert RDF.Data.object_resources(minimal_dataset()) == [@o1]
  end

  test "RDF.Data.resources/1" do
    assert MapSet.new(RDF.Data.resources(minimal_description())) == MapSet.new([@s, @o1])
    assert MapSet.new(RDF.Data.resources(minimal_graph())) == MapSet.new([@s1, @s2, @o1])
    assert MapSet.new(RDF.Data.resources(minimal_dataset())) == MapSet.new([@s1, @s2, @o1])
  end

  test "RDF.Data.count/1" do
    assert RDF.Data.count(minimal_description()) == 2
    assert RDF.Data.count(minimal_graph()) == 2
    assert RDF.Data.count(minimal_dataset()) == 2
  end

  test "RDF.Data.graph_count/1" do
    assert RDF.Data.graph_count(external()) == 1
    assert RDF.Data.graph_count(minimal_description()) == 1
    assert RDF.Data.graph_count(minimal_graph()) == 1
    assert RDF.Data.graph_count(minimal_dataset()) == 2
  end

  test "RDF.Data.statement_count/1" do
    assert RDF.Data.statement_count(external()) == 2
    assert RDF.Data.statement_count(minimal_description()) == 2
    assert RDF.Data.statement_count(minimal_graph()) == 2
    assert RDF.Data.statement_count(minimal_dataset()) == 2
  end

  test "RDF.Data.subject_count/1" do
    assert RDF.Data.subject_count(external()) == 1
    assert RDF.Data.subject_count(minimal_description()) == 1
    assert RDF.Data.subject_count(minimal_graph()) == 2
    assert RDF.Data.subject_count(minimal_dataset()) == 2
  end

  test "RDF.Data.predicate_count/1" do
    assert RDF.Data.predicate_count(minimal_description()) == 2
    assert RDF.Data.predicate_count(minimal_graph()) == 2
    assert RDF.Data.predicate_count(minimal_dataset()) == 2
  end

  test "RDF.Data.empty?/1" do
    refute RDF.Data.empty?(external())
    assert RDF.Data.empty?(empty_external())

    refute RDF.Data.empty?(minimal_description())
    assert RDF.Data.empty?(empty_minimal_description())

    refute RDF.Data.empty?(minimal_graph())
    assert RDF.Data.empty?(empty_minimal_graph())

    refute RDF.Data.empty?(minimal_dataset())
    assert RDF.Data.empty?(empty_minimal_dataset())
  end

  test "RDF.Data.equal?/2" do
    graph =
      RDF.graph([
        {~I<http://example.com/S>, ~I<http://example.com/p>, 42},
        {~I<http://example.com/S>, ~I<http://example.com/q>, ~I<http://example.com/O>}
      ])

    assert RDF.Data.equal?(external(), graph)
    assert RDF.Data.equal?(graph, external())

    assert RDF.Data.equal?(
             minimal_description(),
             RDF.description(EX.S, init: [{EX.p(), EX.O1}, {EX.q(), "literal"}])
           )

    assert RDF.Data.equal?(
             minimal_graph(),
             RDF.graph([{EX.S1, EX.p(), EX.O1}, {EX.S2, EX.q(), "literal"}])
           )

    assert RDF.Data.equal?(
             minimal_dataset(),
             RDF.dataset([{EX.S1, EX.p(), EX.O1, nil}, {EX.S2, EX.q(), "literal", EX.G}])
           )
  end

  describe "RDF.Data.include?/2" do
    test "External" do
      assert RDF.Data.include?(
               external(),
               {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42)}
             )

      refute RDF.Data.include?(
               external(),
               {~I<http://example.com/S>, ~I<http://example.com/r>, RDF.literal(42)}
             )
    end

    test "MinimalDescription" do
      assert RDF.Data.include?(minimal_description(), {@s, @p, @o1})
      refute RDF.Data.include?(minimal_description(), {@s, EX.r(), @o1})
    end

    test "MinimalGraph" do
      assert RDF.Data.include?(minimal_graph(), {@s1, @p, @o1})
      refute RDF.Data.include?(minimal_graph(), {@s1, EX.r(), @o1})
    end

    test "MinimalDataset with triple matches any graph" do
      assert RDF.Data.include?(minimal_dataset(), {@s1, @p, @o1})
      assert RDF.Data.include?(minimal_dataset(), {@s2, @q, "literal"})
      refute RDF.Data.include?(minimal_dataset(), {@s1, EX.r(), @o1})
    end

    test "MinimalDataset with quad matches specific graph" do
      assert RDF.Data.include?(minimal_dataset(), {@s1, @p, @o1, nil})
      refute RDF.Data.include?(minimal_dataset(), {@s1, @p, @o1, @g})
    end
  end

  test "RDF.Data.describes?/2" do
    assert RDF.Data.describes?(external(), ~I<http://example.com/S>)
    refute RDF.Data.describes?(external(), ~I<http://example.com/Other>)

    assert RDF.Data.describes?(minimal_description(), @s)
    refute RDF.Data.describes?(minimal_description(), EX.Other)

    assert RDF.Data.describes?(minimal_graph(), @s1)
    refute RDF.Data.describes?(minimal_graph(), EX.Other)

    assert RDF.Data.describes?(minimal_dataset(), @s1)
    refute RDF.Data.describes?(minimal_dataset(), EX.Other)
  end

  describe "RDF.Data.to_graph/1" do
    test "MinimalDescription" do
      desc = minimal_description()
      assert RDF.Data.to_graph(desc) == MinimalGraph.new(RDF.graph(desc.data))
      assert RDF.Data.to_graph(desc, native: true) == RDF.graph(desc.data)
    end

    test "MinimalGraph" do
      graph = minimal_graph()
      assert RDF.Data.to_graph(graph) == graph
      assert RDF.Data.to_graph(graph, native: true) == graph.data
    end

    test "MinimalDataset" do
      dataset = minimal_dataset()
      assert RDF.Data.to_graph(dataset) == MinimalGraph.new(RDF.graph(dataset.data))
      assert RDF.Data.to_graph(dataset, native: true) == RDF.graph(dataset.data)
    end
  end

  describe "RDF.Data.to_dataset/1" do
    test "MinimalDescription" do
      desc = minimal_description()
      assert RDF.Data.to_dataset(desc) == MinimalDataset.new(RDF.dataset(desc.data))
      assert RDF.Data.to_dataset(desc, native: true) == RDF.dataset(desc.data)
    end

    test "MinimalGraph" do
      graph = minimal_graph()
      assert RDF.Data.to_dataset(graph) == MinimalDataset.new(RDF.dataset(graph.data))
      assert RDF.Data.to_dataset(graph, native: true) == RDF.dataset(graph.data)
    end

    test "MinimalDataset" do
      dataset = minimal_dataset()
      assert RDF.Data.to_dataset(dataset) == dataset
      assert RDF.Data.to_dataset(dataset, native: true) == dataset.data
    end
  end
end
