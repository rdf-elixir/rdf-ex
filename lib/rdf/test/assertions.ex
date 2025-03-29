defmodule RDF.Test.Assertions do
  @moduledoc """
  Assertions for ExUnit tests.
  """

  alias RDF.{Graph, Dataset}

  @doc """
  Asserts that two RDF graphs or datasets are isomorphic.

  This assertion checks if two RDF graphs or datasets are isomorphic
  using `RDF.Dataset.isomorphic?/2`. In case of a failure, it displays
  a diff of the graphs.

  ## Examples

      assert_rdf_isomorphic actual_graph, expected_graph
      assert_rdf_isomorphic actual_dataset, expected_dataset
      assert_rdf_isomorphic actual_dataset, expected_graph
  """
  def assert_rdf_isomorphic(left, right) do
    Dataset.isomorphic?(left, right) ||
      raise_non_isomorphic_error(left, right)
  end

  @dialyzer {:nowarn_function, raise_non_isomorphic_error: 2}
  defp raise_non_isomorphic_error(left, right) do
    raise ExUnit.AssertionError,
          [message: "RDF data is not isomorphic"]
          |> Keyword.merge(
            non_isomorphic_error_diff(left, right, single_graph(left), single_graph(right))
          )
  end

  defp non_isomorphic_error_diff(_, _, %Graph{name: name} = left, %Graph{name: name} = right) do
    [left: left, right: right]
  end

  defp non_isomorphic_error_diff(left, right, _, _) do
    [left: left, right: right]
  end

  defp single_graph(%Graph{} = graph), do: graph

  defp single_graph(%Dataset{} = dataset) do
    case Dataset.graphs(dataset) do
      [graph] -> graph
      _ -> nil
    end
  end
end
