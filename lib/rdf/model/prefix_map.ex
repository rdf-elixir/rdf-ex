defmodule RDF.PrefixMap do
  @moduledoc """
  A mapping of prefix atoms to IRI namespaces.

  The empty prefix is represented as the `:""` atom.

  This module implements the `Enumerable` protocol.
  """

  alias RDF.IRI

  @type prefix :: atom
  @type namespace :: IRI.t()

  @type coercible_prefix :: atom | String.t()
  @type coercible_namespace :: RDF.Vocabulary.Namespace.t() | String.t() | IRI.t()

  @type prefix_map :: %{prefix => namespace}

  @type conflict_resolver ::
          (coercible_prefix, coercible_namespace, coercible_namespace -> coercible_namespace)
          | :ignore
          | :overwrite

  @type t :: %__MODULE__{
          map: prefix_map
        }

  defstruct map: %{}

  @doc """
  Creates an empty `RDF.PrefixMap`.
  """
  @spec new :: t
  def new, do: %__MODULE__{}

  @doc """
  Creates a new `RDF.PrefixMap` with initial mappings.

  The initial prefix mappings can be passed as keyword lists or maps.
  The keys for the prefixes can be given as atoms or strings and will be normalized to atoms.
  The namespaces can be given as `RDF.IRI`s or strings and will be normalized to `RDF.IRI`s.
  """
  @spec new(t | map | keyword) :: t
  def new(map)

  def new(%__MODULE__{} = prefix_map), do: prefix_map

  def new(map) when is_map(map) do
    %__MODULE__{map: Map.new(map, &normalize/1)}
  end

  def new(map) when is_list(map) do
    map |> Map.new() |> new()
  end

  defp normalize({prefix, namespace}) when is_atom(prefix),
    do: {prefix, IRI.coerce_base(namespace)}

  defp normalize({prefix, namespace}) when is_binary(prefix),
    do: normalize({String.to_atom(prefix), namespace})

  defp normalize({prefix, namespace}),
    do:
      raise(ArgumentError, "Invalid prefix mapping: #{inspect(prefix)} => #{inspect(namespace)}")

  @doc """
  Adds a prefix mapping to `prefix_map`.

  Unless a mapping of `prefix` to a different namespace already exists,
  an `:ok` tuple is returned, otherwise an `:error` tuple.
  """
  @spec add(t, coercible_prefix, coercible_namespace) :: {:ok, t} | {:error, String.t()}
  def add(prefix_map, prefix, namespace)

  def add(%__MODULE__{map: map}, prefix, %IRI{} = namespace) when is_atom(prefix) do
    if conflicts?(map, prefix, namespace) do
      {:error, "prefix #{inspect(prefix)} is already mapped to another namespace"}
    else
      {:ok, %__MODULE__{map: Map.put(map, prefix, namespace)}}
    end
  end

  def add(%__MODULE__{} = prefix_map, prefix, namespace) do
    {prefix, namespace} = normalize({prefix, namespace})
    add(prefix_map, prefix, namespace)
  end

  @doc """
  Adds a prefix mapping to the given `RDF.PrefixMap` and raises an exception in error cases.
  """
  @spec add!(t, coercible_prefix, coercible_namespace) :: t
  def add!(prefix_map, prefix, namespace) do
    case add(prefix_map, prefix, namespace) do
      {:ok, new_prefix_map} -> new_prefix_map
      {:error, error} -> raise error
    end
  end

  @doc """
  Adds a prefix mapping to `prefix_map` overwriting an existing mapping.
  """
  @spec put(t, coercible_prefix, coercible_namespace) :: t
  def put(prefix_map, prefix, namespace)

  def put(%__MODULE__{map: map}, prefix, %IRI{} = namespace) when is_atom(prefix) do
    %__MODULE__{map: Map.put(map, prefix, namespace)}
  end

  def put(%__MODULE__{} = prefix_map, prefix, namespace) do
    {prefix, namespace} = normalize({prefix, namespace})
    put(prefix_map, prefix, namespace)
  end

  @doc """
  Merges two `RDF.PrefixMap`s.

  The second prefix map can also be given as any structure which can converted
  to a `RDF.PrefixMap` via `new/1`.

  If the prefix maps can be merged without conflicts, that is there are no
  prefixes mapped to different namespaces an `:ok` tuple is returned.
  Otherwise, an `:error` tuple with the list of prefixes with conflicting
  namespaces is returned.

  See also `merge/3` which allows you to resolve conflicts with a function.
  """
  @spec merge(t, t | map | keyword) :: {:ok, t} | {:error, [atom | String.t()]}
  def merge(prefix_map1, prefix_map2)

  def merge(%__MODULE__{map: map1}, %__MODULE__{map: map2}) do
    case merge_conflicts(map1, map2) do
      [] -> {:ok, %__MODULE__{map: Map.merge(map1, map2)}}
      conflicts -> {:error, conflicts}
    end
  end

  def merge(%__MODULE__{} = prefix_map, other_prefixes) do
    merge(prefix_map, new(other_prefixes))
  rescue
    FunctionClauseError ->
      # credo:disable-for-next-line Credo.Check.Warning.RaiseInsideRescue
      raise ArgumentError, "#{inspect(other_prefixes)} is not convertible to a RDF.PrefixMap"
  end

  @doc """
  Merges two `RDF.PrefixMap`s, resolving conflicts through the given `conflict_resolver` function.

  The second prefix map can also be given as any structure which can converted
  to a `RDF.PrefixMap` via `new/1`.

  The given function will be invoked when there are conflicting mappings of
  prefixes to different namespaces; its arguments are `prefix`, `namespace1`
  (the namespace for the prefix in the first prefix map),
  and `namespace2` (the namespace for the prefix in the second prefix map).
  The value returned by the `conflict_resolver` function is used as the namespace
  for the prefix in the resulting prefix map.
  Non-`RDF.IRI` values will be tried to be converted to `RDF.IRI`s via
  `RDF.IRI.new` implicitly.

  The most common conflict resolution strategies on can be chosen directly with
  the following atoms:

  - `:ignore`: keep the original namespace from `prefix_map1`
  - `:overwrite`: use the other namespace from `prefix_map2`

  If a conflict can't be resolved, the provided function can return `nil`.
  This will result in an overall return of an `:error` tuple with the list of
  prefixes for which the conflict couldn't be resolved.

  If everything could be merged, an `:ok` tuple is returned.

  """
  @spec merge(t, t | map | keyword, conflict_resolver | nil) ::
          {:ok, t} | {:error, [atom | String.t()]}
  def merge(prefix_map1, prefix_map2, conflict_resolver)

  def merge(prefix_map1, prefix_map2, :ignore) do
    merge(prefix_map1, prefix_map2, fn _, ns, _ -> ns end)
  end

  def merge(prefix_map1, prefix_map2, :overwrite) do
    merge(prefix_map1, prefix_map2, fn _, _, ns -> ns end)
  end

  def merge(%__MODULE__{map: map1}, %__MODULE__{map: map2}, conflict_resolver)
      when is_function(conflict_resolver) do
    conflict_resolution = fn prefix, namespace1, namespace2 ->
      case conflict_resolver.(prefix, namespace1, namespace2) do
        nil -> :conflict
        result -> IRI.new(result)
      end
    end

    resolved_merge = Map.merge(map1, map2, conflict_resolution)

    case resolved_merge_rest_conflicts(resolved_merge) do
      [] -> {:ok, %__MODULE__{map: resolved_merge}}
      conflicts -> {:error, conflicts}
    end
  end

  def merge(%__MODULE__{} = prefix_map1, prefix_map2, conflict_resolver)
      when is_function(conflict_resolver) do
    merge(prefix_map1, new(prefix_map2), conflict_resolver)
  end

  def merge(prefix_map1, prefix_map2, nil), do: merge(prefix_map1, prefix_map2)

  defp resolved_merge_rest_conflicts(map) do
    Enum.reduce(map, [], fn
      {prefix, :conflict}, conflicts -> [prefix | conflicts]
      _, conflicts -> conflicts
    end)
  end

  defp merge_conflicts(map1, map2) do
    Enum.reduce(map1, [], fn {prefix, namespace}, conflicts ->
      if conflicts?(map2, prefix, namespace) do
        [prefix | conflicts]
      else
        conflicts
      end
    end)
  end

  defp conflicts?(map, prefix, namespace) do
    (existing_namespace = Map.get(map, prefix)) && existing_namespace != namespace
  end

  @doc """
  Merges two `RDF.PrefixMap`s and raises an exception in error cases.

  See `merge/2` and `merge/3` for more information on merging prefix maps.
  """
  @spec merge!(t, t | map | keyword, conflict_resolver | nil) :: t
  def merge!(prefix_map1, prefix_map2, conflict_resolver \\ nil) do
    case merge(prefix_map1, prefix_map2, conflict_resolver) do
      {:ok, new_prefix_map} ->
        new_prefix_map

      {:error, conflicts} ->
        raise "conflicting prefix mappings: #{Enum.map_join(conflicts, ", ", &inspect/1)}"
    end
  end

  @doc """
  Deletes the prefix mapping for `prefix` from `prefix_map`.

  If no mapping for `prefix` exists, `prefix_map` is returned unchanged.
  """
  @spec delete(t, coercible_prefix) :: t
  def delete(prefix_map, prefix)

  def delete(%__MODULE__{map: map}, prefix) when is_atom(prefix) do
    %__MODULE__{map: Map.delete(map, prefix)}
  end

  def delete(prefix_map, prefix) when is_binary(prefix) do
    delete(prefix_map, String.to_atom(prefix))
  end

  @doc """
  Drops the given `prefixes` from `prefix_map`.

  If `prefixes` contains prefixes that are not in `prefix_map`, they're simply ignored.
  """
  @spec drop(t, [coercible_prefix]) :: t
  def drop(prefix_map, prefixes)

  def drop(%__MODULE__{map: map}, prefixes) do
    %__MODULE__{
      map:
        Map.drop(
          map,
          Enum.map(prefixes, fn
            prefix when is_binary(prefix) -> String.to_atom(prefix)
            other -> other
          end)
        )
    }
  end

  @doc """
  Returns if the given `prefix_map` is empty.
  """
  @spec empty?(t) :: boolean
  def empty?(%__MODULE__{} = prefix_map) do
    Enum.empty?(prefix_map.map)
  end

  @doc """
  Returns the namespace for the given `prefix` in `prefix_map`.

  Returns `nil`, when the given `prefix` is not present in `prefix_map`.
  """
  @spec namespace(t, coercible_prefix) :: namespace | nil
  def namespace(prefix_map, prefix)

  def namespace(%__MODULE__{map: map}, prefix) when is_atom(prefix) do
    Map.get(map, prefix)
  end

  def namespace(prefix_map, prefix) when is_binary(prefix) do
    namespace(prefix_map, String.to_atom(prefix))
  end

  @doc """
  Returns the prefix for the given `namespace` in `prefix_map`.

  Returns `nil`, when the given `namespace` is not present in `prefix_map`.
  """
  @spec prefix(t, coercible_namespace) :: coercible_prefix | nil
  def prefix(prefix_map, namespace)

  def prefix(%__MODULE__{map: map}, %IRI{} = namespace) do
    Enum.find_value(map, fn {prefix, ns} -> ns == namespace && prefix end)
  end

  def prefix(prefix_map, namespace) when is_binary(namespace) do
    prefix(prefix_map, IRI.new(namespace))
  end

  @doc """
  Returns whether the given prefix exists in the given `RDF.PrefixMap`.
  """
  @spec has_prefix?(t, coercible_prefix) :: boolean
  def has_prefix?(prefix_map, prefix)

  def has_prefix?(%__MODULE__{map: map}, prefix) when is_atom(prefix) do
    Map.has_key?(map, prefix)
  end

  def has_prefix?(prefix_map, prefix) when is_binary(prefix) do
    has_prefix?(prefix_map, String.to_atom(prefix))
  end

  @doc """
  Returns all prefixes from the given `RDF.PrefixMap`.
  """
  @spec prefixes(t) :: [coercible_prefix]
  def prefixes(%__MODULE__{map: map}) do
    Map.keys(map)
  end

  @doc """
  Returns all namespaces from the given `RDF.PrefixMap`.
  """
  @spec namespaces(t) :: [coercible_namespace]
  def namespaces(%__MODULE__{map: map}) do
    Map.values(map)
  end

  @doc """
  Returns a new prefix map limited to the given prefixes.

  ## Examples

      iex> RDF.PrefixMap.new(ex1: "http://example.com/ns1", ex2: "http://example.com/ns2")
      ...> |> RDF.PrefixMap.limit([:ex1])
      RDF.PrefixMap.new(ex1: "http://example.com/ns1")
      iex> RDF.PrefixMap.new(ex: "http://example.com/")
      ...> |> RDF.PrefixMap.limit([:foo])
      RDF.PrefixMap.new()
  """
  @spec limit(t, [prefix]) :: t
  def limit(%__MODULE__{map: map}, prefixes) do
    %__MODULE__{map: Map.take(map, prefixes)}
  end

  @doc """
  Converts an IRI into a prefixed name.

  Returns `nil` when no prefix for the namespace of `iri` is defined in `prefix_map`.

  ## Examples

      iex> RDF.PrefixMap.new(ex: "http://example.com/")
      ...> |> RDF.PrefixMap.prefixed_name(~I<http://example.com/Foo>)
      "ex:Foo"
      iex> RDF.PrefixMap.new(ex: "http://example.com/")
      ...> |> RDF.PrefixMap.prefixed_name("http://example.com/Foo")
      "ex:Foo"

  """
  @spec prefixed_name(t, IRI.t() | String.t()) :: String.t() | nil
  def prefixed_name(prefix_map, iri)

  def prefixed_name(%__MODULE__{} = prefix_map, %IRI{} = iri) do
    prefixed_name(prefix_map, IRI.to_string(iri))
  end

  def prefixed_name(%__MODULE__{} = prefix_map, iri) when is_binary(iri) do
    case prefix_name_pair(prefix_map, iri) do
      {prefix, name} -> prefix <> ":" <> name
      _ -> nil
    end
  end

  @doc false
  @spec prefix_name_pair(t, IRI.t() | String.t()) :: {String.t(), String.t()} | nil
  def prefix_name_pair(prefix_map, iri)

  def prefix_name_pair(%__MODULE__{} = prefix_map, %IRI{} = iri) do
    prefix_name_pair(prefix_map, IRI.to_string(iri))
  end

  def prefix_name_pair(%__MODULE__{} = prefix_map, iri) when is_binary(iri) do
    Enum.find_value(prefix_map, fn {prefix, namespace} ->
      case String.trim_leading(iri, IRI.to_string(namespace)) do
        ^iri ->
          nil

        truncated_name ->
          unless String.contains?(truncated_name, ~w[/ #]) do
            {to_string(prefix), truncated_name}
          end
      end
    end)
  end

  @doc """
  Converts a prefixed name into an IRI.

  Returns `nil` when the prefix in `prefixed_name` is not defined in `prefix_map`.

  ## Examples

      iex> RDF.PrefixMap.new(ex: "http://example.com/")
      ...> |> RDF.PrefixMap.prefixed_name_to_iri("ex:Foo")
      ~I<http://example.com/Foo>

  """
  @spec prefixed_name_to_iri(t, String.t()) :: IRI.t() | nil
  def prefixed_name_to_iri(%__MODULE__{} = prefix_map, prefixed_name)
      when is_binary(prefixed_name) do
    case String.split(prefixed_name, ":", parts: 2) do
      [prefix, name] ->
        if ns = namespace(prefix_map, prefix) do
          IRI.new(ns.value <> name)
        end

      _ ->
        nil
    end
  end

  @doc """
  Converts prefix map to a list.

  Each prefix-namespace pair in the prefix map is converted to a two-element tuple
  `{prefix, namespace_iri}` in the resulting list.

  ## Examples

      iex> RDF.PrefixMap.new(ex: "http://example.com/") |> RDF.PrefixMap.to_list()
      [ex: ~I<http://example.com/>]

  """
  @spec to_list(t()) :: [{prefix(), namespace()}]
  def to_list(%__MODULE__{map: map}), do: Map.to_list(map)

  @doc """
  Converts prefix map to a list sorted by prefix.

  Each prefix-namespace pair in the prefix map is converted to a two-element tuple
  `{prefix, namespace_iri}` in the resulting list.

  ## Examples

      iex> RDF.PrefixMap.new(
      ...>   foo: "http://example.com/foo",
      ...>   bar: "http://example.com/bar")
      ...> |> RDF.PrefixMap.to_sorted_list()
      [bar: ~I<http://example.com/bar>, foo: ~I<http://example.com/foo>]

      iex> RDF.PrefixMap.new(
      ...>   a: "http://example.com/foo",
      ...>   "": "http://example.com/bar")
      ...> |> RDF.PrefixMap.to_sorted_list()
      ["": ~I<http://example.com/bar>, a: ~I<http://example.com/foo>]

  """
  @spec to_sorted_list(t() | map | keyword) :: [{prefix(), namespace()}]
  def to_sorted_list(%__MODULE__{map: map}), do: to_sorted_list(map)

  def to_sorted_list(map) do
    Enum.sort(map, fn
      {prefix1, _}, {prefix2, _} -> prefix1 < prefix2
    end)
  end

  @doc """
  Converts the given `prefix_map` to a Turtle or SPARQL header string.

  The `style` argument can be either `:sparql` or `:turtle`.

  ## Options

  - `:indent`: allows to specify an integer by how many spaces the header
    should be indented (default: `0`)
  - `:iodata`: return the header as an IO list

  ## Examples

      iex> RDF.PrefixMap.new(
      ...>   foo: "http://example.com/foo",
      ...>   bar: "http://example.com/bar"
      ...> ) |> RDF.PrefixMap.to_header(:sparql)
      \"""
      PREFIX bar: <http://example.com/bar>
      PREFIX foo: <http://example.com/foo>
      \"""

      iex> RDF.PrefixMap.new(
      ...>   foo: "http://example.com/foo",
      ...>   bar: "http://example.com/bar"
      ...> ) |> RDF.PrefixMap.to_header(:turtle)
      \"""
      @prefix bar: <http://example.com/bar> .
      @prefix foo: <http://example.com/foo> .
      \"""

      iex> RDF.PrefixMap.new() |> RDF.PrefixMap.to_header(:sparql)
      ""

  """
  @spec to_header(t(), :sparql | :turtle, keyword) :: String.t() | iolist()
  def to_header(%__MODULE__{} = prefix_map, style, opts \\ []) do
    indentation =
      case Keyword.get(opts, :indent, 0) do
        0 -> ""
        nil -> ""
        count when is_integer(count) -> String.duplicate(" ", count)
      end

    iolist =
      prefix_map
      |> to_sorted_list()
      |> Enum.map(&[indentation | prefix_directive(&1, style)])

    if Keyword.get(opts, :iodata, false) do
      iolist
    else
      IO.iodata_to_binary(iolist)
    end
  end

  defp prefix_directive({prefix, ns}, :sparql),
    do: ["PREFIX ", to_string(prefix), ": <", to_string(ns), ">\n"]

  defp prefix_directive({prefix, ns}, :turtle),
    do: ["@prefix ", to_string(prefix), ": <", to_string(ns), "> .\n"]

  @doc """
  Converts the given `prefix_map` to a SPARQL header string.

  ## Examples

      iex> RDF.PrefixMap.new(
      ...>   foo: "http://example.com/foo",
      ...>   bar: "http://example.com/bar"
      ...> ) |> RDF.PrefixMap.to_sparql()
      \"""
      PREFIX bar: <http://example.com/bar>
      PREFIX foo: <http://example.com/foo>
      \"""
  """
  @spec to_sparql(t()) :: String.t()
  def to_sparql(prefix_map), do: to_header(prefix_map, :sparql)

  @doc """
  Converts the given `prefix_map` to a Turtle header string.

  ## Examples

      iex> RDF.PrefixMap.new(
      ...>   foo: "http://example.com/foo",
      ...>   bar: "http://example.com/bar"
      ...> ) |> RDF.PrefixMap.to_turtle()
      \"""
      @prefix bar: <http://example.com/bar> .
      @prefix foo: <http://example.com/foo> .
      \"""

  """
  @spec to_turtle(t()) :: String.t()
  def to_turtle(prefix_map), do: to_header(prefix_map, :turtle)

  defimpl Enumerable do
    def reduce(%RDF.PrefixMap{map: map}, acc, fun), do: Enumerable.reduce(map, acc, fun)

    def member?(%RDF.PrefixMap{map: map}, mapping), do: Enumerable.member?(map, mapping)
    def count(%RDF.PrefixMap{map: map}), do: Enumerable.count(map)

    def slice(%RDF.PrefixMap{map: map}) do
      size = map_size(map)
      {:ok, size, &RDF.PrefixMap.to_list/1}
    end
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(prefix_map, opts) do
      map = RDF.PrefixMap.to_sorted_list(prefix_map)
      open = color("RDF.PrefixMap.new(%{", :map, opts)
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
