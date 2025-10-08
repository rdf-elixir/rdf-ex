defmodule RDF.Graph.Reachability do
  @moduledoc !"""
             Graph reachability algorithm.

             This module provides functions for computing reachable subgraphs.
             """

  alias RDF.{Graph, BlankNode}

  import RDF.Guards

  @reachable_doc """
  Computes the reachable subgraph by traversing from a starting node.

  This function computes a form of forward reachability closure with
  configurable traversal constraints.

  ## Parameters

  - `graph`: The RDF graph to traverse
  - `resource`: The starting node for traversal (supports coercible resources like namespace terms and also RDF-star quoted triples)
  - `follow_fun_or_opts`: Either a custom follow function or keyword options (optional, defaults to `follow: :all`)

  ## Follow Function

  A custom follow function can be provided either:

  - As the third argument directly: `reachable(graph, resource, follow_fun)`
  - Via the `:follow` option: `reachable(graph, resource, follow: follow_fun)`

  The follow function receives three parameters:
    
  1. `object`: The object node of the current triple (potential next node to visit)
  2. `predicate`: The predicate of the current triple
  3. `depth`: Current depth of traversal (starting node has depth 0, its neighbors depth 1, etc.)

  Returns `true` to follow the node, `false` to skip it.

  **Note**: When providing a custom follow function directly as the third argument,
  it cannot be combined with other options (except `:into`). Use the `:follow` keyword
  option if you need to combine it with other options.

  ## Keyword Options

  - `:follow` - Traversal strategy or custom function:
    - `:all` - Follow all nodes (complete reachability) (default)
    - `:bnodes` - Only follow blank nodes (similar to Concise Bounded Description)
    - custom function with arity 3 - See "Follow Function" section above
  - `:max_depth` - Maximum traversal depth for all nodes (integer or `:unlimited`, default: `:unlimited`)
  - `:bnode_depth` - Maximum traversal depth for blank nodes (integer or `:unlimited`, defaults to the value of `max_depth`)
  - `:predicates` - List of predicates to follow (only edges with these predicates are traversed)
  - `:into` - Target graph to write results into (default: empty graph)

  ## Examples

  Complete reachability (using default):

      iex> graph = RDF.Graph.new([
      ...>   {EX.A, EX.p(), EX.B},
      ...>   {EX.B, EX.p(), EX.C},
      ...>   {EX.D, EX.p(), EX.E}
      ...> ])
      iex> RDF.Graph.reachable(graph, EX.A)
      RDF.Graph.new([
        {EX.A, EX.p(), EX.B},
        {EX.B, EX.p(), EX.C}
      ])

  Only follow blank nodes (similar to Concise Bounded Description):

      iex> graph = RDF.Graph.new([
      ...>   {EX.A, EX.p(), ~B<b1>},
      ...>   {EX.A, EX.q(), EX.B},
      ...>   {~B<b1>, EX.r(), ~B<b2>},
      ...>   {EX.B, EX.s(), EX.C}
      ...> ])
      iex> RDF.Graph.reachable(graph, EX.A, follow: :bnodes)
      RDF.Graph.new([
        {EX.A, EX.p(), ~B<b1>},
        {EX.A, EX.q(), EX.B},
        {~B<b1>, EX.r(), ~B<b2>}
      ])

  With maximum depth and unlimited blank nodes:

      iex> graph = RDF.Graph.new([
      ...>   {EX.A, EX.p(), EX.B},
      ...>   {EX.B, EX.p(), EX.C},
      ...>   {EX.B, EX.p(), ~B<b1>},
      ...>   {~B<b1>, EX.p(), ~B<b2>},
      ...>   {~B<b2>, EX.p(), EX.C},
      ...>   {EX.C, EX.p(), EX.D}
      ...> ])
      iex> RDF.Graph.reachable(graph, EX.A, max_depth: 1, bnode_depth: :unlimited)
      RDF.Graph.new([
        {EX.A, EX.p(), EX.B},
        {EX.B, EX.p(), EX.C},
        {EX.B, EX.p(), ~B<b1>},
        {~B<b1>, EX.p(), ~B<b2>},
        {~B<b2>, EX.p(), EX.C}
      ])

  With custom follow function (as third argument):

      iex> alias RDF.NS.RDFS
      iex> graph = RDF.Graph.new([
      ...>   {EX.A, RDFS.subClassOf(), EX.B},
      ...>   {EX.A, EX.other(), EX.C},
      ...>   {EX.B, RDFS.subClassOf(), EX.D}
      ...> ])
      iex> RDF.Graph.reachable(graph, EX.A, fn _obj, pred, depth ->
      ...>   pred == RDFS.subClassOf() and depth <= 2
      ...> end)
      RDF.Graph.new([
        {EX.A, RDFS.subClassOf(), EX.B},
        {EX.A, EX.other(), EX.C},
        {EX.B, RDFS.subClassOf(), EX.D}
      ])

  Writing into an existing graph:

      iex> target = RDF.Graph.new({EX.Existing, EX.p(), EX.O}, name: EX.MyGraph)
      iex> graph = RDF.Graph.new([
      ...>   {EX.A, EX.p(), EX.B},
      ...>   {EX.B, EX.p(), EX.C}
      ...> ])
      iex> RDF.Graph.reachable(graph, EX.A, into: target)
      RDF.Graph.new([
        {EX.Existing, EX.p(), EX.O},
        {EX.A, EX.p(), EX.B},
        {EX.B, EX.p(), EX.C}
      ], name: EX.MyGraph)

  """
  def reachable_doc, do: @reachable_doc

  def reachable(graph, resource, follow_fun_or_opts \\ [])

  def reachable(graph, resource, follow_fun) when is_function(follow_fun, 3) do
    reachable(graph, resource, follow: follow_fun)
  end

  def reachable(graph, resource, opts) when is_list(opts) do
    {into, opts} = Keyword.pop(opts, :into, Graph.new())
    {follow, opts} = Keyword.pop(opts, :follow, :all)

    follow_fun =
      cond do
        is_function(follow, 3) and opts == [] ->
          follow

        is_function(follow, 3) ->
          raise ArgumentError, "follow function cannot be combined with other options"

        is_function(follow) ->
          raise ArgumentError, "follow function must have arity 3"

        true ->
          build_follow_fun_from_opts(Keyword.put(opts, :follow, follow))
      end

    traverse(graph, [RDF.coerce_subject(resource)], into, follow_fun, 0)
  end

  defp traverse(_graph, [], result, _follow_fun, _depth), do: result

  defp traverse(graph, nodes, result, follow_fun, depth) do
    depth = depth + 1

    {result, next_level_nodes} =
      Enum.reduce(nodes, {result, []}, fn node, {result, next} ->
        if Graph.describes?(result, node) do
          # Already visited, skip
          {result, next}
        else
          node_description = Graph.description(graph, node)

          next_level_nodes =
            Enum.flat_map(node_description, fn
              {_s, _p, o} when is_rdf_literal(o) -> []
              {_s, p, o} -> if follow_fun.(o, p, depth), do: [o], else: []
            end)

          {Graph.add(result, node_description), next_level_nodes}
        end
      end)

    traverse(graph, next_level_nodes, result, follow_fun, depth)
  end

  defp build_follow_fun_from_opts(opts) do
    max_depth = Keyword.get(opts, :max_depth, :unlimited)
    max_bnode_depth = Keyword.get(opts, :bnode_depth, max_depth)
    predicates = Keyword.get(opts, :predicates)

    follow_all? =
      case Keyword.get(opts, :follow, :all) do
        :all -> true
        :bnodes -> false
        invalid -> raise ArgumentError, "invalid follow option: #{inspect(invalid)}"
      end

    unlimited_depth? = max_depth == :unlimited
    unlimited_bnode_depth? = max_bnode_depth == :unlimited
    predicates? = is_nil(predicates)

    fn
      %BlankNode{}, predicate, depth ->
        (unlimited_bnode_depth? or depth <= max_bnode_depth) and
          (predicates? or predicate in predicates)

      _object, predicate, depth ->
        follow_all? and
          (unlimited_depth? or depth <= max_depth) and
          (predicates? or predicate in predicates)
    end
  end
end
