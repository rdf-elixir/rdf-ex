defmodule RDF.Vocabulary.Namespace do
  @moduledoc """
  An RDF vocabulary as a `RDF.Namespace`.

  `RDF.Vocabulary.Namespace` modules represent a RDF vocabulary as a `RDF.Namespace`.
  They can be defined with the `defvocab/2` macro of this module.

  RDF.ex comes with predefined modules for some fundamental vocabularies in
  the `RDF.NS` module.
  """

  alias RDF.{Description, Graph, Dataset, Vocabulary, Namespace, IRI}

  import RDF.Vocabulary.Namespace.{TermMapping, CaseValidation}
  import RDF.Vocabulary, only: [term_to_iri: 2, extract_terms: 2]

  @type t :: module

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__)
    end
  end

  @doc """
  Defines a `RDF.Vocabulary.Namespace` module for a RDF vocabulary.
  """
  defmacro defvocab({:__aliases__, _, [module]}, spec) do
    env = __CALLER__
    module = Namespace.module(env, module)
    {base_iri, spec} = Keyword.pop(spec, :base_iri)
    {input, opts} = input(module, spec)
    no_warn_undefined = if Keyword.get(opts, :strict) == false, do: no_warn_undefined(module)

    [
      quote do
        result =
          create!(
            unquote(module),
            unquote(base_iri),
            unquote(input),
            unquote(Macro.escape(env)),
            unquote(opts)
            |> Keyword.put(:moduledoc, Module.delete_attribute(__MODULE__, :vocabdoc))
          )

        alias unquote(module)

        result
      end
      | List.wrap(no_warn_undefined)
    ]
  end

  @required_input_opts ~w[file data terms]a

  defp input(module, opts), do: do_input(module, nil, opts, @required_input_opts)

  defp do_input(module, nil, _, []) do
    raise ArgumentError,
          "none of #{Enum.join(@required_input_opts, ", ")} are given on defvocab for #{module}"
  end

  defp do_input(_, input, opts, []), do: {input, opts}

  defp do_input(module, input, opts, [opt | rest]) do
    case Keyword.pop(opts, opt) do
      {nil, opts} ->
        do_input(module, input, opts, rest)

      {value, opts} ->
        if input do
          raise ArgumentError,
                "multiple values for #{Enum.join(@required_input_opts, ", ")} are given on defvocab for #{module}"
        else
          do_input(module, value, opts, rest)
        end
    end
  end

  defp no_warn_undefined(module) do
    quote do
      @compile {:no_warn_undefined, unquote(module)}
    end
  end

  def create(module, base_uri, vocab, location, opts)

  def create(module, base_uri, file, location, opts) when is_binary(file) do
    compile_path = Vocabulary.compile_path(file)

    create(
      module,
      base_uri,
      RDF.read_file!(compile_path, base_iri: nil),
      location,
      opts
      |> Keyword.put(:file, file)
      |> Keyword.put(:compile_path, compile_path)
    )
  end

  def create(module, base_uri, %struct{} = data, location, opts)
      when struct in [Graph, Dataset] do
    do_create(
      module,
      base_uri,
      extract_terms(data, base_uri),
      location,
      Keyword.put(opts, :data, data)
    )
  end

  def create(module, base_uri, terms, location, opts) do
    {terms, opts} = extract_aliases(terms, opts)
    do_create(module, base_uri, terms, location, opts)
  end

  defp do_create(module, base_uri, terms, location, opts) do
    base_uri = normalize_base_uri(base_uri)
    strict = Keyword.get(opts, :strict, true)
    ignored_terms = Keyword.get(opts, :ignore, []) |> normalize_ignored_terms()
    {terms, aliases} = normalize_terms(module, terms, ignored_terms, strict, opts)

    {terms, ignored_terms} =
      {terms, ignored_terms}
      |> validate!(opts)
      |> validate_case!(Keyword.get(opts, :data), base_uri, aliases, opts)

    Namespace.Builder.create(
      module,
      term_mapping(base_uri, terms, ignored_terms),
      location,
      if strict do
        opts
      else
        Keyword.put(opts, :add_after, define_undefined_function_handler())
      end
      |> Keyword.put(
        :namespace_functions,
        define_namespace_functions(base_uri, terms, ignored_terms, strict, opts)
      )
      |> Keyword.put(:skip_normalization, true)
    )
  end

  def create!(module, base_uri, vocab, env, opts) do
    case create(module, base_uri, vocab, env, opts) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  def define_namespace_functions(base_iri, terms, ignored_terms, strict, opts) do
    file = Keyword.get(opts, :file)
    compile_path = Keyword.get(opts, :compile_path)

    quote do
      if unquote(file) do
        @external_resource unquote(compile_path)

        @spec __file__ :: String.t() | nil
        def __file__, do: unquote(__MODULE__).path(__MODULE__, unquote(file))
      else
        @spec __file__ :: nil
        def __file__, do: nil
      end

      @strict unquote(strict)
      @spec __strict__ :: boolean
      def __strict__, do: @strict

      @base_iri unquote(base_iri)
      @spec __base_iri__ :: String.t()
      def __base_iri__, do: @base_iri

      @terms unquote(Macro.escape(terms))
      @impl Elixir.RDF.Namespace
      def __terms__, do: Map.keys(@terms)

      @spec __term_aliases__ :: [atom]
      def __term_aliases__, do: RDF.Vocabulary.Namespace.TermMapping.aliases(@terms)

      @ignored_terms unquote(Macro.escape(ignored_terms))

      @doc """
      Returns all known IRIs of the vocabulary.
      """
      @impl Elixir.RDF.Namespace
      def __iris__ do
        @terms
        |> Enum.map(fn
          {term, true} -> term_to_iri(@base_iri, term)
          {_alias, term} -> term_to_iri(@base_iri, term)
        end)
        |> Enum.uniq()
      end

      @impl Elixir.RDF.Namespace
      @dialyzer {:nowarn_function, __resolve_term__: 1}
      def __resolve_term__(term) do
        case @terms[term] do
          nil ->
            if @strict or MapSet.member?(@ignored_terms, term) do
              {:error,
               %Elixir.RDF.Namespace.UndefinedTermError{
                 message: "undefined term #{term} in strict vocabulary #{__MODULE__}"
               }}
            else
              {:ok, term_to_iri(@base_iri, term)}
            end

          true ->
            {:ok, term_to_iri(@base_iri, term)}

          original_term ->
            {:ok, term_to_iri(@base_iri, original_term)}
        end
      end
    end
  end

  def define_undefined_function_handler do
    quote do
      def unquote(:"$handle_undefined_function")(term, []) do
        if MapSet.member?(@ignored_terms, term) do
          raise UndefinedFunctionError
        end

        term_to_iri(@base_iri, term)
      end

      def unquote(:"$handle_undefined_function")(term, [subject | objects]) do
        if MapSet.member?(@ignored_terms, term) do
          raise UndefinedFunctionError
        end

        objects =
          case objects do
            [objects] when is_list(objects) -> objects
            _ -> objects
          end

        case subject do
          %Description{} -> subject
          _ -> Description.new(subject)
        end
        |> Description.add({term_to_iri(@base_iri, term), objects})
      end
    end
  end

  defp normalize_base_uri(%IRI{} = base_iri), do: IRI.to_string(base_iri)

  defp normalize_base_uri(base_uri) when is_binary(base_uri) do
    if IRI.valid?(base_uri) do
      base_uri
    else
      raise RDF.Namespace.InvalidVocabBaseIRIError, "invalid base IRI: #{inspect(base_uri)}"
    end
  end

  defp normalize_base_uri(base_uri) do
    base_uri |> IRI.new() |> normalize_base_uri()
  rescue
    [Namespace.UndefinedTermError, IRI.InvalidError, FunctionClauseError] ->
      reraise RDF.Namespace.InvalidVocabBaseIRIError,
              "invalid base IRI: #{inspect(base_uri)}",
              __STACKTRACE__
  end

  @doc false
  def path(module, path) do
    case :application.get_application(module) do
      :undefined -> nil
      {:ok, app_name} -> Path.join([:code.priv_dir(app_name), Vocabulary.dir(), path])
    end
  end

  @doc false
  @spec vocabulary_namespace?(module) :: boolean
  def vocabulary_namespace?(name) do
    case Code.ensure_compiled(name) do
      {:module, name} -> function_exported?(name, :__base_iri__, 0)
      _ -> false
    end
  end
end
