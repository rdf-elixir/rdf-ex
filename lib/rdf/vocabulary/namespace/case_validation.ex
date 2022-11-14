defmodule RDF.Vocabulary.Namespace.CaseValidation do
  @moduledoc false

  defmodule CaseViolationError do
    defexception [:message, label: "Case violations"]
  end

  import RDF.Utils, only: [downcase?: 1]

  alias RDF.Vocabulary.Namespace.TermMapping

  def validate_case(term_mapping)

  def validate_case(%{term_classification: nil} = term_mapping), do: term_mapping

  def validate_case(%{case_violation_handling: :ignore} = term_mapping), do: term_mapping

  def validate_case(term_mapping) do
    handle_case_violations(term_mapping, detect_case_violations(term_mapping))
  end

  defp detect_case_violations(term_mapping) do
    Enum.filter(term_mapping.terms, fn
      {term, true} ->
        if term not in term_mapping.aliased_terms,
          do: improper_case?(term_mapping, Atom.to_string(term), term)

      {term, original_term} ->
        improper_case?(term_mapping, Atom.to_string(term), String.to_atom(original_term))
    end)
  end

  defp improper_case?(_, "_" <> _, _), do: false

  defp improper_case?(%{allow_lowercase_resource_terms: false} = term_mapping, term, original) do
    case term_mapping.term_classification[original] do
      :property -> not downcase?(term)
      :resource -> downcase?(term)
      nil -> downcase?(term)
    end
  end

  defp improper_case?(%{allow_lowercase_resource_terms: true} = term_mapping, term, original) do
    term_mapping.term_classification[original] == :property and not downcase?(term)
  end

  defp group_case_violations(violations) do
    violations
    |> Enum.group_by(fn
      {term, true} -> if downcase?(term), do: :lowercased_term, else: :capitalized_term
      {term, _original} -> if downcase?(term), do: :lowercased_alias, else: :capitalized_alias
    end)
  end

  defp handle_case_violations(term_mapping, []), do: term_mapping

  defp handle_case_violations(term_mapping, violations) do
    do_handle_case_violations(
      term_mapping,
      group_case_violations(violations),
      term_mapping.case_violation_handling
    )
  end

  defp do_handle_case_violations(term_mapping, grouped_violations, _)
       when map_size(grouped_violations) == 0,
       do: term_mapping

  defp do_handle_case_violations(term_mapping, violations, :fail) do
    resource_name_violations = fn violations ->
      Enum.map_join(violations, "\n- ", fn {term, true} ->
        term_mapping |> TermMapping.term_to_iri(term) |> to_string()
      end)
    end

    alias_violations = fn violations ->
      Enum.map_join(violations, "\n- ", fn {term, original} ->
        "alias #{term} for #{TermMapping.term_to_iri(term_mapping, original)}"
      end)
    end

    violation_error_lines =
      Enum.map_join(violations, fn
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

    TermMapping.add_error(term_mapping, CaseViolationError, """
    #{violation_error_lines}
    You have the following options:

    - if you are in control of the vocabulary, consider renaming the resource
    - define a properly cased alias with the :alias option on defvocab
    - change the handling of case violations with the :case_violations option on defvocab
    - ignore the resource with the :ignore option on defvocab
    """)
  end

  defp do_handle_case_violations(term_mapping, violation_groups, :warn) do
    for {type, violations} <- violation_groups,
        {term, original} <- violations do
      case_violation_warning(type, term, original, term_mapping)
    end

    term_mapping
  end

  defp do_handle_case_violations(term_mapping, violation_groups, :auto_fix) do
    do_handle_case_violations(term_mapping, violation_groups, &auto_fix_term/2)
  end

  defp do_handle_case_violations(term_mapping, violation_groups, fun)
       when is_function(fun) do
    {alias_violations, term_violations} =
      Map.split(violation_groups, [:capitalized_alias, :lowercased_alias])

    term_mapping = do_handle_case_violations(term_mapping, alias_violations, :fail)

    Enum.reduce(term_violations, term_mapping, fn {group, violations}, term_mapping ->
      type =
        case group do
          :capitalized_term -> :property
          :lowercased_term -> :resource
        end

      Enum.reduce(violations, term_mapping, fn {term, _}, term_mapping ->
        case fun.(type, Atom.to_string(term)) do
          :ignore -> TermMapping.ignore_term(term_mapping, term)
          {:error, error} -> raise error
          {:ok, alias} -> TermMapping.add_alias(term_mapping, term, alias)
        end
      end)
    end)
  end

  defp do_handle_case_violations(term_mapping, violation_groups, {mod, fun})
       when is_atom(mod) and is_atom(fun) do
    do_handle_case_violations(term_mapping, violation_groups, &apply(mod, fun, [&1, &2]))
  end

  defp do_handle_case_violations(term_mapping, violation_groups, {mod, fun, args})
       when is_atom(mod) and is_atom(fun) and is_list(args) do
    do_handle_case_violations(term_mapping, violation_groups, &apply(mod, fun, [&1, &2 | args]))
  end

  defp case_violation_warning(:capitalized_term, term, _, term_mapping) do
    IO.warn("'#{TermMapping.term_to_iri(term_mapping, term)}' is a capitalized property")
  end

  defp case_violation_warning(:lowercased_term, term, _, term_mapping) do
    IO.warn(
      "'#{TermMapping.term_to_iri(term_mapping, term)}' is a lowercased non-property resource"
    )
  end

  defp case_violation_warning(:capitalized_alias, term, _, _) do
    IO.warn("capitalized alias '#{term}' for a property")
  end

  defp case_violation_warning(:lowercased_alias, term, _, _) do
    IO.warn("lowercased alias '#{term}' for a non-property resource")
  end

  defp auto_fix_term(:property, term) do
    {first, rest} = String.next_grapheme(term)
    {:ok, String.downcase(first) <> rest}
  end

  defp auto_fix_term(:resource, term), do: {:ok, :string.titlecase(term)}
end
