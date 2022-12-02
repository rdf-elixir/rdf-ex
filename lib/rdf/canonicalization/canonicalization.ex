defmodule RDF.Canonicalization do
  use RDF
  alias RDF.Canonicalization.{IdentifierIssuer, State}
  alias RDF.{BlankNode, Dataset, Quad, Statement, Utils}

  def normalize(input) do
    urdna2015(input)
  end

  defp urdna2015(input) do
    {:ok, issuer_sv} = IdentifierIssuer.Supervisor.start_link()

    try do
      input
      |> State.new()
      |> create_canonical_identifiers_for_single_node_hashes()
      |> create_canonical_identifiers_for_multiple_node_hashes(issuer_sv)
      |> apply_canonicalization(input)
    after
      DynamicSupervisor.stop(issuer_sv)
    end
  end

  # 3)
  defp create_canonical_identifiers_for_single_node_hashes(state) do
    non_normalized_identifiers = Map.keys(state.bnode_to_statements)
    do_create_canonical_identifiers_for_single_node_hashes(state, non_normalized_identifiers)
  end

  # 4)
  defp do_create_canonical_identifiers_for_single_node_hashes(
         state,
         non_normalized_identifiers,
         simple \\ true
       )

  # 5)
  defp do_create_canonical_identifiers_for_single_node_hashes(
         state,
         non_normalized_identifiers,
         true
       ) do
    # 5.2)
    state = State.clear_hash_to_bnodes(state)

    # 5.3) Calculate hashes for first degree nodes
    state =
      Enum.reduce(non_normalized_identifiers, state, fn identifier, state ->
        State.add_bnode_hash(state, identifier, hash_first_degree_quads(state, identifier))
      end)

    # 5.4) Create canonical replacements for hashes mapping to a single node
    {non_normalized_identifiers, state, simple} =
      state.hash_to_bnodes
      |> Enum.sort()
      |> Enum.reduce({non_normalized_identifiers, state, false}, fn
        {hash, identifier_list}, {non_normalized_identifiers, state, simple} ->
          case MapSet.to_list(identifier_list) do
            [identifier] ->
              state = State.issue_canonical_identifier(state, identifier)

              {
                List.delete(non_normalized_identifiers, identifier),
                State.delete_bnode_hash(state, hash),
                true
              }

            [] ->
              raise "unexpected empty identifier list"

            _ ->
              {non_normalized_identifiers, state, simple}
          end
      end)

    do_create_canonical_identifiers_for_single_node_hashes(
      state,
      non_normalized_identifiers,
      simple
    )
  end

  defp do_create_canonical_identifiers_for_single_node_hashes(state, _, false), do: state

  # 6)
  defp create_canonical_identifiers_for_multiple_node_hashes(state, issuer_sv) do
    state.hash_to_bnodes
    |> Enum.sort()
    |> Enum.reduce(state, fn {_hash, identifier_list}, state ->
      # 6.1-2) Create a hash_path_list for all bnodes using a temporary identifier used to create canonical replacements
      identifier_list
      |> Enum.reduce([], fn identifier, hash_path_list ->
        if IdentifierIssuer.State.issued?(state.canonical_issuer, identifier) do
          hash_path_list
        else
          temporary_issuer = IdentifierIssuer.Supervisor.new_issuer(issuer_sv, "_:b")
          IdentifierIssuer.issue_identifier(temporary_issuer, identifier)

          [
            hash_n_degree_quads(state, identifier, temporary_issuer, issuer_sv)
            | hash_path_list
          ]
        end
      end)
      |> Enum.sort()
      # 6.3) Create canonical replacements for nodes
      |> Enum.reduce(state, fn {_hash, issuer}, state ->
        issuer
        |> IdentifierIssuer.issued_identifiers()
        |> Enum.reduce(state, &State.issue_canonical_identifier(&2, &1))
      end)
    end)
  end

  # 7)
  defp apply_canonicalization(state, data) do
    Enum.reduce(data, Dataset.new(), fn statement, canonicalized_data ->
      Dataset.add(
        canonicalized_data,
        if Statement.has_bnode?(statement) do
          Statement.map(statement, fn
            {_, %BlankNode{} = bnode} ->
              state.canonical_issuer
              |> IdentifierIssuer.State.identifier(bnode)
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

  # see https://www.w3.org/community/reports/credentials/CG-FINAL-rdf-dataset-canonicalization-20221009/#hash-first-degree-quads
  defp hash_first_degree_quads(state, ref_bnode_id) do
    state.bnode_to_statements
    |> Map.get(ref_bnode_id, [])
    |> Enum.map(fn statement ->
      statement
      |> Quad.new()
      |> Statement.map(fn
        {_, ^ref_bnode_id} -> ~B<a>
        {_, %BlankNode{}} -> ~B<z>
        {_, node} -> node
      end)
      |> RDF.dataset()
      |> NQuads.write_string!()
    end)
    |> Enum.sort()
    |> Enum.join()
    |> hash()

    # |> IO.inspect(label: "1deg: node: #{inspect(ref_bnode_id)}, hash_first_degree_quads")
  end

  # see https://www.w3.org/community/reports/credentials/CG-FINAL-rdf-dataset-canonicalization-20221009/#hash-related-blank-node
  defp hash_related_bnode(state, related, statement, issuer, position) do
    identifier =
      IdentifierIssuer.State.identifier(state.canonical_issuer, related) ||
        IdentifierIssuer.identifier(issuer, related) ||
        hash_first_degree_quads(state, related)

    input = to_string(position)

    input =
      if position != :g do
        "#{input}<#{Statement.predicate(statement)}>"
      else
        input
      end <> identifier

    hash(input)
    # |> IO.inspect(label: "hrel: input: #{inspect(input)}, hash_related_bnode")
  end

  # see https://www.w3.org/community/reports/credentials/CG-FINAL-rdf-dataset-canonicalization-20221009/#hash-n-degree-quads
  def hash_n_degree_quads(state, identifier, issuer, issuer_sv) do
    # IO.inspect(identifier, label: "ndeg: identifier")

    # 1-3)
    hash_to_related_bnodes =
      Enum.reduce(state.bnode_to_statements[identifier], %{}, fn statement, map ->
        Map.merge(
          map,
          hash_related_statement(state, identifier, statement, issuer),
          fn _, terms, new -> terms ++ new end
        )
      end)

    # |> IO.inspect(label: "ndeg: hash_to_related_bnodes")

    {data_to_hash, issuer} =
      hash_to_related_bnodes
      |> Enum.sort()
      |> Enum.reduce({"", issuer}, fn
        {related_hash, bnode_list}, {data_to_hash, issuer} ->
          # 5.1)
          data_to_hash = data_to_hash <> related_hash
          chosen_path = ""
          chosen_issuer = nil

          # 5.2-4)
          {chosen_path, chosen_issuer} =
            bnode_list
            |> Utils.permutations()
            |> Enum.reduce({chosen_path, chosen_issuer}, fn
              permutation, {chosen_path, chosen_issuer} ->
                # IO.inspect(permutation, label: "ndeg: perm")

                issuer_copy = IdentifierIssuer.Supervisor.copy_issuer(issuer_sv, issuer)
                chosen_path_length = String.length(chosen_path)

                # 5.4.4)
                {path, recursion_list} =
                  Enum.reduce_while(permutation, {"", []}, fn
                    related, {path, recursion_list} ->
                      {path, recursion_list} =
                        if issued_identifier =
                             IdentifierIssuer.State.identifier(state.canonical_issuer, related) do
                          {path <> issued_identifier, recursion_list}
                        else
                          if issued_identifier = IdentifierIssuer.identifier(issuer_copy, related) do
                            {path <> issued_identifier, recursion_list}
                          else
                            {
                              path <> IdentifierIssuer.issue_identifier(issuer_copy, related),
                              [related | recursion_list]
                            }
                          end
                        end

                      if chosen_path_length != 0 and
                           String.length(path) >= chosen_path_length and
                           path > chosen_path do
                        {:halt, {path, recursion_list}}
                      else
                        {:cont, {path, recursion_list}}
                      end
                  end)

                # IO.puts("ndeg: related_hash: #{related_hash}, path: #{path}, recursion: #{inspect(recursion_list)}")

                # 5.4.5)
                {issuer_copy, path} =
                  recursion_list
                  |> Enum.reverse()
                  |> Enum.reduce_while({issuer_copy, path}, fn related, {issuer_copy, path} ->
                    # Note: The following steps are the only steps in the whole algorithm which really seem to rely on global state.
                    {result_hash, result_issuer} =
                      hash_n_degree_quads(state, related, issuer_copy, issuer_sv)

                    path =
                      path <>
                        IdentifierIssuer.issue_identifier(issuer_copy, related) <>
                        "<#{result_hash}>"

                    if chosen_path_length != 0 and
                         String.length(path) >= chosen_path_length and
                         path > chosen_path do
                      {:halt, {result_issuer, path}}
                    else
                      {:cont, {result_issuer, path}}
                    end
                  end)

                if chosen_path_length == 0 or path < chosen_path do
                  {path, issuer_copy}
                else
                  {chosen_path, chosen_issuer}
                end
            end)

          # 5.5)
          {data_to_hash <> chosen_path, chosen_issuer}
      end)

    # IO.puts("ndeg: datatohash: #{data_to_hash}, hash: #{hash(data_to_hash)}")

    {hash(data_to_hash), issuer}
  end

  # 4.8.2.3.1) Group adjacent bnodes by hash
  defp hash_related_statement(state, identifier, statement, issuer) do
    [
      s: Statement.subject(statement),
      o: Statement.object(statement),
      g: Statement.graph_name(statement)
    ]
    |> Enum.reduce(%{}, fn
      {_, ^identifier}, map ->
        map

      {pos, %BlankNode{} = term}, map ->
        hash = hash_related_bnode(state, term, statement, issuer, pos)

        Map.update(map, hash, [term], fn terms ->
          if term in terms, do: terms, else: [term | terms]
        end)

      _, map ->
        map
    end)
  end

  defp hash(data) do
    :crypto.hash(:sha256, data) |> Base.encode16(case: :lower)
  end
end
