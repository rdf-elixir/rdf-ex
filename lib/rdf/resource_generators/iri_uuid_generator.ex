# Since optional dependencies don't get started, dialyzer can't find these functions.
# We're ignoring these warnings (via .dialyzer_ignore).
# See https://elixirforum.com/t/confusing-behavior-of-optional-deps-in-mix-exs/17719/4

if Code.ensure_loaded?(UUID) do
  defmodule RDF.IRI.UUID.Generator do
    use RDF.Resource.Generator

    alias RDF.IRI
    alias RDF.Resource.Generator.ConfigError

    import RDF.Utils.Guards

    @impl true
    def generate(config), do: config |> config!(:random_based) |> do_generate()

    @impl true
    def generate(config, value), do: config |> config!(:value_based) |> do_generate(value)

    defp do_generate({1, format, prefix, _}), do: format |> UUID.uuid1() |> iri(format, prefix)
    defp do_generate({4, format, prefix, _}), do: format |> UUID.uuid4() |> iri(format, prefix)

    defp do_generate({version, _, _, _}) do
      raise ConfigError,
            "invalid :uuid_version for random resource generator: #{inspect(version)}; only version 1 and 4 are allowed"
    end

    defp do_generate({3, format, prefix, namespace}, value),
      do: UUID.uuid3(namespace, value, format) |> iri(format, prefix)

    defp do_generate({5, format, prefix, namespace}, value),
      do: UUID.uuid5(namespace, value, format) |> iri(format, prefix)

    defp do_generate({version, _, _, _}, _) do
      raise ConfigError,
            "invalid :uuid_version for value-based resource generator: #{inspect(version)}; only version 3 and 5 are allowed"
    end

    defp default_uuid_version(:random_based), do: 4
    defp default_uuid_version(:value_based), do: 5

    defp config!(config, id_type) do
      {prefix, config} = Keyword.pop(config, :prefix)
      {uuid_version, config} = Keyword.pop(config, :uuid_version, default_uuid_version(id_type))

      {uuid_format, config} =
        Keyword.pop(config, :uuid_format, if(prefix, do: :default, else: :urn))

      {namespace, _config} =
        cond do
          uuid_version in [3, 5] ->
            unless Keyword.has_key?(config, :uuid_namespace) do
              raise ConfigError,
                    "missing required :uuid_namespace argument for UUID version #{uuid_version}"
            end

            Keyword.pop!(config, :uuid_namespace)

          uuid_version in [1, 4] ->
            {nil, config}

          true ->
            raise ConfigError, "invalid :uuid_version: #{uuid_version}"
        end

      {uuid_version, uuid_format, prefix, namespace}
    end

    defp iri(uuid, :urn, nil), do: IRI.new(uuid)

    defp iri(_uuid, :urn, _),
      do: raise(ConfigError, "prefix option not support on URN UUIDs")

    defp iri(_, _, nil),
      do: raise(ConfigError, "missing required :prefix argument on non-URN UUIDs")

    defp iri(uuid, format, prefix) when maybe_module(prefix),
      do: iri(uuid, format, prefix.__base_iri__())

    defp iri(uuid, _, prefix), do: IRI.new(prefix <> uuid)
  end
end
