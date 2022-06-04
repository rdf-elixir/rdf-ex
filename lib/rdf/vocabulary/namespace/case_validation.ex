defmodule RDF.Vocabulary.Namespace.CaseValidation do
  import RDF.Vocabulary, only: [term_to_iri: 2]
  import RDF.Utils, only: [downcase?: 1]

  alias RDF.Utils.ResourceClassifier

  def validate_case!(terms_and_ignored, nil, _, _, _), do: terms_and_ignored

  def validate_case!({terms, ignored_terms}, data, base_iri, aliases, opts) do
    handling = Keyword.get(opts, :case_violations, :warn)

    if handling == :ignore do
      {terms, ignored_terms}
    else
      handle_case_violations(
        {terms, ignored_terms},
        detect_case_violations(terms, data, base_iri, Keyword.values(aliases)),
        handling,
        base_iri
      )
    end
  end

  defp detect_case_violations(terms, data, base_iri, aliased_terms) do
    Enum.filter(terms, fn
      {term, true} -> if term not in aliased_terms, do: improper_case?(term, base_iri, term, data)
      {term, original_term} -> improper_case?(term, base_iri, original_term, data)
    end)
  end

  defp improper_case?(term, base_iri, iri_suffix, data) when is_atom(term),
    do: improper_case?(Atom.to_string(term), base_iri, iri_suffix, data)

  defp improper_case?("_" <> _, _, _, _), do: false

  defp improper_case?(term, base_iri, iri_suffix, data) do
    case ResourceClassifier.property?(term_to_iri(base_iri, iri_suffix), data) do
      true -> not downcase?(term)
      false -> downcase?(term)
      nil -> downcase?(term)
    end
  end

  defp group_case_violations(violations) do
    violations
    |> Enum.group_by(fn
      {term, true} -> if downcase?(term), do: :lowercased_term, else: :capitalized_term
      {term, _original} -> if downcase?(term), do: :lowercased_alias, else: :capitalized_alias
    end)
  end

  defp handle_case_violations(terms_and_ignored, [], _, _), do: terms_and_ignored

  defp handle_case_violations(terms_and_ignored, violations, handling, base_uri) do
    do_handle_case_violations(
      terms_and_ignored,
      group_case_violations(violations),
      handling,
      base_uri
    )
  end

  defp do_handle_case_violations(_, violations, :fail, base_iri) do
    resource_name_violations = fn violations ->
      violations
      |> Enum.map(fn {term, true} -> base_iri |> term_to_iri(term) |> to_string() end)
      |> Enum.join("\n- ")
    end

    alias_violations = fn violations ->
      violations
      |> Enum.map(fn {term, original} ->
        "alias #{term} for #{term_to_iri(base_iri, original)}"
      end)
      |> Enum.join("\n- ")
    end

    violation_error_lines =
      violations
      |> Enum.map(fn
        {:capitalized_term, violations} ->
          """
          Terms for properties should be lowercased, but the following properties are
          capitalized:

          - #{resource_name_violations.(violations)}

          """

        {:lowercased_term, violations} ->
          """
          Terms for non-property resource should be capitalized, but the following
          non-properties are lowercased:

          - #{resource_name_violations.(violations)}

          """

        {:capitalized_alias, violations} ->
          """
          Terms for properties should be lowercased, but the following aliases for
          properties are capitalized:

          - #{alias_violations.(violations)}

          """

        {:lowercased_alias, violations} ->
          """
          Terms for non-property resource should be capitalized, but the following
          aliases for non-properties are lowercased:

          - #{alias_violations.(violations)}

          """
      end)
      |> Enum.join()

    raise RDF.Namespace.InvalidTermError, """
    Case violations detected

    #{violation_error_lines}
    You have the following options:

    - if you are in control of the vocabulary, consider renaming the resource
    - define a properly cased alias with the :alias option on defvocab
    - change the handling of case violations with the :case_violations option on defvocab
    - ignore the resource with the :ignore option on defvocab
    """
  end

  defp do_handle_case_violations(terms_and_ignored, violation_groups, :warn, base_iri) do
    for {type, violations} <- violation_groups,
        {term, original} <- violations do
      case_violation_warning(type, term, original, base_iri)
    end

    terms_and_ignored
  end

  defp case_violation_warning(:capitalized_term, term, _, base_iri) do
    IO.warn("'#{term_to_iri(base_iri, term)}' is a capitalized property")
  end

  defp case_violation_warning(:lowercased_term, term, _, base_iri) do
    IO.warn("'#{term_to_iri(base_iri, term)}' is a lowercased non-property resource")
  end

  defp case_violation_warning(:capitalized_alias, term, _, _) do
    IO.warn("capitalized alias '#{term}' for a property")
  end

  defp case_violation_warning(:lowercased_alias, term, _, _) do
    IO.warn("lowercased alias '#{term}' for a non-property resource")
  end
end
