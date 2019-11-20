defmodule RDF.DiffTest do
  use RDF.Test.Case

  doctest RDF.Diff

  alias RDF.Diff

  test "new" do
    assert Diff.new() ==
             %Diff{additions: Graph.new(), deletions: Graph.new()}
    assert Diff.new(additions: [], deletions: []) ==
             %Diff{additions: Graph.new(), deletions: Graph.new()}
    assert Diff.new(additions: Graph.new(), deletions: Graph.new) ==
             %Diff{additions: Graph.new(), deletions: Graph.new()}
    description = Description.new({EX.S, EX.p, EX.O1})
    graph = Graph.new({EX.S, EX.p, EX.O2})
    assert Diff.new(additions: description, deletions: graph) ==
             %Diff{additions: Graph.new(description), deletions: graph}
  end

  describe "diff/2 " do
    test "with two descriptions that are equal it returns an empty diff" do
      assert Diff.diff(description(), description()) == Diff.new()
      description = description({EX.foo(), EX.Bar})
      assert Diff.diff(description, description) == Diff.new()
    end

    test "with two descriptions with different subjects" do
      description1 = Description.new({EX.S1, EX.p, EX.O})
      description2 = Description.new({EX.S2, EX.p, EX.O})
      assert Diff.diff(description1, description2) ==
               Diff.new(additions: Graph.new(description2),
                        deletions: Graph.new(description1))
    end

    test "with two descriptions when the second description has additional statements" do
      description1 = Description.new({EX.S, EX.p, EX.O})
      description2 =
        description1
        |> EX.p(EX.O2)
        |> EX.p2(EX.O)

      assert Diff.diff(description1, description2) ==
               Diff.new(additions: Graph.new(
                                     EX.S
                                     |> EX.p(EX.O2)
                                     |> EX.p2(EX.O)
                                   ),
                        deletions: Graph.new())
    end

    test "with two descriptions when the first description has additional statements" do
      description1 = Description.new({EX.S, EX.p, EX.O})
      description2 =
        description1
        |> EX.p(EX.O2)
        |> EX.p2(EX.O)

      assert Diff.diff(description2, description1) ==
               Diff.new(additions: Graph.new,
                 deletions: Graph.new(
                   EX.S
                   |> EX.p(EX.O2)
                   |> EX.p2(EX.O)
                 ))
    end
  end

  test "with two descriptions with additions and deletions" do
    description1 =
      EX.S
      |> EX.p(EX.O1, EX.O2)
      |> EX.p2(EX.O)
    description2 =
      EX.S
      |> EX.p(EX.O1, EX.O3)
      |> EX.p3(EX.O)

    assert Diff.diff(description1, description2) ==
             Diff.new(
               additions: Graph.new(
                 EX.S
                 |> EX.p(EX.O3)
                 |> EX.p3(EX.O)

               ),
               deletions: Graph.new(
                 EX.S
                 |> EX.p(EX.O2)
                 |> EX.p2(EX.O)
               ))
  end

  test "with one description and a graph" do
    description =
      EX.S1
      |> EX.p(EX.O1, EX.O2)
      |> EX.p2(EX.O)
    graph = Graph.new([
      EX.S1
      |> EX.p(EX.O2, EX.O3)
      |> EX.p3(EX.O),
      EX.S3
      |> EX.p(EX.O)
    ])
    assert Diff.diff(description, graph) ==
             Diff.new(
               additions: Graph.new([
                 EX.S1
                 |> EX.p(EX.O3)
                 |> EX.p3(EX.O),
                 EX.S3
                 |> EX.p(EX.O)
               ]),
               deletions: Graph.new([
                 EX.S1
                 |> EX.p(EX.O1)
                 |> EX.p2(EX.O),
               ]))

    assert Diff.diff(graph, description) ==
             Diff.new(
               additions: Graph.new([
                 EX.S1
                 |> EX.p(EX.O1)
                 |> EX.p2(EX.O),
               ]),
               deletions: Graph.new([
                 EX.S1
                 |> EX.p(EX.O3)
                 |> EX.p3(EX.O),
                 EX.S3
                 |> EX.p(EX.O)
               ])
             )

    disjoint_description =
      EX.S
      |> EX.p(EX.O1, EX.O2)
      |> EX.p2(EX.O)
    assert Diff.diff(disjoint_description, graph) ==
             Diff.new(
               additions: graph,
               deletions: Graph.new(disjoint_description))
    assert Diff.diff(graph, disjoint_description) ==
             Diff.new(
               additions: Graph.new(disjoint_description),
               deletions: graph)
  end

  test "with two graphs with additions and deletions" do
    graph1 = Graph.new([
      EX.S1
      |> EX.p(EX.O1, EX.O2)
      |> EX.p2(EX.O),
      EX.S2
      |> EX.p(EX.O)
    ])
    graph2 = Graph.new([
      EX.S1
      |> EX.p(EX.O2, EX.O3)
      |> EX.p3(EX.O),
      EX.S3
      |> EX.p(EX.O)
    ])

    assert Diff.diff(graph1, graph2) ==
             Diff.new(
               additions: Graph.new([
                 EX.S1
                 |> EX.p(EX.O3)
                 |> EX.p3(EX.O),
                 EX.S3
                 |> EX.p(EX.O)
               ]),
               deletions: Graph.new([
                 EX.S1
                 |> EX.p(EX.O1)
                 |> EX.p2(EX.O),
                 EX.S2
                 |> EX.p(EX.O)
               ]))
  end

  test "merge/2" do
    assert Diff.merge(
             Diff.new(additions: Graph.new({EX.S, EX.p, EX.O1}),
                      deletions: Graph.new({EX.S1, EX.p, EX.O})),
             Diff.new(additions: Graph.new({EX.S, EX.p, EX.O2}),
                      deletions: Graph.new({EX.S2, EX.p, EX.O}))
           ) ==
             Diff.new(
               additions: Graph.new({EX.S, EX.p, [EX.O1, EX.O2]}),
               deletions: Graph.new([
                 {EX.S1, EX.p, EX.O},
                 {EX.S2, EX.p, EX.O}
               ])
             )
  end

  test "empty?/1" do
    assert Diff.empty?(Diff.new()) == true
    assert Diff.empty?(Diff.new(additions: EX.p(EX.S, EX.O),
                                deletions: EX.p(EX.S, EX.O))) == false
    assert Diff.empty?(Diff.new(additions: EX.p(EX.S, EX.O))) == false
    assert Diff.empty?(Diff.new(deletions: EX.p(EX.S, EX.O))) == false
  end

  describe "apply/2" do
    test "on a graph" do
      assert Diff.new(
                 additions: Graph.new([
                   EX.S1
                   |> EX.p(EX.O3)
                   |> EX.p3(EX.O),
                   EX.S3
                   |> EX.p(EX.O)
                 ]),
                 deletions: Graph.new([
                   EX.S1
                   |> EX.p(EX.O1)
                   |> EX.p2(EX.O),
                   EX.S2
                   |> EX.p(EX.O)
                 ]))
             |> Diff.apply(Graph.new([
                              EX.S1
                              |> EX.p(EX.O1, EX.O2)
                              |> EX.p2(EX.O),
                              EX.S2
                              |> EX.p(EX.O)
                            ])) ==
               Graph.new([
                 EX.S1
                 |> EX.p(EX.O2, EX.O3)
                 |> EX.p3(EX.O),
                 EX.S3
                 |> EX.p(EX.O)
               ])
    end

    test "on a description" do
      assert Diff.new(
               additions: Graph.new([
                 EX.S1
                 |> EX.p(EX.O3)
                 |> EX.p3(EX.O),
                 EX.S3
                 |> EX.p(EX.O)
               ]),
               deletions: Graph.new([
                 EX.S1
                 |> EX.p(EX.O1)
                 |> EX.p2(EX.O),
               ]))
             |> Diff.apply(
                  EX.S1
                  |> EX.p(EX.O1, EX.O2)
                  |> EX.p2(EX.O)
                ) ==
               Graph.new([
                 EX.S1
                 |> EX.p(EX.O2, EX.O3)
                 |> EX.p3(EX.O),
                 EX.S3
                 |> EX.p(EX.O)
               ])
    end

    test "when the statements to be deleted are not present" do
      assert Diff.new(
               additions: Graph.new(
                 EX.S1
                 |> EX.p(EX.O4)
               ),
               deletions: Graph.new([
                 EX.S1
                 |> EX.p(EX.O2, EX.O3)
                 |> EX.p2(EX.O),
                 EX.S2
                 |> EX.p(EX.O)
               ]))
             |> Diff.apply(Graph.new(
               EX.S1
               |> EX.p(EX.O1, EX.O2)
             )) ==
               Graph.new(
                 EX.S1
                 |> EX.p(EX.O1, EX.O4)
               )
    end
  end
end
