defmodule RDF.Vocabulary do # or RDF.URI.Namespace?
  @moduledoc """
  Defines a RDF Vocabulary.

  A `RDF.Vocabulary` is a collection of URIs and serves as a namespace for its
  elements, called terms. The terms can be accessed by qualification on the
  resp. Vocabulary module.

  ## Using a Vocabulary

  There are two types of terms in a `RDF.Vocabulary`, which are resolved
  differently:

  1. Lowercased terms (usually used for RDF properties, but this is not
    enforced) are represented as functions on a Vocabulary module and return the
    URI directly.
  2. Uppercased terms are by standard Elixir semantics modules names, i.e.
    atoms. In many in RDF.ex, where an URI is expected, you can use atoms
    qualified with a `RDF.Vocabulary` directly, but if you want to resolve it
    manually, you can pass the `RDF.Vocabulary` qualified atom to `RDF.uri`.

  Examples:

      iex> RDF.RDFS.subClassOf
      %URI{authority: "www.w3.org", fragment: "subClassOf", host: "www.w3.org",
       path: "/2000/01/rdf-schema", port: 80, query: nil, scheme: "http",
       userinfo: nil}
      iex> RDF.RDFS.Class
      RDF.RDFS.Class
      iex> RDF.uri(RDF.RDFS.Class)
      %URI{authority: "www.w3.org", fragment: "Class", host: "www.w3.org",
       path: "/2000/01/rdf-schema", port: 80, query: nil, scheme: "http",
       userinfo: nil}
      iex> RDF.triple(RDF.RDFS.Class, RDF.RDFS.subClass, RDF.RDFS.Resource)
      {RDF.uri(RDF.RDFS.Class), RDF.uri(RDF.RDFS.subClass), RDF.uri(RDF.RDFS.Resource)}


  ## Strict vocabularies

  What is a strict vocabulary and why should I use them over non-strict
  vocabularies and define all terms ...


  ## Defining a vocabulary

  There are two basic ways to define a vocabulary:

  1. You can define all terms manually.
  2. You can load all terms from a specified namespace in a given dataset or
     graph.

  Either way, you'll first have to define a new module for your vocabulary:

      defmodule ExampleVocab do
        use RDF.Vocabulary, base_uri: "http://www.example.com/ns/"

        # Your term definitions
      end

  The `base_uri` argument with the URI prefix of all the terms in the defined
  vocabulary is required and expects a valid URI ending with either a `"/"` or
  a `"#"`.


  ## Reflection

  `__base_uri__` and `__terms__` ...
  """

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts], unquote: true do
      import unquote(__MODULE__)

      # TODO: @terms should be a MapSet for faster term lookup
      Module.register_attribute __MODULE__, :terms, accumulate: true

      @before_compile unquote(__MODULE__)

      @strict Keyword.get(opts, :strict, false)

      with {:ok, base_uri} <- Keyword.fetch(opts, :base_uri),
           true <- base_uri |> String.ends_with?(["/", "#"]) do
        @base_uri base_uri
      else
        :error ->
          raise RDF.Vocabulary.InvalidBaseURIError, "required base_uri missing"
        false  ->
          raise RDF.Vocabulary.InvalidBaseURIError,
                  "a base_uri without a trailing '/' or '#' is invalid"
      end

      def __base_uri__, do: @base_uri
      def __strict__, do: @strict

      unless @strict do
        def unquote(:"$handle_undefined_function")(term, args) do
          RDF.Vocabulary.term_to_uri(@base_uri, term)
        end
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def __terms__, do: @terms

      if @strict do
        def uri(term) do
          if Enum.member?(@terms, term) do
            RDF.Vocabulary.term_to_uri(@base_uri, term)
          else
            raise RDF.Vocabulary.UndefinedTermError,
              "undefined term #{term} in strict vocabulary #{__MODULE__}"
          end
        end
      else
        def uri(term) do
          RDF.Vocabulary.term_to_uri(@base_uri, term)
        end
      end
    end
  end

  @doc """
  Defines an URI via a term concatenated to the `base_uri` of the vocabulary
  module.
  """
  defmacro defuri(term) when is_atom(term) do
    quote do
      @terms unquote(term)

      if Atom.to_string(unquote(term)) =~ ~r/^\p{Ll}/u do
#  TODO: the URI should be built at compile-time
        # uri = RDF.Vocabulary.term_to_uri(@base_uri, unquote(term))
        def unquote(term)() do
          URI.parse(__base_uri__() <> to_string(unquote(term)))
        end
      end
    end
  end

  @doc false
  def term_to_uri(base_uri, term) do
    URI.parse(base_uri <> to_string(term))
  end

  @doc false
  def __uri__(uri = %URI{}), do: uri
  def __uri__(namespaced_atom) when is_atom(namespaced_atom) do
    case namespaced_atom
    |> to_string
    |> String.reverse
    |> String.split(".", parts: 2)
    |> Enum.map(&String.reverse/1)
    |> Enum.map(&String.to_existing_atom/1) do
      [term, vocabulary] -> vocabulary.uri(term)
      _ -> raise RDF.Vocabulary.InvalidTermError, ""
    end

  end

end
