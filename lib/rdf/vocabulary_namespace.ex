defmodule RDF.Vocabulary.Namespace do
  @moduledoc """
  Defines a RDF Vocabulary as a `RDF.Namespace`.


  ## Strict vocabularies

  What is a strict vocabulary and why should I use them over non-strict
  vocabularies and define all terms ...


  ## Defining a vocabulary

  There are two basic ways to define a vocabulary:

  1. You can define all terms manually.
  2. You can load all terms from a specified namespace in a given dataset or
     graph.

  Either way, you'll first have to define a new module for your vocabulary:

      defmodule Example do
        use RDF.Vocabulary.Namespace

        defvocab EX,
          base_uri: "http://www.example.com/ns/",
          terms: ~w[Foo bar]

        # Your term definitions
      end

  The `base_uri` argument with the URI prefix of all the terms in the defined
  vocabulary is required and expects a valid URI ending with either a `"/"` or
  a `"#"`.


  ## Reflection

  `__base_uri__` and `__terms__` ...

  """

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
    base_uri = base_uri!(opts)
    file     = filename!(opts)
    terms    = terms!(opts) |> term_mapping!(opts) |> validate_terms!(opts)
    strict   = strict?(opts)
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
        def __terms__, do: @terms  |> Map.keys

        define_vocab_terms unquote(lowercased_terms), unquote(base_uri)

        def __resolve_term__(term) do
          case @terms[term] do
            nil ->
              if @strict do
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
            term_to_uri(@base_uri, term)
          end

          def unquote(:"$handle_undefined_function")(term, [subject | objects]) do
            RDF.Description.new(subject, term_to_uri(@base_uri, term), objects)
          end
        end

        Module.delete_attribute(__MODULE__, :tmp_uri)
      end
    end
  end

  defmacro define_vocab_terms(terms, base_uri) do
    terms
    |> Stream.map(fn
        {term, true}          -> {term, term}
        {term, original_term} -> {term, original_term}
       end)
    |> Enum.map(fn {term, uri_suffix} ->
# TODO: Why does this way of precompiling the URI not work? We're getting an "invalid quoted expression: %URI{...}"
#      uri = term_to_uri(base_uri, term)
#      quote bind_quoted: [uri: Macro.escape(uri), term: String.to_atom(term)] do
##        @doc "<#{@tmp_uri}>"
#        def unquote(term)() do
#          unquote(uri)
#        end
#      end
# Temporary workaround:
      quote do
        @tmp_uri term_to_uri(@base_uri, unquote(uri_suffix))
        @doc "<#{@tmp_uri}>"
        def unquote(term)(), do: @tmp_uri

        @doc "`RDF.Description` builder for <#{@tmp_uri}>"
        def unquote(term)(subject, object) do
          RDF.Description.new(subject, @tmp_uri, object)
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

  def terms!(opts) do
    cond do
      Keyword.has_key?(opts, :file) ->
        filename!(opts)
        |> load_file
        |> terms_from_rdf_data!(opts)
      rdf_data = Keyword.get(opts, :data) ->
        terms_from_rdf_data!(rdf_data, opts)
      terms = Keyword.get(opts, :terms) ->
        # TODO: find an alternative to Code.eval_quoted - We want to support that the terms can be given as sigils ...
        {terms, _ } = Code.eval_quoted(terms, [], rdf_data_env())
        terms
        |> Enum.map(fn
             term when is_atom(term)   -> term
             term when is_binary(term) -> String.to_atom(term)
             term ->
               raise RDF.Namespace.InvalidTermError,
                 "'#{term}' is not a valid vocabulary term"
           end)
      true ->
        raise KeyError, key: ~w[terms data file], term: opts
    end
  end

  # TODO: support also RDF.Datasets ...
  defp terms_from_rdf_data!(%RDF.Graph{} = rdf_data, opts) do
    rdf_data_vocab_terms(rdf_data, Keyword.fetch!(opts, :base_uri))
  end

  defp terms_from_rdf_data!(rdf_data, opts) do
    # TODO: find an alternative to Code.eval_quoted
    {rdf_data, _} = Code.eval_quoted(rdf_data, [], rdf_data_env())
    terms_from_rdf_data!(rdf_data, opts)
  end


  def term_mapping!(terms, opts) do
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

  defp validate_terms!(terms, opts) do
    if (handling = Keyword.get(opts, :invalid_characters, :fail)) == :ignore do
      terms
    else
      terms
      |> detect_invalid_terms(opts)
      |> handle_invalid_terms(handling, terms, opts)
    end
  end

  defp detect_invalid_terms(terms, _opts) do
    aliased =
      terms
      |> Map.values
      |> MapSet.new
      |> MapSet.delete(true)
      |> Enum.map(&String.to_atom/1)
    terms
    |> Stream.filter(fn {term, _} ->
         not valid_term?(term) and not term in aliased
       end)
    |> Enum.map(fn {term, _} -> term end)
  end

  defp handle_invalid_terms([], _, terms, _), do: terms

  defp handle_invalid_terms(invalid_terms, :fail, _, _) do
    raise RDF.Namespace.InvalidTermError, """
      The following terms contain invalid characters:

      - #{Enum.join(invalid_terms, "\n- ")}

      You have the following options:

      - if you are in control of the vocabulary, consider renaming the resource
      - define an alias with the :alias option on defvocab
      - change the handling of invalid characters with the :invalid_characters option on defvocab
      """
  end

  defp handle_invalid_terms(invalid_terms, :warn, terms, _) do
    Enum.each invalid_terms, fn term ->
      IO.warn "'#{term}' is not valid term, since it contains invalid characters"
    end
    terms
  end

  defp valid_term?(nil), do: true
  defp valid_term?(term) do
    Regex.match?(~r/^[a-zA-Z_]\w*$/, to_string(term))
  end


  def filename!(opts) do
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
    RDF.NTriples.read_file!(file)  # TODO: support other formats
  end

  defp rdf_data_env do
    __ENV__
  end

  defp rdf_data_vocab_terms(data, base_uri) do
    data
    |> RDF.Graph.resources # TODO: support also RDF.Datasets ...
    # filter URIs
    |> Stream.filter(fn
        %URI{} -> true
        _      -> false
       end)
    |> Stream.map(&to_string/1)
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
    do: term =~ ~r/^\p{Ll}/u

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
  def term_to_uri(base_uri, term) do
    URI.parse(base_uri <> to_string(term))
  end

end
