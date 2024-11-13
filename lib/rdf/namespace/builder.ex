defmodule RDF.Namespace.Builder do
  @moduledoc false

  alias RDF.{Description, IRI}

  import RDF.Utils

  @type term_mapping :: map | keyword

  @spec create(module, term_mapping, Macro.Env.t() | keyword, keyword) ::
          {:ok, {:module, module(), binary(), term()}} | {:error, any}
  def create(module, term_mapping, location, opts \\ []) do
    moduledoc = opts[:moduledoc]
    skip_normalization = opts[:skip_normalization]

    with {:ok, term_mapping} <- normalize_term_mapping(term_mapping, skip_normalization) do
      property_terms = property_terms(term_mapping)

      body =
        quote do
          unquote(List.wrap(define_module_header(moduledoc)))

          unquote_splicing(Enum.map(property_terms, &define_property_function/1))

          unquote(
            Keyword.get_lazy(opts, :namespace_functions, fn ->
              define_namespace_functions(term_mapping)
            end)
          )

          unquote_splicing(List.wrap(Keyword.get(opts, :add_after)))
        end

      {:ok, Module.create(module, body, location)}
    end
  end

  @spec create!(module, term_mapping, Macro.Env.t() | keyword, keyword) ::
          {:module, module(), binary(), term()}
  def create!(module, term_mapping, location, opts \\ []) do
    case create(module, term_mapping, location, opts) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  defp define_module_header(moduledoc) do
    quote do
      @moduledoc unquote(moduledoc)

      @behaviour RDF.Namespace

      import Kernel,
        except: [
          min: 2,
          max: 2,
          div: 2,
          rem: 2,
          abs: 1,
          ceil: 1,
          floor: 1,
          elem: 2,
          send: 2,
          apply: 2,
          destructure: 2,
          get_and_update_in: 2,
          get_in: 2,
          pop_in: 2,
          put_in: 2,
          put_elem: 2,
          update_in: 2,
          raise: 2,
          reraise: 2,
          inspect: 2,
          struct: 1,
          struct: 2,
          use: 1,
          use: 2
        ]
    end
  end

  defp define_property_function({term, iri}) do
    quote do
      @doc "<#{unquote(to_string(iri))}>"
      def unquote(term)(), do: unquote(Macro.escape(iri))

      @doc "`RDF.Description` property accessor for `#{unquote(term)}/0`"
      def unquote(term)(%Description{} = subject) do
        Description.get(subject, unquote(Macro.escape(iri)))
      end

      @doc "`RDF.Description` builder for `#{unquote(term)}/0`"
      def unquote(term)(subject, object)

      def unquote(term)(%Description{} = subject, object) do
        Description.add(subject, {unquote(Macro.escape(iri)), object})
      end

      def unquote(term)(subject, object) do
        Description.new(subject, init: {unquote(Macro.escape(iri)), object})
      end
    end
  end

  defp define_namespace_functions(term_mapping) do
    quote do
      @term_mapping unquote(Macro.escape(term_mapping))
      def __term_mapping__, do: @term_mapping

      @impl Elixir.RDF.Namespace
      def __terms__, do: Map.keys(@term_mapping)

      @impl Elixir.RDF.Namespace
      def __iris__, do: Map.values(@term_mapping)

      @impl Elixir.RDF.Namespace
      def __resolve_term__(term) do
        if iri = @term_mapping[term] do
          {:ok, iri}
        else
          {:error,
           %Elixir.RDF.Namespace.UndefinedTermError{
             message: "undefined term #{term} in namespace #{__MODULE__}"
           }}
        end
      end
    end
  end

  defp normalize_term_mapping(term_mapping, true), do: {:ok, term_mapping}

  defp normalize_term_mapping(term_mapping, _) do
    Enum.reduce_while(term_mapping, {:ok, %{}}, fn {term, iri}, {:ok, normalized} ->
      if valid_term?(term) do
        {:cont, {:ok, Map.put(normalized, term, IRI.new(iri))}}
      else
        {:halt,
         {:error, %RDF.Namespace.InvalidTermError{message: "invalid term: #{inspect(term)}"}}}
      end
    end)
  end

  defp property_terms(term_mapping) do
    for {term, iri} <- term_mapping, downcase?(term), into: %{} do
      {term, iri}
    end
  end

  @reserved_terms ~w[
    and
    or
    xor
    in
    fn
    def
    defp
    defdelegate
    defexception
    defguard
    defguardp
    defimpl
    defmacro
    defmacrop
    defmodule
    defoverridable
    defprotocol
    defstruct
    function_exported?
    macro_exported?
    when
    if
    unless
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
    __info__
  ]a

  def reserved_terms, do: @reserved_terms

  def reserved_term?(term) when term in @reserved_terms, do: true
  def reserved_term?(_), do: false

  def valid_characters?(term) when is_atom(term),
    do: term |> Atom.to_string() |> valid_characters?()

  def valid_characters?(term), do: Regex.match?(~r/^[a-zA-Z_]\w*$/, term)

  def valid_term?(term), do: not reserved_term?(term) and valid_characters?(term)
end
