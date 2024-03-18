defmodule RDF.Vocabulary.Namespace do
  @moduledoc """
  An RDF vocabulary as a `RDF.Namespace`.

  `RDF.Vocabulary.Namespace` modules represent an RDF vocabulary as a `RDF.Namespace`.
  They can be defined with the `defvocab/2` macro of this module.

  RDF.ex comes with predefined modules for some fundamental vocabularies in
  the `RDF.NS` module.

  For an introduction into `RDF.Vocabulary.Namespace`s see [this guide](https://rdf-elixir.dev/rdf-ex/namespaces.html).
  """

  alias RDF.{Description, Graph, Dataset, Vocabulary, Namespace, IRI}
  alias RDF.Vocabulary.Namespace.TermMapping

  import RDF.Vocabulary, only: [term_to_iri: 2]

  @type t :: module

  @type base_uri :: IRI.t() | String.t()

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__)
    end
  end

  @doc """
  Defines a `RDF.Vocabulary.Namespace` module for a RDF vocabulary.

  ## Options

  - `:base_iri` (required): the base IRI of the vocabulary namespace
  - `:file`: a path to a file in the `priv/vocabs` directory from which terms starting
    with the specified `base_iri` should be loaded
  - `:data`: a `RDF.Graph` or `RDF.Dataset` from which terms starting with the specified
     `base_iri` should be loaded
  - `:terms`: the list of terms of the vocabulary namespace, which can also contain
     aliases directly as keywords
  - `:alias`: a keyword list of aliases for terms with the aliases as keys and aliased
     terms as values
  - `:ignore`: a list of terms to be ignored
  - `:strict`: when set to `false` terms not specified are nevertheless resolved by
    simple concatenation of the specified base IRI with the term (default: `true`)
  - `:invalid_characters`: allows to specify what should happen when a term contains
    invalid characters
    - `:fail`: raises an error  (default)
    - `:ignore`: ignores terms with invalid characters
    - `:warn`: raises a warning and ignores terms with invalid characters
  - `:case_violations`: allows to specify what should happen with case violations of
     the term, the following values are allowed
    - `:warn`: raises a warning (default)
    - `:fail`: raises an error
    - `:ignore`: ignores terms with case violations
    - `:auto_fix`: fixes a case violation by automatically defining an alias with
      the proper casing of the first letter
    - an anonymous function or `{module, fun_name}` tuple to an external function,
      which receives a `:resource` or `:property` atom and a case violated term and
      returns a properly cased alias in an ok tuple
  - `:allow_lowercase_resource_terms`: allows to specify that lower-cased non-property
     terms are not considered a case violation by setting this option to `true`
     (default: `false`)

  Besides `:base_iri` one of the `:terms`, `:file` or `:data` options must be provided.
  The `:file` and `:data` options are not allowed to be provided together.
  When the `:terms` option is given in conjunction with one of the `:file` and `:data`
  options, it has a different semantics as given alone: it restricts the terms loaded
  from the vocabulary data to the specified terms.

  ## Example

      defmodule YourApp.NS do
        use RDF.Vocabulary.Namespace

        defvocab EX1,
          base_iri: "http://www.example.com/ns1/",
          terms: [:Foo, :bar]

        defvocab EX2,
          base_iri: "http://www.example.com/ns2/",
          file: "your_vocabulary.ttl",
          case_violations: :fail,
          terms: fn
            _, "_" <> _     -> :ignore
            _, "erroneous"  -> {:error, "erroneous term"}
            :resource, term -> {:ok, Recase.to_pascal(term)}
            :property, term -> {:ok, Recase.to_snake(term)}
      end

  > #### Warning {: .warning}
  >
  > This macro is intended to be used at compile-time, i.e. in the body of a
  > `defmodule` definition. If you want to create `RDF.Vocabulary.Namespace`s
  > dynamically at runtime, please use `create/5`.

  """
  defmacro defvocab(module, spec) do
    env = __CALLER__
    stacktrace = Macro.Env.stacktrace(env)
    module = Namespace.fully_qualified_module(module, env)
    {base_iri, spec} = Keyword.pop(spec, :base_iri)
    {input, opts} = input(module, stacktrace, spec)
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

  defp input(module, stacktrace, opts) do
    case extract_input(opts) do
      {[], _} ->
        TermMapping.raise_error(
          stacktrace,
          ArgumentError,
          "none of #{Enum.join(@required_input_opts, ", ")} are given on defvocab for #{module}"
        )

      {[{_, input}], opts} ->
        {input, opts}

      {inputs, opts} ->
        if Keyword.has_key?(inputs, :file) and Keyword.has_key?(inputs, :data) do
          TermMapping.raise_error(
            stacktrace,
            ArgumentError,
            "both :file and :data are given on defvocab for #{module}"
          )
        else
          {term_restriction, [{_, input}]} = Keyword.pop!(inputs, :terms)
          {input, Keyword.put(opts, :term_restriction, term_restriction)}
        end
    end
  end

  defp extract_input(opts) do
    Enum.reduce(@required_input_opts, {[], opts}, fn input_opt, {inputs, opts} ->
      case Keyword.pop(opts, input_opt) do
        {nil, opts} -> {inputs, opts}
        {input, opts} -> {[{input_opt, input} | inputs], opts}
      end
    end)
  end

  defp no_warn_undefined(module) do
    quote do
      @compile {:no_warn_undefined, unquote(module)}
    end
  end

  @doc """
  Creates a `RDF.Vocabulary.Namespace` module with the given name.

  Except for the `:base_uri` and the value of one of the `:terms`, `:file` or `:data`
  options of `defvocab/2`, which are given as second and third argument respectively,
  all options of `defvocab/2` can be given as `opts`. One notable difference is the
  overloaded use of the `:terms` option as a restriction of the terms loaded from a
  `:file` or `:data`. The term restriction in this case has to be provided with the
  `:term_restriction` keyword option.

  The line where the module is defined and its file must be passed as `location`.

  It returns a tuple of shape `{:module, module, binary, term}` where `module` is
  the module name, `binary` is the module bytecode.

  Similar to `Module.create/3`, the binary will only be written to disk as a
  `.beam` file if `RDF.Namespace.Vocabulary.create/3` is invoked in a file
  that is currently being compiled.
  """
  @spec create(
          module,
          base_uri,
          binary | Graph.t() | Dataset.t() | keyword,
          Macro.Env.t(),
          keyword
        ) ::
          {:ok, {:module, module(), binary(), term()}} | {:error, any}
  def create(module, base_uri, vocab, location, opts)

  def create(module, base_uri, file, location, opts) when is_binary(file) do
    compile_path = Vocabulary.compile_path(file)

    create(
      module,
      base_uri,
      RDF.Serialization.read_file!(compile_path, base_iri: nil),
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
    term_mapping = TermMapping.new(module, base_uri, terms, Macro.Env.stacktrace(location), opts)

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

  @spec create!(
          module,
          base_uri,
          binary | Graph.t() | Dataset.t() | keyword,
          Macro.Env.t(),
          keyword
        ) ::
          {:module, module(), binary(), term()}
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
      {:ok, app_name} -> Vocabulary.path(app_name, path)
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
