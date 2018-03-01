defmodule RDF.Normalization do
  @moduledoc """
  RDF normalization algorithm.

  This is an implementation of the Universal RDF Dataset Normalization Algorithm 2015
  or URDNA2015 as specified in <https://json-ld.github.io/normalization/spec/>.
  """

  alias RDF.Normalization.{IssueIdentifier, State}
  alias RDF.{Statement, Quad, BlankNode, NQuads, Data}

  import RDF.Sigils

  require Logger


#  @doc """
#  Checks if two `RDF.Data` structures are isomorphic.
#
#  Two graphs are isomorphic, if they are structurally equal, ignoring blank node
#  identifiers.
#
#  When option `canonicalize: true` is set, `RDF.Literals` will be
#  canonicalized while producing a bijection.  This results in broader
#  matches for isomorphism in the case of equivalent literals with different
#  representations.
#  """
#  def isomorphic_graphs?(%Graph{} = graph1, %Graph{} = graph2, opts \\ []) do
##    graph1 == graph2
#    not is_nil(bnode_bijection(graph1, graph2, opts))
#  end

  def normalize(input) do
    urdna2015(input)
  end

  defp urdna2015(input) do
    with {:ok, state} <- State.start_link(input) do
      try do
        create_canonical_identifiers(state)

        State.hash_to_bnodes(state)
        |> Enum.sort
        # Iterate over hashs having more than one node
        |> Enum.each(fn {hash, identifier_list} ->
             # Create a hash_path_list for all bnodes using a temporary identifier used to create canonical replacements
             identifier_list
             |> Enum.reduce([], fn identifier, hash_path_list ->
                  unless IssueIdentifier.issued?(State.canonical_issuer(state), identifier) do
                    # TODO: rework and possible parallelize this
                    result =
                      with {:ok, temporary_issuer} <- IssueIdentifier.start_link("_:b") do
                        IssueIdentifier.issue_identifier(temporary_issuer, identifier)
                        hash_n_degree_quads(state, identifier, temporary_issuer)
                      end
                    [result | hash_path_list]
                  else
                    hash_path_list
                  end
#        |> IO.puts("-> hash_path_list: #{hash_path_list.map(&:first).inspect}")

                end)
             |> Enum.sort
             # Create canonical replacements for nodes
             |> Enum.each(fn {hash, issuer} ->
                  issuer
                  |> IssueIdentifier.issued
                  |> Enum.each(fn bnode ->
                       state
                       |> State.canonical_issuer()
                       |> IssueIdentifier.issue_identifier(node)
                     end)
                end)
              # TODO: stop the created temporary issuers
           end)

        canonicalize(state, input)

      after
        State.stop(state)
      end
    end
  end


  defp create_canonical_identifiers(state) do
    with non_normalized_identifiers = State.bnode_to_statements(state) |> Map.keys do
      do_create_canonical_identifiers(state, non_normalized_identifiers)
    end
  end

  defp do_create_canonical_identifiers(state, non_normalized_identifiers, simple \\ true)
  defp do_create_canonical_identifiers(state, non_normalized_identifiers, true) do
    State.clear_hash_to_bnodes(state)

    # Calculate hashes for first degree nodes
    # TODO: Can this be parallelized?
    Enum.each non_normalized_identifiers, fn identifier ->
      hash = hash_first_degree_quads(state, identifier)
      Logger.debug fn -> "1deg: hash: #{hash}" end
      State.add_bnode_hash state, identifier, hash
    end

    # Create canonical replacements for hashes mapping to a single node
    {non_normalized_identifiers, simple} =
      State.hash_to_bnodes(state)
      |> Enum.sort
      |> Enum.reduce({non_normalized_identifiers, false},
          fn {hash, identifier_list}, {non_normalized_identifiers, simple} ->
            case MapSet.to_list(identifier_list) do
              [node] ->
                id = # TODO: id is actually not needed, so, couldn't this be handled async?
                  State.canonical_issuer(state)
                  |> IssueIdentifier.issue_identifier(node)
                Logger.debug fn -> "single node: node: #{inspect node}, hash: #{hash}, id: #{inspect id}" end
                State.delete_bnode_hash(state, hash)
                {List.delete(non_normalized_identifiers, node), true}
              [] ->
                raise "empty identifier list" # TODO: handle this case properly
              _ ->
                {non_normalized_identifiers, simple}
            end
          end)

    do_create_canonical_identifiers(state, non_normalized_identifiers, simple)
  end
  defp do_create_canonical_identifiers(state, non_normalized_identifiers, false), do: nil


  # 4.4.2: step 7)
  # TODO: generalize this to RDF.Data
  defp canonicalize(state, data) do
    Enum.reduce data, RDF.Dataset.new, fn statement, canonicalized_data ->
        canonicalized_data
        |> RDF.Dataset.add(
             if Statement.has_bnode?(statement) do
               Statement.map statement, fn
                 %BlankNode{} = bnode ->
                   state
                   |> State.canonical_issuer()
                   |> IssueIdentifier.issued_identifier(bnode)
                   |> String.slice(2..-1)
                   |> BlankNode.new
                 node ->
                   node
               end
             else
               statement
             end)
    end
  end



  @doc """
  <https://json-ld.github.io/normalization/spec/#hash-first-degree-quads>
  """
  defp hash_first_degree_quads(state, node) do
    State.bnode_to_statements(state)
    |> Map.get(node, [])
    |> Enum.map(fn statement ->
         statement
         |> Quad.new
         |> Statement.map(fn
              ^node        -> ~B<a>
              %BlankNode{} -> ~B<z>
              node         -> node
            end)
         |> RDF.Dataset.new
         |> NQuads.write_string!
       end)
    |> Enum.sort
    |> Enum.join
    |> hash()
#    |> IO.inspect(label: "node: #{inspect node}, hash_first_degree_quads:")
  end


  @doc """
  <https://json-ld.github.io/normalization/spec/#hash-related-blank-node>
  """
  defp hash_related_bnode(state, related, statement, issuer, position) do
    with identifier =
          (state |> State.canonical_issuer() |> IssueIdentifier.issue_identifier(related)) ||
          (issuer |> IssueIdentifier.issue_identifier(related)) ||
          hash_first_degree_quads(state, related),
         input = to_string(position),
         input = (
           if position != :g do
             "#{input}<#{Statement.predicate(statement)}>"
           else
             input
           end <> identifier)
    do
      hash(input)
      |> IO.inspect(label: "input: #{inspect input}, hash_related_bnode: ")
    end
  end


  @doc """
  <https://json-ld.github.io/normalization/spec/#hash-n-degree-quads>
  """
  def hash_n_degree_quads(state, identifier, issuer) do
    hash_to_related_blank_nodes_map =
      Enum.reduce State.bnode_to_statements(state)[identifier], %{}, fn statement, map ->
        Map.merge map, hash_related_statement(state, identifier, statement, issuer),
          fn(_, terms, new) -> terms ++ new end
      end

    {data_to_hash, _, issuer} =
      hash_to_related_blank_nodes_map
      |> Enum.sort
      |> Enum.reduce({"", "", nil}, fn
           {related_hash, bnode_list}, {data_to_hash, chosen_path, chosen_issuer} ->
             {chosen_path, chosen_issuer} =
               bnode_list
               |> permutations()
               |> Enum.reduce({chosen_path, chosen_issuer}, fn
                    permutation, {chosen_path, chosen_issuer} ->
                      {:ok, issuer_copy} = IssueIdentifier.copy(issuer)

                      {path, recursion_list} = Enum.reduce_while permutation, {"", []},
                        fn related, {path, recursion_list} ->
                          {path, recursion_list} =
                            state
                            |> State.canonical_issuer()
                            |> IssueIdentifier.issued_identifier(related)
                            |> case do
                                 nil ->
                                   case IssueIdentifier.issued_identifier(issuer_copy, related) do
                                     nil ->
                                       {
                                         path <> IssueIdentifier.issue_identifier(issuer_copy, related),
                                         [related | recursion_list]
                                       }
                                     issued_identifier ->
                                       {path <> issued_identifier, recursion_list}
                                   end
                                 issued_identifier ->
                                   {path <> issued_identifier, recursion_list}
                               end

                          if chosen_path == "" or String.length(path) < String.length(chosen_path) do
                            {:cont, {path, recursion_list}}
                          else
                            {:halt, {path, recursion_list}}
                          end
                        end

                      {issuer_copy, path} =
                        recursion_list
                        |> Enum.reverse
                        |> Enum.reduce_while({issuer_copy, path},
                             fn related, {issuer_copy, path} ->
                               {result_hash, result_issuer} =
                                 hash_n_degree_quads(state, related, issuer_copy)

                               path = path
                                 <> IssueIdentifier.issue_identifier(issuer_copy, related)
                                 <> "<#{hd(result_hash)}>"
                               issuer_copy = result_issuer

                               if chosen_path == "" or
                                  String.length(path) < String.length(chosen_path) or
                                  path <= chosen_path do
                                 {:cont, {issuer_copy, path}}
                               else
                                 {:halt, {issuer_copy, path}}
                               end
                             end)

                      if chosen_path == "" or path < chosen_path do
                        {path, issuer_copy}
                      else
                        {chosen_path, chosen_issuer}
                      end
                    end)

             {data_to_hash <> chosen_path, chosen_path, chosen_issuer}
         end)

     {hash(data_to_hash), issuer}
  end

  # 4.8.2.3.1) Group adjacent bnodes by hash
  defp hash_related_statement(state, identifier, statement, issuer) do
    %{
      s: Statement.subject(statement),
      p: Statement.predicate(statement),
      o: Statement.object(statement),
      g: Statement.graph_name(statement),
    }
    |> Enum.reduce(%{}, fn
        ({_, ^identifier}, map) -> map
        ({pos, term}, map) ->
          hash = hash_related_bnode(state, term, statement, issuer, pos)
          Map.update(map, hash, [term], fn terms ->
            if term in terms, do: terms, else: terms ++ [term]
          end)
       end)
  end


  defp hash(data) do
    :crypto.hash(:sha256, data) |> Base.encode16(case: :lower)
  end

  defp permutations([]), do: [[]]
  defp permutations(list) do
    for elem <- list, rest <- permutations(list -- [elem]),
      do: [elem|rest]
  end

end
