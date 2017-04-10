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
    file     = file!(opts)
    terms    = terms!(opts)
    strict   = Keyword.get(opts, :strict, true)
    case_separated_terms = group_terms_by_case(terms)
    lowercased_terms  = Map.get(case_separated_terms, :lowercased, [])
    capitalized_terms = Map.get(case_separated_terms, :capitalized, [])

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

        @lowercased_terms  unquote(lowercased_terms  |> Enum.map(&String.to_atom/1))
        @capitalized_terms unquote(capitalized_terms |> Enum.map(&String.to_atom/1))
        @terms @lowercased_terms ++ @capitalized_terms
        def __terms__, do: @terms

        define_vocab_terms unquote(lowercased_terms), unquote(base_uri)

        if @strict do
          def __resolve_term__(term) do
            if Enum.member?(@capitalized_terms, term) do
              term_to_uri(@base_uri, term)
            else
              raise RDF.Namespace.UndefinedTermError,
                "undefined term #{term} in strict vocabulary #{__MODULE__}"
            end
          end
        else
          def __resolve_term__(term) do
            term_to_uri(@base_uri, term)
          end

          def unquote(:"$handle_undefined_function")(term, args) do
            term_to_uri(@base_uri, term)
          end
        end

        Module.delete_attribute(__MODULE__, :tmp_uri)
      end
    end
  end

  defp base_uri!(opts) do
    base_uri = Keyword.fetch!(opts, :base_uri)
    unless String.ends_with?(base_uri, ["/", "#"]) do
      raise RDF.Namespace.InvalidVocabBaseURIError,
              "a base_uri without a trailing '/' or '#' is invalid"
    else
      base_uri
    end
  end

  def terms!(opts) do
    cond do
      Keyword.has_key?(opts, :file) ->
        opts
        |> Keyword.delete(:file)
        |> Keyword.put(:data, load_file(file!(opts)))
        |> terms!
      data = Keyword.get(opts, :data) ->
        # TODO: support also RDF.Datasets ...
        data = unless match?(%RDF.Graph{}, data) do
          # TODO: find an alternative to Code.eval_quoted
          {data, _ } = Code.eval_quoted(data, [], data_env())
          data
        else
          data
        end
        data_vocab_terms(data, Keyword.fetch!(opts, :base_uri))
      terms = Keyword.get(opts, :terms) ->
        # TODO: find an alternative to Code.eval_quoted - We want to support that the terms can be given as sigils ...
        {terms, _ } = Code.eval_quoted(terms, [], data_env())
        terms
        |> Enum.map(&to_string/1)
      true ->
        raise KeyError, key: ~w[terms data file], term: opts
    end
  end

  def file!(opts) do
    if file = Keyword.get(opts, :file) do
      cond do
        File.exists?(file) ->
          file
        File.exists?(expanded_file = Path.expand(file, @vocabs_dir)) ->
          expanded_file
        true ->
          raise File.Error, path: file, action: "find", reason: :enoent
       end
    end
  end

  defp load_file(file) do
    RDF.NTriples.read_file!(file)
  end

  defp data_env do
    __ENV__
  end


  defmacro define_vocab_terms(terms, base_uri) do
    Enum.map terms, fn term ->
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
        @tmp_uri term_to_uri(@base_uri, unquote(term))
        @doc "<#{@tmp_uri}>"
        def unquote(term |> String.to_atom)(), do: @tmp_uri
      end
    end
  end

  defp data_vocab_terms(data, base_uri) do
    data
    |> RDF.Graph.resources # TODO: support also RDF.Datasets ...
    # filter URIs
    |> Stream.filter(fn
        %URI{} -> true
        _      -> false
       end)
    |> Stream.map(&to_string/1)
    |> Stream.map(&(strip_base_uri(&1, base_uri)))
    |> Enum.filter(&vocab_term?/1)
  end

  defp group_terms_by_case(terms) do
    Enum.group_by terms, fn term ->
      if lowercase?(term),
        do:   :lowercased,
        else: :capitalized
    end
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

  defp vocab_term?(term) when is_binary(term) do
    not String.contains?(term, "/")
  end
  defp vocab_term?(_), do: false

  @doc false
  def term_to_uri(base_uri, term) do
    URI.parse(base_uri <> to_string(term))
  end

end
