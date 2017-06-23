defmodule RDF.Vocabulary.Namespace do
  @moduledoc """
  A RDF vocabulary as a `RDF.Namespace`.

  `RDF.Vocabulary.Namespace` modules represent a RDF vocabulary as a `RDF.Namespace`.
  They can be defined with the `defvocab/2` macro of this module.

  RDF.ex comes with predefined modules for some fundamentals vocabularies in
  the `RDF.NS` module.
  Furthermore, the [rdf_vocab](https://hex.pm/packages/rdf_vocab) package
  contains predefined modules for popular vocabularies.
  """

  alias RDF.Utils.ResourceClassifier

  @vocabs_dir "priv/vocabs"
  @big_vocab_threshold 300

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
    base_uri = base_uri!(opts)
    file     = filename!(opts)
    {terms, data} =
      case source!(opts) do
        {:terms, terms} -> {terms, nil}
        {:data, data}   -> {rdf_data_vocab_terms(data, base_uri), data}
      end

    if data && RDF.Data.subject_count(data) > @big_vocab_threshold do
      IO.puts("Compiling vocabulary namespace for #{base_uri} may take some time")
    end

    ignored_terms = ignored_terms!(opts)
    terms =
      terms
      |> term_mapping!(opts)
      |> Map.drop(MapSet.to_list(ignored_terms))
      |> validate_terms!(opts)
      |> validate_case!(data, base_uri, opts)
    case_separated_terms = group_terms_by_case(terms)
    lowercased_terms  = Map.get(case_separated_terms, :lowercased, %{})

    quote do
      vocabdoc = Module.delete_attribute(__MODULE__, :vocabdoc)

      defmodule unquote(name) do
        @moduledoc vocabdoc

        @behaviour RDF.Namespace

        if unquote(file) do
          @external_resource unquote(file)
        end

        @base_uri unquote(base_uri)
        def __base_uri__, do: @base_uri

        @strict unquote(strict)
        def __strict__, do: @strict

        @terms unquote(Macro.escape(terms))
        def __terms__, do: @terms |> Map.keys

        @ignored_terms unquote(Macro.escape(ignored_terms))

        @doc """
        Returns all known URIs of the vocabulary.
        """
        def __uris__ do
          @terms
          |> Enum.map(fn
               {term, true}   -> term_to_uri(@base_uri, term)
               {_alias, term} -> term_to_uri(@base_uri, term)
             end)
          |> Enum.uniq
        end

        define_vocab_terms unquote(lowercased_terms), unquote(base_uri)

        def __resolve_term__(term) do
          case @terms[term] do
            nil ->
              # TODO: Why does this MapSet.member? call produce a warning? It does NOT always yield the same result!
              if @strict or MapSet.member?(@ignored_terms, term) do
                raise RDF.Namespace.UndefinedTermError,
                  "undefined term #{term} in strict vocabulary #{__MODULE__}"
              else
                term_to_uri(@base_uri, term)
              end
            true ->
              term_to_uri(@base_uri, term)
            original_term ->
              term_to_uri(@base_uri, original_term)
          end
        end

        if not @strict do
          def unquote(:"$handle_undefined_function")(term, []) do
            if MapSet.member?(@ignored_terms, term) do
              raise UndefinedFunctionError
            else
              term_to_uri(@base_uri, term)
            end
          end

          def unquote(:"$handle_undefined_function")(term, [subject | objects]) do
            if MapSet.member?(@ignored_terms, term) do
              raise UndefinedFunctionError
            else
              RDF.Description.new(subject, term_to_uri(@base_uri, term), objects)
            end
          end
        end
      end
    end
  end

  @doc false
  defmacro define_vocab_terms(terms, base_uri) do
    terms
    |> Stream.map(fn
        {term, true}          -> {term, term}
        {term, original_term} -> {term, original_term}
       end)
    |> Enum.map(fn {term, uri_suffix} ->
        uri = term_to_uri(base_uri, uri_suffix)
        quote do
          @doc "<#{unquote(to_string(uri))}>"
          def unquote(term)(), do: unquote(Macro.escape(uri))

          @doc "`RDF.Description` builder for `#{unquote(term)}/0`"
          def unquote(term)(subject, object) do
            RDF.Description.new(subject, unquote(Macro.escape(uri)), object)
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

  defp base_uri!(opts) do
    base_uri = Keyword.fetch!(opts, :base_uri)
    unless is_binary(base_uri) and String.ends_with?(base_uri, ["/", "#"]) do
      raise RDF.Namespace.InvalidVocabBaseURIError,
              "a base_uri without a trailing '/' or '#' is invalid"
    else
      base_uri
    end
  end

  defp source!(opts) do
    cond do
      Keyword.has_key?(opts, :file)        -> {:data, filename!(opts) |> load_file}
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


  defp term_mapping!(terms, opts) do
    terms = Map.new terms, fn
      term when is_atom(term) -> {term, true}
      term                    -> {String.to_atom(term), true}
    end
    Keyword.get(opts, :alias, [])
    |> Enum.reduce(terms, fn {alias, original_term}, terms ->
         term = String.to_atom(original_term)
         cond do
           not valid_term?(alias) ->
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

  defp validate_terms!(terms, opts) do
    if (handling = Keyword.get(opts, :invalid_characters, :fail)) == :ignore do
      terms
    else
      terms
      |> detect_invalid_terms
      |> handle_invalid_terms(handling, terms)
    end
  end

  defp detect_invalid_terms(terms) do
    aliased_terms = aliased_terms(terms)
    Enum.filter_map terms,
      fn {term, _} ->
        not term in aliased_terms and not valid_term?(term)
      end,
      fn {term, _} -> term end
  end

  defp handle_invalid_terms([], _, terms), do: terms

  defp handle_invalid_terms(invalid_terms, :fail, _) do
    raise RDF.Namespace.InvalidTermError, """
      The following terms contain invalid characters:

      - #{Enum.join(invalid_terms, "\n- ")}

      You have the following options:

      - if you are in control of the vocabulary, consider renaming the resource
      - define an alias with the :alias option on defvocab
      - change the handling of invalid characters with the :invalid_characters option on defvocab
      """
  end

  defp handle_invalid_terms(invalid_terms, :warn, terms) do
    Enum.each invalid_terms, fn term ->
      IO.warn "'#{term}' is not valid term, since it contains invalid characters"
    end
    terms
  end

  defp valid_term?(term) when is_atom(term),
    do: valid_term?(Atom.to_string(term))
  defp valid_term?(term),
    do: Regex.match?(~r/^[a-zA-Z_]\w*$/, term)

  defp validate_case!(terms, nil, _, _), do: terms
  defp validate_case!(terms, data, base_uri, opts) do
    if (handling = Keyword.get(opts, :case_violations, :warn)) == :ignore do
      terms
    else
      terms
      |> detect_case_violations(data, base_uri)
      |> group_case_violations
      |> handle_case_violations(handling, terms, base_uri, opts)
    end
  end

  defp detect_case_violations(terms, data, base_uri) do
    aliased_terms = aliased_terms(terms)
    terms
    |> Enum.filter(fn {term, _} ->
         not(Atom.to_string(term) |> String.starts_with?("_"))
       end)
    |> Enum.filter(fn
         {term, true} ->
           if not term in aliased_terms do
             proper_case?(term, base_uri, Atom.to_string(term), data)
           end
         {term, original_term} ->
           proper_case?(term, base_uri, original_term, data)
       end)
  end

  defp proper_case?(term, base_uri, uri_suffix, data) do
    case ResourceClassifier.property?(term_to_uri(base_uri, uri_suffix), data) do
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

  defp handle_case_violations(violations, :fail, _, base_uri, _) do
    resource_name_violations = fn violations ->
      violations
      |> Enum.map(fn {term, true} -> term_to_uri(base_uri, term) end)
      |> Enum.map(&to_string/1)
      |> Enum.join("\n- ")
    end
    alias_violations = fn violations ->
      violations
      |> Enum.map(fn {term, original} ->
          "alias #{term} for #{term_to_uri(base_uri, original)}"
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
      """
  end


  defp handle_case_violations(violations, :warn, terms, base_uri, _) do
    for {type, violations} <- violations,
        {term, original}   <- violations do
      case_violation_warning(type, term, original, base_uri)
    end
    terms
  end

  defp case_violation_warning(:capitalized_term, term, _, base_uri) do
    IO.warn "'#{term_to_uri(base_uri, term)}' is a capitalized property"
  end

  defp case_violation_warning(:lowercased_term, term, _, base_uri) do
    IO.warn "'#{term_to_uri(base_uri, term)}' is a lowercased non-property resource"
  end

  defp case_violation_warning(:capitalized_alias, term, _, _) do
    IO.warn "capitalized alias '#{term}' for a property"
  end

  defp case_violation_warning(:lowercased_alias, term, _, _) do
    IO.warn "lowercased alias '#{term}' for a non-property resource"
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

  defp load_file(file) do
    # TODO: support other formats
    cond do
      String.ends_with?(file, ".nt") -> RDF.NTriples.read_file!(file)
      String.ends_with?(file, ".nq") -> RDF.NQuads.read_file!(file)
      true ->
        raise ArgumentError,
          "unsupported file type for #{file}: vocabulary namespaces can currently be created from NTriple and NQuad files"
    end
  end

  defp rdf_data_env do
    import RDF.Sigils
    __ENV__
  end

  defp rdf_data_vocab_terms(data, base_uri) do
    data
    |> RDF.Data.resources
    # filter URIs
    |> Stream.filter(fn
        %URI{} -> true
        _      -> false
       end)
    |> Stream.map(&URI.to_string/1)
    |> Stream.map(&(strip_base_uri(&1, base_uri)))
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

  defp strip_base_uri(uri, base_uri) do
    if String.starts_with?(uri, base_uri) do
      String.replace_prefix(uri, base_uri, "")
    end
  end

  defp vocab_term?(""), do: false
  defp vocab_term?(term) when is_binary(term) do
    not String.contains?(term, "/")
  end
  defp vocab_term?(_), do: false

  @doc false
  def term_to_uri(base_uri, term) when is_atom(term),
    do: term_to_uri(base_uri, Atom.to_string(term))
  def term_to_uri(base_uri, term),
    do: URI.parse(base_uri <> term)

end
