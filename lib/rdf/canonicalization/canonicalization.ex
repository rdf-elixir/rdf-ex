defmodule RDF.Canonicalization do
  @moduledoc """
  An implementation of the standard RDF Dataset Canonicalization Algorithm.

  See <https://www.w3.org/TR/rdf-canon/>.
  """

  alias RDF.Canonicalization.{IdentifierIssuer, State}
  alias RDF.{BlankNode, Dataset, Quad, Statement, NQuads, Utils}

  import RDF.Sigils

  @hash_algorithm_config_doc """
  - `:hash_algorithm`: Allows to set the hash algorithm to be used. Any of the `:crypto.hash_algorithm()`
    values is allowed. Defaults to the runtime configured `:canon_hash_algorithm` of the `:rdf`
    application or `:sha256` of not configured otherwise.

        config :rdf,
          canon_hash_algorithm: :sha512

  """

  @doc """
  Canonicalizes the blank nodes of a graph or dataset according to the RDF Dataset Canonicalization spec.

  This function always returns a `RDF.Dataset`. If you want to canonicalize a `RDF.Graph` and
  get a `RDF.Graph` back, use `RDF.Graph.canonicalize/2`.

  ## Options

  #{@hash_algorithm_config_doc}

  ## Example

      iex> RDF.Graph.new([{~B<foo>, EX.p(), ~B<bar>}, {~B<bar>, EX.p(), ~B<foo>}])
      ...> |> RDF.Canonicalization.canonicalize()
      RDF.Dataset.new([{~B<c14n0>, EX.p(), ~B<c14n1>}, {~B<c14n1>, EX.p(), ~B<c14n0>}])

  """
  @spec canonicalize(RDF.Graph.t() | RDF.Dataset.t(), keyword) :: RDF.Dataset.t()
  def canonicalize(input, opts \\ []) do
    rdfc10(input, opts)
  end

  @doc """
  Checks whether two graphs or datasets are equal, regardless of the concrete names of the blank nodes they contain.

  ## Options

  #{@hash_algorithm_config_doc}

  ## Examples

      iex> RDF.Graph.new([{~B<foo>, EX.p(), ~B<bar>}, {~B<bar>, EX.p(), 42}])
      ...> |> RDF.Canonicalization.isomorphic?(
      ...>      RDF.Graph.new([{~B<b1>, EX.p(), ~B<b2>}, {~B<b2>, EX.p(), 42}]))
      true

      iex> RDF.Graph.new([{~B<foo>, EX.p(), ~B<bar>}, {~B<bar>, EX.p(), 42}])
      ...> |> RDF.Canonicalization.isomorphic?(
      ...>      RDF.Graph.new([{~B<b1>, EX.p(), ~B<b2>}, {~B<b3>, EX.p(), 42}]))
      false
  """
  @spec isomorphic?(RDF.Graph.t() | RDF.Dataset.t(), RDF.Graph.t() | RDF.Dataset.t(), keyword) ::
          boolean
  def isomorphic?(a, b, opts \\ []) do
    a |> canonicalize(opts) |> Dataset.equal?(canonicalize(b, opts))
  end

  defp rdfc10(input, opts) do
    input
    |> State.new(opts)
    |> create_canonical_identifiers_for_single_node_hashes()
    |> create_canonical_identifiers_for_multiple_node_hashes()
    |> apply_canonicalization(input)
  end

  defp create_canonical_identifiers_for_single_node_hashes(state) do
    # 3) Calculate hashes for first degree nodes
    state =
      Enum.reduce(state.bnode_to_quads, state, fn {n, _}, state ->
        State.add_bnode_hash(state, n, hash_first_degree_quads(state, n))
      end)

    # 4) Create canonical replacements for hashes mapping to a single node
    state.hash_to_bnodes
    # TODO: "Sort in Unicode code point order"
    |> Enum.sort()
    |> Enum.reduce(state, fn {hash, identifier_list}, state ->
      case MapSet.to_list(identifier_list) do
        [identifier] ->
          state
          |> State.issue_canonical_identifier(identifier)
          |> State.delete_bnode_hash(hash)

        [] ->
          raise "unexpected empty identifier list"

        _ ->
          state
      end
    end)
  end

  # 5)
  defp create_canonical_identifiers_for_multiple_node_hashes(state) do
    state.hash_to_bnodes
    |> Enum.sort()
    |> Enum.reduce(state, fn {_hash, identifier_list}, state ->
      # 5.1-2) Create a hash_path_list for all bnodes using a temporary identifier used to create canonical replacements
      identifier_list
      |> Enum.reduce([], fn identifier, hash_path_list ->
        if IdentifierIssuer.issued?(state.canonical_issuer, identifier) do
          hash_path_list
        else
          {_issued_identifier, temporary_issuer} =
            "b"
            |> IdentifierIssuer.new()
            |> IdentifierIssuer.issue_identifier(identifier)

          [
            hash_n_degree_quads(state, identifier, temporary_issuer)
            | hash_path_list
          ]
        end
      end)
      |> Enum.sort()
      # 5.3) Create canonical replacements for nodes
      |> Enum.reduce(state, fn {_hash, issuer}, state ->
        issuer
        |> IdentifierIssuer.issued_identifiers()
        |> Enum.reduce(state, &State.issue_canonical_identifier(&2, &1))
      end)
    end)
  end

  # 6)
  defp apply_canonicalization(state, data) do
    Enum.reduce(data, Dataset.new(), fn statement, canonicalized_data ->
      Dataset.add(
        canonicalized_data,
        if Statement.has_bnode?(statement) do
          Statement.map(statement, fn
            {_, %BlankNode{} = bnode} ->
              state.canonical_issuer
              |> IdentifierIssuer.identifier(bnode)
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

  # see https://www.w3.org/TR/rdf-canon/#hash-1d-quads
  defp hash_first_degree_quads(state, ref_bnode_id) do
    state.bnode_to_quads
    |> Map.get(ref_bnode_id, [])
    |> Enum.map(fn quads ->
      quads
      |> Quad.new()
      |> Statement.map(fn
        {_, ^ref_bnode_id} -> ~B<a>
        {_, %BlankNode{}} -> ~B<z>
        {_, node} -> node
      end)
      |> Dataset.new()
      |> NQuads.write_string!()
    end)
    # TODO: "Sort nquads in Unicode code point order"
    |> Enum.sort()
    |> Enum.join()
    |> hash(state)

    # |> IO.inspect(label: "1deg: node: #{inspect(ref_bnode_id)}, hash_first_degree_quads")
  end

  # see https://www.w3.org/TR/rdf-canon/#hash-related-blank-node
  defp hash_related_bnode(state, related, quad, issuer, position) do
    input = to_string(position)

    input =
      if position != :g do
        "#{input}<#{Statement.predicate(quad)}>"
      else
        input
      end <>
        if identifier =
             IdentifierIssuer.identifier(state.canonical_issuer, related) ||
               IdentifierIssuer.identifier(issuer, related) do
          "_:" <> identifier
        else
          hash_first_degree_quads(state, related)
        end

    hash(input, state)
    # |> IO.inspect(label: "hrel: input: #{inspect(input)}, hash_related_bnode")
  end

  # see https://www.w3.org/TR/rdf-canon/#hash-nd-quads
  def hash_n_degree_quads(state, identifier, issuer) do
    # IO.inspect(identifier, label: "ndeg: identifier")

    # 1-3)
    # hash_to_related_bnodes is called now H_n in the new spec
    hash_to_related_bnodes =
      Enum.reduce(state.bnode_to_quads[identifier], %{}, fn quad, map ->
        Map.merge(
          map,
          hash_related_quad(state, identifier, quad, issuer),
          fn _, terms, new -> terms ++ new end
        )
      end)

    # |> IO.inspect(label: "ndeg: hash_to_related_bnodes")

    {data_to_hash, issuer} =
      hash_to_related_bnodes
      # TODO: "Sort in Unicode code point order"
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

                issuer_copy = IdentifierIssuer.copy(issuer)
                chosen_path_length = String.length(chosen_path)

                # 5.4.4)
                {path, recursion_list, issuer_copy} =
                  Enum.reduce_while(permutation, {"", [], issuer_copy}, fn
                    related, {path, recursion_list, issuer_copy} ->
                      {path, recursion_list, issuer_copy} =
                        if issued_identifier =
                             IdentifierIssuer.identifier(state.canonical_issuer, related) do
                          {path <> "_:" <> issued_identifier, recursion_list, issuer_copy}
                        else
                          if issued_identifier = IdentifierIssuer.identifier(issuer_copy, related) do
                            {path <> "_:" <> issued_identifier, recursion_list, issuer_copy}
                          else
                            {issued_identifier, issuer_copy} =
                              IdentifierIssuer.issue_identifier(issuer_copy, related)

                            {
                              path <> "_:" <> issued_identifier,
                              [related | recursion_list],
                              issuer_copy
                            }
                          end
                        end

                      # TODO: considering code point order
                      if chosen_path_length != 0 and
                           String.length(path) >= chosen_path_length and
                           path > chosen_path do
                        {:halt, {path, recursion_list, issuer_copy}}
                      else
                        {:cont, {path, recursion_list, issuer_copy}}
                      end
                  end)

                # IO.puts("ndeg: related_hash: #{related_hash}, path: #{path}, recursion: #{inspect(recursion_list)}")

                # 5.4.5)
                {issuer_copy, path} =
                  recursion_list
                  |> Enum.reverse()
                  |> Enum.reduce_while({issuer_copy, path}, fn related, {issuer_copy, path} ->
                    # Note: The following steps seem to be the only steps in the whole algorithm
                    # which really rely on global state.

                    # 5.4.5.1)
                    {result_hash, result_issuer} =
                      hash_n_degree_quads(state, related, issuer_copy)

                    # This step was added to circumvent the need for global state.
                    # It's unclear whether it is actually required, since all test
                    # of the test suite pass without it.
                    # see https://github.com/w3c-ccg/rdf-dataset-canonicalization/issues/31
                    result_issuer =
                      if result_issuer.id == issuer_copy.id do
                        {_, issuer} = IdentifierIssuer.issue_identifier(result_issuer, related)
                        issuer
                      else
                        result_issuer
                      end

                    # 5.4.5.2)
                    {issued_identifier, _issuer_copy} =
                      IdentifierIssuer.issue_identifier(issuer_copy, related)

                    path = path <> "_:" <> issued_identifier <> "<#{result_hash}>"

                    # TODO: considering code point order
                    if chosen_path_length != 0 and
                         String.length(path) >= chosen_path_length and
                         path > chosen_path do
                      {:halt, {result_issuer, path}}
                    else
                      {:cont, {result_issuer, path}}
                    end
                  end)

                # TODO: considering code point order
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

    {hash(data_to_hash, state), issuer}
  end

  # 4.8.2.3.1) Group adjacent bnodes by hash
  defp hash_related_quad(state, identifier, quad, issuer) do
    [
      s: Statement.subject(quad),
      o: Statement.object(quad),
      g: Statement.graph_name(quad)
    ]
    |> Enum.reduce(%{}, fn
      {_, ^identifier}, map ->
        map

      {pos, %BlankNode{} = term}, map ->
        hash = hash_related_bnode(state, term, quad, issuer, pos)

        Map.update(map, hash, [term], fn terms ->
          if term in terms, do: terms, else: [term | terms]
        end)

      _, map ->
        map
    end)
  end

  defp hash(data, state) do
    :crypto.hash(state.hash_algorithm, data) |> Base.encode16(case: :lower)
  end
end
