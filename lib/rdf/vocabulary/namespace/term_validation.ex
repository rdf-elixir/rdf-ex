defmodule RDF.Vocabulary.Namespace.TermValidation do
  @moduledoc false

  import RDF.Namespace.Builder, only: [valid_characters?: 1, reserved_term?: 1]

  alias RDF.Vocabulary.Namespace.TermMapping
  alias RDF.Vocabulary.Namespace.TermMapping.InvalidTermError

  def validate(term_mapping) do
    {invalid_terms, invalid_characters} =
      Enum.reduce(term_mapping.terms, {[], []}, fn
        {term, _}, {invalid_terms, invalid_character_terms} ->
          cond do
            reserved_term?(term) -> {[term | invalid_terms], invalid_character_terms}
            not valid_characters?(term) -> {invalid_terms, [term | invalid_character_terms]}
            true -> {invalid_terms, invalid_character_terms}
          end
      end)

    term_mapping
    |> handle_reserved_terms(invalid_terms)
    |> handle_invalid_characters(invalid_characters)
  end

  defp handle_reserved_terms(term_mapping, []), do: term_mapping

  defp handle_reserved_terms(%{invalid_term_handling: :ignore} = term_mapping, invalid_terms) do
    TermMapping.ignore_terms(term_mapping, invalid_terms)
  end

  defp handle_reserved_terms(%{invalid_term_handling: :fail} = term_mapping, invalid_terms) do
    TermMapping.add_error(term_mapping, InvalidTermError, """
    The following terms can not be used, because they conflict with reserved Elixir terms:

    - #{Enum.join(invalid_terms, "\n- ")}

    You have the following options:

    - define an alias with the :alias option on defvocab
    - ignore the resource with the :ignore option on defvocab

    """)
  end

  defp handle_invalid_characters(term_mapping, []), do: term_mapping

  defp handle_invalid_characters(
         %{invalid_character_handling: :fail} = term_mapping,
         invalid_terms
       ) do
    TermMapping.add_error(term_mapping, InvalidTermError, """
    The following terms contain invalid characters:

    - #{invalid_terms |> Enum.sort() |> Enum.join("\n- ")}

    You have the following options:

    - if you are in control of the vocabulary, consider renaming the resource
    - define an alias with the :alias option on defvocab
    - change the handling of invalid characters with the :invalid_characters option on defvocab
    - ignore the resource with the :ignore option on defvocab
    """)
  end

  defp handle_invalid_characters(
         %{invalid_character_handling: :ignore} = term_mapping,
         invalid_terms
       ) do
    TermMapping.ignore_terms(term_mapping, invalid_terms)
  end

  defp handle_invalid_characters(
         %{invalid_character_handling: :warn} = term_mapping,
         invalid_terms
       ) do
    Enum.each(
      invalid_terms,
      &TermMapping.warn(
        term_mapping,
        "ignoring term '#{&1}', since it contains invalid characters"
      )
    )

    TermMapping.ignore_terms(term_mapping, invalid_terms)
  end
end
