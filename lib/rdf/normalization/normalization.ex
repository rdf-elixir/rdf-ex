defmodule RDF.Normalization do
  @moduledoc """
  RDF normalization algorithm.

  This is an implementation of the Universal RDF Dataset Normalization Algorithm 2015
  or URDNA2015 as specified in <https://json-ld.github.io/normalization/spec/>.
  """

  alias RDF.Normalization.IssueIdentifier
  alias RDF.{Statement, Quad, BlankNode, NQuads, Data, Dataset}

  import RDF.Sigils

  #  use GenServer

  # Client API

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

  #  def normalize(input) do
  #    # TODO: We're passing in the input although not used - it's passed again on the call
  #    with {:ok, pid} <- start_link(input) do
  #      try do
  #        GenServer.call(pid, {:normalize, input})
  #      after
  #        stop(pid)
  #      end
  #    end
  #  end
  #
  #  defp start_link(data, opts \\ []) do
  #    GenServer.start_link(__MODULE__, data, opts)
  #  end
  #
  #  defp stop(pid, reason \\ :normal, timeout \\ :infinity) do
  #    GenServer.stop(pid, reason, timeout)
  #  end
  #
  #  #  def init(init_arg) do
  #  #    {:ok, init_arg}
  #  #  end

  # TODO: Why were these commented out? We were transition to a GenServer containing the state
  def bnode_to_statements(state), do: Agent.get(state, & &1.bnode_to_statements)
  def hash_to_bnodes(state), do: Agent.get(state, & &1.hash_to_bnodes)
  def canonical_issuer(state), do: Agent.get(state, & &1.canonical_issuer)

  # -------------------------------

  # Server Callbacks

  #  def handle_call({:normalize, data}, _, state) do
  #    {:reply, urdna2015(data), state}
  #  end

  defp init_state(data) do
    %{
      #      bnode_to_statements: init_bnode_to_statements(data),
      #      hash_to_bnodes: %{}
      #      canonical_issuer: IssueIdentifier.start_link("_:c14n")
    }
  end

  defp clear_hash_to_bnodes(state) do
    Map.put(state, :hash_to_bnodes, %{})
  end

  defp add_bnode_hash(state, bnode, hash) do
    %{
      state
      | hash_to_bnodes:
          Map.update(
            state.hash_to_bnodes,
            hash,
            MapSet.new() |> MapSet.put(bnode),
            &MapSet.put(&1, bnode)
          )
    }
  end

  defp delete_bnode_hash(state, hash) do
    %{state | hash_to_bnodes: Map.delete(state.hash_to_bnodes, hash)}
  end

  # TODO: Problem this contains references to quads according to the spec 2.1)
  defp init_bnode_to_statements(data) do
    Enum.reduce(data, %{}, fn statement, bnode_to_statements ->
      statement
      |> Tuple.to_list()
      |> Enum.filter(&RDF.bnode?/1)
      |> Enum.reduce(bnode_to_statements, fn bnode, bnode_to_statements ->
        Map.update(bnode_to_statements, bnode, [statement], fn statements ->
          [statement | statements]
        end)
      end)
    end)
  end

  defp urdna2015(input) do
    #    state = init_state(input)
    {:ok, canonical_issuer} = IssueIdentifier.start_link("_:c14n")
    bnode_to_statements = init_bnode_to_statements(input)
    hash_to_bnodes = %{}
    # TODO:   create_canonical_identifiers(state)

    hash_to_bnodes
    |> Enum.sort()
    # Iterate over hashs having more than one node
    |> Enum.each(fn {hash, identifier_list} ->
      # Create a hash_path_list for all bnodes using a temporary identifier used to create canonical replacements
      identifier_list
      |> Enum.reduce([], fn identifier, hash_path_list ->
        unless IssueIdentifier.issued?(canonical_issuer, identifier) do
          # TODO: rework and possible parallelize this
          result =
            with {:ok, temporary_issuer} <- IssueIdentifier.start_link("_:b") do
              IssueIdentifier.issue_identifier(temporary_issuer, identifier)

              hash_n_degree_quads(
                canonical_issuer,
                bnode_to_statements,
                identifier,
                temporary_issuer
              )
            end

          [result | hash_path_list]
        else
          hash_path_list
        end
      end)
      |> Enum.sort()
      # Create canonical replacements for nodes
      |> Enum.each(fn {_hash, issuer} ->
        issuer
        |> IssueIdentifier.issued()
        |> Enum.each(&IssueIdentifier.issue_identifier(canonical_issuer, &1))
      end)

      # TODO: stop the created temporary issuers
    end)

    # TODO: stop the created canonical_issuer
    canonicalize(input, canonical_issuer)
  end

  defp create_canonical_identifiers(state) do
    non_normalized_identifiers = state.bnode_to_statements |> Map.keys()
    do_create_canonical_identifiers(state, non_normalized_identifiers)
  end

  defp do_create_canonical_identifiers(state, non_normalized_identifiers, simple \\ true)

  defp do_create_canonical_identifiers(state, non_normalized_identifiers, true) do
    state = clear_hash_to_bnodes(state)

    # Calculate hashes for first degree nodes
    # TODO: Can this be parallelized?
    Enum.each(non_normalized_identifiers, fn identifier ->
      add_bnode_hash(state, identifier, hash_first_degree_quads(state, identifier))
    end)

    # Create canonical replacements for hashes mapping to a single node
    {non_normalized_identifiers, simple} =
      hash_to_bnodes(state)
      |> Enum.sort()
      |> Enum.reduce(
        {non_normalized_identifiers, false},
        fn {hash, identifier_list}, {non_normalized_identifiers, simple} ->
          case MapSet.to_list(identifier_list) do
            [node] ->
              # TODO: id is actually not needed, so, couldn't this be handled async?
              id =
                canonical_issuer(state)
                |> IssueIdentifier.issue_identifier(node)

              #                log_debug("single node") {"node: #{node.to_ntriples}, hash: #{hash}, id: #{id}"}
              delete_bnode_hash(state, hash)
              {List.delete(non_normalized_identifiers, node), true}

            [] ->
              # TODO: handle this case properly
              raise "empty identifier list"

            _ ->
              {non_normalized_identifiers, simple}
          end
        end
      )

    do_create_canonical_identifiers(state, non_normalized_identifiers, simple)
  end

  defp do_create_canonical_identifiers(_state, _non_normalized_identifiers, false), do: nil

  # TODO: generalize this to RDF.Data
  defp canonicalize(data, canonical_issuer) do
    Enum.reduce(data, Dataset.new(), fn statement, canonicalized_data ->
      canonicalized_data
      |> Dataset.add(
        if Statement.has_bnode?(statement) do
          Statement.map(statement, fn
            {_, %BlankNode{} = bnode} ->
              canonical_issuer
              |> IssueIdentifier.issued_identifier(bnode)
              # TODO: Can we get rid of this slicing?
              |> String.slice(2..-1)
              |> BlankNode.new()

            {_, node} ->
              node
          end)
        else
          statement
        end
      )
    end)
  end

  @doc !"<https://json-ld.github.io/normalization/spec/#hash-first-degree-quads>"
  defp hash_first_degree_quads(bnode_to_statements, ref_bnode_id) do
    bnode_to_statements
    |> Map.get(ref_bnode_id, [])
    |> Enum.map(fn statement ->
      statement
      |> Quad.new()
      |> Statement.map(fn
        # TODO: see note in the spec: "potential need to normalize literals to their canonical representation here as well, if not done on the original input dataset"
        {_, ^ref_bnode_id} -> ~B<a>
        {_, %BlankNode{}} -> ~B<z>
        {_, node} -> node
      end)
      |> NQuads.write_string!()
    end)
    |> Enum.sort()
    |> Enum.join()
    |> hash()
    |> IO.inspect(label: "node: #{inspect(ref_bnode_id)}, hash_first_degree_quads:")
  end

  @doc !"<https://json-ld.github.io/normalization/spec/#hash-related-blank-node>"
  defp hash_related_bnode(
         canonical_issuer,
         bnode_to_statements,
         related,
         statement,
         issuer,
         position
       ) do
    identifier =
      IssueIdentifier.issue_identifier(canonical_issuer, related) ||
        IssueIdentifier.issue_identifier(issuer, related) ||
        hash_first_degree_quads(bnode_to_statements, related)

    input = Integer.to_string(position)

    input =
      if position != :g do
        "#{input}<#{Statement.predicate(statement)}>"
      else
        input
      end <> identifier

    hash(input)
    |> IO.inspect(label: "input: #{inspect(input)}, hash_related_bnode: ")
  end

  @doc !"<https://json-ld.github.io/normalization/spec/#hash-n-degree-quads>"
  # TODO: follow the recommendation in this issue:
  # "An additional input to this algorithm should be added that allows it to be optionally skipped
  # and throw an error if any equivalent related hashes were produced that must be permuted during
  # step 5.4.4. For practical uses of the algorithm, this step should never be encountered and could
  # be turned off, disabling canonizing datasets that include a need to run it as a security measure."
  def hash_n_degree_quads(canonical_issuer, bnode_to_statements, identifier, issuer) do
    # 1-3)
    hash_to_related_blank_nodes_map =
      bnode_to_statements[identifier]
      |> Enum.reduce(%{}, fn statement, map ->
        Map.merge(
          map,
          hash_related_statement(
            canonical_issuer,
            bnode_to_statements,
            identifier,
            statement,
            issuer
          ),
          fn _, terms, new -> terms ++ new end
        )
      end)

    {data_to_hash, _, issuer} =
      hash_to_related_blank_nodes_map
      |> Enum.sort()
      |> Enum.reduce({"", "", nil}, fn
        {related_hash, bnode_list}, {data_to_hash, chosen_path, chosen_issuer} ->
          # 5.1)
          data_to_hash = data_to_hash <> related_hash

          # 5.2-4)
          {chosen_path, chosen_issuer} =
            bnode_list
            |> permutations()
            |> Enum.reduce({chosen_path, chosen_issuer}, fn
              permutation, {chosen_path, chosen_issuer} ->
                issuer_copy = IssueIdentifier.copy(issuer)
                chosen_path_length = String.length(chosen_path)
                # 5.4.4)
                {path, recursion_list} =
                  Enum.reduce_while(permutation, {"", []}, fn related, {path, recursion_list} ->
                    {path, recursion_list} =
                      canonical_issuer
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

                    if chosen_path_length == 0 or String.length(path) < chosen_path_length do
                      {:cont, {path, recursion_list}}
                    else
                      {:halt, {path, recursion_list}}
                    end
                  end)

                {issuer_copy, path} =
                  recursion_list
                  |> Enum.reverse()
                  |> Enum.reduce_while(
                    {issuer_copy, path},
                    fn related, {issuer_copy, path} ->
                      {result_hash, result_issuer} =
                        hash_n_degree_quads(
                          canonical_issuer,
                          bnode_to_statements,
                          related,
                          issuer_copy
                        )

                      path =
                        path <>
                          IssueIdentifier.issue_identifier(issuer_copy, related) <>
                          "<#{hd(result_hash)}>"

                      issuer_copy = result_issuer

                      if chosen_path_length == 0 or
                           String.length(path) < chosen_path_length or
                           path <= chosen_path do
                        {:cont, {issuer_copy, path}}
                      else
                        {:halt, {issuer_copy, path}}
                      end
                    end
                  )

                if chosen_path_length == 0 or path < chosen_path do
                  {path, issuer_copy}
                else
                  {chosen_path, chosen_issuer}
                end
            end)

          # 5.5)
          {data_to_hash <> chosen_path, chosen_path, chosen_issuer}
      end)

    {hash(data_to_hash), issuer}
  end

  # 4.8.2.3.1) Group adjacent bnodes by hash
  defp hash_related_statement(
         canonical_issuer,
         bnode_to_statements,
         identifier,
         statement,
         issuer
       ) do
    %{
      s: Statement.subject(statement),
      p: Statement.predicate(statement),
      o: Statement.object(statement),
      g: Statement.graph_name(statement)
    }
    |> Enum.reduce(%{}, fn
      {_, ^identifier}, map ->
        map

      {pos, term}, map ->
        hash =
          hash_related_bnode(canonical_issuer, bnode_to_statements, term, statement, issuer, pos)

        Map.update(map, hash, [term], fn terms ->
          # TODO: Check if order is irrelevant here and we can prepend here
          if term in terms, do: terms, else: terms ++ [term]
        end)
    end)
  end

  defp hash(data) do
    :crypto.hash(:sha256, data) |> Base.encode16(case: :lower)
  end

  def permutations([]), do: [[]]

  def permutations(list) do
    for elem <- list, rest <- permutations(list -- [elem]), do: [elem | rest]
  end
end
