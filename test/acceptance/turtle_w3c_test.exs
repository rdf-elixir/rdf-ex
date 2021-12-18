defmodule RDF.Turtle.W3C.Test do
  @moduledoc """
  The official W3C RDF 1.1 Turtles Test Suite.

  from <https://www.w3.org/2013/TurtleTests/>

  see also <https://www.w3.org/2011/rdf-wg/wiki/RDF_Test_Suites#Turtle_Tests>
  """

  use ExUnit.Case, async: false

  alias RDF.{Turtle, TestSuite, NTriples}
  alias TestSuite.NS.RDFT

  @path RDF.TestData.path("TURTLE-TESTS")
  @base "http://www.w3.org/2013/TurtleTests/"
  @manifest TestSuite.manifest_path(@path) |> TestSuite.manifest_graph(base: @base)

  TestSuite.test_cases(@manifest, RDFT.TestTurtleEval)
  |> Enum.each(fn test_case ->
    @tag test_case: test_case
    if TestSuite.test_name(test_case) in ~w[
            anonymous_blank_node_subject
            anonymous_blank_node_object
            labeled_blank_node_subject
            labeled_blank_node_object
            labeled_blank_node_with_leading_digit
            labeled_blank_node_with_leading_underscore
            labeled_blank_node_with_non_leading_extras
            labeled_blank_node_with_PN_CHARS_BASE_character_boundaries
            sole_blankNodePropertyList
            blankNodePropertyList_as_subject
            blankNodePropertyList_as_object
            blankNodePropertyList_with_multiple_triples
            blankNodePropertyList_containing_collection
            nested_blankNodePropertyLists
            collection_subject
            collection_object
            nested_collection
            first
            last
            turtle-subm-01
            turtle-subm-05
            turtle-subm-06
            turtle-subm-08
            turtle-subm-10
            turtle-subm-14
          ] do
      @tag skip: """
           The produced graphs are correct, but have different blank node labels than the result graph.
           TODO: Implement a graph isomorphism algorithm.
           """
    end

    test TestSuite.test_title(test_case), %{test_case: test_case} do
      with base = to_string(TestSuite.test_input_file(test_case)) do
        assert RDF.Graph.equal?(
                 TestSuite.test_input_file_path(test_case, @path)
                 |> Turtle.read_file!(base: base),
                 TestSuite.test_result_file_path(test_case, @path)
                 |> NTriples.read_file!()
               )
      end
    end
  end)

  TestSuite.test_cases(@manifest, RDFT.TestTurtlePositiveSyntax)
  |> Enum.each(fn test_case ->
    @tag test_case: test_case
    test TestSuite.test_title(test_case), %{test_case: test_case} do
      with base = to_string(TestSuite.test_input_file(test_case)) do
        assert {:ok, _} =
                 TestSuite.test_input_file_path(test_case, @path)
                 |> Turtle.read_file(base: base)
      end
    end
  end)

  TestSuite.test_cases(@manifest, RDFT.TestTurtleNegativeSyntax)
  |> Enum.each(fn test_case ->
    @tag test_case: test_case
    test TestSuite.test_title(test_case), %{test_case: test_case} do
      with base = to_string(TestSuite.test_input_file(test_case)) do
        assert {:error, _} =
                 TestSuite.test_input_file_path(test_case, @path)
                 |> Turtle.read_file(base: base)
      end
    end
  end)

  TestSuite.test_cases(@manifest, RDFT.TestTurtleNegativeEval)
  |> Enum.each(fn test_case ->
    if TestSuite.test_name(test_case) in ~w[turtle-eval-bad-01 turtle-eval-bad-02 turtle-eval-bad-03] do
      @tag skip: "TODO: IRI validation"
    end

    @tag test_case: test_case
    test TestSuite.test_title(test_case), %{test_case: test_case} do
      with base = to_string(TestSuite.test_input_file(test_case)) do
        assert {:error, _} =
                 TestSuite.test_input_file_path(test_case, @path)
                 |> Turtle.read_file(base: base)
      end
    end
  end)
end
