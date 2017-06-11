defmodule RDF.IsomorphicTest do
  use RDF.Test.Case

  alias RDF.{NTriples, NQuads}

  with dir = Path.join(RDF.TestData.dir, "isomorphic") do
    dir
    |> File.ls!
    |> Enum.each(fn
         ("graph-" <> test_name) = test_case ->
           @tag data: %{
            file1: Path.join([dir, test_case, test_name <> "-1.nt"]),
            file2: Path.join([dir, test_case, test_name <> "-2.nt"])
           }
           test "#{test_name} is isomorphic", %{data: %{file1: file1, file2: file2}} do
             assert RDF.Graph.isomorphic?(NTriples.read_file!(file1), NTriples.read_file!(file2))
           end

         ("dataset-" <> test_name) = test_case ->
           @tag data: %{
            file1: Path.join([dir, test_case, test_name <> "-1.nq"]),
            file2: Path.join([dir, test_case, test_name <> "-2.nq"])
           }
           @tag skip: "TODO"
           test "#{test_name} is isomorphic", %{data: %{file1: file1, file2: file2}} do
             assert RDF.Dataset.isomorphic?(NQuads.read_file!(file1), NQuads.read_file!(file2))
           end
       end)
  end

  with dir = Path.join(RDF.TestData.dir, "non-isomorphic") do
    dir
    |> File.ls!
    |> Enum.each(fn
         ("graph-" <> test_name) = test_case ->
           @tag data: %{
            file1: Path.join([dir, test_case, test_name <> "-1.nt"]),
            file2: Path.join([dir, test_case, test_name <> "-2.nt"])
           }
           test "#{test_name} is not isomorphic", %{data: %{file1: file1, file2: file2}} do
             refute RDF.Graph.isomorphic?(NTriples.read_file!(file1), NTriples.read_file!(file2))
           end

         ("dataset-" <> test_name) = test_case ->
           @tag data: %{
            file1: Path.join([dir, test_case, test_name <> "-1.nq"]),
            file2: Path.join([dir, test_case, test_name <> "-2.nq"])
           }
           @tag skip: "TODO"
           test "#{test_name} is not isomorphic", %{data: %{file1: file1, file2: file2}} do
             refute RDF.Dataset.isomorphic?(NQuads.read_file!(file1), NQuads.read_file!(file2))
           end
       end)
  end

end
