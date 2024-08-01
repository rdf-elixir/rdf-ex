defmodule RDF.IRI.UUID.Generator do
  @moduledoc """
  A `RDF.Resource.Generator` for various kinds of UUID-based IRI identifiers.

  ## Configuration options

  - `:prefix`: The URI prefix to be prepended to the generated UUID.
    It can be given also as `RDF.Vocabulary.Namespace` module.
    If the `:uuid_format` is set explicitly to something other than `:urn`
    (which is the default), this is a required parameter.
  - `:uuid_version`: The UUID version to be used. Can be any of the
    integers 1 and 4 for random-based identifiers (4 being the default) and
    3 and 5 for value-based identifiers (5 being the default).
  - `:uuid_format`: The format of the UUID to be generated. Can be any of the
    following atoms:
    - `:urn`: a standard UUID representation, prefixed with the UUID URN
      (in this case the `:prefix` is not used) (the default when no `:prefix` given)
    - `:default`: a standard UUID representation, appended to the `:prefix` value
      (the default when a `:prefix` is given)
    - `:hex`: a standard UUID without the `-` (dash) characters, appended to the
      `:prefix` value
  - `:uuid_namespace` (only with `:uuid_version` 3 and 5, where it is a required parameter)

  When your generator configuration is just for a function producing one of
  the two kinds of identifiers, you can use these options directly.
  Otherwise, you must provide the identifier-specific configuration under one
  of the keys `:random_based` and `:value_based`.

    
  ## Example configuration

      config :example, :id,
        generator: RDF.IRI.UUID.Generator,
        prefix: "http://example.com/",
        uuid_format: :hex,
        random_based: [
          uuid_version: 1
        ],
        value_based: [
          uuid_version: 3,
          uuid_namespace: UUID.uuid5(:url, "http://your.application.com/example")
        ]

  """

  use RDF.Resource.Generator

  alias Uniq.UUID

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
