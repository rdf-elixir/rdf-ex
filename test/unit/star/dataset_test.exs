defmodule RDF.Star.Dataset.Test do
  use RDF.Test.Case

  test "add/3" do
    dataset =
      dataset()
      |> Dataset.add({statement(), EX.ap1(), EX.AO1})
      |> Dataset.add({statement(), EX.ap2(), "foo", EX.Graph})
      |> Dataset.add({statement(), EX.ap3(), statement(), EX.Graph})

    assert dataset_includes_statement?(dataset, {statement(), EX.ap1(), RDF.iri(EX.AO1)})

    assert dataset_includes_statement?(
             dataset,
             {statement(), EX.ap2(), ~L"foo", RDF.iri(EX.Graph)}
           )

    assert dataset_includes_statement?(
             dataset,
             {statement(), EX.ap3(), statement(), RDF.iri(EX.Graph)}
           )
  end

  test "put/3" do
    dataset =
      dataset()
      |> Dataset.put({statement(), EX.ap1(), EX.AO1})
      |> Dataset.put({statement(), EX.ap2(), "foo", EX.Graph})
      |> Dataset.put({statement(), EX.ap3(), EX.AO3})

    refute dataset_includes_statement?(dataset, {statement(), EX.ap1(), RDF.iri(EX.AO1)})
    assert dataset_includes_statement?(dataset, {statement(), EX.ap3(), RDF.iri(EX.AO3)})

    assert dataset_includes_statement?(
             dataset,
             {statement(), EX.ap2(), ~L"foo", RDF.iri(EX.Graph)}
           )
  end

  test "delete/3" do
    assert Dataset.delete(dataset_with_annotation(), annotation_description()) == dataset()
  end

  test ":filter_star opt on statements/1" do
    assert dataset()
           |> Dataset.put(statement())
           |> Dataset.put(statement(), graph: EX.Graph)
           |> Dataset.put({statement(), EX.ap1(), EX.AO1})
           |> Dataset.put({statement(), EX.ap2(), "foo", EX.Graph})
           |> Dataset.put({statement(), EX.ap3(), EX.AO3})
           |> Dataset.statements(filter_star: true) ==
             dataset()
             |> Dataset.put(statement())
             |> Dataset.put(statement(), graph: EX.Graph)
             |> Dataset.statements()
  end
end
