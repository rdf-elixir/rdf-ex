defmodule RDF.PrefixMap do
  @moduledoc """
  A mapping a prefix atoms to IRI namespaces.

  `RDF.PrefixMap` implements the `Enumerable` protocol.
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
    with {prefix, namespace} = normalize({prefix, namespace}) do
      add(prefix_map, prefix, namespace)
    end
  end

  @doc """
  Adds a prefix mapping to the given `RDF.PrefixMap` and raises an exception in error cases.
  """
  @spec add!(t, coercible_prefix, coercible_namespace) :: t
  def add!(prefix_map, prefix, namespace) do
    with {:ok, new_prefix_map} <- add(prefix_map, prefix, namespace) do
      new_prefix_map
    else
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
    with {prefix, namespace} = normalize({prefix, namespace}) do
      put(prefix_map, prefix, namespace)
    end
  end

  @doc """
  Merges two `RDF.PrefixMap`s.

  The second prefix map can also be given as any structure which can converted
  to a `RDF.PrefixMap` via `new/1`.

  If the prefix maps can be merged without conflicts, that is there are no
  prefixes mapped to different namespaces an `:ok` tuple is returned.
  Otherwise an `:error` tuple with the list of prefixes with conflicting
  namespaces is returned.

  See also `merge/3` which allows you to resolve conflicts with a function.
  """
  @spec merge(t, t | map | keyword) :: {:ok, t} | {:error, [atom | String.t()]}
  def merge(prefix_map1, prefix_map2)

  def merge(%__MODULE__{map: map1}, %__MODULE__{map: map2}) do
    with [] <- merge_conflicts(map1, map2) do
      {:ok, %__MODULE__{map: Map.merge(map1, map2)}}
    else
      conflicts -> {:error, conflicts}
    end
  end

  def merge(%__MODULE__{} = prefix_map, other_prefixes) do
    merge(prefix_map, new(other_prefixes))
  rescue
    FunctionClauseError ->
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

    with resolved_merge = Map.merge(map1, map2, conflict_resolution),
         [] <- resolved_merge_rest_conflicts(resolved_merge) do
      {:ok, %__MODULE__{map: resolved_merge}}
    else
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
    with {:ok, new_prefix_map} <- merge(prefix_map1, prefix_map2, conflict_resolver) do
      new_prefix_map
    else
      {:error, conflicts} ->
        conflicts = conflicts |> Stream.map(&inspect/1) |> Enum.join(", ")

        raise "conflicting prefix mappings: #{conflicts}"
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
    Enum.find_value(prefix_map, fn {prefix, namespace} ->
      case String.replace_leading(iri, IRI.to_string(namespace), ":") do
        ^iri ->
          nil

        truncated_name ->
          unless String.contains?(truncated_name, ~w[/ #]) do
            to_string(prefix) <> truncated_name
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
    Enum.find_value(prefix_map, fn {prefix, namespace} ->
      case String.replace_leading(prefixed_name, "#{prefix}:", IRI.to_string(namespace)) do
        ^prefixed_name -> nil
        iri -> IRI.new(iri)
      end
    end)
  end

  defimpl Enumerable do
    def reduce(%RDF.PrefixMap{map: map}, acc, fun), do: Enumerable.reduce(map, acc, fun)

    def member?(%RDF.PrefixMap{map: map}, mapping), do: Enumerable.member?(map, mapping)
    def count(%RDF.PrefixMap{map: map}), do: Enumerable.count(map)
    def slice(_prefix_map), do: {:error, __MODULE__}
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(prefix_map, opts) do
      map = Map.to_list(prefix_map.map)
      open = color("%RDF.PrefixMap{", :map, opts)
      sep = color(",", :map, opts)
      close = color("}", :map, opts)

      container_doc(open, map, close, opts, &Inspect.List.keyword/2,
        separator: sep,
        break: :strict
      )
    end
  end
end
