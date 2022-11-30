defmodule RDF.Canonicalization do
  use RDF
  alias RDF.Canonicalization.{IdentifierIssuer, State}
  alias RDF.{BlankNode, Dataset, Quad, Statement, Utils}

  def normalize(input) do
    urdna2015(input)
  end

  defp urdna2015(input) do
    state =
      input
      |> State.new()
      |> create_simple_canonical_identifiers()

    # 6)
    canonical_issuer =
      state.hash_to_bnodes
      |> Enum.sort()
      |> Enum.reduce(state.canonical_issuer, fn {hash, identifier_list}, canonical_issuer ->
        # 6.1-2) Create a hash_path_list for all bnodes using a temporary identifier used to create canonical replacements
        identifier_list
        |> Enum.reduce([], fn identifier, hash_path_list ->
          if IdentifierIssuer.issued?(canonical_issuer, identifier) do
            hash_path_list
          else
            {_issued_identifier, temporary_issuer} =
              "_:b"
              |> IdentifierIssuer.new()
              |> IdentifierIssuer.issue_identifier(identifier)

            [
              hash_n_degree_quads(state, identifier, canonical_issuer, temporary_issuer)
              | hash_path_list
            ]
          end
        end)
        |> Enum.sort()
        # 6.3) Create canonical replacements for nodes
        |> Enum.reduce(canonical_issuer, fn {_hash, issuer}, canonical_issuer ->
          issuer
          |> IdentifierIssuer.issued_identifiers()
          |> Enum.reduce(canonical_issuer, fn existing_identifier, canonical_issuer ->
            {_, canonical_issuer} =
              IdentifierIssuer.issue_identifier(canonical_issuer, existing_identifier)

            canonical_issuer
          end)
        end)
      end)

    canonicalize(input, canonical_issuer)
  end

  # 3)
  defp create_simple_canonical_identifiers(state) do
    non_normalized_identifiers = Map.keys(state.bnode_to_statements)
    do_create_simple_canonical_identifiers(state, non_normalized_identifiers)
  end

  # 4)
  defp do_create_simple_canonical_identifiers(state, non_normalized_identifiers, simple \\ true)

  # 5)
  defp do_create_simple_canonical_identifiers(state, non_normalized_identifiers, true) do
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
              {_id, state} = State.issue_canonical_identifier(state, identifier)

              {
                List.delete(non_normalized_identifiers, identifier),
                State.delete_bnode_hash(state, hash),
                true
              }

            [] ->
              # TODO: handle this case properly
              raise "empty identifier list"

            _ ->
              {non_normalized_identifiers, state, simple}
          end
      end)

    do_create_simple_canonical_identifiers(state, non_normalized_identifiers, simple)
  end

  defp do_create_simple_canonical_identifiers(state, _non_normalized_identifiers, false),
    do: state

  # 7)
  defp canonicalize(data, canonical_issuer) do
    Enum.reduce(data, Dataset.new(), fn statement, canonicalized_data ->
      Dataset.add(
        canonicalized_data,
        if Statement.has_bnode?(statement) do
          Statement.map(statement, fn
            {_, %BlankNode{} = bnode} ->
              canonical_issuer
              |> IdentifierIssuer.identifier(bnode)
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

  #################

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
  end

  # see https://www.w3.org/community/reports/credentials/CG-FINAL-rdf-dataset-canonicalization-20221009/#hash-related-blank-node
  defp hash_related_bnode(state, related, statement, canonical_issuer, issuer, position) do
    identifier =
      IdentifierIssuer.identifier(canonical_issuer, related) ||
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
  end

  # see https://www.w3.org/community/reports/credentials/CG-FINAL-rdf-dataset-canonicalization-20221009/#hash-n-degree-quads
  def hash_n_degree_quads(state, identifier, canonical_issuer, issuer) do
    # 1-3)
    hash_to_related_bnodes =
      Enum.reduce(state.bnode_to_statements[identifier], %{}, fn statement, map ->
        Map.merge(
          map,
          hash_related_statement(state, identifier, statement, canonical_issuer, issuer),
          fn _, terms, new -> terms ++ new end
        )
      end)

    {data_to_hash, _, issuer} =
      hash_to_related_bnodes
      |> Enum.sort()
      |> Enum.reduce({"", nil, issuer}, fn
        {related_hash, bnode_list}, {data_to_hash, chosen_path, issuer} ->
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
                issuer_copy = issuer
                chosen_path_length = String.length(chosen_path)
                # 5.4.4)
                {path, recursion_list, issuer_copy} =
                  Enum.reduce_while(permutation, {"", [], issuer_copy}, fn
                    related, {path, recursion_list, issuer_copy} ->
                      {path, recursion_list, issuer_copy} =
                        if issued_identifier =
                             IdentifierIssuer.identifier(canonical_issuer, related) do
                          {path <> issued_identifier, recursion_list, issuer_copy}
                        else
                          if issued_identifier = IdentifierIssuer.identifier(issuer_copy, related) do
                            {path <> issued_identifier, recursion_list, issuer_copy}
                          else
                            {issued_identifier, issuer_copy} =
                              IdentifierIssuer.issue_identifier(issuer_copy, related)

                            {
                              path <> issued_identifier,
                              [related | recursion_list],
                              issuer_copy
                            }
                          end
                        end

                      if chosen_path_length == 0 or String.length(path) < chosen_path_length do
                        {:cont, {path, recursion_list, issuer_copy}}
                      else
                        {:halt, {path, recursion_list, issuer_copy}}
                      end
                  end)

                # 5.4.5)
                {issuer_copy, path} =
                  recursion_list
                  |> Enum.reverse()
                  |> Enum.reduce_while({issuer_copy, path}, fn related, {issuer_copy, path} ->
                    {result_hash, result_issuer} =
                      hash_n_degree_quads(state, related, canonical_issuer, issuer_copy)

                    # TODO: This step doesn't work without global state:
                    # issuing an identifier in the issuer copy which MIGHT be the result_issuer ...
                    # This causes some tests to fail, eg. test023
                    {issued_identifier, issuer_copy} =
                      IdentifierIssuer.issue_identifier(issuer_copy, related)

                    path = path <> issued_identifier <> "<#{result_hash}>"

                    if chosen_path_length == 0 or
                         String.length(path) < chosen_path_length or
                         path <= chosen_path do
                      {:cont, {result_issuer, path}}
                    else
                      {:halt, {result_issuer, path}}
                    end
                  end)

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
  defp hash_related_statement(state, identifier, statement, canonical_issuer, issuer) do
    [
      s: Statement.subject(statement),
      o: Statement.object(statement),
      g: Statement.graph_name(statement)
    ]
    |> Enum.reduce(%{}, fn
      {_, ^identifier}, map ->
        map

      {pos, %BlankNode{} = term}, map ->
        hash = hash_related_bnode(state, term, statement, canonical_issuer, issuer, pos)

        Map.update(map, hash, [term], fn terms ->
          if term in terms, do: terms, else: terms ++ [term]
        end)

      _, map ->
        map
    end)
  end

  defp hash(data) do
    :crypto.hash(:sha256, data) |> Base.encode16(case: :lower)
  end
end
