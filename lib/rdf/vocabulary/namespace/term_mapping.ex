defmodule RDF.Vocabulary.Namespace.TermMapping do
  @moduledoc false

  import RDF.Namespace.Builder, only: [valid_term?: 1, valid_characters?: 1, reserved_term?: 1]
  import RDF.Vocabulary, only: [term_to_iri: 2]

  def normalize_terms(module, terms, ignored_terms, strict, opts) do
    aliases =
      opts
      |> Keyword.get(:alias, [])
      |> Keyword.new(fn {alias, original_term} ->
        {normalize_term(alias), normalize_term(original_term)}
      end)

    terms = Map.new(terms, &{normalize_term(&1), true})

    normalized_terms =
      Enum.reduce(aliases, terms, fn {alias, original_term}, terms ->
        cond do
          reserved_term?(alias) ->
            raise RDF.Namespace.InvalidAliasError,
                  "alias '#{alias}' in vocabulary namespace #{module} is a reserved term and can't be used as an alias"

          not valid_characters?(alias) ->
            raise RDF.Namespace.InvalidAliasError,
                  "alias '#{alias}' in vocabulary namespace #{module} contains invalid characters"

          Map.get(terms, alias) == true ->
            raise RDF.Namespace.InvalidAliasError,
                  "alias '#{alias}' in vocabulary namespace #{module} already defined"

          strict and not Map.has_key?(terms, original_term) ->
            raise RDF.Namespace.InvalidAliasError,
                  "term '#{original_term}' is not a term in vocabulary namespace #{module}"

          Map.get(terms, original_term, true) != true ->
            raise RDF.Namespace.InvalidAliasError,
                  "'#{original_term}' is already an alias in vocabulary namespace #{module}"

          true ->
            if alias in ignored_terms do
              IO.warn("ignoring alias '#{alias}' in vocabulary namespace #{module}")
            end

            if valid_term?(original_term) and original_term not in ignored_terms do
              terms
            else
              Map.delete(terms, original_term)
            end
            |> Map.put(alias, normalize_aliased_term(original_term))
        end
      end)
      |> Map.drop(MapSet.to_list(ignored_terms))

    {normalized_terms, aliases}
  end

  def term_mapping(base_uri, terms, ignored_terms) do
    Enum.flat_map(terms, fn
      {term, true} ->
        [{term, term_to_iri(base_uri, term)}]

      {term, original} ->
        iri = term_to_iri(base_uri, original)
        original = normalize_term(original)

        if valid_term?(original) and original not in ignored_terms do
          [{term, iri}, {original, iri}]
        else
          [{term, iri}]
        end
    end)
  end

  def normalize_term(term) when is_atom(term), do: term
  def normalize_term(term) when is_binary(term), do: String.to_atom(term)
  def normalize_term(term), do: raise(RDF.Namespace.InvalidTermError, inspect(term))

  def normalize_aliased_term(term) when is_binary(term), do: term
  def normalize_aliased_term(term) when is_atom(term), do: Atom.to_string(term)

  def normalize_ignored_terms(terms), do: MapSet.new(terms, &normalize_term/1)

  def extract_aliases(terms, opts) do
    aliases = opts |> Keyword.get(:alias, []) |> Keyword.new()

    {terms, aliases} =
      Enum.reduce(terms, {[], aliases}, fn
        {_, term} = alias, {terms, aliases} -> {[term | terms], [alias | aliases]}
        term, {terms, aliases} -> {[term | terms], aliases}
      end)

    {terms, Keyword.put(opts, :alias, aliases)}
  end

  def aliases(terms) do
    for {alias, term} <- terms, term != true, do: alias
  end

  def validate!({terms, ignored_terms}, opts) do
    {invalid_terms, invalid_characters} =
      Enum.reduce(terms, {[], []}, fn
        {term, _}, {invalid_terms, invalid_character_terms} ->
          cond do
            reserved_term?(term) ->
              {[term | invalid_terms], invalid_character_terms}

            not valid_characters?(term) ->
              {invalid_terms, [term | invalid_character_terms]}

            true ->
              {
                invalid_terms,
                invalid_character_terms
              }
          end
      end)

    {terms, ignored_terms}
    |> handle_invalid_terms!(
      invalid_terms,
      Keyword.get(opts, :invalid_terms, :fail)
    )
    |> handle_invalid_characters!(
      invalid_characters,
      Keyword.get(opts, :invalid_characters, :fail)
    )
  end

  defp handle_invalid_terms!(terms_and_ignored, [], _), do: terms_and_ignored

  defp handle_invalid_terms!({terms, aliases}, invalid_terms, :ignore) do
    {Map.drop(terms, invalid_terms), MapSet.union(aliases, MapSet.new(invalid_terms))}
  end

  defp handle_invalid_terms!(_, invalid_terms, :fail) do
    raise RDF.Namespace.InvalidTermError, """
    The following terms can not be used, because they conflict with the Elixir semantics:

    - #{Enum.join(invalid_terms, "\n- ")}

    You have the following options:

    - define an alias with the :alias option on defvocab
    - ignore the resource with the :ignore option on defvocab
    """
  end

  defp handle_invalid_characters!(terms_and_ignored, [], _), do: terms_and_ignored

  defp handle_invalid_characters!({terms, ignored_terms}, invalid_terms, :ignore) do
    {Map.drop(terms, invalid_terms), MapSet.union(ignored_terms, MapSet.new(invalid_terms))}
  end

  defp handle_invalid_characters!(_, invalid_terms, :fail) do
    raise RDF.Namespace.InvalidTermError, """
    The following terms contain invalid characters:

    - #{Enum.join(invalid_terms, "\n- ")}

    You have the following options:

    - if you are in control of the vocabulary, consider renaming the resource
    - define an alias with the :alias option on defvocab
    - change the handling of invalid characters with the :invalid_characters option on defvocab
    - ignore the resource with the :ignore option on defvocab
    """
  end

  defp handle_invalid_characters!(terms_and_ignored, invalid_terms, :warn) do
    Enum.each(invalid_terms, fn term ->
      IO.warn("'#{term}' is not valid term, since it contains invalid characters")
    end)

    terms_and_ignored
  end
end
