defmodule RDF.Vocabulary.Namespace do
  @moduledoc """
  A RDF vocabulary as a `RDF.Namespace`.

  `RDF.Vocabulary.Namespace` modules represent a RDF vocabulary as a `RDF.Namespace`.
  They can be defined with the `defvocab/2` macro of this module.

  RDF.ex comes with predefined modules for some fundamental vocabularies in
  the `RDF.NS` module.
  """

  alias RDF.Utils.ResourceClassifier

  @vocabs_dir "priv/vocabs"

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__)
    end
  end

  @doc """
  Defines a `RDF.Namespace` module for a RDF vocabulary.
  """
  defmacro defvocab(name, opts) do
    strict   = strict?(opts)
    base_iri = base_iri!(opts)
    file     = filename!(opts)
    {terms, data} =
      case source!(opts) do
        {:terms, terms} -> {terms, nil}
        {:data, data}   -> {rdf_data_vocab_terms(data, base_iri), data}
      end

    IO.puts("Compiling vocabulary namespace for #{base_iri}")

    ignored_terms = ignored_terms!(opts)
    terms =
      terms
      |> term_mapping!(opts)
      |> Map.drop(MapSet.to_list(ignored_terms))
      |> validate_terms!
      |> validate_characters!(opts)
      |> validate_case!(data, base_iri, opts)
    case_separated_terms = group_terms_by_case(terms)
    lowercased_terms  = Map.get(case_separated_terms, :lowercased, %{})

    quote do
      vocabdoc = Module.delete_attribute(__MODULE__, :vocabdoc)

      defmodule unquote(name) do
        @moduledoc vocabdoc

        @behaviour Elixir.RDF.Namespace

        if unquote(file) do
          @external_resource unquote(file)
        end

        @base_iri unquote(base_iri)
        def   __base_iri__, do: @base_iri

        @strict unquote(strict)
        def __strict__, do: @strict

        @terms unquote(Macro.escape(terms))
        @impl Elixir.RDF.Namespace
        def __terms__, do: @terms |> Map.keys

        @ignored_terms unquote(Macro.escape(ignored_terms))

        @doc """
        Returns all known IRIs of the vocabulary.
        """
        def __iris__ do
          @terms
          |> Enum.map(fn
               {term, true}   -> term_to_iri(@base_iri, term)
               {_alias, term} -> term_to_iri(@base_iri, term)
             end)
          |> Enum.uniq
        end

        define_vocab_terms unquote(lowercased_terms), unquote(base_iri)

        @impl Elixir.RDF.Namespace
        def __resolve_term__(term) do
          case @terms[term] do
            nil ->
              # TODO: Why does this MapSet.member? call produce a warning? It does NOT always yield the same result!
              if @strict or MapSet.member?(@ignored_terms, term) do
                raise Elixir.RDF.Namespace.UndefinedTermError,
                  "undefined term #{term} in strict vocabulary #{__MODULE__}"
              else
                term_to_iri(@base_iri, term)
              end
            true ->
              term_to_iri(@base_iri, term)
            original_term ->
              term_to_iri(@base_iri, original_term)
          end
        end

        if not @strict do
          def unquote(:"$handle_undefined_function")(term, []) do
            if MapSet.member?(@ignored_terms, term) do
              raise UndefinedFunctionError
            else
              term_to_iri(@base_iri, term)
            end
          end

          def unquote(:"$handle_undefined_function")(term, [subject | objects]) do
            if MapSet.member?(@ignored_terms, term) do
              raise UndefinedFunctionError
            else
              RDF.Description.new(subject, term_to_iri(@base_iri, term), objects)
            end
          end
        end
      end
    end
  end

  @doc false
  defmacro define_vocab_terms(terms, base_iri) do
    terms
    |> Stream.filter(fn
        {term, true} -> valid_term?(term)
        {_, _}       -> true
       end)
    |> Stream.map(fn
        {term, true}          -> {term, term}
        {term, original_term} -> {term, original_term}
       end)
    |> Enum.map(fn {term, iri_suffix} ->
        iri = term_to_iri(base_iri, iri_suffix)
        quote do
          @doc "<#{unquote(to_string(iri))}>"
          def unquote(term)(), do: unquote(Macro.escape(iri))

          @doc "`RDF.Description` builder for `#{unquote(term)}/0`"
          def unquote(term)(subject, object) do
            RDF.Description.new(subject, unquote(Macro.escape(iri)), object)
          end

          # Is there a better way to support multiple objects via arguments?
          @doc false
          def unquote(term)(subject,  o1, o2),
          do: unquote(term)(subject, [o1, o2])
          @doc false
          def unquote(term)(subject,  o1, o2, o3),
          do: unquote(term)(subject, [o1, o2, o3])
          @doc false
          def unquote(term)(subject,  o1, o2, o3, o4),
          do: unquote(term)(subject, [o1, o2, o3, o4])
          @doc false
          def unquote(term)(subject,  o1, o2, o3, o4, o5),
          do: unquote(term)(subject, [o1, o2, o3, o4, o5])
        end
      end)
  end

  defp strict?(opts),
    do: Keyword.get(opts, :strict, true)

  defp base_iri!(opts) do
    base_iri = Keyword.fetch!(opts, :base_iri)
    unless is_binary(base_iri) and String.ends_with?(base_iri, ["/", "#"]) do
      raise RDF.Namespace.InvalidVocabBaseIRIError,
              "a base_iri without a trailing '/' or '#' is invalid"
    else
      base_iri
    end
  end

  defp source!(opts) do
    cond do
      Keyword.has_key?(opts, :file)        -> {:data, filename!(opts) |> RDF.read_file!()}
      rdf_data = Keyword.get(opts, :data)  -> {:data, raw_rdf_data(rdf_data)}
      terms    = Keyword.get(opts, :terms) -> {:terms, terms_from_user_input!(terms)}
      true ->
        raise KeyError, key: ~w[terms data file], term: opts
    end
  end

  defp terms_from_user_input!(terms) do
    # TODO: find an alternative to Code.eval_quoted - We want to support that the terms can be given as sigils ...
    {terms, _ } = Code.eval_quoted(terms, [], rdf_data_env())
    Enum.map terms, fn
      term when is_atom(term)   -> term
      term when is_binary(term) -> String.to_atom(term)
      term ->
        raise RDF.Namespace.InvalidTermError,
          "'#{term}' is not a valid vocabulary term"
    end
  end

  defp raw_rdf_data(%RDF.Description{} = rdf_data), do: rdf_data
  defp raw_rdf_data(%RDF.Graph{} = rdf_data), do: rdf_data
  defp raw_rdf_data(%RDF.Dataset{} = rdf_data), do: rdf_data
  defp raw_rdf_data(rdf_data) do
    # TODO: find an alternative to Code.eval_quoted
    {rdf_data, _} = Code.eval_quoted(rdf_data, [], rdf_data_env())
    rdf_data
  end


  defp ignored_terms!(opts) do
    # TODO: find an alternative to Code.eval_quoted - We want to support that the terms can be given as sigils ...
    with terms = Keyword.get(opts, :ignore, []) do
      {terms, _ } = Code.eval_quoted(terms, [], rdf_data_env())
      terms
      |> Enum.map(fn
           term when is_atom(term)   -> term
           term when is_binary(term) -> String.to_atom(term)
           term -> raise RDF.Namespace.InvalidTermError, inspect(term)
         end)
      |> MapSet.new
    end
  end


  defp term_mapping!(terms, opts) do
    terms = Map.new terms, fn
      term when is_atom(term) -> {term, true}
      term                    -> {String.to_atom(term), true}
    end
    Keyword.get(opts, :alias, [])
    |> Enum.reduce(terms, fn {alias, original_term}, terms ->
         term = String.to_atom(original_term)
         cond do
           not valid_characters?(alias) ->
             raise RDF.Namespace.InvalidAliasError,
               "alias '#{alias}' contains invalid characters"

           Map.get(terms, alias) == true ->
             raise RDF.Namespace.InvalidAliasError,
               "alias '#{alias}' already defined"

           strict?(opts) and not Map.has_key?(terms, term) ->
              raise RDF.Namespace.InvalidAliasError,
                "term '#{original_term}' is not a term in this vocabulary"

           Map.get(terms, term, true) != true ->
              raise RDF.Namespace.InvalidAliasError,
                "'#{original_term}' is already an alias"

           true ->
             Map.put(terms, alias, to_string(original_term))
         end
       end)
  end

  defp aliased_terms(terms) do
    terms
    |> Map.values
    |> MapSet.new
    |> MapSet.delete(true)
    |> Enum.map(&String.to_atom/1)
  end

  @invalid_terms MapSet.new ~w[
    and
    or
    xor
    in
    fn
    def
    when
    if
    for
    case
    with
    quote
    unquote
    unquote_splicing
    alias
    import
    require
    super
    __aliases__
  ]a

  def invalid_terms, do: @invalid_terms

  defp validate_terms!(terms) do
    with aliased_terms = aliased_terms(terms) do
      for {term, _} <- terms, term not in aliased_terms and not valid_term?(term) do
        term
      end
      |> handle_invalid_terms!
    end

    terms
  end

  defp valid_term?(term) do
    not MapSet.member?(@invalid_terms, term)
  end

  defp handle_invalid_terms!([]), do: nil

  defp handle_invalid_terms!(invalid_terms) do
    raise RDF.Namespace.InvalidTermError, """
      The following terms can not be used, because they conflict with the Elixir semantics:

      - #{Enum.join(invalid_terms, "\n- ")}

      You have the following options:

      - define an alias with the :alias option on defvocab
      - ignore the resource with the :ignore option on defvocab
      """
  end


  defp validate_characters!(terms, opts) do
    if (handling = Keyword.get(opts, :invalid_characters, :fail)) == :ignore do
      terms
    else
      terms
      |> detect_invalid_characters
      |> handle_invalid_characters(handling, terms)
    end
  end

  defp detect_invalid_characters(terms) do
    with aliased_terms = aliased_terms(terms) do
      for {term, _} <- terms, term not in aliased_terms and not valid_characters?(term),
        do: term
    end
  end

  defp handle_invalid_characters([], _, terms), do: terms

  defp handle_invalid_characters(invalid_terms, :fail, _) do
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

  defp handle_invalid_characters(invalid_terms, :warn, terms) do
    Enum.each invalid_terms, fn term ->
      IO.warn "'#{term}' is not valid term, since it contains invalid characters"
    end
    terms
  end

  defp valid_characters?(term) when is_atom(term),
    do: valid_characters?(Atom.to_string(term))
  defp valid_characters?(term),
    do: Regex.match?(~r/^[a-zA-Z_]\w*$/, term)

  defp validate_case!(terms, nil, _, _), do: terms
  defp validate_case!(terms, data, base_iri, opts) do
    if (handling = Keyword.get(opts, :case_violations, :warn)) == :ignore do
      terms
    else
      terms
      |> detect_case_violations(data, base_iri)
      |> group_case_violations
      |> handle_case_violations(handling, terms, base_iri, opts)
    end
  end

  defp detect_case_violations(terms, data, base_iri) do
    aliased_terms = aliased_terms(terms)
    terms
    |> Enum.filter(fn {term, _} ->
         not(Atom.to_string(term) |> String.starts_with?("_"))
       end)
    |> Enum.filter(fn
         {term, true} ->
           if term not in aliased_terms do
             proper_case?(term, base_iri, Atom.to_string(term), data)
           end
         {term, original_term} ->
           proper_case?(term, base_iri, original_term, data)
       end)
  end

  defp proper_case?(term, base_iri, iri_suffix, data) do
    case ResourceClassifier.property?(term_to_iri(base_iri, iri_suffix), data) do
      true  -> not lowercase?(term)
      false -> lowercase?(term)
      nil   -> lowercase?(term)
    end
  end

  defp group_case_violations(violations) do
    violations
    |> Enum.group_by(fn
         {term, true} ->
           if lowercase?(term),
             do:   :lowercased_term,
             else: :capitalized_term
         {term, _original} ->
           if lowercase?(term),
             do:   :lowercased_alias,
             else: :capitalized_alias
       end)
  end

  defp handle_case_violations(%{} = violations, _, terms, _, _) when map_size(violations) == 0,
    do: terms

  defp handle_case_violations(violations, :fail, _, base_iri, _) do
    resource_name_violations = fn violations ->
      violations
      |> Enum.map(fn {term, true} -> term_to_iri(base_iri, term) end)
      |> Enum.map(&to_string/1)
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
      |> Enum.join

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


  defp handle_case_violations(violations, :warn, terms, base_iri, _) do
    for {type, violations} <- violations,
        {term, original}   <- violations do
      case_violation_warning(type, term, original, base_iri)
    end
    terms
  end

  defp case_violation_warning(:capitalized_term, term, _, base_iri) do
    IO.warn "'#{term_to_iri(base_iri, term)}' is a capitalized property"
  end

  defp case_violation_warning(:lowercased_term, term, _, base_iri) do
    IO.warn "'#{term_to_iri(base_iri, term)}' is a lowercased non-property resource"
  end

  defp case_violation_warning(:capitalized_alias, term, _, _) do
    IO.warn "capitalized alias '#{term}' for a property"
  end

  defp case_violation_warning(:lowercased_alias, term, _, _) do
    IO.warn "lowercased alias '#{term}' for a non-property resource"
  end


  defp filename!(opts) do
    if filename = Keyword.get(opts, :file) do
      cond do
        File.exists?(filename) ->
          filename
        File.exists?(expanded_filename = Path.expand(filename, @vocabs_dir)) ->
          expanded_filename
        true ->
          raise File.Error, path: filename, action: "find", reason: :enoent
       end
    end
  end

  defp rdf_data_env do
    import RDF.Sigils # TODO: Can we get rid of the warning about this line somehow? It is plain false.
    __ENV__
  end

  defp rdf_data_vocab_terms(data, base_iri) do
    data
    |> RDF.Data.resources
    |> Stream.filter(fn
        %RDF.IRI{} -> true
        _          -> false
       end)
    |> Stream.map(&to_string/1)
    |> Stream.map(&(strip_base_iri(&1, base_iri)))
    |> Stream.filter(&vocab_term?/1)
    |> Enum.map(&String.to_atom/1)
  end

  defp group_terms_by_case(terms) do
    terms
    |> Enum.group_by(fn {term, _} ->
         if lowercase?(term),
           do:   :lowercased,
           else: :capitalized
       end)
    |> Map.new(fn {group, term_mapping} ->
         {group, Map.new(term_mapping)}
       end)
  end

  defp lowercase?(term) when is_atom(term),
    do: Atom.to_string(term) |> lowercase?
  defp lowercase?(term),
    do: term =~ ~r/^(_|\p{Ll})/u

  defp strip_base_iri(iri, base_iri) do
    if String.starts_with?(iri, base_iri) do
      String.replace_prefix(iri, base_iri, "")
    end
  end

  defp vocab_term?(""), do: false
  defp vocab_term?(term) when is_binary(term) do
    not String.contains?(term, "/")
  end
  defp vocab_term?(_), do: false

  @doc false
  def term_to_iri(base_iri, term) when is_atom(term),
    do: term_to_iri(base_iri, Atom.to_string(term))
  def term_to_iri(base_iri, term),
    do: RDF.iri(base_iri <> term)

  @doc false
  def vocabulary_namespace?(name) do
    Code.ensure_loaded?(name) && function_exported?(name, :__base_iri__, 0)
  end

end
