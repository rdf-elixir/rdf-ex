defmodule RDF.Isomorphic do
  @moduledoc """
  RDF Graph comparison algorithm.

  Two graphs are isomorphic, if they are structurally equal, ignoring blank node
  identifiers.

  Kudos to [rdf-isomorphic](https://github.com/ruby-rdf/rdf-isomorphic) whose implementation of
  [Jeremy J. Carroll: "Matching RDF Graphs", 2001](http://www.hpl.hp.com/techreports/2001/HPL-2001-293.pdf)
  this is a port of.
  See also <http://blog.datagraph.org/2010/03/rdf-isomorphism>.
  """

  alias RDF.{Graph, Statement, BlankNode}


  @doc """
  Checks if two graphs are isomorphic.

  When option `canonicalize: true` is set, `RDF.Literals` will be
  canonicalized while producing a bijection.  This results in broader
  matches for isomorphism in the case of equivalent literals with different
  representations.
  """
  def isomorphic_graphs?(%Graph{} = graph1, %Graph{} = graph2, opts \\ []) do
#    graph1 == graph2
    not is_nil(bnode_bijection(graph1, graph2, opts))
  end

  @doc """
  Returns a map of `RDF.BlankNode`s to `RDF.BlankNode`s, representing an
  isomorphic bijection between the blank nodes of the given graphs, or `nil` if
  a bijection cannot be found.

  When option `canonicalize: true` is set, `RDF.Literals` will be
  canonicalized while producing a bijection.  This results in broader
  matches for isomorphism in the case of equivalent literals with different
  representations.
  """
  def bnode_bijection(%Graph{} = graph1, %Graph{} = graph2, opts \\ []) do
    with statements1 = Graph.triples(graph1), statements2 = Graph.triples(graph2) do
      if Enum.count(statements1) == Enum.count(statements2) and
          Enum.all?(statements1, fn statement ->
            Statement.has_bnode?(statement) or Graph.include?(graph2, statement)
          end) do
        # blank_statements1 and blank_statements2 are just a performance consideration.
        # We will be iterating over this list quite a bit during the algorithm,
        # so we break it down to the parts we're interested in.
        blank_statements1 = Stream.filter(statements1, &Statement.has_bnode?/1) |> Enum.map(&Tuple.to_list/1)
        blank_statements2 = Stream.filter(statements2, &Statement.has_bnode?/1) |> Enum.map(&Tuple.to_list/1)
        nodes1 = blank_nodes_in(blank_statements1)
        nodes2 = blank_nodes_in(blank_statements2)
#        build_bijection_to(blank_statements1, nodes1, blank_statements2, nodes2, {}, {}, opts)

      end
    end
  end

  defp build_bijection_to(statements1, nodes1, statements2, nodes2,
        grounded_hashes1 \\ %{}, grounded_hashes2 \\ %{}, opts \\ %{}) do

    # Create a hash signature of every node, based on the signature of
    # statements it exists in.
    # We also save hashes of nodes that cannot be reliably known; we will use
    # that information to eliminate possible recursion combinations.
    #
    # Any mappings given in the functions parameters are considered grounded.
    {hashes1, ungrounded_hashes1} = hash_nodes(statements1, nodes1, grounded_hashes1, opts[:canonicalize])
    {hashes2, ungrounded_hashes2} = hash_nodes(statements2, nodes2, grounded_hashes2, opts[:canonicalize])


  end

  defp blank_nodes_in(statements) do
    Enum.reduce statements, MapSet.new, fn(statement, blank_nodes) ->
      statement
      |> Enum.filter(fn
          %BlankNode{} -> true
          _            -> false
         end)
      |> Enum.reduce(blank_nodes, fn(blank_node, blank_nodes) ->
           MapSet.put(blank_nodes, blank_node)
         end)
    end
  end

  # Given a set of statements, create a mapping of node => SHA1 for a given
  # set of blank nodes.  grounded_hashes is a mapping of node => SHA1 pairs
  # that we will take as a given, and use those to make more specific
  # signatures of other nodes.
  #
  # Returns a tuple of hashes:  one of grounded hashes, and one of all
  # hashes.  grounded hashes are based on non-blank nodes and grounded blank
  # nodes, and can be used to determine if a node's signature matches
  # another.
  #
  defp hash_nodes(statements, nodes, grounded_hashes, canonicalize \\ false) do
#    hashes = grounded_hashes.dup
#    ungrounded_hashes = {}
#    hash_needed = true
#
#    # We may have to go over the list multiple times.  If a node is marked as
#    # grounded, other nodes can then use it to decide their own state of
#    # grounded.
#    while hash_needed
#      starting_grounded_nodes = hashes.size
#      nodes.each do | node |
#        unless hashes.member? node
#          grounded, hash = node_hash_for(node, statements, hashes, canonicalize)
#          if grounded
#            hashes[node] = hash
#          end
#          ungrounded_hashes[node] = hash
#        end
#      end
#      # after going over the list, any nodes with a unique hash can be marked
#      # as grounded, even if we have not tied them back to a root yet.
#      uniques = {}
#      ungrounded_hashes.each do |node, hash|
#        uniques[hash] = uniques.has_key?(hash) ? false : node
#      end
#      uniques.each do |hash, node|
#        hashes[node] = hash if node
#      end
#      hash_needed = starting_grounded_nodes != hashes.size
#    end
#    [hashes,ungrounded_hashes]
  end

  # Generate a hash for a node based on the signature of the statements it
  # appears in. Signatures consist of grounded elements in statements
  # associated with a node, that is, anything but an ungrounded anonymous
  # node. Creating the hash is simply hashing a sorted list of each
  # statement's signature, which is itself a concatenation of the string form
  # of all grounded elements.
  #
  # Nodes other than the given node are considered grounded if they are a
  # member in the given hash.
  #
  # Returns a tuple consisting of grounded being true or false and the String
  # for the hash
  defp node_hash_for(node, statements, hashes, canonicalize) do
    {statement_signatures, grounded} =
      Enum.reduce(statements, {[], true},
        fn (statement, {statement_signatures, grounded}) ->
          if Enum.include?(statement, node) do
            # TODO: The original implementation seems broken with respect to the grounded flag, so we set it temporarily to false
            {[hash_string_for(statement, hashes, node, canonicalize) | statement_signatures], false}
          else
            {statement_signatures, grounded}
          end
        end)
    # Note that we sort the signatures--without a canonical ordering,
    # we might get different hashes for equivalent nodes.
#    [grounded, Digest::SHA1.hexdigest(statement_signatures.sort.to_s)]
#    [grounded, :crypto.hash(:sha, statement_signatures |> Enum.sort |> to_string)]
    [grounded, :erlang.phash2(statement_signatures |> Enum.sort |> to_string)]
  end

  # Provide a string signature for the given statement, collecting
  # string signatures for grounded node elements.
  defp hash_string_for(statement, hashes, node, canonicalize) do
    statement
    |> Enum.map(fn element -> string_for_node(element, hashes, node, canonicalize) end)
    |> Enum.join
  end

  # Provides a string for the given node for use in a string signature
  # Non-anonymous nodes will return their string form.  Grounded anonymous
  # nodes will return their hashed form.
  defp string_for_node(node, hashes, target, canonicalize) do
    case node do
      nil          -> ""
      ^target      -> "itself"
      %BlankNode{} ->
        if Map.has_key?(hashes, node) do
          hashes[node]
        else
          "a blank node"
        end
      # TODO
      # RDF.rb auto-boxing magic makes some literals the same when they
      # should not be; the ntriples serializer will take care of us
#      when node.literal?
#        node.class.name + RDF::NTriples.serialize(canonicalize ? node.canonicalize : node)
      _ ->
        to_string(node)
    end
  end

  # Returns true if a given node is grounded
  # A node is grounded if it is not a blank node or it is included in the given
  # mapping of grounded nodes.
  def grounded?(%BlankNode{} = node, hashes), do: Map.has_key?(hashes, node)
  def grounded?(_, _),                        do: true

end
