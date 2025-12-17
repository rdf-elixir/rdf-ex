defmodule RDF.DataTest do
  use RDF.Test.Case

  import RDF.Guards

  doctest RDF.Data

  describe "reduce/3" do
    test "RDF.Description" do
      desc = EX.S |> EX.p1(EX.O1) |> EX.p2(EX.O2)

      assert RDF.Data.reduce(desc, [], fn stmt, acc -> [stmt | acc] end) ==
               [
                 {RDF.iri(EX.S), EX.p2(), RDF.iri(EX.O2)},
                 {RDF.iri(EX.S), EX.p1(), RDF.iri(EX.O1)}
               ]
    end

    test "RDF.Graph" do
      graph =
        RDF.graph([
          {EX.S1, EX.p1(), EX.O1},
          {EX.S1, EX.p2(), EX.O2},
          {EX.S2, EX.p1(), EX.O3}
        ])

      assert RDF.Data.reduce(graph, 0, fn _stmt, acc -> acc + 1 end) == 3
    end

    test "RDF.Dataset" do
      dataset =
        RDF.dataset([
          {EX.S1, EX.p1(), EX.O1, nil},
          {EX.S2, EX.p2(), EX.O2, EX.Graph}
        ])

      assert RDF.Data.reduce(dataset, [], fn stmt, acc -> [stmt | acc] end) ==
               [
                 {RDF.iri(EX.S2), EX.p2(), RDF.iri(EX.O2), RDF.iri(EX.Graph)},
                 {RDF.iri(EX.S1), EX.p1(), RDF.iri(EX.O1), nil}
               ]
    end

    test "works with empty data structures" do
      assert RDF.Data.reduce(RDF.description(EX.S), 42, fn _stmt, _acc -> 0 end) == 42
      assert RDF.Data.reduce(RDF.graph(), :empty, fn _stmt, _acc -> :not_empty end) == :empty
      assert RDF.Data.reduce(RDF.dataset(), :empty, fn _stmt, _acc -> :not_empty end) == :empty
    end
  end

  describe "reduce/2" do
    test "RDF.Description" do
      desc = EX.S |> EX.p1(EX.O1) |> EX.p2(EX.O2) |> EX.p3(EX.O3)

      assert RDF.Data.reduce(desc, fn _stmt, acc ->
               case acc do
                 {_, _, _} -> 1
                 n -> n + 1
               end
             end) == 2
    end

    test "RDF.Graph" do
      graph = RDF.graph([{EX.S, EX.p(), EX.O}])

      assert RDF.Data.reduce(graph, fn {s, _p, _o}, _acc -> s end) ==
               {RDF.iri(EX.S), EX.p(), RDF.iri(EX.O)}

      graph =
        RDF.graph([
          {EX.S1, EX.p1(), EX.O1},
          {EX.S2, EX.p2(), EX.O2}
        ])

      assert RDF.Data.reduce(graph, fn {s, _p, _o}, _acc -> s end) == RDF.iri(EX.S2)
    end

    test "RDF.Dataset" do
      dataset = RDF.dataset([{EX.S, EX.p(), EX.O}])

      assert RDF.Data.reduce(dataset, fn {s, _p, _o}, _acc -> s end) ==
               {RDF.iri(EX.S), EX.p(), RDF.iri(EX.O), nil}
    end

    test "raises Enum.EmptyError for empty data" do
      assert_raise Enum.EmptyError, fn ->
        RDF.Data.reduce(RDF.description(EX.S), fn stmt, _acc -> stmt end)
      end

      assert_raise Enum.EmptyError, fn ->
        RDF.Data.reduce(RDF.graph(), fn stmt, _acc -> stmt end)
      end

      assert_raise Enum.EmptyError, fn ->
        RDF.Data.reduce(RDF.dataset(), fn stmt, _acc -> stmt end)
      end
    end
  end

  describe "reduce_while/3" do
    test "continues iteration with {:cont, acc}" do
      graph =
        RDF.graph([
          {EX.S1, EX.p1(), EX.O1},
          {EX.S1, EX.p2(), EX.O2},
          {EX.S2, EX.p1(), EX.O3}
        ])

      assert RDF.Data.reduce_while(graph, 0, fn _stmt, acc -> {:cont, acc + 1} end) == 3
    end

    test "halts iteration early with {:halt, acc}" do
      graph =
        RDF.graph([
          {EX.S1, EX.p1(), EX.O1},
          {EX.S2, EX.p2(), EX.O2},
          {EX.S3, EX.p3(), EX.O3}
        ])

      assert RDF.Data.reduce_while(graph, [], fn {s, _p, _o} = stmt, acc ->
               if s == RDF.iri(EX.S2) do
                 {:halt, [stmt | acc]}
               else
                 {:cont, [stmt | acc]}
               end
             end) == [
               {RDF.iri(EX.S2), EX.p2(), RDF.iri(EX.O2)},
               {RDF.iri(EX.S1), EX.p1(), RDF.iri(EX.O1)}
             ]
    end

    test "halts on first element if requested" do
      graph =
        RDF.graph([
          {EX.S1, EX.p1(), EX.O1},
          {EX.S2, EX.p2(), EX.O2}
        ])

      assert RDF.Data.reduce_while(graph, :initial, fn stmt, _acc -> {:halt, stmt} end) ==
               {RDF.iri(EX.S1), EX.p1(), RDF.iri(EX.O1)}
    end

    test "RDF.Description" do
      desc = EX.S |> EX.p1(EX.O1) |> EX.p2(EX.O2) |> EX.p3(EX.O3)

      assert RDF.Data.reduce_while(desc, nil, fn {_s, p, o}, _acc ->
               if p == EX.p2() do
                 {:halt, o}
               else
                 {:cont, nil}
               end
             end) == RDF.iri(EX.O2)
    end

    test "RDF.Dataset" do
      dataset =
        RDF.dataset([
          {EX.S1, EX.p1(), EX.O1, nil},
          {EX.S2, EX.p2(), EX.O2, EX.Graph1},
          {EX.S3, EX.p3(), EX.O3, EX.Graph2}
        ])

      assert RDF.Data.reduce_while(dataset, nil, fn quad, _acc ->
               case quad do
                 {s, _p, _o, graph} when not is_nil(graph) ->
                   {:halt, {s, graph}}

                 _ ->
                   {:cont, nil}
               end
             end) == {RDF.iri(EX.S2), RDF.iri(EX.Graph1)}
    end

    test "empty data" do
      assert RDF.Data.reduce_while(RDF.graph(), :initial, fn _stmt, _acc ->
               {:cont, :modified}
             end) == :initial

      assert RDF.Data.reduce_while(RDF.description(EX.S), 42, fn _stmt, _acc ->
               {:cont, 0}
             end) == 42

      assert RDF.Data.reduce_while(RDF.dataset(), [], fn _stmt, acc ->
               {:cont, [:item | acc]}
             end) == []
    end
  end

  describe "each/2" do
    test "RDF.Description" do
      desc = EX.S |> EX.p1(EX.O1) |> EX.p2(EX.O2)

      {:ok, agent} = Agent.start_link(fn -> [] end)

      assert RDF.Data.each(desc, fn stmt ->
               Agent.update(agent, &[stmt | &1])
             end) == :ok

      assert Agent.get(agent, & &1) |> Enum.sort() ==
               Enum.sort([
                 {RDF.iri(EX.S), EX.p1(), RDF.iri(EX.O1)},
                 {RDF.iri(EX.S), EX.p2(), RDF.iri(EX.O2)}
               ])

      Agent.stop(agent)
    end

    test "RDF.Graph" do
      graph =
        RDF.graph([
          {EX.S1, EX.p1(), EX.O1},
          {EX.S2, EX.p2(), EX.O2}
        ])

      {:ok, agent} = Agent.start_link(fn -> [] end)

      assert RDF.Data.each(graph, fn stmt ->
               Agent.update(agent, &[stmt | &1])
             end) ==
               :ok

      assert Agent.get(agent, & &1) |> Enum.sort() ==
               Enum.sort([
                 {RDF.iri(EX.S1), EX.p1(), RDF.iri(EX.O1)},
                 {RDF.iri(EX.S2), EX.p2(), RDF.iri(EX.O2)}
               ])

      Agent.stop(agent)
    end

    test "RDF.Dataset" do
      dataset =
        RDF.dataset([
          {EX.S1, EX.p1(), EX.O1, nil},
          {EX.S2, EX.p2(), EX.O2, EX.Graph}
        ])

      {:ok, agent} = Agent.start_link(fn -> [] end)

      assert RDF.Data.each(dataset, fn stmt ->
               Agent.update(agent, &[stmt | &1])
             end) ==
               :ok

      assert Agent.get(agent, & &1) |> Enum.sort() ==
               Enum.sort([
                 {RDF.iri(EX.S1), EX.p1(), RDF.iri(EX.O1), nil},
                 {RDF.iri(EX.S2), EX.p2(), RDF.iri(EX.O2), RDF.iri(EX.Graph)}
               ])

      Agent.stop(agent)
    end

    test "works with empty structures" do
      assert RDF.Data.each(RDF.description(EX.S), fn _stmt -> :ignored end) == :ok
      assert RDF.Data.each(RDF.graph(), fn _stmt -> :ignored end) == :ok
      assert RDF.Data.each(RDF.dataset(), fn _stmt -> :ignored end) == :ok
    end
  end

  describe "map/2" do
    test "transforms statements" do
      assert [{EX.S1, EX.p1(), EX.O1}, {EX.S2, EX.p2(), EX.O2}]
             |> RDF.graph()
             |> RDF.Data.map(fn {s, p, _o} -> {s, p, EX.NewObject} end) ==
               RDF.graph([{EX.S1, EX.p1(), EX.NewObject}, {EX.S2, EX.p2(), EX.NewObject}])
    end

    test "filters via nil return" do
      assert [{EX.S1, EX.p1(), EX.O1}, {EX.S2, EX.p2(), EX.O2}]
             |> RDF.graph()
             |> RDF.Data.map(fn {s, p, _o} -> if p == EX.p1(), do: {s, p, EX.Modified} end) ==
               RDF.graph([{EX.S1, EX.p1(), EX.Modified}])
    end

    test "expands via list return" do
      assert EX.S
             |> EX.p(EX.O)
             |> RDF.Data.map(fn {s, p, _o} -> [{s, p, EX.O1}, {s, p, EX.O2}] end) ==
               EX.S |> EX.p([EX.O1, EX.O2])
    end

    test "handles empty structures" do
      assert RDF.Data.map(RDF.description(EX.S), &Function.identity/1) == RDF.description(EX.S)
      assert RDF.Data.map(RDF.graph(), &Function.identity/1) == RDF.graph()
      assert RDF.Data.map(RDF.dataset(), &Function.identity/1) == RDF.dataset()
    end

    test "Description stays Description with triples (same subject)" do
      desc = EX.S |> EX.p1(EX.O1) |> EX.p2(EX.O2)

      assert RDF.Data.map(desc, fn {s, _p, o} -> {s, EX.transformed(), o} end) ==
               EX.S |> EX.transformed([EX.O1, EX.O2])
    end

    test "Description stays Description with triples (different subject)" do
      desc = EX.S1 |> EX.p(EX.O1) |> EX.p(EX.O2)

      assert RDF.Data.map(desc, fn {_s, p, o} -> {EX.S2, p, o} end) ==
               EX.S2 |> EX.p([EX.O1, EX.O2])
    end

    test "Description stays Description with quads (same subject, same graph)" do
      desc = EX.S |> EX.p1(EX.O1) |> EX.p2(EX.O2)

      assert RDF.Data.map(desc, fn {s, p, o} -> {s, p, o, EX.G} end) ==
               EX.S |> EX.p1(EX.O1) |> EX.p2(EX.O2)
    end

    test "Description → Graph with triples (different subjects)" do
      desc = EX.S1 |> EX.p(EX.O1) |> EX.p(EX.O2)

      assert RDF.Data.map(desc, fn {_s, p, o} ->
               if o == RDF.iri(EX.O1), do: {EX.S1, p, o}, else: {EX.S2, p, o}
             end) == RDF.graph([{EX.S1, EX.p(), EX.O1}, {EX.S2, EX.p(), EX.O2}])
    end

    test "Description → Graph with quads (different subjects, same graph)" do
      desc = EX.S1 |> EX.p(EX.O1) |> EX.p(EX.O2)

      assert RDF.Data.map(desc, fn {_s, p, o} ->
               subject = if o == RDF.iri(EX.O1), do: EX.S1, else: EX.S2
               {subject, p, o, EX.G}
             end) == RDF.graph([{EX.S1, EX.p(), EX.O1}, {EX.S2, EX.p(), EX.O2}], name: EX.G)
    end

    test "Description → Dataset with quads (same subject, different graphs)" do
      desc = EX.S |> EX.p(EX.O1) |> EX.p(EX.O2)

      assert RDF.Data.map(desc, fn {s, p, o} ->
               graph = if o == RDF.iri(EX.O1), do: EX.G1, else: EX.G2
               {s, p, o, graph}
             end) == RDF.dataset([{EX.S, EX.p(), EX.O1, EX.G1}, {EX.S, EX.p(), EX.O2, EX.G2}])
    end

    test "Description → Dataset with quads (different subjects, different graphs)" do
      desc = EX.S1 |> EX.p(EX.O1) |> EX.p(EX.O2)

      assert RDF.Data.map(desc, fn {_s, p, o} ->
               if o == RDF.iri(EX.O1), do: {EX.S1, p, o, EX.G1}, else: {EX.S2, p, o, EX.G2}
             end) == RDF.dataset([{EX.S1, EX.p(), EX.O1, EX.G1}, {EX.S2, EX.p(), EX.O2, EX.G2}])
    end

    test "Description → Dataset with mixed quads and triples (same subject)" do
      desc = EX.S |> EX.p(EX.O1) |> EX.p(EX.O2)

      assert RDF.Data.map(desc, fn {s, p, o} ->
               if o == RDF.iri(EX.O1), do: {s, p, o, EX.G}, else: {s, p, o}
             end) == RDF.dataset([{EX.S, EX.p(), EX.O1, EX.G}, {EX.S, EX.p(), EX.O2, nil}])
    end

    test "Graph stays Graph with triples" do
      graph = RDF.graph([{EX.S1, EX.p(), EX.O1}, {EX.S2, EX.p(), EX.O2}], name: EX.G)

      assert RDF.Data.map(graph, fn {s, p, _o} -> {s, p, EX.NewObject} end) ==
               RDF.graph([{EX.S1, EX.p(), EX.NewObject}, {EX.S2, EX.p(), EX.NewObject}],
                 name: EX.G
               )
    end

    test "Graph stays Graph with quads (same graph)" do
      graph = RDF.graph([{EX.S1, EX.p(), EX.O1}, {EX.S2, EX.p(), EX.O2}], name: EX.G1)

      assert RDF.Data.map(graph, fn {s, p, o} -> {s, p, o, EX.G1} end) ==
               RDF.graph([{EX.S1, EX.p(), EX.O1}, {EX.S2, EX.p(), EX.O2}], name: EX.G1)
    end

    test "Graph stays Graph with quads (different graph than original)" do
      graph = RDF.graph([{EX.S, EX.p(), EX.O}], name: EX.G1)

      assert RDF.Data.map(graph, fn {s, p, o} -> {s, p, o, EX.G2} end) ==
               RDF.graph([{EX.S, EX.p(), EX.O}], name: EX.G2)
    end

    test "Graph → Dataset with quads (different graphs)" do
      graph = RDF.graph([{EX.S1, EX.p(), EX.O1}, {EX.S2, EX.p(), EX.O2}], name: EX.G1)

      assert RDF.Data.map(graph, fn {s, p, o} ->
               if s == RDF.iri(EX.S1), do: {s, p, o, EX.G1}, else: {s, p, o, EX.G2}
             end) == RDF.dataset([{EX.S1, EX.p(), EX.O1, EX.G1}, {EX.S2, EX.p(), EX.O2, EX.G2}])
    end

    test "Graph → Dataset with quads (nil vs named graph)" do
      graph = RDF.graph([{EX.S1, EX.p(), EX.O1}, {EX.S2, EX.p(), EX.O2}])

      assert RDF.Data.map(graph, fn {s, p, o} ->
               if s == RDF.iri(EX.S1), do: {s, p, o, nil}, else: {s, p, o, EX.G}
             end) == RDF.dataset([{EX.S1, EX.p(), EX.O1, nil}, {EX.S2, EX.p(), EX.O2, EX.G}])
    end

    test "Graph → Dataset with mixed quads and triples" do
      graph = RDF.graph([{EX.S1, EX.p(), EX.O1}, {EX.S2, EX.p(), EX.O2}])

      assert RDF.Data.map(graph, fn {s, p, o} ->
               if s == RDF.iri(EX.S1), do: {s, p, o, EX.G}, else: {s, p, o}
             end) == RDF.dataset([{EX.S1, EX.p(), EX.O1, EX.G}, {EX.S2, EX.p(), EX.O2, nil}])
    end

    test "Dataset stays Dataset" do
      dataset = RDF.dataset([{EX.S1, EX.p(), EX.O1, EX.G1}, {EX.S2, EX.p(), EX.O2, nil}])

      assert RDF.Data.map(dataset, fn {s, p, _o, g} -> {s, p, EX.NewObject, g} end) ==
               RDF.dataset([
                 {EX.S1, EX.p(), EX.NewObject, EX.G1},
                 {EX.S2, EX.p(), EX.NewObject, nil}
               ])
    end

    test "preserves graph metadata" do
      graph =
        RDF.graph([{EX.S, EX.p(), EX.O}],
          name: EX.G,
          prefixes: [ex: EX],
          base_iri: "http://example.com/"
        )

      assert RDF.Data.map(graph, fn {s, p, _o} -> {s, p, EX.NewObject} end) ==
               RDF.graph([{EX.S, EX.p(), EX.NewObject}],
                 name: EX.G,
                 prefixes: [ex: EX],
                 base_iri: "http://example.com/"
               )
    end
  end

  describe "map_reduce/3" do
    test "transforms statements with accumulator" do
      graph = RDF.graph([{EX.S1, EX.p1(), EX.O1}, {EX.S2, EX.p2(), EX.O2}])

      assert RDF.Data.map_reduce(graph, 0, fn {s, p, _o}, count ->
               {{s, p, EX.NewObject}, count + 1}
             end) ==
               {RDF.graph([{EX.S1, EX.p1(), EX.NewObject}, {EX.S2, EX.p2(), EX.NewObject}]), 2}
    end

    test "filters via nil return with accumulator" do
      graph = RDF.graph([{EX.S1, EX.p1(), EX.O1}, {EX.S2, EX.p2(), EX.O2}])

      assert RDF.Data.map_reduce(graph, [], fn {s, p, o}, seen ->
               if p == EX.p1() do
                 {{s, p, EX.Modified}, [o | seen]}
               else
                 {nil, seen}
               end
             end) == {RDF.graph([{EX.S1, EX.p1(), EX.Modified}]), [RDF.iri(EX.O1)]}
    end

    test "expands via list return with accumulator" do
      desc = EX.S |> EX.p(EX.O)

      assert RDF.Data.map_reduce(desc, 0, fn {s, p, _o}, count ->
               {[{s, p, EX.O1}, {s, p, EX.O2}], count + 1}
             end) == {EX.S |> EX.p([EX.O1, EX.O2]), 1}
    end

    test "handles empty structures" do
      assert RDF.Data.map_reduce(RDF.description(EX.S), 0, fn stmt, acc -> {stmt, acc + 1} end) ==
               {RDF.description(EX.S), 0}

      assert RDF.Data.map_reduce(RDF.graph(), 0, fn stmt, acc -> {stmt, acc + 1} end) ==
               {RDF.graph(), 0}

      assert RDF.Data.map_reduce(RDF.dataset(), 0, fn stmt, acc -> {stmt, acc + 1} end) ==
               {RDF.dataset(), 0}
    end

    test "Description stays Description with same subject" do
      desc = EX.S |> EX.p1(EX.O1) |> EX.p2(EX.O2)

      assert RDF.Data.map_reduce(desc, 0, fn {s, _p, o}, count ->
               {{s, EX.transformed(), o}, count + 1}
             end) == {EX.S |> EX.transformed([EX.O1, EX.O2]), 2}
    end

    test "Description → Graph with different subjects" do
      desc = EX.S1 |> EX.p(EX.O1) |> EX.p(EX.O2)

      assert RDF.Data.map_reduce(desc, %{}, fn {_s, p, o}, mapping ->
               subject = if o == RDF.iri(EX.O1), do: RDF.iri(EX.S1), else: RDF.iri(EX.S2)
               {{subject, p, o}, Map.put(mapping, o, subject)}
             end) ==
               {RDF.graph([{EX.S1, EX.p(), EX.O1}, {EX.S2, EX.p(), EX.O2}]),
                %{RDF.iri(EX.O1) => RDF.iri(EX.S1), RDF.iri(EX.O2) => RDF.iri(EX.S2)}}
    end

    test "Graph → Dataset with different graphs" do
      graph = RDF.graph([{EX.S1, EX.p(), EX.O1}, {EX.S2, EX.p(), EX.O2}])

      assert RDF.Data.map_reduce(graph, [], fn {s, p, o}, graphs ->
               graph_name = if s == RDF.iri(EX.S1), do: EX.G1, else: EX.G2
               {{s, p, o, graph_name}, [graph_name | graphs]}
             end) ==
               {RDF.dataset([{EX.S1, EX.p(), EX.O1, EX.G1}, {EX.S2, EX.p(), EX.O2, EX.G2}]),
                [EX.G2, EX.G1]}
    end

    test "Dataset stays Dataset" do
      dataset = RDF.dataset([{EX.S1, EX.p(), EX.O1, EX.G1}, {EX.S2, EX.p(), EX.O2, nil}])

      assert RDF.Data.map_reduce(dataset, 0, fn {s, p, _o, g}, count ->
               {{s, p, EX.NewObject, g}, count + 1}
             end) ==
               {RDF.dataset([
                  {EX.S1, EX.p(), EX.NewObject, EX.G1},
                  {EX.S2, EX.p(), EX.NewObject, nil}
                ]), 2}
    end

    test "preserves graph metadata" do
      graph =
        RDF.graph([{EX.S, EX.p(), EX.O}],
          name: EX.G,
          prefixes: [ex: EX],
          base_iri: "http://example.com/"
        )

      assert RDF.Data.map_reduce(graph, 0, fn {s, p, _o}, count ->
               {{s, p, EX.NewObject}, count + 1}
             end) ==
               {RDF.graph([{EX.S, EX.p(), EX.NewObject}],
                  name: EX.G,
                  prefixes: [ex: EX],
                  base_iri: "http://example.com/"
                ), 1}
    end

    test "use-case: rename blank nodes and build mapping" do
      graph =
        RDF.graph([
          {RDF.bnode(:a), EX.p(), EX.O1},
          {RDF.bnode(:b), EX.p(), EX.O2},
          {EX.S, EX.p(), RDF.bnode(:a)}
        ])

      {result, mapping} =
        RDF.Data.map_reduce(graph, %{}, fn {s, p, o}, mapping ->
          {new_s, mapping} = rename_bnode(s, mapping)
          {new_o, mapping} = rename_bnode(o, mapping)
          {{new_s, p, new_o}, mapping}
        end)

      assert map_size(mapping) == 2
      assert RDF.Data.statement_count(result) == 3
    end

    defp rename_bnode(%RDF.BlankNode{} = bnode, mapping) do
      case Map.fetch(mapping, bnode) do
        {:ok, new_bnode} ->
          {new_bnode, mapping}

        :error ->
          new_bnode = RDF.bnode()
          {new_bnode, Map.put(mapping, bnode, new_bnode)}
      end
    end

    defp rename_bnode(term, mapping), do: {term, mapping}
  end

  describe "filter/2" do
    test "RDF.Description" do
      desc = EX.S |> EX.p1(EX.O1) |> EX.p2(EX.O2)

      assert RDF.Data.filter(desc, fn {_s, p, _o} -> p == EX.p1() end) ==
               EX.S |> EX.p1(EX.O1)

      assert RDF.Data.filter(desc, fn {_s, p, _o} -> p == EX.nonexistent() end) ==
               RDF.description(EX.S)
    end

    test "RDF.Graph" do
      graph =
        RDF.graph([
          {EX.S1, EX.p1(), EX.O1},
          {EX.S1, EX.p2(), EX.O2},
          {EX.S2, EX.p1(), EX.O3}
        ])

      assert RDF.Data.filter(graph, fn {_s, p, _o} -> p == EX.p1() end) ==
               RDF.graph([
                 {EX.S1, EX.p1(), EX.O1},
                 {EX.S2, EX.p1(), EX.O3}
               ])

      graph =
        RDF.graph([
          {EX.S1, EX.p(), "value1"},
          {EX.S2, EX.p(), 42},
          {EX.S3, EX.p(), RDF.iri(EX.O)}
        ])

      assert RDF.Data.filter(graph, fn {_s, _p, o} -> RDF.literal?(o) end) ==
               RDF.graph([
                 {EX.S1, EX.p(), "value1"},
                 {EX.S2, EX.p(), 42}
               ])
    end

    test "RDF.Dataset" do
      dataset =
        RDF.dataset([
          {EX.S1, EX.p1(), EX.O1, EX.Graph1},
          {EX.S1, EX.p2(), EX.O2, EX.Graph1},
          {EX.S2, EX.p1(), EX.O3, nil}
        ])

      assert RDF.Data.filter(dataset, fn {_s, p, _o, _g} -> p == EX.p1() end) ==
               RDF.dataset([
                 {EX.S1, EX.p1(), EX.O1, EX.Graph1},
                 {EX.S2, EX.p1(), EX.O3, nil}
               ])
    end

    test "empty data structures" do
      assert RDF.Data.filter(RDF.graph(), fn _ -> true end) == RDF.graph()
      assert RDF.Data.filter(RDF.description(EX.S), fn _ -> true end) == RDF.description(EX.S)
      assert RDF.Data.filter(RDF.dataset(), fn _ -> true end) == RDF.dataset()
    end

    test "preserves graph metadata (name, prefixes, base_iri)" do
      graph =
        RDF.graph([{EX.S1, EX.p(), EX.O1}, {EX.S2, EX.p(), EX.O2}],
          name: EX.G,
          prefixes: [ex: EX],
          base_iri: "http://example.com/"
        )

      assert RDF.Data.filter(graph, fn {s, _, _} -> s == RDF.iri(EX.S1) end) ==
               RDF.graph([{EX.S1, EX.p(), EX.O1}],
                 name: EX.G,
                 prefixes: [ex: EX],
                 base_iri: "http://example.com/"
               )
    end
  end

  describe "reject/2" do
    test "RDF.Description" do
      desc = EX.S |> EX.p1(EX.O1) |> EX.p2(EX.O2)

      assert RDF.Data.reject(desc, fn {_s, p, _o} -> p == EX.p1() end) ==
               EX.S |> EX.p2(EX.O2)

      assert RDF.Data.reject(desc, fn {_s, p, _o} -> p == EX.nonexistent() end) ==
               desc
    end

    test "RDF.Graph" do
      graph =
        RDF.graph([
          {EX.S1, EX.p1(), EX.O1},
          {EX.S1, EX.p2(), EX.O2},
          {EX.S2, EX.p1(), EX.O3}
        ])

      assert RDF.Data.reject(graph, fn {_s, p, _o} -> p == EX.p1() end) ==
               RDF.graph([
                 {EX.S1, EX.p2(), EX.O2}
               ])

      graph =
        RDF.graph([
          {EX.S1, EX.p(), "value1"},
          {EX.S2, EX.p(), 42},
          {EX.S3, EX.p(), RDF.iri(EX.O)}
        ])

      assert RDF.Data.reject(graph, fn {_s, _p, o} -> RDF.literal?(o) end) ==
               RDF.graph([
                 {EX.S3, EX.p(), RDF.iri(EX.O)}
               ])
    end

    test "RDF.Dataset" do
      dataset =
        RDF.dataset([
          {EX.S1, EX.p1(), EX.O1, EX.Graph1},
          {EX.S1, EX.p2(), EX.O2, EX.Graph1},
          {EX.S2, EX.p1(), EX.O3, nil}
        ])

      assert RDF.Data.reject(dataset, fn {_s, p, _o, _g} -> p == EX.p1() end) ==
               RDF.dataset([
                 {EX.S1, EX.p2(), EX.O2, EX.Graph1}
               ])
    end

    test "empty data structures" do
      assert RDF.Data.reject(RDF.graph(), fn _ -> true end) == RDF.graph()
      assert RDF.Data.reject(RDF.description(EX.S), fn _ -> true end) == RDF.description(EX.S)
      assert RDF.Data.reject(RDF.dataset(), fn _ -> true end) == RDF.dataset()
    end

    test "preserves graph metadata (name, prefixes, base_iri)" do
      graph =
        RDF.graph([{EX.S1, EX.p(), EX.O1}, {EX.S2, EX.p(), EX.O2}],
          name: EX.G,
          prefixes: [ex: EX],
          base_iri: "http://example.com/"
        )

      assert RDF.Data.reject(graph, fn {s, _, _} -> s == RDF.iri(EX.S1) end) ==
               RDF.graph([{EX.S2, EX.p(), EX.O2}],
                 name: EX.G,
                 prefixes: [ex: EX],
                 base_iri: "http://example.com/"
               )
    end
  end

  describe "take/2" do
    test "RDF.Description" do
      desc = EX.S |> EX.p1(EX.O1) |> EX.p2(EX.O2) |> EX.p3(EX.O3)

      assert %RDF.Description{} = result = RDF.Data.take(desc, 2)
      assert RDF.Data.statement_count(result) == 2
    end

    test "RDF.Graph" do
      graph =
        RDF.graph([
          {EX.S1, EX.p(), EX.O1},
          {EX.S2, EX.p(), EX.O2},
          {EX.S3, EX.p(), EX.O3}
        ])

      assert %RDF.Graph{} = result = RDF.Data.take(graph, 2)
      assert RDF.Data.statement_count(result) == 2
    end

    test "RDF.Dataset" do
      dataset =
        RDF.dataset([
          {EX.S1, EX.p(), EX.O1, nil},
          {EX.S2, EX.p(), EX.O2, EX.G1},
          {EX.S3, EX.p(), EX.O3, EX.G2}
        ])

      assert %RDF.Dataset{} = result = RDF.Data.take(dataset, 2)
      assert RDF.Data.statement_count(result) == 2
    end

    test "returns empty structure for amount <= 0" do
      desc = EX.S |> EX.p(EX.O)
      graph = RDF.graph({EX.S, EX.p(), EX.O})
      dataset = RDF.dataset({EX.S, EX.p(), EX.O, nil})

      assert RDF.Data.take(desc, 0) == RDF.description(EX.S)
      assert RDF.Data.take(graph, -1) == RDF.graph()
      assert RDF.Data.take(dataset, -5) == RDF.dataset()
    end

    test "returns all statements when amount exceeds statement count" do
      graph = RDF.graph([{EX.S1, EX.p(), EX.O1}, {EX.S2, EX.p(), EX.O2}])

      assert RDF.Data.take(graph, 100) == graph
    end

    test "works with empty data structures" do
      assert RDF.Data.take(RDF.description(EX.S), 5) == RDF.description(EX.S)
      assert RDF.Data.take(RDF.graph(), 5) == RDF.graph()
      assert RDF.Data.take(RDF.dataset(), 5) == RDF.dataset()
    end
  end

  describe "delete/3" do
    test "RDF.Description" do
      desc =
        EX.S
        |> EX.p1(EX.O1)
        |> EX.p2(EX.O2)
        |> EX.p3(EX.O3)

      assert RDF.Data.delete(desc, {EX.S, EX.p2(), EX.O2}) == EX.S |> EX.p1(EX.O1) |> EX.p3(EX.O3)

      assert RDF.Data.delete(desc, [{EX.S, EX.p1(), EX.O1}, {EX.S, EX.p3(), EX.O3}]) ==
               EX.S |> EX.p2(EX.O2)

      assert RDF.Data.delete(desc, {EX.S, EX.p4(), EX.O4}) == desc
    end

    test "RDF.Graph" do
      graph =
        RDF.graph([
          {EX.S1, EX.p1(), EX.O1},
          {EX.S1, EX.p2(), EX.O2},
          {EX.S2, EX.p1(), EX.O3},
          {EX.S2, EX.p2(), EX.O4}
        ])

      assert RDF.Data.delete(graph, {EX.S1, EX.p2(), EX.O2}) ==
               RDF.graph([
                 {EX.S1, EX.p1(), EX.O1},
                 {EX.S2, EX.p1(), EX.O3},
                 {EX.S2, EX.p2(), EX.O4}
               ])

      assert RDF.Data.delete(graph, [{EX.S1, EX.p1(), EX.O1}, {EX.S2, EX.p2(), EX.O4}]) ==
               RDF.graph([
                 {EX.S1, EX.p2(), EX.O2},
                 {EX.S2, EX.p1(), EX.O3}
               ])

      assert RDF.Data.delete(graph, {EX.S1, EX.p3(), EX.O5}) == graph
    end

    test "RDF.Dataset" do
      dataset =
        RDF.dataset([
          {EX.S1, EX.p1(), EX.O1, EX.G1},
          {EX.S1, EX.p2(), EX.O2, EX.G1},
          {EX.S2, EX.p1(), EX.O3, EX.G2},
          {EX.S3, EX.p1(), EX.O4, nil}
        ])

      assert RDF.Data.delete(dataset, {EX.S1, EX.p2(), EX.O2, EX.G1}) ==
               RDF.dataset([
                 {EX.S1, EX.p1(), EX.O1, EX.G1},
                 {EX.S2, EX.p1(), EX.O3, EX.G2},
                 {EX.S3, EX.p1(), EX.O4, nil}
               ])

      assert RDF.Data.delete(dataset, [
               {EX.S1, EX.p1(), EX.O1, EX.G1},
               {EX.S3, EX.p1(), EX.O4, nil}
             ]) ==
               RDF.dataset([
                 {EX.S1, EX.p2(), EX.O2, EX.G1},
                 {EX.S2, EX.p1(), EX.O3, EX.G2}
               ])

      assert RDF.Data.delete(dataset, {EX.S1, EX.p3(), EX.O5, EX.G3}) == dataset
    end

    test "delete from another data structure" do
      graph =
        RDF.graph([
          {EX.S1, EX.p1(), EX.O1},
          {EX.S1, EX.p2(), EX.O2},
          {EX.S2, EX.p1(), EX.O3}
        ])

      desc_to_delete = EX.S1 |> EX.p1(EX.O1) |> EX.p2(EX.O2)

      assert RDF.Data.delete(graph, desc_to_delete) == RDF.graph([{EX.S2, EX.p1(), EX.O3}])

      dataset =
        RDF.dataset([
          {EX.S1, EX.p1(), EX.O1, EX.G1},
          {EX.S2, EX.p1(), EX.O2, EX.G1},
          {EX.S3, EX.p1(), EX.O3, EX.G2},
          {EX.S4, EX.p1(), EX.O4, nil}
        ])

      graph_to_delete =
        RDF.graph([
          {EX.S1, EX.p1(), EX.O1},
          {EX.S2, EX.p1(), EX.O2}
        ])

      assert RDF.Data.delete(dataset, graph_to_delete) == dataset

      dataset_to_delete =
        RDF.dataset([
          {EX.S1, EX.p1(), EX.O1, EX.G1},
          {EX.S4, EX.p1(), EX.O4, nil}
        ])

      assert RDF.Data.delete(dataset, dataset_to_delete) ==
               RDF.dataset([
                 {EX.S2, EX.p1(), EX.O2, EX.G1},
                 {EX.S3, EX.p1(), EX.O3, EX.G2}
               ])
    end

    test "delete with empty structures" do
      assert RDF.Data.delete(RDF.description(EX.S), {EX.S, EX.p(), EX.O}) ==
               RDF.description(EX.S)

      assert RDF.Data.delete(RDF.graph(), {EX.S, EX.p(), EX.O}) == RDF.graph()

      graph = RDF.graph([{EX.S, EX.p(), EX.O}])

      assert RDF.Data.delete(graph, RDF.description(EX.S)) == graph
    end

    test "delete all statements leaves empty structure" do
      desc = EX.S |> EX.p1(EX.O1) |> EX.p2(EX.O2)
      assert RDF.Data.delete(desc, desc) == RDF.description(EX.S)

      graph = RDF.graph([{EX.S1, EX.p(), EX.O1}, {EX.S2, EX.p(), EX.O2}], name: EX.G)
      assert RDF.Data.delete(graph, graph) == RDF.graph(name: EX.G)

      dataset = RDF.dataset([{EX.S, EX.p(), EX.O, EX.G}], name: EX.DS)
      assert RDF.Data.delete(dataset, dataset) == RDF.dataset(name: EX.DS)
    end

    test "delete preserves structure metadata" do
      graph = RDF.graph([{EX.S1, EX.p(), EX.O1}, {EX.S2, EX.p(), EX.O2}], name: EX.G)

      assert RDF.Data.delete(graph, {EX.S1, EX.p(), EX.O1}) ==
               RDF.graph([{EX.S2, EX.p(), EX.O2}], name: EX.G)

      dataset = RDF.dataset([{EX.S, EX.p(), EX.O, EX.G}], name: EX.DS)

      assert RDF.Data.delete(dataset, {EX.S, EX.p(), EX.O, EX.G}) == RDF.dataset([], name: EX.DS)
    end

    test "preserves all graph metadata (name, prefixes, base_iri)" do
      graph =
        RDF.graph([{EX.S1, EX.p(), EX.O1}, {EX.S2, EX.p(), EX.O2}],
          name: EX.G,
          prefixes: [ex: EX],
          base_iri: "http://example.com/"
        )

      assert RDF.Data.delete(graph, {EX.S1, EX.p(), EX.O1}) ==
               RDF.graph([{EX.S2, EX.p(), EX.O2}],
                 name: EX.G,
                 prefixes: [ex: EX],
                 base_iri: "http://example.com/"
               )
    end

    test "deleting quad from Description skips when graph name present" do
      desc = RDF.description(EX.S, init: {EX.p(), EX.O})
      assert RDF.Data.delete(desc, {EX.S, EX.p(), EX.O, EX.G}) == desc
    end

    test "deleting quad with nil graph from Description works" do
      desc = RDF.description(EX.S, init: {EX.p(), EX.O})
      assert RDF.Data.delete(desc, {EX.S, EX.p(), EX.O, nil}) == RDF.description(EX.S)
    end

    test "deleting quad from Graph skips when graph name mismatches" do
      graph = RDF.graph([{EX.S, EX.p(), EX.O}])
      assert RDF.Data.delete(graph, {EX.S, EX.p(), EX.O, EX.OtherGraph}) == graph
    end

    test "deleting quad from Graph works when graph names match" do
      graph = RDF.graph([{EX.S, EX.p(), EX.O}], name: EX.G)
      assert RDF.Data.delete(graph, {EX.S, EX.p(), EX.O, EX.G}) == RDF.graph(name: EX.G)
    end

    test "deleting quad with nil from unnamed Graph works" do
      graph = RDF.graph([{EX.S, EX.p(), EX.O}])
      assert RDF.Data.delete(graph, {EX.S, EX.p(), EX.O, nil}) == RDF.graph()
    end

    test "deleting quad with nil from named Graph skips" do
      graph = RDF.graph([{EX.S, EX.p(), EX.O}], name: EX.G)
      assert RDF.Data.delete(graph, {EX.S, EX.p(), EX.O, nil}) == graph
    end
  end

  describe "pop/1" do
    test "RDF.Description" do
      assert EX.S |> EX.p1(EX.O1) |> EX.p2(EX.O2) |> RDF.Data.pop() ==
               {{RDF.iri(EX.S), EX.p1(), RDF.iri(EX.O1)}, EX.S |> EX.p2(EX.O2)}

      assert RDF.Data.pop(RDF.description(EX.S)) == {nil, RDF.description(EX.S)}
    end

    test "RDF.Graph" do
      assert RDF.graph([{EX.S, EX.p(), EX.O}]) |> RDF.Data.pop() ==
               {{RDF.iri(EX.S), EX.p(), RDF.iri(EX.O)}, RDF.graph()}

      assert RDF.Data.pop(RDF.graph()) == {nil, RDF.graph()}
    end

    test "RDF.Dataset" do
      assert RDF.dataset([{EX.S, EX.p(), EX.O, EX.Graph}]) |> RDF.Data.pop() ==
               {{RDF.iri(EX.S), EX.p(), RDF.iri(EX.O), RDF.iri(EX.Graph)}, RDF.dataset()}

      assert RDF.Data.pop(RDF.dataset()) == {nil, RDF.dataset()}
    end
  end

  describe "merge/3" do
    test "Description + Description with same subject stays Description" do
      desc1 = EX.S |> EX.p1(EX.O1) |> EX.p2(EX.O2)
      desc2 = EX.S |> EX.p3(EX.O3) |> EX.p4(EX.O4)

      assert RDF.Data.merge(desc1, desc2) ==
               EX.S |> EX.p1(EX.O1) |> EX.p2(EX.O2) |> EX.p3(EX.O3) |> EX.p4(EX.O4)
    end

    test "Description + Description with different subjects promotes to Graph" do
      desc1 = EX.S1 |> EX.p1(EX.O1) |> EX.p2(EX.O2)
      desc2 = EX.S2 |> EX.p3(EX.O3) |> EX.p4(EX.O4)

      assert RDF.Data.merge(desc1, desc2) == RDF.graph([desc1, desc2])
    end

    test "Graph + Graph with same name stays Graph" do
      graph1 =
        RDF.graph(
          [
            {EX.S1, EX.p1(), EX.O1},
            {EX.S2, EX.p2(), EX.O2}
          ],
          name: EX.G
        )

      graph2 =
        RDF.graph(
          [
            {EX.S3, EX.p3(), EX.O3},
            {EX.S4, EX.p4(), EX.O4}
          ],
          name: EX.G
        )

      assert RDF.Data.merge(graph1, graph2) ==
               RDF.graph(
                 [
                   {EX.S1, EX.p1(), EX.O1},
                   {EX.S2, EX.p2(), EX.O2},
                   {EX.S3, EX.p3(), EX.O3},
                   {EX.S4, EX.p4(), EX.O4}
                 ],
                 name: EX.G
               )

      graph1 =
        RDF.graph([
          {EX.S1, EX.p1(), EX.O1},
          {EX.S2, EX.p2(), EX.O2}
        ])

      graph2 =
        RDF.graph([
          {EX.S3, EX.p3(), EX.O3},
          {EX.S4, EX.p4(), EX.O4}
        ])

      assert RDF.Data.merge(graph1, graph2) == RDF.graph([graph1, graph2])
    end

    test "Graph + Graph with different names promotes to Dataset" do
      graph1 =
        RDF.graph(
          [
            {EX.S1, EX.p1(), EX.O1},
            {EX.S2, EX.p2(), EX.O2}
          ],
          name: EX.G1
        )

      graph2 =
        RDF.graph(
          [
            {EX.S3, EX.p3(), EX.O3},
            {EX.S4, EX.p4(), EX.O4}
          ],
          name: EX.G2
        )

      assert RDF.Data.merge(graph1, graph2) == RDF.dataset([graph1, graph2])

      graph1 =
        RDF.graph([
          {EX.S1, EX.p1(), EX.O1},
          {EX.S2, EX.p2(), EX.O2}
        ])

      graph2 =
        RDF.graph(
          [
            {EX.S3, EX.p3(), EX.O3},
            {EX.S4, EX.p4(), EX.O4}
          ],
          name: EX.G
        )

      assert RDF.Data.merge(graph1, graph2) == RDF.dataset([graph1, graph2])
    end

    test "Description + Graph (unnamed) produces Graph" do
      desc = EX.S1 |> EX.p1(EX.O1) |> EX.p2(EX.O2)

      graph =
        RDF.graph([
          {EX.S2, EX.p3(), EX.O3},
          {EX.S3, EX.p4(), EX.O4}
        ])

      assert RDF.Data.merge(desc, graph) == RDF.graph([desc, graph])
    end

    test "Description + Graph (named) produces Dataset" do
      desc = EX.S1 |> EX.p1(EX.O1)
      graph = RDF.graph({EX.S2, EX.p2(), EX.O2}, name: EX.G)

      assert RDF.Data.merge(desc, graph) ==
               RDF.dataset([{EX.S1, EX.p1(), EX.O1, nil}, {EX.S2, EX.p2(), EX.O2, EX.G}])
    end

    test "Graph + Dataset produces Dataset" do
      graph =
        RDF.graph(
          [
            {EX.S1, EX.p1(), EX.O1},
            {EX.S2, EX.p2(), EX.O2}
          ],
          name: EX.G1
        )

      dataset =
        RDF.dataset([
          {EX.S3, EX.p3(), EX.O3, EX.G2},
          {EX.S4, EX.p4(), EX.O4, nil}
        ])

      assert RDF.Data.merge(graph, dataset) ==
               RDF.dataset([
                 {EX.S1, EX.p1(), EX.O1, EX.G1},
                 {EX.S2, EX.p2(), EX.O2, EX.G1},
                 {EX.S3, EX.p3(), EX.O3, EX.G2},
                 {EX.S4, EX.p4(), EX.O4, nil}
               ])
    end

    test "Description + Dataset produces Dataset" do
      desc = EX.S1 |> EX.p1(EX.O1) |> EX.p2(EX.O2)

      dataset =
        RDF.dataset([
          {EX.S3, EX.p3(), EX.O3, EX.G1},
          {EX.S4, EX.p4(), EX.O4, nil}
        ])

      assert RDF.Data.merge(desc, dataset) == RDF.Dataset.add(dataset, desc)
      assert RDF.Data.merge(dataset, desc) == RDF.Dataset.add(dataset, desc)
    end

    test "merging empty structures" do
      assert RDF.Data.merge(RDF.description(EX.S), RDF.description(EX.S)) ==
               RDF.description(EX.S)

      desc = EX.S |> EX.p(EX.O)
      assert RDF.Data.merge(RDF.description(EX.S), desc) == desc

      assert RDF.Data.merge(desc, RDF.description(EX.S)) == desc
    end

    test "handles duplicate statements" do
      desc1 = EX.S |> EX.p(EX.O1) |> EX.q(EX.O2)
      desc2 = EX.S |> EX.p(EX.O1) |> EX.r(EX.O3)

      assert RDF.Data.merge(desc1, desc2) == EX.S |> EX.p(EX.O1) |> EX.q(EX.O2) |> EX.r(EX.O3)
    end

    test "preserves metadata when possible" do
      named_graph = RDF.graph([{EX.S1, EX.p1(), EX.O1}], name: EX.G)
      unnamed_graph = RDF.graph([{EX.S2, EX.p2(), EX.O2}])

      assert RDF.Data.merge(named_graph, unnamed_graph) ==
               RDF.dataset([{EX.S1, EX.p1(), EX.O1, EX.G}, {EX.S2, EX.p2(), EX.O2}])

      dataset1 = RDF.dataset([{EX.S1, EX.p1(), EX.O1, EX.G1}], name: EX.DS)
      dataset2 = RDF.dataset([{EX.S2, EX.p2(), EX.O2, EX.G2}])

      assert RDF.Data.merge(dataset1, dataset2) ==
               RDF.dataset([{EX.S1, EX.p1(), EX.O1, EX.G1}, {EX.S2, EX.p2(), EX.O2, EX.G2}],
                 name: EX.DS
               )
    end

    test "preserves all graph metadata (name, prefixes, base_iri) when graphs have same name" do
      graph1 =
        RDF.graph([{EX.S1, EX.p(), EX.O1}],
          name: EX.G,
          prefixes: [ex: EX],
          base_iri: "http://example.com/"
        )

      graph2 = RDF.graph([{EX.S2, EX.p(), EX.O2}], name: EX.G)

      assert RDF.Data.merge(graph1, graph2) ==
               RDF.graph([{EX.S1, EX.p(), EX.O1}, {EX.S2, EX.p(), EX.O2}],
                 name: EX.G,
                 prefixes: [ex: EX],
                 base_iri: "http://example.com/"
               )
    end

    test "Description + Triple with same subject stays Description" do
      desc = EX.S |> EX.p1(EX.O1)
      triple = {EX.S, EX.p2(), EX.O2}

      assert RDF.Data.merge(desc, triple) == EX.S |> EX.p1(EX.O1) |> EX.p2(EX.O2)
    end

    test "Description + Triple with different subject promotes to Graph" do
      desc = EX.S1 |> EX.p1(EX.O1)
      triple = {EX.S2, EX.p2(), EX.O2}

      assert RDF.Data.merge(desc, triple) == RDF.graph([{EX.S1, EX.p1(), EX.O1}, triple])
    end

    test "Description + Quad promotes to Dataset" do
      desc = EX.S1 |> EX.p1(EX.O1)
      quad = {EX.S2, EX.p2(), EX.O2, EX.G}

      assert RDF.Data.merge(desc, RDF.dataset(quad)) ==
               RDF.dataset([{EX.S1, EX.p1(), EX.O1, nil}, quad])

      assert RDF.Data.merge(desc, quad) == RDF.dataset([{EX.S1, EX.p1(), EX.O1, nil}, quad])
    end

    test "Graph (unnamed) + Triple stays Graph" do
      graph = RDF.graph([{EX.S1, EX.p1(), EX.O1}])
      triple = {EX.S2, EX.p2(), EX.O2}

      assert RDF.Data.merge(graph, triple) ==
               RDF.graph([{EX.S1, EX.p1(), EX.O1}, triple])
    end

    test "Graph (named) + Triple promotes to Dataset" do
      graph = RDF.graph([{EX.S1, EX.p1(), EX.O1}], name: EX.G)
      triple = {EX.S2, EX.p2(), EX.O2}

      assert RDF.Data.merge(graph, triple) ==
               RDF.dataset([{EX.S1, EX.p1(), EX.O1, EX.G}, {EX.S2, EX.p2(), EX.O2, nil}])
    end

    test "Graph + Quad with same graph name stays Graph" do
      graph = RDF.graph([{EX.S1, EX.p1(), EX.O1}], name: EX.G)
      quad = {EX.S2, EX.p2(), EX.O2, EX.G}

      assert RDF.Data.merge(graph, quad) ==
               RDF.graph([{EX.S1, EX.p1(), EX.O1}, {EX.S2, EX.p2(), EX.O2}], name: EX.G)
    end

    test "Graph + Quad with nil graph stays Graph (when Graph has nil name)" do
      graph = RDF.graph([{EX.S1, EX.p1(), EX.O1}])
      quad = {EX.S2, EX.p2(), EX.O2, nil}

      assert RDF.Data.merge(graph, quad) ==
               RDF.graph([{EX.S1, EX.p1(), EX.O1}, {EX.S2, EX.p2(), EX.O2}])
    end

    test "Graph + Quad with different graph name promotes to Dataset" do
      graph = RDF.graph([{EX.S1, EX.p1(), EX.O1}], name: EX.G1)
      quad = {EX.S2, EX.p2(), EX.O2, EX.G2}

      assert RDF.Data.merge(graph, quad) ==
               RDF.dataset([{EX.S1, EX.p1(), EX.O1, EX.G1}, quad])
    end

    test "Dataset + Triple stays Dataset" do
      dataset = RDF.dataset([{EX.S1, EX.p1(), EX.O1, EX.G}])
      triple = {EX.S2, EX.p2(), EX.O2}

      assert RDF.Data.merge(dataset, triple) ==
               RDF.dataset([{EX.S1, EX.p1(), EX.O1, EX.G}, {EX.S2, EX.p2(), EX.O2, nil}])
    end

    test "Dataset + Quad stays Dataset" do
      dataset = RDF.dataset([{EX.S1, EX.p1(), EX.O1, EX.G1}])
      quad = {EX.S2, EX.p2(), EX.O2, EX.G2}

      assert RDF.Data.merge(dataset, quad) ==
               RDF.dataset([{EX.S1, EX.p1(), EX.O1, EX.G1}, quad])
    end

    test "merge with list of statements" do
      desc = EX.S1 |> EX.p1(EX.O1)

      assert RDF.Data.merge(desc, [{EX.S1, EX.p2(), EX.O2}, {EX.S2, EX.p3(), EX.O3}]) ==
               RDF.graph([
                 {EX.S1, EX.p1(), EX.O1},
                 {EX.S1, EX.p2(), EX.O2},
                 {EX.S2, EX.p3(), EX.O3}
               ])
    end

    test "merge with list of data structures" do
      graph = RDF.graph({EX.S1, EX.p1(), EX.O1})
      desc = EX.S2 |> EX.p2(EX.O2)

      assert RDF.Data.merge(graph, [desc, {EX.S3, EX.p3(), EX.O3}]) ==
               RDF.graph([
                 {EX.S1, EX.p1(), EX.O1},
                 {EX.S2, EX.p2(), EX.O2},
                 {EX.S3, EX.p3(), EX.O3}
               ])
    end

    test "merge with empty list returns original" do
      desc = EX.S |> EX.p(EX.O)
      assert RDF.Data.merge(desc, []) == desc
    end
  end

  describe "merge/1" do
    test "with only statements uses first as description base" do
      assert RDF.Data.merge([{EX.S1, EX.p1(), EX.O1}, {EX.S2, EX.p2(), EX.O2}]) ==
               RDF.graph([{EX.S1, EX.p1(), EX.O1}, {EX.S2, EX.p2(), EX.O2}])
    end

    test "with structure as first element" do
      graph = RDF.graph({EX.S1, EX.p1(), EX.O1})

      assert RDF.Data.merge([graph, {EX.S2, EX.p2(), EX.O2}]) ==
               RDF.graph([{EX.S1, EX.p1(), EX.O1}, {EX.S2, EX.p2(), EX.O2}])
    end

    test "with structure after statements uses structure as base" do
      graph = RDF.graph({EX.S2, EX.p2(), EX.O2})

      assert RDF.Data.merge([{EX.S1, EX.p1(), EX.O1}, graph, {EX.S3, EX.p3(), EX.O3}]) ==
               RDF.graph([
                 {EX.S1, EX.p1(), EX.O1},
                 {EX.S2, EX.p2(), EX.O2},
                 {EX.S3, EX.p3(), EX.O3}
               ])
    end

    test "with single statement" do
      assert RDF.Data.merge([{EX.S, EX.p(), EX.O}]) == EX.S |> EX.p(EX.O)
    end

    test "with single structure" do
      graph = RDF.graph({EX.S, EX.p(), EX.O})
      assert RDF.Data.merge([graph]) == graph
    end

    test "with empty list returns empty graph" do
      assert RDF.Data.merge([]) == RDF.graph()
    end
  end

  describe "statements/1" do
    test "RDF.Description" do
      assert RDF.Data.statements(EX.S |> EX.p1(EX.O1) |> EX.p2(EX.O2)) ==
               [
                 {RDF.iri(EX.S), EX.p1(), RDF.iri(EX.O1)},
                 {RDF.iri(EX.S), EX.p2(), RDF.iri(EX.O2)}
               ]

      assert RDF.Data.statements(RDF.description(EX.S)) == []
    end

    test "RDF.Graph" do
      graph =
        RDF.graph([
          {EX.S1, EX.p1(), EX.O1},
          {EX.S2, EX.p2(), EX.O2}
        ])

      assert RDF.Data.statements(graph) ==
               [
                 {RDF.iri(EX.S1), EX.p1(), RDF.iri(EX.O1)},
                 {RDF.iri(EX.S2), EX.p2(), RDF.iri(EX.O2)}
               ]

      named_graph =
        RDF.graph(
          [
            {EX.S1, EX.p1(), EX.O1},
            {EX.S2, EX.p2(), EX.O2}
          ],
          name: EX.G
        )

      assert RDF.Data.statements(named_graph) ==
               [
                 {RDF.iri(EX.S1), EX.p1(), RDF.iri(EX.O1)},
                 {RDF.iri(EX.S2), EX.p2(), RDF.iri(EX.O2)}
               ]

      assert RDF.Data.statements(RDF.graph()) == []
    end

    test "RDF.Dataset" do
      dataset =
        RDF.dataset([
          {EX.S1, EX.p1(), EX.O1, nil},
          {EX.S2, EX.p2(), EX.O2, EX.Graph}
        ])

      assert RDF.Data.statements(dataset) ==
               [
                 {RDF.iri(EX.S1), EX.p1(), RDF.iri(EX.O1), nil},
                 {RDF.iri(EX.S2), EX.p2(), RDF.iri(EX.O2), RDF.iri(EX.Graph)}
               ]

      assert RDF.Data.statements(RDF.dataset()) == []
    end
  end

  describe "triples/1" do
    test "RDF.Description" do
      assert RDF.Data.triples(EX.S |> EX.p(EX.O)) == [{RDF.iri(EX.S), EX.p(), RDF.iri(EX.O)}]
      assert RDF.Data.triples(RDF.description(EX.S)) == []
    end

    test "RDF.Graph" do
      graph = RDF.graph([{EX.S, EX.p(), EX.O}])
      assert RDF.Data.triples(graph) == [{RDF.iri(EX.S), EX.p(), RDF.iri(EX.O)}]

      named_graph = RDF.graph([{EX.S, EX.p(), EX.O}], name: EX.Graph)
      assert RDF.Data.triples(named_graph) == [{RDF.iri(EX.S), EX.p(), RDF.iri(EX.O)}]

      assert RDF.Data.triples(RDF.graph()) == []
    end

    test "RDF.Dataset" do
      dataset =
        RDF.dataset([
          {EX.S1, EX.p1(), EX.O1, nil},
          {EX.S2, EX.p2(), EX.O2, EX.Graph}
        ])

      assert RDF.Data.triples(dataset) == [
               {RDF.iri(EX.S1), EX.p1(), RDF.iri(EX.O1)},
               {RDF.iri(EX.S2), EX.p2(), RDF.iri(EX.O2)}
             ]

      assert RDF.Data.triples(RDF.dataset()) == []
    end
  end

  describe "quads/1" do
    test "RDF.Description" do
      assert RDF.Data.quads(EX.S |> EX.p(EX.O)) == [{RDF.iri(EX.S), EX.p(), RDF.iri(EX.O), nil}]
      assert RDF.Data.quads(RDF.description(EX.S)) == []
    end

    test "RDF.Graph" do
      graph = RDF.graph([{EX.S, EX.p(), EX.O}])
      assert RDF.Data.quads(graph) == [{RDF.iri(EX.S), EX.p(), RDF.iri(EX.O), nil}]

      named_graph = RDF.graph([{EX.S, EX.p(), EX.O}], name: EX.Graph)

      assert RDF.Data.quads(named_graph) == [
               {RDF.iri(EX.S), EX.p(), RDF.iri(EX.O), RDF.iri(EX.Graph)}
             ]

      assert RDF.Data.quads(RDF.graph()) == []
    end

    test "RDF.Dataset" do
      dataset =
        RDF.dataset([
          {EX.S1, EX.p1(), EX.O1, nil},
          {EX.S2, EX.p2(), EX.O2, EX.Graph}
        ])

      assert RDF.Data.quads(dataset) == [
               {RDF.iri(EX.S1), EX.p1(), RDF.iri(EX.O1), nil},
               {RDF.iri(EX.S2), EX.p2(), RDF.iri(EX.O2), RDF.iri(EX.Graph)}
             ]

      assert RDF.Data.quads(RDF.dataset()) == []
    end
  end

  test "default_graph/1" do
    desc = EX.S |> EX.p1(EX.O1) |> EX.p2(EX.O2)
    assert RDF.Data.default_graph(desc) == RDF.Graph.new(desc)

    unnamed_graph = RDF.graph([{EX.S1, EX.p(), EX.O}])
    assert RDF.Data.default_graph(unnamed_graph) == unnamed_graph

    named_graph = RDF.graph([{EX.S1, EX.p(), EX.O}], name: EX.NamedGraph)
    assert RDF.Data.default_graph(named_graph) == RDF.Graph.new()

    dataset =
      RDF.dataset([
        {EX.S1, EX.p1(), EX.O1, nil},
        {EX.S2, EX.p2(), EX.O2, nil},
        {EX.S3, EX.p3(), EX.O3, EX.Graph1}
      ])

    assert RDF.Data.default_graph(dataset) ==
             RDF.Graph.new([
               {EX.S1, EX.p1(), EX.O1},
               {EX.S2, EX.p2(), EX.O2}
             ])

    assert RDF.Data.default_graph(RDF.description(EX.S)) == RDF.graph()
    assert RDF.Data.default_graph(RDF.graph()) == RDF.graph()
    assert RDF.Data.default_graph(RDF.dataset()) == RDF.graph()
  end

  describe "graph/2,3" do
    test "RDF.Description" do
      desc = EX.S |> EX.p(EX.O)

      assert RDF.Data.graph(desc, nil) == RDF.graph(desc)
      assert RDF.Data.graph(desc, EX.Graph1) == RDF.graph(name: EX.Graph1)

      assert RDF.Data.graph(RDF.description(EX.S), nil) == RDF.graph()
    end

    test "RDF.Graph" do
      graph = RDF.graph([{EX.S1, EX.p(), EX.O}])
      assert RDF.Data.graph(graph, nil) == graph

      assert RDF.Data.graph(graph, EX.Graph1) == RDF.graph(name: EX.Graph1)

      matching_graph = RDF.graph([{EX.S1, EX.p(), EX.O}], name: EX.Graph1)
      assert RDF.Data.graph(matching_graph, EX.Graph1) == matching_graph

      other_graph = RDF.graph([{EX.S1, EX.p(), EX.O}], name: EX.Graph2)
      assert RDF.Data.graph(other_graph, EX.Graph1) == RDF.graph(name: EX.Graph1)

      assert RDF.Data.graph(RDF.graph(), nil) == RDF.graph()
      assert RDF.Data.graph(RDF.graph(name: EX.Graph), EX.Graph) == RDF.graph(name: EX.Graph)
    end

    test "RDF.Dataset" do
      dataset =
        RDF.dataset([
          {EX.S1, EX.p1(), EX.O1, nil},
          {EX.S2, EX.p2(), EX.O2, EX.Graph1},
          {EX.S3, EX.p3(), EX.O3, EX.Graph2}
        ])

      assert RDF.Data.graph(dataset, EX.Graph1) ==
               RDF.Graph.new([{EX.S2, EX.p2(), EX.O2}], name: EX.Graph1)

      assert RDF.Data.graph(dataset, EX.Graph2) ==
               RDF.Graph.new([{EX.S3, EX.p3(), EX.O3}], name: EX.Graph2)

      assert RDF.Data.graph(dataset, nil) == RDF.Graph.new([{EX.S1, EX.p1(), EX.O1}])
      assert RDF.Data.graph(dataset, EX.NonExistent) == RDF.graph(name: EX.NonExistent)

      assert RDF.Data.graph(RDF.dataset(), nil) == RDF.graph()
      assert RDF.Data.graph(RDF.dataset(), EX.Graph) == RDF.graph(name: EX.Graph)

      assert RDF.Data.graph(RDF.dataset(RDF.graph(name: EX.Graph)), EX.Graph) ==
               RDF.graph(name: EX.Graph)
    end

    test "graph/2 always returns a graph" do
      assert RDF.Data.graph(RDF.description(EX.S), EX.SomeGraph) ==
               RDF.graph(name: EX.SomeGraph)

      assert RDF.Data.graph(RDF.graph([{EX.S1, EX.p(), EX.O}]), EX.SomeGraph) ==
               RDF.graph(name: EX.SomeGraph)

      assert RDF.Data.graph(RDF.dataset([{EX.S2, EX.p(), EX.O, EX.Graph}]), EX.NonExistent) ==
               RDF.graph(name: EX.NonExistent)
    end

    test "graph/3 allows to provide a custom default value" do
      desc = EX.S |> EX.p(EX.O)
      assert RDF.Data.graph(desc, EX.Graph1, nil) == nil
      assert RDF.Data.graph(desc, EX.Graph1, :not_found) == :not_found

      graph = RDF.graph([{EX.S, EX.p(), EX.O}], name: EX.Graph1)
      assert RDF.Data.graph(graph, EX.Graph2, nil) == nil
      assert RDF.Data.graph(graph, EX.Graph2, :not_found) == :not_found

      dataset = RDF.dataset([{EX.S1, EX.p(), EX.O, EX.Graph1}])
      assert RDF.Data.graph(dataset, EX.NonExistent, nil) == nil
      assert RDF.Data.graph(dataset, EX.NonExistent, :not_found) == :not_found

      expected_graph = RDF.Graph.new([{EX.S1, EX.p(), EX.O}], name: EX.Graph1)
      assert RDF.Data.graph(dataset, EX.Graph1, nil) == expected_graph
      assert RDF.Data.graph(dataset, EX.Graph1, :not_found) == expected_graph
    end

    test "graph name coercion" do
      dataset =
        RDF.dataset([
          {EX.S1, EX.p(), EX.O1, nil},
          {EX.S2, EX.p(), EX.O2, EX.Graph1}
        ])

      expected_graph = RDF.Graph.new([{EX.S2, EX.p(), EX.O2}], name: EX.Graph1)

      assert RDF.Data.graph(dataset, RDF.iri(EX.Graph1) |> to_string()) == expected_graph
      assert RDF.Data.graph(dataset, EX.Graph1) == expected_graph
    end
  end

  describe "graphs/1" do
    test "RDF.Description" do
      desc = EX.S |> EX.p1(EX.O1) |> EX.p2(EX.O2)

      assert RDF.Data.graphs(desc) == [RDF.graph(desc)]
    end

    test "RDF.Graph" do
      graph = RDF.graph([{EX.S, EX.p(), EX.O}], name: EX.G)

      assert RDF.Data.graphs(graph) == [graph]
    end

    test "RDF.Dataset" do
      dataset =
        RDF.dataset([
          {EX.S1, EX.p(), EX.O1, EX.G1},
          {EX.S2, EX.p(), EX.O2, EX.G2},
          {EX.S3, EX.p(), EX.O3, nil}
        ])

      assert Enum.sort_by(RDF.Data.graphs(dataset), & &1.name) ==
               [
                 RDF.graph([{EX.S3, EX.p(), EX.O3}]),
                 RDF.graph([{EX.S1, EX.p(), EX.O1}], name: EX.G1),
                 RDF.graph([{EX.S2, EX.p(), EX.O2}], name: EX.G2)
               ]

      assert RDF.Data.graphs(RDF.dataset()) == []

      assert RDF.Dataset.new(name: EX.Dataset)
             |> RDF.Dataset.put_graph(RDF.graph(name: EX.EmptyGraph))
             |> RDF.Data.graphs() == [RDF.graph(name: EX.EmptyGraph)]
    end
  end

  describe "graph_names/1" do
    test "RDF.Description" do
      assert RDF.Data.graph_names(EX.S |> EX.p1(EX.O1)) == [nil]
      assert RDF.Data.graph_names(RDF.description(EX.S)) == [nil]
    end

    test "RDF.Graph" do
      unnamed_graph = RDF.graph([{EX.S, EX.p(), EX.O}])
      assert RDF.Data.graph_names(unnamed_graph) == [nil]

      named_graph = RDF.graph([{EX.S, EX.p(), EX.O}], name: EX.Graph1)
      assert RDF.Data.graph_names(named_graph) == [RDF.iri(EX.Graph1)]

      empty_named_graph = RDF.graph([], name: EX.Graph2)
      assert RDF.Data.graph_names(empty_named_graph) == [RDF.iri(EX.Graph2)]
    end

    test "RDF.Dataset" do
      dataset_default_only = RDF.dataset([{EX.S, EX.p(), EX.O, nil}])

      assert RDF.Data.graph_names(dataset_default_only) == [nil]

      dataset_named_only =
        RDF.dataset([
          {EX.S1, EX.p(), EX.O1, EX.Graph1},
          {EX.S1, EX.p(), EX.O12, EX.Graph1},
          {EX.S2, EX.p(), EX.O2, EX.Graph2}
        ])

      assert RDF.Data.graph_names(dataset_named_only) == [RDF.iri(EX.Graph1), RDF.iri(EX.Graph2)]

      dataset =
        RDF.dataset([
          {EX.S1, EX.p1(), EX.O1, nil},
          {EX.S2, EX.p2(), EX.O2, EX.Graph1},
          {EX.S2, EX.p2(), EX.O22, EX.Graph1},
          {EX.S3, EX.p3(), EX.O3, EX.Graph2}
        ])

      assert RDF.Data.graph_names(dataset) == [nil, RDF.iri(EX.Graph1), RDF.iri(EX.Graph2)]

      assert RDF.Data.graph_names(RDF.dataset()) == []
    end
  end

  describe "descriptions/1" do
    test "RDF.Description" do
      desc = EX.S |> EX.p1(EX.O1) |> EX.p2(EX.O2)

      assert RDF.Data.descriptions(desc) == [desc]
    end

    test "RDF.Graph" do
      graph =
        RDF.graph([
          {EX.S1, EX.p1(), EX.O1},
          {EX.S1, EX.p2(), EX.O2},
          {EX.S2, EX.p1(), EX.O3},
          {EX.S2, EX.p2(), EX.O4}
        ])

      assert RDF.Data.descriptions(graph) == [
               EX.S1 |> EX.p1(EX.O1) |> EX.p2(EX.O2),
               EX.S2 |> EX.p1(EX.O3) |> EX.p2(EX.O4)
             ]
    end

    test "RDF.Dataset" do
      dataset =
        RDF.dataset([
          {EX.S1, EX.p1(), EX.O1, EX.G1},
          {EX.S1, EX.p2(), EX.O2, EX.G1},
          {EX.S2, EX.p1(), EX.O3, EX.G2},
          {EX.S1, EX.p3(), EX.O4, EX.G2}
        ])

      assert RDF.Data.descriptions(dataset) == [
               EX.S1 |> EX.p1(EX.O1) |> EX.p2(EX.O2) |> EX.p3(EX.O4),
               EX.S2 |> EX.p1(EX.O3)
             ]
    end

    test "returns empty list for empty data" do
      assert RDF.Data.descriptions(RDF.graph()) == []
      assert RDF.Data.descriptions(RDF.dataset()) == []
      assert RDF.Data.descriptions(RDF.description(EX.S)) == []
    end
  end

  describe "description/2,3" do
    test "RDF.Description" do
      desc = EX.S1 |> EX.p1(EX.O1) |> EX.p2(EX.O2)

      assert RDF.Data.description(desc, EX.S1) == desc
      assert RDF.Data.description(desc, EX.S2) == RDF.description(EX.S2)
    end

    test "RDF.Graph" do
      graph =
        RDF.graph([
          {EX.S1, EX.p1(), EX.O1},
          {EX.S1, EX.p2(), EX.O2},
          {EX.S2, EX.p1(), EX.O3}
        ])

      assert RDF.Data.description(graph, EX.S1) == EX.S1 |> EX.p1(EX.O1) |> EX.p2(EX.O2)
    end

    test "RDF.Dataset" do
      assert [
               {EX.S1, EX.p1(), EX.O1, nil},
               {EX.S1, EX.p2(), EX.O2, nil},
               {EX.S1, EX.p3(), EX.O3, EX.Graph1},
               {EX.S1, EX.p4(), EX.O4, EX.Graph2},
               {EX.S2, EX.p1(), EX.O5, EX.Graph1}
             ]
             |> RDF.dataset()
             |> RDF.Data.description(EX.S1) ==
               EX.S1 |> EX.p1(EX.O1) |> EX.p2(EX.O2) |> EX.p3(EX.O3) |> EX.p4(EX.O4)
    end

    test "description/2 always returns a description" do
      assert RDF.Data.description(RDF.graph(), EX.NonExistent) == RDF.description(EX.NonExistent)

      assert RDF.graph([{EX.S1, EX.p(), EX.O}])
             |> RDF.Data.description(EX.S2) == RDF.description(EX.S2)

      assert RDF.dataset([{EX.S1, EX.p(), EX.O, nil}])
             |> RDF.Data.description(EX.S1) == EX.S1 |> EX.p(EX.O)
    end

    test "description/3 allows to provide a custom default value" do
      assert RDF.Data.description(RDF.description(EX.S), EX.NonExistent, nil) == nil
      assert RDF.Data.description(RDF.description(EX.S), EX.NonExistent, :not_found) == :not_found
      assert RDF.Data.description(RDF.graph(), EX.NonExistent, nil) == nil
      assert RDF.Data.description(RDF.graph(), EX.NonExistent, :not_found) == :not_found
      assert RDF.Data.description(RDF.dataset(), EX.NonExistent, nil) == nil
      assert RDF.Data.description(RDF.dataset(), EX.NonExistent, :not_found) == :not_found
    end

    test "subject coercion" do
      graph = RDF.graph([{EX.S1, EX.p(), EX.O}])

      assert RDF.Data.description(graph, EX.S1) == EX.S1 |> EX.p(EX.O)
      assert RDF.Data.description(graph, RDF.iri(EX.S1) |> to_string()) == EX.S1 |> EX.p(EX.O)

      assert RDF.graph([{RDF.bnode(:b1), EX.p(), EX.O}])
             |> RDF.Data.description("_:b1") == RDF.bnode(:b1) |> EX.p(EX.O)
    end
  end

  describe "subjects/1" do
    test "RDF.Description" do
      assert EX.S
             |> EX.p1(EX.O1)
             |> EX.p2(EX.O2)
             |> RDF.Data.subjects() == [RDF.iri(EX.S)]

      assert RDF.Data.subjects(RDF.description(EX.S)) == []
    end

    test "RDF.Graph" do
      assert [
               {EX.S1, EX.p1(), EX.O1},
               {EX.S2, EX.p2(), EX.O2},
               {~B<blank>, EX.p3(), EX.O3}
             ]
             |> RDF.graph()
             |> RDF.Data.subjects()
             |> MapSet.new() ==
               MapSet.new([RDF.iri(EX.S1), RDF.iri(EX.S2), ~B<blank>])

      assert RDF.Data.subjects(RDF.graph()) == []
    end

    test "RDF.Dataset" do
      assert [
               {EX.S1, EX.p1(), EX.O1, nil},
               {EX.S2, EX.p2(), EX.O2, EX.Graph1},
               {~B<blank>, EX.p3(), EX.O3, EX.Graph2}
             ]
             |> RDF.dataset()
             |> RDF.Data.subjects()
             |> MapSet.new() ==
               MapSet.new([RDF.iri(EX.S1), RDF.iri(EX.S2), ~B<blank>])

      assert RDF.Data.subjects(RDF.dataset()) == []
    end

    if RDF.star?() do
      test "handles RDF-star quoted triples as subjects" do
        quoted_triple = {EX.s1(), EX.says(), ~L"Hello"}

        assert [
                 {quoted_triple, EX.confidence(), 0.9},
                 {EX.S2, EX.p(), EX.O}
               ]
               |> RDF.graph()
               |> RDF.Data.subjects()
               |> MapSet.new() ==
                 MapSet.new([quoted_triple, RDF.iri(EX.S2)])
      end
    end
  end

  test "subjects/2" do
    graph =
      RDF.graph([
        {EX.S1, EX.p(), EX.O},
        {EX.S2, EX.p(), EX.O},
        {~B<blank>, EX.p(), EX.O}
      ])

    assert graph
           |> RDF.Data.subjects(&is_rdf_iri/1)
           |> MapSet.new() == MapSet.new([RDF.iri(EX.S1), RDF.iri(EX.S2)])

    assert graph
           |> RDF.Data.subjects(&is_rdf_bnode/1)
           |> MapSet.new() == MapSet.new([~B<blank>])

    assert RDF.Data.subjects(graph, fn _ -> false end) == []

    assert RDF.Data.subjects(RDF.graph(), fn _ -> true end) == []
  end

  describe "predicates/1" do
    test "RDF.Description" do
      assert EX.S
             |> EX.p1(EX.O1)
             |> EX.p2(EX.O2)
             |> RDF.Data.predicates()
             |> MapSet.new() == MapSet.new([EX.p1(), EX.p2()])

      assert RDF.Data.predicates(RDF.description(EX.S)) == []
    end

    test "RDF.Graph" do
      assert [
               {EX.S1, EX.p1(), EX.O1},
               {EX.S1, EX.p1(), EX.O12},
               {EX.S2, EX.p2(), EX.O2},
               {EX.S3, EX.p1(), EX.O3}
             ]
             |> RDF.graph()
             |> RDF.Data.predicates()
             |> MapSet.new() == MapSet.new([EX.p1(), EX.p2()])

      assert RDF.Data.predicates(RDF.graph()) == []
    end

    test "RDF.Dataset" do
      assert [
               {EX.S1, EX.p1(), EX.O1, nil},
               {EX.S2, EX.p2(), EX.O2, EX.Graph1},
               {EX.S3, EX.p1(), EX.O3, EX.Graph2}
             ]
             |> RDF.dataset()
             |> RDF.Data.predicates()
             |> MapSet.new() == MapSet.new([EX.p1(), EX.p2()])

      assert RDF.Data.predicates(RDF.dataset()) == []
    end
  end

  test "predicates/2" do
    graph =
      RDF.graph([
        {EX.S1, EX.p1(), EX.O},
        {EX.S2, EX.p2(), EX.O},
        {EX.S3, EX.p1(), EX.O}
      ])

    assert graph
           |> RDF.Data.predicates(&(&1 == EX.p1()))
           |> MapSet.new() == MapSet.new([EX.p1()])

    assert RDF.Data.predicates(graph, fn _ -> false end) == []

    assert RDF.Data.predicates(RDF.graph(), fn _ -> true end) == []
  end

  describe "object_resources/1" do
    test "RDF.Description" do
      assert EX.S
             |> EX.p1(EX.O1)
             |> EX.p2("literal")
             |> EX.p3(~B<blank>)
             |> RDF.Data.object_resources()
             |> MapSet.new() ==
               MapSet.new([RDF.iri(EX.O1), ~B<blank>])

      assert RDF.Data.object_resources(RDF.description(EX.S)) == []
    end

    test "RDF.Graph" do
      assert [
               {EX.S1, EX.p1(), EX.O1},
               {EX.S2, EX.p2(), "literal"},
               {EX.S3, EX.p3(), ~B<blank>}
             ]
             |> RDF.graph()
             |> RDF.Data.object_resources()
             |> MapSet.new() ==
               MapSet.new([RDF.iri(EX.O1), ~B<blank>])

      assert RDF.Data.object_resources(RDF.graph()) == []
    end

    test "RDF.Dataset" do
      assert [
               {EX.S1, EX.p1(), EX.O1, nil},
               {EX.S2, EX.p2(), "literal", EX.Graph1},
               {EX.S3, EX.p3(), EX.O1, EX.Graph2},
               {EX.S4, EX.p4(), ~B<blank>, EX.Graph1}
             ]
             |> RDF.dataset()
             |> RDF.Data.object_resources()
             |> MapSet.new() ==
               MapSet.new([RDF.iri(EX.O1), ~B<blank>])

      assert RDF.Data.object_resources(RDF.dataset()) == []
    end
  end

  describe "objects/1" do
    test "RDF.Description" do
      assert EX.S
             |> EX.p1(EX.O1)
             |> EX.p2("literal")
             |> EX.p3(42)
             |> RDF.Data.objects()
             |> MapSet.new() ==
               MapSet.new([RDF.iri(EX.O1), RDF.XSD.string("literal"), RDF.XSD.integer(42)])

      assert RDF.Data.objects(RDF.description(EX.S)) == []
    end

    test "RDF.Graph" do
      assert [
               {EX.S1, EX.p1(), EX.O1},
               {EX.S2, EX.p2(), "literal"},
               {EX.S3, EX.p3(), ~B<blank>},
               {EX.S4, EX.p4(), 42}
             ]
             |> RDF.graph()
             |> RDF.Data.objects()
             |> MapSet.new() ==
               MapSet.new([
                 RDF.iri(EX.O1),
                 RDF.XSD.string("literal"),
                 ~B<blank>,
                 RDF.XSD.integer(42)
               ])

      assert RDF.Data.objects(RDF.graph()) == []
    end

    test "RDF.Dataset" do
      assert [
               {EX.S1, EX.p1(), EX.O1, nil},
               {EX.S2, EX.p2(), "literal", EX.Graph1},
               {EX.S3, EX.p3(), EX.O1, EX.Graph2},
               {EX.S4, EX.p4(), 42, EX.Graph1}
             ]
             |> RDF.dataset()
             |> RDF.Data.objects()
             |> MapSet.new() ==
               MapSet.new([RDF.iri(EX.O1), RDF.XSD.string("literal"), RDF.XSD.integer(42)])

      assert RDF.Data.objects(RDF.dataset()) == []
    end
  end

  test "objects/2" do
    graph =
      RDF.graph([
        {EX.S1, EX.p1(), EX.O1},
        {EX.S2, EX.p2(), "literal"},
        {EX.S3, EX.p3(), ~B<blank>},
        {EX.S4, EX.p4(), 42}
      ])

    assert graph
           |> RDF.Data.objects(&is_rdf_resource/1)
           |> MapSet.new() == MapSet.new([RDF.iri(EX.O1), ~B<blank>])

    assert graph
           |> RDF.Data.objects(&RDF.literal?/1)
           |> MapSet.new() == MapSet.new([RDF.XSD.string("literal"), RDF.XSD.integer(42)])

    assert RDF.Data.objects(graph, fn _ -> false end) == []

    assert RDF.Data.objects(RDF.graph(), fn _ -> true end) == []
  end

  describe "resources/1,2" do
    test "RDF.Description" do
      assert EX.S
             |> EX.p1(EX.O1)
             |> EX.p2("literal")
             |> EX.p3(~B<blank>)
             |> RDF.Data.resources()
             |> MapSet.new() ==
               MapSet.new([RDF.iri(EX.S), RDF.iri(EX.O1), ~B<blank>])

      assert RDF.Data.resources(RDF.description(EX.S)) == []

      assert EX.S
             |> EX.p1(EX.O1)
             |> EX.p2("literal")
             |> EX.p3(~B<blank>)
             |> RDF.Data.resources(predicates: true)
             |> MapSet.new() ==
               MapSet.new([RDF.iri(EX.S), RDF.iri(EX.O1), EX.p1(), EX.p2(), EX.p3(), ~B<blank>])
    end

    test "RDF.Graph" do
      assert [
               {EX.S1, EX.p1(), EX.O1},
               {EX.S2, EX.p2(), "literal"},
               {~B<b1>, EX.p3(), ~B<blank>}
             ]
             |> RDF.graph()
             |> RDF.Data.resources()
             |> MapSet.new() ==
               MapSet.new([RDF.iri(EX.S1), RDF.iri(EX.S2), RDF.iri(EX.O1), ~B<b1>, ~B<blank>])

      assert RDF.Data.resources(RDF.graph()) == []

      assert [
               {EX.S1, EX.p1(), EX.O1},
               {EX.S2, EX.p2(), "literal"},
               {~B<b1>, EX.p3(), ~B<blank>}
             ]
             |> RDF.graph()
             |> RDF.Data.resources(predicates: true)
             |> MapSet.new() ==
               MapSet.new([
                 RDF.iri(EX.S1),
                 RDF.iri(EX.S2),
                 RDF.iri(EX.O1),
                 EX.p1(),
                 EX.p2(),
                 EX.p3(),
                 ~B<b1>,
                 ~B<blank>
               ])
    end

    test "RDF.Dataset" do
      assert [
               {EX.S1, EX.p1(), EX.O1, nil},
               {EX.S2, EX.p2(), "literal", EX.Graph1},
               {~B<b1>, EX.p3(), EX.O2, EX.Graph2}
             ]
             |> RDF.dataset()
             |> RDF.Data.resources()
             |> MapSet.new() ==
               MapSet.new([
                 RDF.iri(EX.S1),
                 RDF.iri(EX.S2),
                 RDF.iri(EX.O1),
                 RDF.iri(EX.O2),
                 ~B<b1>
               ])

      assert [
               {EX.S1, EX.p1(), EX.O1, nil},
               {EX.S2, EX.p2(), "literal", EX.Graph1},
               {~B<b1>, EX.p3(), EX.O2, EX.Graph2}
             ]
             |> RDF.dataset()
             |> RDF.Data.resources(predicates: true)
             |> MapSet.new() ==
               MapSet.new([
                 RDF.iri(EX.S1),
                 RDF.iri(EX.S2),
                 RDF.iri(EX.O1),
                 RDF.iri(EX.O2),
                 EX.p1(),
                 EX.p2(),
                 EX.p3(),
                 ~B<b1>
               ])

      assert RDF.Data.resources(RDF.dataset()) == []
    end

    test "resources/2 with filter" do
      graph =
        RDF.graph([
          {EX.S1, EX.p1(), EX.O1},
          {EX.S2, EX.p2(), "literal"},
          {~B<b1>, EX.p3(), ~B<b2>}
        ])

      # Filter by position
      assert graph
             |> RDF.Data.resources(fn _term, position -> position == :subject end)
             |> MapSet.new() == MapSet.new([RDF.iri(EX.S1), RDF.iri(EX.S2), ~B<b1>])

      assert graph
             |> RDF.Data.resources(fn _term, position -> position == :object end)
             |> MapSet.new() == MapSet.new([RDF.iri(EX.O1), ~B<b2>])

      # Filter by term type
      assert graph
             |> RDF.Data.resources(&is_rdf_iri/1)
             |> MapSet.new() == MapSet.new([RDF.iri(EX.S1), RDF.iri(EX.S2), RDF.iri(EX.O1)])

      assert graph
             |> RDF.Data.resources(&is_rdf_bnode/1)
             |> MapSet.new() == MapSet.new([~B<b1>, ~B<b2>])

      # Combined with predicates: true
      assert graph
             |> RDF.Data.resources(
               predicates: true,
               filter: fn _term, position -> position == :predicate end
             )
             |> MapSet.new() == MapSet.new([EX.p1(), EX.p2(), EX.p3()])

      # Filter as keyword option
      assert graph
             |> RDF.Data.resources(filter: &is_rdf_iri/1)
             |> MapSet.new() == MapSet.new([RDF.iri(EX.S1), RDF.iri(EX.S2), RDF.iri(EX.O1)])

      # Edge cases
      assert RDF.Data.resources(graph, fn _, _ -> false end) == []
      assert RDF.Data.resources(RDF.graph(), fn _, _ -> true end) == []
    end
  end

  describe "count/1" do
    test "returns predicate count for Description" do
      assert EX.S
             |> EX.p1(EX.O1)
             |> EX.p2(EX.O2)
             |> EX.p3([EX.O3, EX.O4])
             |> RDF.Data.count() ==
               3

      assert EX.S |> RDF.description() |> RDF.Data.count() == 0

      assert EX.S |> EX.p(EX.O) |> RDF.Data.count() == 1

      assert EX.S
             |> EX.p([EX.O1, EX.O2, EX.O3, EX.O4, EX.O5])
             |> RDF.Data.count() == 1
    end

    test "returns subject count for Graph" do
      assert RDF.graph([
               {EX.S1, EX.p1(), EX.O1},
               {EX.S1, EX.p2(), EX.O2},
               {EX.S2, EX.p1(), EX.O3},
               {EX.S3, EX.p3(), EX.O4}
             ])
             |> RDF.Data.count() == 3

      assert RDF.Data.count(RDF.graph()) == 0

      assert [{EX.S, EX.p(), EX.O}] |> RDF.graph() |> RDF.Data.count() == 1

      assert [
               {EX.S, EX.p1(), EX.O1},
               {EX.S, EX.p2(), EX.O2},
               {EX.S, EX.p3(), EX.O3}
             ]
             |> RDF.graph()
             |> RDF.Data.count() == 1
    end

    test "returns graph count for Dataset" do
      assert [
               {EX.S1, EX.p1(), EX.O1, nil},
               {EX.S2, EX.p2(), EX.O2, EX.Graph1},
               {EX.S3, EX.p3(), EX.O3, EX.Graph2}
             ]
             |> RDF.dataset()
             |> RDF.Data.count() == 3

      assert RDF.Data.count(RDF.dataset()) == 0

      assert RDF.dataset([{EX.S, EX.p(), EX.O, nil}]) |> RDF.Data.count() == 1
    end
  end

  test "graph_count/1" do
    assert RDF.Data.graph_count(EX.S |> EX.p1(EX.O1) |> EX.p2(EX.O2)) == 1

    assert RDF.graph([
             {EX.S1, EX.p1(), EX.O1},
             {EX.S2, EX.p2(), EX.O2}
           ])
           |> RDF.Data.graph_count() == 1

    assert RDF.graph([{EX.S1, EX.p1(), EX.O1}], name: EX.Graph)
           |> RDF.Data.graph_count() == 1

    assert RDF.dataset([
             {EX.S1, EX.p1(), EX.O1, nil},
             {EX.S2, EX.p2(), EX.O2, EX.Graph1},
             {EX.S3, EX.p3(), EX.O3, EX.Graph2}
           ])
           |> RDF.Data.graph_count() == 3

    assert RDF.dataset([{EX.S1, EX.p1(), EX.O1, nil}])
           |> RDF.Data.graph_count() == 1

    assert RDF.dataset([
             {EX.S1, EX.p1(), EX.O1, EX.Graph1},
             {EX.S2, EX.p2(), EX.O2, EX.Graph2}
           ])
           |> RDF.Data.graph_count() == 2

    assert RDF.Data.graph_count(RDF.description(EX.S)) == 1
    assert RDF.Data.graph_count(RDF.graph()) == 1
    assert RDF.Data.graph_count(RDF.dataset()) == 0
  end

  test "statement_count/1" do
    assert RDF.Data.statement_count(EX.S |> EX.p1(EX.O1) |> EX.p2(EX.O2)) == 2

    assert RDF.graph([
             {EX.S1, EX.p1(), EX.O1},
             {EX.S1, EX.p2(), EX.O2},
             {EX.S2, EX.p1(), EX.O3}
           ])
           |> RDF.Data.statement_count() == 3

    assert RDF.dataset([
             {EX.S1, EX.p1(), EX.O1, nil},
             {EX.S2, EX.p2(), EX.O2, EX.Graph},
             {EX.S3, EX.p3(), EX.O3, EX.Graph}
           ])
           |> RDF.Data.statement_count() == 3

    assert RDF.Data.statement_count(RDF.description(EX.S)) == 0
    assert RDF.Data.statement_count(RDF.graph()) == 0
    assert RDF.Data.statement_count(RDF.dataset()) == 0
  end

  describe "subject_count/1" do
    test "returns subject count" do
      assert RDF.Data.subject_count(EX.S |> EX.p1(EX.O1) |> EX.p2(EX.O2)) == 1

      assert RDF.graph([
               {EX.S1, EX.p1(), EX.O1},
               {EX.S1, EX.p2(), EX.O2},
               {RDF.bnode(), EX.p1(), EX.O3},
               {EX.S3, EX.p3(), EX.O4}
             ])
             |> RDF.Data.subject_count() == 3

      assert RDF.dataset([
               {~b<S1>, EX.p1(), EX.O1, nil},
               {~b<S1>, EX.p2(), EX.O2, nil},
               {EX.S2, EX.p1(), EX.O3, EX.Graph},
               {EX.S3, EX.p3(), EX.O4, EX.Graph},
               {~b<S1>, EX.p4(), EX.O5, EX.Graph}
             ])
             |> RDF.Data.subject_count() == 3

      assert RDF.Data.subject_count(RDF.description(EX.S)) == 0
      assert RDF.Data.subject_count(RDF.graph()) == 0
      assert RDF.Data.subject_count(RDF.dataset()) == 0
    end

    if RDF.star?() do
      test "handles RDF-star quoted triples as subjects" do
        quoted_triple = {EX.S1, EX.says(), "Hello"}

        assert RDF.graph([
                 {quoted_triple, EX.confidence(), 0.9},
                 {EX.S2, EX.p(), EX.O}
               ])
               |> RDF.Data.subject_count() == 2
      end
    end
  end

  describe "predicate_count/1" do
    test "counts predicates with objects for Description" do
      assert EX.S
             |> EX.p1(EX.O1)
             |> EX.p2(EX.O2)
             |> EX.p3([EX.O3, EX.O4])
             |> RDF.Data.predicate_count() == 3

      assert RDF.Data.predicate_count(RDF.description(EX.S)) == 0

      assert EX.S |> EX.p([EX.O1, EX.O2, EX.O3]) |> RDF.Data.predicate_count() == 1
    end

    test "counts unique predicates for Graph" do
      assert [
               {EX.S1, EX.p1(), EX.O1},
               {EX.S1, EX.p2(), EX.O2},
               {EX.S2, EX.p1(), EX.O3},
               {EX.S2, EX.p3(), EX.O4},
               {EX.S3, EX.p2(), EX.O5}
             ]
             |> RDF.graph()
             |> RDF.Data.predicate_count() == 3

      assert RDF.Data.predicate_count(RDF.graph()) == 0

      assert [
               {EX.S1, EX.p(), EX.O1},
               {EX.S2, EX.p(), EX.O2},
               {EX.S3, EX.p(), EX.O3}
             ]
             |> RDF.graph()
             |> RDF.Data.predicate_count() == 1
    end

    test "counts unique predicates for Dataset" do
      assert [
               {EX.S1, EX.p1(), EX.O1, nil},
               {EX.S1, EX.p2(), EX.O2, nil},
               {EX.S2, EX.p1(), EX.O3, EX.Graph1},
               {EX.S2, EX.p3(), EX.O4, EX.Graph1},
               {EX.S3, EX.p2(), RDF.bnode(:b1), EX.Graph2},
               {EX.S3, EX.p4(), EX.O6, EX.Graph2}
             ]
             |> RDF.dataset()
             |> RDF.Data.predicate_count() == 4

      assert RDF.Data.predicate_count(RDF.dataset()) == 0

      assert [
               {EX.S1, EX.p(), EX.O1, nil},
               {EX.S2, EX.p(), EX.O2, EX.Graph1},
               {EX.S3, EX.p(), EX.O3, EX.Graph2}
             ]
             |> RDF.dataset()
             |> RDF.Data.predicate_count() == 1
    end

    if RDF.star?() do
      test "handles RDF-star quoted triples if enabled" do
        quoted_triple = {EX.S1, EX.says(), "Hello"}

        assert [
                 {quoted_triple, EX.confidence(), 0.9},
                 {EX.S2, EX.p1(), quoted_triple},
                 {EX.S3, EX.p2(), EX.O}
               ]
               |> RDF.graph()
               |> RDF.Data.predicate_count() == 3
      end
    end
  end

  describe "empty?/1" do
    test "returns true for empty Description" do
      assert RDF.Data.empty?(RDF.description(EX.S)) == true
    end

    test "returns false for non-empty Description" do
      assert RDF.Data.empty?(EX.S |> EX.p(EX.O)) == false
    end

    test "returns true for empty Graph" do
      assert RDF.Data.empty?(RDF.graph()) == true
    end

    test "returns false for non-empty Graph" do
      assert RDF.graph([{EX.S, EX.p(), EX.O}]) |> RDF.Data.empty?() == false
    end

    test "returns true for empty Dataset" do
      assert RDF.Data.empty?(RDF.dataset()) == true
    end

    test "returns false for non-empty Dataset" do
      assert RDF.dataset([{EX.S, EX.p(), EX.O, nil}]) |> RDF.Data.empty?() == false
    end
  end

  describe "equal?/2" do
    test "RDF.Description" do
      desc1 = EX.S |> EX.p1(EX.O1) |> EX.p2(EX.O2)
      desc2 = EX.S |> EX.p2(EX.O2) |> EX.p1(EX.O1)
      desc3 = EX.S |> EX.p1(EX.O1) |> EX.p3(EX.O3)

      assert RDF.Data.equal?(desc1, desc2) == true
      assert RDF.Data.equal?(desc1, desc3) == false
      assert RDF.Data.equal?(desc1, desc1) == true
    end

    test "RDF.Graph" do
      graph1 =
        RDF.graph([
          {EX.S1, EX.p1(), EX.O1},
          {EX.S2, EX.p2(), EX.O2}
        ])

      graph2 =
        RDF.graph([
          {EX.S2, EX.p2(), EX.O2},
          {EX.S1, EX.p1(), EX.O1}
        ])

      graph3 =
        RDF.graph([
          {EX.S1, EX.p1(), EX.O1},
          {EX.S3, EX.p3(), EX.O3}
        ])

      assert RDF.Data.equal?(graph1, graph2) == true
      assert RDF.Data.equal?(graph1, graph3) == false
      assert RDF.Data.equal?(graph1, graph1) == true
    end

    test "RDF.Dataset" do
      dataset1 =
        RDF.dataset([
          {EX.S1, EX.p1(), EX.O1, nil},
          {EX.S2, EX.p2(), EX.O2, EX.G1}
        ])

      dataset2 =
        RDF.dataset([
          {EX.S2, EX.p2(), EX.O2, EX.G1},
          {EX.S1, EX.p1(), EX.O1, nil}
        ])

      dataset3 =
        RDF.dataset([
          {EX.S1, EX.p1(), EX.O1, EX.G1},
          {EX.S2, EX.p2(), EX.O2, nil}
        ])

      assert RDF.Data.equal?(dataset1, dataset2) == true
      assert RDF.Data.equal?(dataset1, dataset3) == false
      assert RDF.Data.equal?(dataset1, dataset1) == true
    end

    test "RDF.Description can equal RDF.Graph" do
      desc = EX.S |> EX.p1(EX.O1) |> EX.p2(EX.O2)
      graph_matching = RDF.graph(desc)
      graph_extra = RDF.graph([desc, {EX.S2, EX.p3(), EX.O3}])

      graph_different =
        RDF.graph([
          {EX.S2, EX.p1(), EX.O1},
          {EX.S2, EX.p2(), EX.O2}
        ])

      assert RDF.Data.equal?(desc, graph_matching) == true
      assert RDF.Data.equal?(graph_matching, desc) == true
      assert RDF.Data.equal?(desc, graph_extra) == false
      assert RDF.Data.equal?(graph_extra, desc) == false
      assert RDF.Data.equal?(desc, graph_different) == false
    end

    test "RDF.Description can equal RDF.Dataset" do
      desc = EX.S |> EX.p(EX.O)
      dataset = RDF.dataset(desc)
      dataset_named = RDF.dataset([{EX.S, EX.p(), EX.O, EX.G1}])

      assert RDF.Data.equal?(desc, dataset) == true
      assert RDF.Data.equal?(desc, dataset_named) == false
    end

    test "RDF.Graph can equal RDF.Dataset" do
      graph =
        RDF.graph(
          [
            {EX.S1, EX.p1(), EX.O1},
            {EX.S2, EX.p2(), EX.O2}
          ],
          name: EX.G1
        )

      dataset_matching = RDF.dataset(graph)
      dataset_extra = RDF.dataset([graph, {EX.S3, EX.p3(), EX.O3, EX.G2}])

      dataset_different =
        RDF.dataset([
          {EX.S1, EX.p1(), EX.O1, EX.G2},
          {EX.S2, EX.p2(), EX.O2, EX.G2}
        ])

      assert RDF.Data.equal?(graph, dataset_matching) == true
      assert RDF.Data.equal?(dataset_matching, graph) == true
      assert RDF.Data.equal?(graph, dataset_extra) == false
      assert RDF.Data.equal?(dataset_extra, graph) == false
      assert RDF.Data.equal?(graph, dataset_different) == false
    end

    test "unnamed RDF.Graph equals RDF.Dataset with default graph only" do
      graph =
        RDF.graph([
          {EX.S1, EX.p1(), EX.O1},
          {EX.S2, EX.p2(), EX.O2}
        ])

      dataset_default = RDF.dataset(graph)

      assert RDF.Data.equal?(graph, dataset_default) == true
      assert RDF.Data.equal?(dataset_default, graph) == true
    end

    test "empty structures" do
      empty_desc = RDF.description(EX.S)
      empty_graph = RDF.graph()
      empty_dataset = RDF.dataset()

      assert RDF.Data.equal?(empty_desc, RDF.description(EX.S)) == true
      assert RDF.Data.equal?(empty_graph, RDF.graph()) == true
      assert RDF.Data.equal?(empty_dataset, RDF.dataset()) == true
      assert RDF.Data.equal?(empty_desc, empty_graph) == true
      assert RDF.Data.equal?(empty_graph, empty_desc) == true
      assert RDF.Data.equal?(empty_graph, empty_dataset) == true
      assert RDF.Data.equal?(empty_dataset, empty_graph) == true
      assert RDF.Data.equal?(empty_dataset, empty_desc) == true
      assert RDF.Data.equal?(empty_desc, empty_dataset) == true
    end
  end

  describe "include?/2" do
    test "single statement" do
      graph =
        RDF.graph([
          {EX.S1, EX.p1(), EX.O1},
          {EX.S1, EX.p2(), EX.O2},
          {EX.S2, EX.p1(), EX.O3}
        ])

      assert RDF.Data.include?(graph, {EX.S1, EX.p1(), EX.O1}) == true
      assert RDF.Data.include?(graph, {EX.S1, EX.p2(), EX.O2}) == true
      assert RDF.Data.include?(graph, {EX.S2, EX.p1(), EX.O3}) == true
      assert RDF.Data.include?(graph, {EX.S1, EX.p1(), EX.O2}) == false
      assert RDF.Data.include?(graph, {EX.S1, EX.p3(), EX.O1}) == false
      assert RDF.Data.include?(graph, {EX.S3, EX.p1(), EX.O1}) == false
    end

    test "multiple statements" do
      graph =
        RDF.graph([
          {EX.S1, EX.p1(), EX.O1},
          {EX.S1, EX.p2(), EX.O2},
          {EX.S2, EX.p1(), EX.O3}
        ])

      assert RDF.Data.include?(graph, [
               {EX.S1, EX.p1(), EX.O1},
               {EX.S1, EX.p2(), EX.O2}
             ]) == true

      assert RDF.Data.include?(graph, [
               {EX.S1, EX.p1(), EX.O1},
               {EX.S2, EX.p1(), EX.O3}
             ]) == true

      assert RDF.Data.include?(graph, [
               {EX.S1, EX.p1(), EX.O1},
               {EX.S3, EX.p3(), EX.O3}
             ]) == false

      assert RDF.Data.include?(graph, []) == true
    end

    test "RDF.Description" do
      desc = EX.S |> EX.p1(EX.O1) |> EX.p2(EX.O2)

      assert RDF.Data.include?(desc, {EX.S, EX.p1(), EX.O1}) == true
      assert RDF.Data.include?(desc, {EX.S, EX.p2(), EX.O2}) == true
      assert RDF.Data.include?(desc, {EX.S, EX.p3(), EX.O3}) == false

      assert RDF.Data.include?(desc, [
               {EX.S, EX.p1(), EX.O1},
               {EX.S, EX.p2(), EX.O2}
             ]) == true
    end

    test "RDF.Dataset" do
      dataset =
        RDF.dataset([
          {EX.S1, EX.p1(), EX.O1, nil},
          {EX.S2, EX.p2(), EX.O2, EX.G1},
          {EX.S3, EX.p3(), EX.O3, EX.G2}
        ])

      assert RDF.Data.include?(dataset, {EX.S1, EX.p1(), EX.O1, nil}) == true
      assert RDF.Data.include?(dataset, {EX.S2, EX.p2(), EX.O2, EX.G1}) == true
      assert RDF.Data.include?(dataset, {EX.S3, EX.p3(), EX.O3, EX.G2}) == true
      assert RDF.Data.include?(dataset, {EX.S1, EX.p1(), EX.O1, EX.G1}) == false

      assert RDF.Data.include?(dataset, [
               {EX.S1, EX.p1(), EX.O1, nil},
               {EX.S2, EX.p2(), EX.O2, EX.G1}
             ]) == true
    end

    test "check data structure inclusion" do
      desc = EX.S |> EX.p1(EX.O1) |> EX.p2(EX.O2) |> EX.p3(EX.O3)

      assert RDF.Data.include?(desc, EX.S |> EX.p1(EX.O1) |> EX.p2(EX.O2)) == true
      assert RDF.Data.include?(desc, EX.S |> EX.p1(EX.O1) |> EX.p4(EX.O4)) == false
      assert RDF.Data.include?(desc, EX.Other |> EX.p1(EX.O1)) == false

      graph =
        RDF.graph([
          {EX.S1, EX.p1(), EX.O1},
          {EX.S1, EX.p2(), EX.O2},
          {EX.S2, EX.p1(), EX.O3}
        ])

      assert RDF.Data.include?(graph, EX.S1 |> EX.p1(EX.O1) |> EX.p2(EX.O2)) == true
      assert RDF.Data.include?(graph, EX.S1 |> EX.p1(EX.O1) |> EX.p3(EX.O3)) == false

      subgraph =
        RDF.graph([
          {EX.S1, EX.p1(), EX.O1},
          {EX.S2, EX.p1(), EX.O3}
        ])

      assert RDF.Data.include?(graph, subgraph) == true

      supergraph =
        RDF.graph([
          {EX.S1, EX.p1(), EX.O1},
          {EX.S1, EX.p2(), EX.O2},
          {EX.S2, EX.p1(), EX.O3},
          {EX.S3, EX.p3(), EX.O3}
        ])

      assert RDF.Data.include?(graph, supergraph) == false

      dataset =
        RDF.dataset([
          {EX.S1, EX.p1(), EX.O1, nil},
          {EX.S1, EX.p2(), EX.O2, nil},
          {EX.S2, EX.p2(), EX.O2, EX.G1},
          {EX.S3, EX.p3(), EX.O3, EX.G2}
        ])

      assert RDF.Data.include?(dataset, EX.S1 |> EX.p1(EX.O1) |> EX.p2(EX.O2)) == true
      assert RDF.Data.include?(dataset, EX.S2 |> EX.p2(EX.O2)) == true
      assert RDF.Data.include?(dataset, EX.S1 |> EX.p1(EX.O1) |> EX.p3(EX.O3)) == false

      subgraph =
        RDF.graph([
          {EX.S1, EX.p1(), EX.O1},
          {EX.S2, EX.p2(), EX.O2}
        ])

      assert RDF.Data.include?(dataset, subgraph) == true

      graph_not_included =
        RDF.graph([
          {EX.S1, EX.p1(), EX.O1},
          {EX.S4, EX.p4(), EX.O4}
        ])

      assert RDF.Data.include?(dataset, graph_not_included) == false

      sub_dataset =
        RDF.dataset([
          {EX.S1, EX.p1(), EX.O1, nil},
          {EX.S2, EX.p2(), EX.O2, EX.G1}
        ])

      assert RDF.Data.include?(dataset, sub_dataset) == true

      dataset_wrong_graph =
        RDF.dataset([
          {EX.S1, EX.p1(), EX.O1, EX.G1}
        ])

      assert RDF.Data.include?(dataset, dataset_wrong_graph) == false
    end

    test "works with empty structures" do
      empty_desc = RDF.description(EX.S)
      empty_graph = RDF.graph()
      empty_dataset = RDF.dataset()

      assert RDF.Data.include?(empty_desc, {EX.S, EX.p(), EX.O}) == false
      assert RDF.Data.include?(empty_graph, {EX.S, EX.p(), EX.O}) == false
      assert RDF.Data.include?(empty_dataset, {EX.S, EX.p(), EX.O, nil}) == false

      assert RDF.Data.include?(empty_desc, []) == true
      assert RDF.Data.include?(empty_graph, []) == true
      assert RDF.Data.include?(empty_dataset, []) == true
    end

    test "handles mixed triple/quad patterns" do
      dataset =
        RDF.dataset([
          {EX.S1, EX.p1(), EX.O1, nil},
          {EX.S2, EX.p2(), EX.O2, EX.G1}
        ])

      assert RDF.Data.include?(dataset, {EX.S1, EX.p1(), EX.O1}) == true
      assert RDF.Data.include?(dataset, {EX.S2, EX.p2(), EX.O2}) == true
      assert RDF.Data.include?(dataset, {EX.S1, EX.p1(), EX.O1, nil}) == true
      assert RDF.Data.include?(dataset, {EX.S2, EX.p2(), EX.O2, EX.G1}) == true
    end
  end

  describe "describes?/2" do
    test "RDF.Description" do
      desc = EX.S1 |> EX.p(EX.O)
      assert RDF.Data.describes?(desc, EX.S1) == true
      assert RDF.Data.describes?(desc, "http://example.com/S1") == true
      assert RDF.Data.describes?(desc, EX.S2) == false
      assert RDF.Data.describes?(RDF.description(EX.S1), EX.S1) == false
    end

    test "RDF.Graph" do
      bnode = RDF.bnode("b1")

      graph =
        RDF.graph([
          {EX.S1, EX.p1(), EX.O1},
          {bnode, EX.p2(), EX.O2}
        ])

      assert RDF.Data.describes?(graph, EX.S1) == true
      assert RDF.Data.describes?(graph, bnode) == true
      assert RDF.Data.describes?(graph, EX.S2) == false
      assert RDF.Data.describes?(RDF.graph(), EX.Any) == false
    end

    test "RDF.Dataset" do
      dataset =
        RDF.dataset([
          {EX.S1, EX.p1(), EX.O1, nil},
          {EX.S2, EX.p2(), EX.O2, EX.Graph1}
        ])

      assert RDF.Data.describes?(dataset, EX.S1) == true
      assert RDF.Data.describes?(dataset, EX.S2) == true
      assert RDF.Data.describes?(dataset, EX.S3) == false
      assert RDF.Data.describes?(RDF.dataset(), EX.Any) == false
    end

    if RDF.star?() do
      test "with RDF-star quoted triples as subjects" do
        triple = {EX.S, EX.p(), EX.O}

        graph =
          RDF.graph([
            {triple, EX.confidence(), 0.9},
            {EX.S2, EX.p(), EX.O}
          ])

        assert RDF.Data.describes?(graph, triple) == true
        assert RDF.Data.describes?(graph, {EX.Other, EX.p(), EX.O}) == false
      end
    end
  end

  describe "to_graph/1,2" do
    test "RDF.Description" do
      desc = EX.S |> EX.p1(EX.O1) |> EX.p2(EX.O2)

      assert RDF.Data.to_graph(desc) == RDF.graph(desc)

      assert RDF.Data.to_graph(RDF.description(EX.S)) == RDF.graph()
    end

    test "RDF.Graph" do
      graph = RDF.graph([{EX.S1, EX.p1(), EX.O1}, {EX.S2, EX.p2(), EX.O2}], name: EX.G)

      assert RDF.Data.to_graph(graph) == graph

      assert RDF.Data.to_graph(RDF.graph()) == RDF.graph()
    end

    test "RDF.Dataset" do
      assert [
               {EX.S1, EX.p1(), EX.O1, EX.G1},
               {EX.S2, EX.p2(), EX.O2, EX.G2},
               {EX.S3, EX.p3(), EX.O3, nil}
             ]
             |> RDF.dataset()
             |> RDF.Data.to_graph() ==
               RDF.graph([
                 {EX.S1, EX.p1(), EX.O1},
                 {EX.S2, EX.p2(), EX.O2},
                 {EX.S3, EX.p3(), EX.O3}
               ])

      assert RDF.Data.to_graph(RDF.dataset()) == RDF.graph()
    end

    test "with :native option forces native RDF.Graph" do
      graph = RDF.graph([{EX.S, EX.p(), EX.O}], name: EX.G)
      assert RDF.Data.to_graph(graph, native: true) == graph
    end
  end

  describe "to_dataset/1,2" do
    test "RDF.Description" do
      assert EX.S |> EX.p1(EX.O1) |> EX.p2(EX.O2) |> RDF.Data.to_dataset() ==
               RDF.dataset([
                 {EX.S, EX.p1(), EX.O1, nil},
                 {EX.S, EX.p2(), EX.O2, nil}
               ])

      assert RDF.Data.to_dataset(RDF.description(EX.S)) == RDF.dataset()
    end

    test "named RDF.Graph" do
      assert RDF.graph([{EX.S1, EX.p1(), EX.O1}, {EX.S2, EX.p2(), EX.O2}], name: EX.G)
             |> RDF.Data.to_dataset() ==
               RDF.dataset([
                 {EX.S1, EX.p1(), EX.O1, EX.G},
                 {EX.S2, EX.p2(), EX.O2, EX.G}
               ])
    end

    test "unnamed RDF.Graph" do
      assert RDF.graph([{EX.S, EX.p(), EX.O}]) |> RDF.Data.to_dataset() ==
               RDF.dataset([{EX.S, EX.p(), EX.O, nil}])

      assert RDF.Data.to_dataset(RDF.graph()) == RDF.dataset()
    end

    test "RDF.Dataset" do
      dataset =
        RDF.dataset([
          {EX.S1, EX.p1(), EX.O1, EX.G1},
          {EX.S2, EX.p2(), EX.O2, nil}
        ])

      assert RDF.Data.to_dataset(dataset) == dataset

      assert RDF.Data.to_dataset(RDF.dataset()) == RDF.dataset()
    end

    test "with :native option forces native RDF.Dataset" do
      dataset = RDF.dataset([{EX.S, EX.p(), EX.O, EX.G}], name: EX.DS)
      assert RDF.Data.to_dataset(dataset, native: true) == dataset
    end
  end
end
