defmodule RDF.Vocabulary.Namespace do
  @moduledoc """
  An RDF vocabulary as a `RDF.Namespace`.

  `RDF.Vocabulary.Namespace` modules represent a RDF vocabulary as a `RDF.Namespace`.
  They can be defined with the `defvocab/2` macro of this module.

  RDF.ex comes with predefined modules for some fundamental vocabularies in
  the `RDF.NS` module.
  """

  alias RDF.{Description, Graph, Dataset, Vocabulary, Namespace, IRI}
  alias RDF.Vocabulary.Namespace.TermMapping

  import RDF.Vocabulary, only: [term_to_iri: 2]

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
    create(
      module,
      base_uri,
      Vocabulary.extract_terms(data, base_uri),
      location,
      Keyword.put(opts, :data, data)
    )
  end

  def create(module, base_uri, terms, location, opts) do
    term_mapping = TermMapping.new(module, base_uri, terms, opts)

    namespace_builder_opts =
      if term_mapping.strict do
        opts
      else
        Keyword.put(opts, :add_after, define_undefined_function_handler())
      end
      |> Keyword.put(
        :namespace_functions,
        define_namespace_functions(term_mapping, opts)
      )
      |> Keyword.put(:skip_normalization, true)

    Namespace.Builder.create(
      module,
      TermMapping.term_mapping(term_mapping),
      location,
      namespace_builder_opts
    )
  end

  def create!(module, base_uri, vocab, env, opts) do
    case create(module, base_uri, vocab, env, opts) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  defp define_namespace_functions(term_mapping, opts) do
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

      @strict unquote(term_mapping.strict)
      @spec __strict__ :: boolean
      def __strict__, do: @strict

      @base_iri unquote(term_mapping.base_uri)
      @spec __base_iri__ :: String.t()
      def __base_iri__, do: @base_iri

      @terms unquote(Macro.escape(term_mapping.terms))
      @impl Elixir.RDF.Namespace
      def __terms__, do: Map.keys(@terms)

      @spec __term_aliases__ :: [atom]
      def __term_aliases__, do: unquote(__MODULE__).aliases(@terms)

      @ignored_terms unquote(Macro.escape(term_mapping.ignored_terms))

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
            if @strict or term in @ignored_terms do
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

  defp define_undefined_function_handler do
    quote do
      def unquote(:"$handle_undefined_function")(term, []) do
        if term in @ignored_terms do
          raise UndefinedFunctionError
        end

        term_to_iri(@base_iri, term)
      end

      def unquote(:"$handle_undefined_function")(term, [%Description{} = subject]) do
        if term in @ignored_terms do
          raise UndefinedFunctionError
        end

        Description.get(subject, term_to_iri(@base_iri, term))
      end

      def unquote(:"$handle_undefined_function")(term, [subject | objects]) do
        if term in @ignored_terms do
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

  @doc false
  def aliases(terms) do
    for {alias, term} <- terms, term != true, do: alias
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
