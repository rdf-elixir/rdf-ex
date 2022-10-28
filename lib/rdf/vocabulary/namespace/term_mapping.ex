defmodule RDF.Vocabulary.Namespace.TermMapping do
  @moduledoc false

  defstruct module: nil,
            base_uri: nil,
            strict: true,
            data: nil,
            terms: %{},
            ignored_terms: MapSet.new(),
            aliased_terms: MapSet.new(),
            invalid_character_handling: :fail,
            invalid_term_handling: :fail,
            case_violation_handling: :warn,
            errors: []

  defmodule InvalidVocabBaseIRIError do
    defexception [:message, label: "Invalid base URI"]
  end

  defmodule InvalidTermError do
    defexception [:message, label: "Invalid terms"]
  end

  defmodule InvalidAliasError do
    defexception [:message, label: "Invalid aliases"]
  end

  defmodule InvalidIgnoreTermError do
    defexception [:message, label: "Invalid ignore terms"]
  end

  import RDF.Namespace.Builder, only: [valid_term?: 1, valid_characters?: 1, reserved_term?: 1]
  import RDF.Vocabulary, only: [term_to_iri: 2]

  alias RDF.{IRI, Namespace}
  alias RDF.Vocabulary.Namespace.{CompileError, TermValidation, CaseValidation}

  def new(module, base_uri, terms, opts \\ []) do
    {terms, opts} = extract_aliases(terms, opts)

    %__MODULE__{
      module: module,
      terms: Map.new(terms, &{normalize_term(&1), true}),
      strict: Keyword.get(opts, :strict, true),
      invalid_character_handling: Keyword.get(opts, :invalid_characters, :fail),
      invalid_term_handling: Keyword.get(opts, :invalid_terms, :fail),
      case_violation_handling: Keyword.get(opts, :case_violations, :warn)
    }
    |> set_base_uri(base_uri)
    |> ignore_terms(Keyword.get(opts, :ignore, []), validate_existence: true)
    |> add_aliases(Keyword.get(opts, :alias, []))
    |> TermValidation.validate()
    |> CaseValidation.validate_case(Keyword.get(opts, :data))
    |> raise_error()
  end

  defp extract_aliases(terms, opts) do
    aliases = opts |> Keyword.get(:alias, []) |> Keyword.new()

    {terms, aliases} =
      Enum.reduce(terms, {[], aliases}, fn
        {_, term} = alias, {terms, aliases} -> {[term | terms], [alias | aliases]}
        term, {terms, aliases} -> {[term | terms], aliases}
      end)

    {terms, Keyword.put(opts, :alias, aliases)}
  end

  defp set_base_uri(term_mapping, %IRI{} = base_iri),
    do: set_base_uri(term_mapping, IRI.to_string(base_iri))

  defp set_base_uri(term_mapping, base_uri) when is_binary(base_uri) do
    if IRI.valid?(base_uri) do
      %__MODULE__{term_mapping | base_uri: base_uri}
    else
      add_error(term_mapping, InvalidVocabBaseIRIError, "invalid base IRI: #{inspect(base_uri)}")
    end
  end

  defp set_base_uri(term_mapping, base_uri) do
    set_base_uri(term_mapping, IRI.new(base_uri))
  rescue
    [Namespace.UndefinedTermError, IRI.InvalidError, FunctionClauseError] ->
      add_error(term_mapping, InvalidVocabBaseIRIError, "invalid base IRI: #{inspect(base_uri)}")
  end

  def ignore_term(term_mapping, term, opts \\ []) do
    term = normalize_term(term)

    if not Keyword.get(opts, :validate_existence, false) or
         not term_mapping.strict or
         Map.has_key?(term_mapping.terms, term) do
      %{
        term_mapping
        | terms: Map.delete(term_mapping.terms, term),
          ignored_terms: MapSet.put(term_mapping.ignored_terms, term)
      }
    else
      add_error(
        term_mapping,
        InvalidIgnoreTermError,
        "'#{term}' is not a term in this vocabulary namespace"
      )
    end
  end

  def ignore_terms(term_mapping, terms, opts \\ []) do
    Enum.reduce(terms, term_mapping, &ignore_term(&2, &1, opts))
  end

  def add_alias(term_mapping, term, alias) do
    term = normalize_term(term)
    alias = normalize_term(alias)

    cond do
      reserved_term?(alias) ->
        add_error(
          term_mapping,
          InvalidAliasError,
          "alias '#{alias}' is a reserved term and can't be used as an alias"
        )

      not valid_characters?(alias) ->
        add_error(term_mapping, InvalidAliasError, "alias '#{alias}' contains invalid characters")

      Map.has_key?(term_mapping.terms, alias) ->
        add_error(
          term_mapping,
          InvalidAliasError,
          "alias '#{alias}' conflicts with an existing term or alias"
        )

      Map.get(term_mapping.terms, term, true) != true ->
        add_error(
          term_mapping,
          InvalidAliasError,
          "alias '#{alias}' is referring to alias '#{term}'"
        )

      term_mapping.strict and not Map.has_key?(term_mapping.terms, term) and
          term not in term_mapping.ignored_terms ->
        add_error(
          term_mapping,
          InvalidAliasError,
          "term '#{term}' is not a term in this namespace"
        )

      alias in term_mapping.ignored_terms ->
        add_error(term_mapping, InvalidAliasError, "ignoring alias '#{alias}'")

      true ->
        if valid_term?(term) do
          term_mapping
        else
          ignore_term(term_mapping, term)
        end
        |> Map.update!(:terms, &Map.put(&1, alias, Atom.to_string(term)))
        |> Map.update!(:aliased_terms, &MapSet.put(&1, term))
    end
  end

  def add_aliases(term_mapping, aliases) do
    Enum.reduce(aliases, term_mapping, fn {alias, original_term}, term_mapping ->
      add_alias(term_mapping, original_term, alias)
    end)
  end

  def add_error(term_mapping, error, message) do
    add_error(term_mapping, error.exception(message))
  end

  def add_error(term_mapping, error) do
    %{term_mapping | errors: [error | term_mapping.errors]}
  end

  def errors(%{errors: []}), do: nil
  def errors(%{errors: errors}), do: Enum.reverse(errors)

  def raise_error(%{errors: []} = term_mapping), do: term_mapping

  def raise_error(term_mapping) do
    raise CompileError, error_report(term_mapping)
  end

  defp error_report(term_mapping) do
    grouped_errors =
      term_mapping
      |> errors()
      |> Enum.group_by(fn
        %{label: label} -> label
        %type{} -> to_string(type)
      end)

    """

    ================================================================================
    Errors while compiling vocabulary #{term_mapping.module}
    ================================================================================

    """ <>
      Enum.map_join(grouped_errors, fn {group, errors} ->
        """
        #{group}
        #{String.duplicate("-", String.length(group))}

        #{Enum.map_join(errors, "\n", fn error -> if String.contains?(message = Exception.message(error), "\n") do
            message
          else
            "- " <> message
          end end)}

        """
      end)
  end

  def term_mapping(term_mapping) do
    Enum.flat_map(term_mapping.terms, fn
      {term, true} -> [{term, term_to_iri(term_mapping.base_uri, term)}]
      {term, original} -> [{term, term_to_iri(term_mapping.base_uri, original)}]
    end)
  end

  defp normalize_term(term) when is_atom(term), do: term
  defp normalize_term(term) when is_binary(term), do: String.to_atom(term)

  defp normalize_term(term) do
    raise(
      InvalidTermError,
      "invalid term type: #{inspect(term)}; only strings and atoms are allowed"
    )
  end
end
