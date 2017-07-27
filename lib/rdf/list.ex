defmodule RDF.List do
  @moduledoc """
  Functions for working with RDF lists.

  see
  - <https://www.w3.org/TR/rdf-schema/#ch_collectionvocab>
  - <https://www.w3.org/TR/rdf11-mt/#rdf-collections>
  """

  alias RDF.{Graph, Description, BlankNode}

  @rdf_nil RDF.nil

  @doc """
  Creates a RDF list.

  The function returns a tuple `{node, graph}`, where `node` is the name of the
  head node of the list and `graph` is the `RDF.Graph` with the statements
  constituting the list.

  By default the statements these statements are added to an empty graph. An
  already existing graph to which the statements are added can be specified with
  the `graph` option.

  The name of the head node can be specified with the `head` option
  (default: `RDF.bnode()`, i.e. an arbitrary unique name).
  Note: When the given list is empty, the `name` option will be ignored - the
  head node of the empty list is always `RDF.nil`.

  """
  def new(list, opts \\ []) do
    with head  = Keyword.get(opts, :head,  RDF.bnode),
         graph = Keyword.get(opts, :graph, RDF.graph),
      do: do_new(list, head, graph, opts)
  end

  defp do_new([], _, graph, _) do
    {RDF.nil, graph}
  end

  defp do_new(list, head, graph, opts) when is_atom(head) do
    do_new(list, RDF.uri(head), graph, opts)
  end

  defp do_new([list | rest], head, graph, opts) when is_list(list) do
    with {nested_list_node, graph} = do_new(list, RDF.bnode, graph, opts) do
      do_new([nested_list_node | rest], head, graph, opts)
    end
  end

  defp do_new([first | rest], head, graph, opts) do
    with {next, graph} = do_new(rest, RDF.bnode, graph, opts) do
      {
        head,
        Graph.add(graph,
          head
          |> RDF.first(first)
          |> RDF.rest(next)
        )
      }
    end
  end

  def new!(list, opts \\ []) do
    with {_, graph} = new(list, opts), do: graph
  end

  @doc """
  Converts a RDF list from a graph to native Elixir list.

  Except for nested lists, the values of the list are not further converted, but
  returned as RDF types, i.e. `RDF.Literal`s etc.

  When the given node does not refer to a valid list in the given graph the
  function returns `nil`.
  """
  def to_native(list_node, graph)
  def to_native(@rdf_nil, _),  do: []

  def to_native(list_node, graph) do
    if valid?(list_node, graph) do # TODO: This is not very efficient, we're traversing the list twice ...
      do_to_native(list_node, graph)
    end
  end


  defp do_to_native(list_node, graph, acc \\ []) do
    with description when not is_nil(description) <-
                    Graph.description(graph, list_node),
         [first] <- Description.get(description, RDF.first),
         [rest]  <- Description.get(description, RDF.rest)
    do
      first = if node?(first, graph), do: to_native(first, graph), else: first
      if rest == RDF.nil do
        [first | acc] |> Enum.reverse
      else
        do_to_native(rest, graph, [first | acc])
      end
    end
  end


  @doc """
  Checks if the given resource is a RDF list node in the given graph.

  Although, technically a resource is a list, if it uses at least one `rdf:first`
  or `rdf:rest`, we pragmatically require the usage of both.

  Note: This function doesn't indicate if the list is valid. See `valid?/2` for that.
  """
  def node?(list_node, graph)

  def node?(@rdf_nil, _),
    do: true

  def node?(%BlankNode{} = list_node, graph),
    do: do_node?(list_node, graph)

  def node?(%URI{} = list_node, graph),
    do: do_node?(list_node, graph)

  def node?(list_node, graph)
    when is_atom(list_node) and not list_node in ~w[true false nil]a,
    do: do_node?(RDF.uri(list_node), graph)

  def node?(_, _), do: false

  defp do_node?(list_node, graph),
    do: graph |> Graph.description(list_node) |> node?

  @doc """
  Checks if the given `RDF.Description` describes a RDF list node.
  """
  def node?(description)

  def node?(nil), do: false

  def node?(%Description{predications: predications}) do
    Map.has_key?(predications, RDF.first) and
      Map.has_key?(predications, RDF.rest)
  end


  @doc """
  Checks if the given resource is a valid RDF list in the given graph.

  A valid list

  - consists of list nodes which are all blank nodes and have exactly one
    `rdf:first` and `rdf:rest` statement each
  - does not contain any circles, i.e. `rdf:rest` statements don't refer to
    preceding list nodes
  """
  def valid?(list_node, graph)
  def valid?(@rdf_nil, _), do: true
  def valid?(list_node, graph), do: do_valid?(list_node, graph)

  defp do_valid?(list, graph, preceding_nodes \\ MapSet.new)

  defp do_valid?(%BlankNode{} = list, graph, preceding_nodes) do
    with description when not is_nil(description) <-
                    Graph.description(graph, list),
         [first] <- Description.get(description, RDF.first),
         [rest]  <- Description.get(description, RDF.rest)
    do
      cond do
        rest == @rdf_nil -> true
        MapSet.member?(preceding_nodes, list) -> false
        true -> do_valid?(rest, graph, MapSet.put(preceding_nodes, list))
      end
    else
      nil -> false
      list when is_list(list) -> false
    end
  end

  defp do_valid?(_, _, _), do: false

end
