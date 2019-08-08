defmodule RDF.PrefixMap do
  @moduledoc """
  A mapping a prefix atoms to IRI namespaces.

  `RDF.PrefixMap` implements the `Enumerable` protocol.
  """

  defstruct map: %{}

  alias RDF.IRI

  @doc """
  Creates an empty `RDF.PrefixMap`.
  """
  def new(), do: %__MODULE__{}

  @doc """
  Creates a new `RDF.PrefixMap`.

  The prefix mappings can be passed as keyword lists or maps.
  The keys for the prefixes can be given as atoms or strings and will be normalized to atoms.
  The namespaces can be given as `RDF.IRI`s or strings and will be normalized to `RDF.IRI`s.
  """
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
  Adds a prefix mapping to the given `RDF.PrefixMap`.

  Unless a mapping of the given prefix to a different namespace already exists,
  an ok tuple is returned, other an error tuple.
  """
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
  def add!(prefix_map, prefix, namespace) do
    with {:ok, new_prefix_map} <- add(prefix_map, prefix, namespace) do
      new_prefix_map
    else
      {:error, error} -> raise error
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
  Non-`RDF.IRI` values will be tried to be converted to converted to `RDF.IRI`
  via `RDF.IRI.new` implicitly.

  If a conflict can't be resolved, the provided function can return `nil`.
  This will result in an overall return of an `:error` tuple with the list of
  prefixes for which the conflict couldn't be resolved.

  If everything could be merged, an `:ok` tuple is returned.

  """
  def merge(prefix_map1, prefix_map2, conflict_resolver)

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
  def merge!(prefix_map1, prefix_map2, conflict_resolver \\ nil) do
    with {:ok, new_prefix_map} <- merge(prefix_map1, prefix_map2, conflict_resolver) do
      new_prefix_map
    else
      {:error, conflicts} ->
        raise "conflicting prefix mappings: #{
                conflicts |> Stream.map(&inspect/1) |> Enum.join(", ")
              }"
    end
  end

  @doc """
  Deletes a prefix mapping from the given `RDF.PrefixMap`.
  """
  def delete(prefix_map, prefix)

  def delete(%__MODULE__{map: map}, prefix) when is_atom(prefix) do
    %__MODULE__{map: Map.delete(map, prefix)}
  end

  def delete(prefix_map, prefix) when is_binary(prefix) do
    delete(prefix_map, String.to_atom(prefix))
  end

  @doc """
  Drops the given `prefixes` from the given `prefix_map`.

  If `prefixes` contains prefixes that are not in `prefix_map`, they're simply ignored.
  """
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
  Returns the namespace for the given prefix in the given `RDF.PrefixMap`.

  Returns `nil`, when the given `prefix` is not present in `prefix_map`.
  """
  def namespace(prefix_map, prefix)

  def namespace(%__MODULE__{map: map}, prefix) when is_atom(prefix) do
    Map.get(map, prefix)
  end

  def namespace(prefix_map, prefix) when is_binary(prefix) do
    namespace(prefix_map, String.to_atom(prefix))
  end

  @doc """
  Returns the prefix for the given namespace in the given `RDF.PrefixMap`.

  Returns `nil`, when the given `namespace` is not present in `prefix_map`.
  """
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
  def prefixes(%__MODULE__{map: map}) do
    Map.keys(map)
  end

  @doc """
  Returns all namespaces from the given `RDF.PrefixMap`.
  """
  def namespaces(%__MODULE__{map: map}) do
    Map.values(map)
  end

  defimpl Enumerable do
    def reduce(%RDF.PrefixMap{map: map}, acc, fun), do: Enumerable.reduce(map, acc, fun)

    def member?(%RDF.PrefixMap{map: map}, mapping), do: Enumerable.member?(map, mapping)
    def count(%RDF.PrefixMap{map: map}), do: Enumerable.count(map)
    def slice(_prefix_map), do: {:error, __MODULE__}
  end
end
