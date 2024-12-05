defmodule RDF.PropertyMap do
  @moduledoc """
  A bidirectional mapping from atom names to `RDF.IRI`s of properties.

  These mappings can be used in all functions of the RDF data structures
  to provide the meaning of the predicate terms in input statements or
  define how the IRIs of predicates should be mapped with the value mapping
  functions like `RDF.Description.values/2` etc.
  The `:context` option of these functions either take a `RDF.PropertyMap` directly
  or anything from which a `RDF.PropertyMap` can be created with `new/1`.

  Because the mapping is bidirectional each term and IRI can be used only in
  one mapping of a `RDF.PropertyMap`.

  This module implements the `Enumerable` protocol and the `Access` behaviour.
  """

  defstruct iris: %{}, terms: %{}

  alias RDF.IRI
  import RDF.Guards
  import RDF.Utils, only: [downcase?: 1]

  @type coercible_term :: atom | String.t()

  @type t :: %__MODULE__{
          iris: %{atom => IRI.t()},
          terms: %{IRI.t() => atom}
        }

  @type input :: t | map | keyword | RDF.Namespace.t() | RDF.Vocabulary.Namespace.t()

  @behaviour Access

  @doc """
  Creates an empty `RDF.PropertyMap`.
  """
  @spec new :: t
  def new(), do: %__MODULE__{}

  @doc """
  Creates a new `RDF.PropertyMap` with initial mappings.

  See `add/2` for the different forms in which mappings can be provided.
  """
  @spec new(input) :: t
  def new(%__MODULE__{} = initial), do: initial

  def new(initial) do
    {:ok, property_map} = new() |> add(initial)

    property_map
  end

  @doc false
  def from_opts(opts)
  def from_opts(nil), do: nil
  def from_opts(opts), do: if(property_map = Keyword.get(opts, :context), do: new(property_map))

  @doc """
  Returns the list of all terms in the given `property_map`.
  """
  @spec terms(t) :: [atom]
  def terms(%__MODULE__{iris: iris}), do: Map.keys(iris)

  @doc """
  Returns the list of all IRIs in the given `property_map`.
  """
  @spec iris(t) :: [IRI.t()]
  def iris(%__MODULE__{terms: terms}), do: Map.keys(terms)

  @doc """
  Returns the IRI for the given `term` in `property_map`.

  Returns `nil`, when the given `term` is not present in `property_map`.
  """
  @spec iri(t, coercible_term) :: IRI.t() | nil
  def iri(%__MODULE__{} = property_map, term) do
    Map.get(property_map.iris, coerce_term(term))
  end

  @doc """
  Returns the term for the given `namespace` in `prefix_map`.

  Returns `nil`, when the given `namespace` is not present in `prefix_map`.
  """
  @spec term(t, IRI.coercible()) :: atom | nil
  def term(%__MODULE__{} = property_map, iri) do
    Map.get(property_map.terms, IRI.new(iri))
  end

  @doc """
  Returns whether a mapping for the given `term` is defined in `property_map`.
  """
  @spec iri_defined?(t, coercible_term) :: boolean
  def iri_defined?(%__MODULE__{} = property_map, term) do
    Map.has_key?(property_map.iris, coerce_term(term))
  end

  @doc """
  Returns whether a mapping for the given `iri` is defined in `property_map`.
  """
  @spec term_defined?(t, IRI.coercible()) :: boolean
  def term_defined?(%__MODULE__{} = property_map, iri) do
    Map.has_key?(property_map.terms, IRI.new(iri))
  end

  @impl Access
  def fetch(%__MODULE__{} = property_map, term) do
    Access.fetch(property_map.iris, coerce_term(term))
  end

  @doc """
  Adds a property mapping between `term` and `iri` to `property_map`.

  Unless another mapping for `term` or `iri` already exists, an `:ok` tuple
  is returned, otherwise an `:error` tuple.
  """
  @spec add(t, coercible_term, IRI.coercible()) :: {:ok, t} | {:error, String.t()}
  def add(%__MODULE__{} = property_map, term, iri) do
    do_set(property_map, :add, coerce_term(term), IRI.new(iri))
  end

  @doc """
  Adds a set of property mappings to `property_map`.

  The mappings can be passed in various ways:

  - as keyword lists or maps where terms for the RDF properties can
    be given as atoms or strings, while the property IRIs can be given as
    `RDF.IRI`s or strings
  - a strict `RDF.Vocabulary.Namespace` from which all lowercase terms are added
    with their respective IRI; since IRIs can also be once in a
    `RDF.PropertyMap` a defined alias term is preferred over an original term
  - a `RDF.Namespace` from which all lowercase terms are added
    with their respective IRI
  - another `RDF.PropertyMap` from which all mappings are merged

  Unless a mapping for any of the terms or IRIs in the `input` already exists,
  an `:ok` tuple is returned, otherwise an `:error` tuple.
  """
  @spec add(t, input) :: {:ok, t} | {:error, String.t()}
  def add(%__MODULE__{} = property_map, namespace) when maybe_ns_term(namespace) do
    is_vocabulary_namespace = RDF.Vocabulary.Namespace.vocabulary_namespace?(namespace)

    cond do
      not is_vocabulary_namespace and RDF.Namespace.namespace?(namespace) ->
        add(property_map, mapping_from_namespace(namespace))

      not is_vocabulary_namespace ->
        raise ArgumentError, "expected a vocabulary namespace, but got #{namespace}"

      not apply(namespace, :__strict__, []) ->
        raise ArgumentError,
              "expected a strict vocabulary namespace, but #{namespace} is non-strict"

      true ->
        add(property_map, mapping_from_vocab_namespace(namespace))
    end
  end

  def add(%__MODULE__{} = property_map, mappings) do
    Enum.reduce_while(mappings, {:ok, property_map}, fn {term, iri}, {:ok, property_map} ->
      case add(property_map, term, iri) do
        {:ok, property_map} -> {:cont, {:ok, property_map}}
        error -> {:halt, error}
      end
    end)
  end

  @doc """
  Adds a set of property mappings to `property_map` and raises an error on conflicts.

  See `add/2` for the different forms in which mappings can be provided.
  """
  @spec add!(t, input) :: t
  def add!(%__MODULE__{} = property_map, mappings) do
    case add(property_map, mappings) do
      {:ok, property_map} -> property_map
      {:error, error} -> raise error
    end
  end

  @doc """
  Adds a property mapping between `term` and `iri` to `property_map` overwriting existing mappings.
  """
  @spec put(t, coercible_term, IRI.coercible()) :: t
  def put(%__MODULE__{} = property_map, term, iri) do
    {:ok, added} = do_set(property_map, :put, coerce_term(term), IRI.new(iri))
    added
  end

  @doc """
  Adds a set of property mappings to `property_map` overwriting all existing mappings.

  See `add/2` for the different forms in which mappings can be provided.

  Note, that not just all mappings with the used terms in the input `mappings`
  are overwritten, but also all mappings with IRIs in the input `mappings`
  """
  @spec put(t, input) :: t
  def put(%__MODULE__{} = property_map, mappings) do
    Enum.reduce(mappings, property_map, fn {term, iri}, property_map ->
      put(property_map, term, iri)
    end)
  end

  defp do_set(property_map, op, term, iri) do
    do_set(property_map, op, term, iri, Map.get(property_map.iris, term))
  end

  defp do_set(property_map, op, term, new_iri, old_iri) do
    do_set(property_map, op, term, new_iri, old_iri, Map.get(property_map.terms, new_iri))
  end

  defp do_set(property_map, _, _, iri, iri, _), do: {:ok, property_map}

  defp do_set(property_map, _, term, iri, nil, nil) do
    {:ok,
     %__MODULE__{
       property_map
       | iris: Map.put(property_map.iris, term, iri),
         terms: Map.put(property_map.terms, iri, term)
     }}
  end

  defp do_set(_context, :add, term, new_iri, old_iri, nil) do
    {:error, "conflicting mapping for #{term}: #{new_iri}; already mapped to #{old_iri}"}
  end

  defp do_set(_context, :add, term, iri, _, old_term) do
    {:error,
     "conflicting mapping for #{term}: #{iri}; IRI already mapped to #{inspect(old_term)}"}
  end

  defp do_set(property_map, :put, term, new_iri, old_iri, nil) do
    %__MODULE__{property_map | terms: Map.delete(property_map.terms, old_iri)}
    |> do_set(:put, term, new_iri, nil, nil)
  end

  defp do_set(property_map, :put, term, new_iri, old_iri, old_term) do
    %__MODULE__{property_map | iris: Map.delete(property_map.iris, old_term)}
    |> do_set(:put, term, new_iri, old_iri, nil)
  end

  @doc """
  Deletes the property mapping for `term` from `property_map`.

  If no mapping for `term` exists, `property_map` is returned unchanged.
  """
  @spec delete(t, coercible_term) :: t
  def delete(%__MODULE__{} = property_map, term) do
    term = coerce_term(term)

    if iri = Map.get(property_map.iris, term) do
      %__MODULE__{
        property_map
        | iris: Map.delete(property_map.iris, term),
          terms: Map.delete(property_map.terms, iri)
      }
    else
      property_map
    end
  end

  @doc """
  Drops the given `terms` from the `property_map`.

  If `terms` contains terms that are not in `property_map`, they're simply ignored.
  """
  @spec drop(t, [coercible_term]) :: t
  def drop(%__MODULE__{} = property_map, terms) when is_list(terms) do
    Enum.reduce(terms, property_map, fn term, property_map ->
      delete(property_map, term)
    end)
  end

  defp coerce_term(term) when is_atom(term), do: term
  defp coerce_term(term) when is_binary(term), do: String.to_atom(term)

  defp mapping_from_vocab_namespace(vocab_namespace) do
    aliases = apply(vocab_namespace, :__term_aliases__, [])

    apply(vocab_namespace, :__terms__, [])
    |> Enum.filter(&downcase?/1)
    |> Enum.map(fn term -> {term, apply(vocab_namespace, term, [])} end)
    |> Enum.group_by(fn {_term, iri} -> iri end)
    |> Map.new(fn
      {_, [mapping]} ->
        mapping

      {_, mappings} ->
        Enum.find(mappings, fn {term, _iri} -> term in aliases end) ||
          raise "conflicting non-alias terms for IRI should not occur in a vocab namespace"
    end)
  end

  defp mapping_from_namespace(namespace) do
    apply(namespace, :__term_mapping__, [])
    |> Enum.filter(fn {term, _} -> downcase?(term) end)
  end

  @impl Access
  def pop(%__MODULE__{} = property_map, term) do
    case Access.pop(property_map.iris, coerce_term(term)) do
      {nil, _} ->
        {nil, property_map}

      {iri, new_context_map} ->
        {iri, %__MODULE__{iris: new_context_map}}
    end
  end

  @impl Access
  def get_and_update(property_map, term, fun) do
    term = coerce_term(term)
    current = iri(property_map, term)

    case fun.(current) do
      {old_iri, new_iri} ->
        {:ok, property_map} = do_set(property_map, :put, term, IRI.new(new_iri), IRI.new(old_iri))
        {old_iri, property_map}

      :pop ->
        {current, delete(property_map, term)}

      other ->
        raise "the given function must return a two-element tuple or :pop, got: #{inspect(other)}"
    end
  end

  @doc """
  Converts property map to a list.

  Each term-IRI pair in the property map is converted to a two-element tuple
  `{term, iri}` in the resulting list.

  ## Examples

      iex> RDF.PropertyMap.new(foo: "http://example.com/foo") |> RDF.PropertyMap.to_list()
      [foo: ~I<http://example.com/foo>]

  """
  @spec to_list(t()) :: [{atom, IRI.t()}]
  def to_list(%__MODULE__{iris: iris}), do: Map.to_list(iris)

  @doc """
  Converts property map to a list sorted by property.

  Each term-IRI pair in the property map is converted to a two-element tuple
  `{term, iri}` in the resulting list.

  ## Examples

      iex> RDF.PropertyMap.new(
      ...>   foo: "http://example.com/foo",
      ...>   bar: "http://example.com/bar")
      ...> |> RDF.PropertyMap.to_sorted_list()
      [bar: ~I<http://example.com/bar>, foo: ~I<http://example.com/foo>]

  """
  @spec to_sorted_list(t()) :: [{atom, IRI.t()}]
  def to_sorted_list(%__MODULE__{iris: iris}) do
    Enum.sort(iris, fn
      {property1, _}, {property2, _} -> property1 < property2
    end)
  end

  defimpl Enumerable do
    alias RDF.PropertyMap
    def reduce(%PropertyMap{iris: iris}, acc, fun), do: Enumerable.reduce(iris, acc, fun)

    def member?(%PropertyMap{iris: iris}, mapping), do: Enumerable.member?(iris, mapping)
    def count(%PropertyMap{iris: iris}), do: Enumerable.count(iris)

    def slice(%PropertyMap{iris: iris}) do
      size = map_size(iris)
      {:ok, size, &PropertyMap.to_list/1}
    end
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(property_map, opts) do
      map = RDF.PropertyMap.to_sorted_list(property_map)
      open = color("RDF.PropertyMap.new(%{", :map, opts)
      sep = color(",", :map, opts)
      close = color("})", :map, opts)

      container_doc(open, map, close, opts, &to_map(&1, &2, color(" => ", :map, opts)),
        separator: sep,
        break: :strict
      )
    end

    defp to_map({key, value}, opts, sep) do
      concat(concat(to_doc(key, opts), sep), to_doc(value, opts))
    end
  end
end
