defmodule RDF.List do
  @moduledoc """
  A structure for RDF lists.

  see
  - <https://www.w3.org/TR/rdf-schema/#ch_collectionvocab>
  - <https://www.w3.org/TR/rdf11-mt/#rdf-collections>
  """

  alias RDF.{BlankNode, Description, Graph, IRI, NS}

  import RDF.Guards

  @type t :: %__MODULE__{
          head: IRI.t(),
          graph: Graph.t()
        }

  @enforce_keys [:head]
  defstruct [:head, :graph]

  @rdf_nil RDF.Utils.Bootstrapping.rdf_iri("nil")

  @doc """
  Creates a `RDF.List` for a given RDF list node of a given `RDF.Graph`.

  If the given node does not refer to a well-formed list in the graph, `nil` is
  returned. A well-formed list

  - consists of list nodes which have exactly one `rdf:first` and `rdf:rest`
    statement each
  - does not contain cycles, i.e. `rdf:rest` statements don't refer to
    preceding list nodes
  """
  @spec new(IRI.coercible(), Graph.t()) :: t | nil
  def new(head, graph)

  def new(head, graph) when maybe_ns_term(head),
    do: new(IRI.new(head), graph)

  def new(head, graph) do
    list = %__MODULE__{head: head, graph: graph}

    if well_formed?(list) do
      list
    end
  end

  defp well_formed?(list) do
    Enum.reduce_while(list, MapSet.new(), fn node_description, preceding_nodes ->
      head = node_description.subject

      if MapSet.member?(preceding_nodes, head) do
        {:halt, false}
      else
        {:cont, MapSet.put(preceding_nodes, head)}
      end
    end) && true
  end

  @doc """
  Creates a `RDF.List` from a native Elixir list or any other `Enumerable` with coercible RDF values.

  By default, the statements constituting the `Enumerable` are added to an empty graph. An
  already existing graph to which the statements are added can be specified with
  the `graph` option.

  The name of the head node can be specified with the `head` option
  (default: `RDF.bnode()`, i.e. an arbitrary unique name).
  Note: When the given `Enumerable` is empty, the `name` option will be ignored -
  the head node of the empty list is always `RDF.nil`.

  """
  @spec from(Enumerable.t(), keyword) :: t
  def from(list, opts \\ []) do
    head = Keyword.get(opts, :head, BlankNode.new())
    graph = Keyword.get(opts, :graph, RDF.graph())
    {head, graph} = do_from(list, head, graph, opts)
    %__MODULE__{head: head, graph: graph}
  end

  defp do_from([], _, graph, _) do
    {NS.RDF.nil(), graph}
  end

  defp do_from(list, head, graph, opts) when maybe_ns_term(head) do
    do_from(list, IRI.new!(head), graph, opts)
  end

  defp do_from([list | rest], head, graph, opts) when is_list(list) do
    {nested_list_node, graph} = do_from(list, BlankNode.new(), graph, opts)
    do_from([nested_list_node | rest], head, graph, opts)
  end

  defp do_from([first | rest], head, graph, opts) do
    {next, graph} = do_from(rest, BlankNode.new(), graph, opts)

    {
      head,
      Graph.add(
        graph,
        head
        |> NS.RDF.first(first)
        |> NS.RDF.rest(next)
      )
    }
  end

  defp do_from(enumerable, head, graph, opts) do
    enumerable
    |> Enum.into([])
    |> do_from(head, graph, opts)
  end

  @doc """
  The values of a `RDF.List` as an Elixir list.

  Nested lists are converted recursively.
  """
  @spec values(t) :: Enumerable.t()
  def values(%__MODULE__{graph: graph} = list) do
    Enum.map(list, fn node_description ->
      value = Description.first(node_description, NS.RDF.first())

      if node?(value, graph) do
        value
        |> new(graph)
        |> values
      else
        value
      end
    end)
  end

  @doc """
  The RDF nodes constituting a `RDF.List` as an Elixir list.
  """
  @spec nodes(t) :: [BlankNode.t()]
  def nodes(%__MODULE__{} = list) do
    Enum.map(list, fn node_description -> node_description.subject end)
  end

  @doc """
  Checks if a list is the empty list.
  """
  @spec empty?(t) :: boolean
  def empty?(%__MODULE__{head: @rdf_nil}), do: true
  def empty?(%__MODULE__{}), do: false

  @doc """
  Checks if the given list consists of list nodes which are all blank nodes.
  """
  @spec valid?(t) :: boolean
  def valid?(%__MODULE__{head: @rdf_nil}), do: true
  def valid?(%__MODULE__{} = list), do: Enum.all?(list, &RDF.bnode?(&1.subject))

  @doc """
  Checks if a given resource is an RDF list node in a given `RDF.Graph`.

  Although, technically a resource is a list, if it uses at least one `rdf:first`
  or `rdf:rest`, we pragmatically require the usage of both.

  Note: This function doesn't indicate if the list is valid.
   See `new/2` and `valid?/2` for validations.
  """
  @spec node?(any, Graph.t()) :: boolean
  def node?(list_node, graph)
  def node?(@rdf_nil, _), do: true
  def node?(%BlankNode{} = list_node, graph), do: do_node?(list_node, graph)
  def node?(%IRI{} = list_node, graph), do: do_node?(list_node, graph)

  def node?(list_node, graph) when maybe_ns_term(list_node),
    do: do_node?(IRI.new(list_node), graph)

  def node?(_, _), do: false

  defp do_node?(list_node, graph), do: graph |> Graph.description(list_node) |> node?()

  @doc """
  Checks if the given `RDF.Description` describes an RDF list node.
  """
  def node?(description)

  def node?(nil), do: false

  def node?(%Description{predications: predications}) do
    Map.has_key?(predications, NS.RDF.first()) and
      Map.has_key?(predications, NS.RDF.rest())
  end

  defimpl Enumerable do
    @rdf_nil RDF.Utils.Bootstrapping.rdf_iri("nil")

    def reduce(_, {:halt, acc}, _fun), do: {:halted, acc}
    def reduce(list, {:suspend, acc}, fun), do: {:suspended, acc, &reduce(list, &1, fun)}

    def reduce(%RDF.List{head: @rdf_nil}, {:cont, acc}, _fun),
      do: {:done, acc}

    def reduce(%RDF.List{head: %BlankNode{}} = list, acc, fun),
      do: do_reduce(list, acc, fun)

    def reduce(%RDF.List{head: %IRI{}} = list, acc, fun),
      do: do_reduce(list, acc, fun)

    def reduce(_, _, _), do: {:halted, nil}

    defp do_reduce(%RDF.List{head: head, graph: graph}, {:cont, acc}, fun) do
      with description when not is_nil(description) <-
             Graph.get(graph, head),
           [_] <- Description.get(description, NS.RDF.first()),
           [rest] <- Description.get(description, NS.RDF.rest()) do
        acc = fun.(description, acc)

        if rest == @rdf_nil do
          case acc do
            {:cont, acc} -> {:done, acc}
            # TODO: Is the :suspend case handled properly
            _ -> reduce(%RDF.List{head: rest, graph: graph}, acc, fun)
          end
        else
          reduce(%RDF.List{head: rest, graph: graph}, acc, fun)
        end
      else
        nil ->
          {:halted, nil}

        values when is_list(values) ->
          {:halted, nil}
      end
    end

    def member?(_, _), do: {:error, __MODULE__}
    def count(_), do: {:error, __MODULE__}
    def slice(_), do: {:error, __MODULE__}
  end
end
