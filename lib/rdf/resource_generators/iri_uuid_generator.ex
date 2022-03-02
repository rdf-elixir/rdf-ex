# Since optional dependencies don't get started, dialyzer can't find these functions.
# We're ignoring these warnings (via .dialyzer_ignore).
# See https://elixirforum.com/t/confusing-behavior-of-optional-deps-in-mix-exs/17719/4

if Code.ensure_loaded?(UUID) do
  defmodule RDF.IRI.UUID.Generator do
    use RDF.Resource.Generator

    alias RDF.IRI

    import RDF.Utils.Guards

    @impl true
    def generate do
      UUID.uuid4(:urn) |> IRI.new()
    end

    @impl true
    def generate(args) do
      {prefix, args} = Keyword.pop(args, :prefix)
      {uuid_version, args} = Keyword.pop(args, :version, 4)
      {uuid_format, args} = Keyword.pop(args, :format, :default)

      {namespace, name, args} =
        if uuid_version in [3, 5] do
          unless Keyword.has_key?(args, :namespace) and Keyword.has_key?(args, :name) do
            raise ArgumentError,
                  "missing required :namespace and :name arguments for UUID version #{uuid_version}"
          end

          {namespace, args} = Keyword.pop!(args, :namespace)
          {name, args} = Keyword.pop!(args, :name)
          {namespace, name, args}
        else
          {nil, nil, args}
        end

      unless Enum.empty?(args) do
        raise ArgumentError, "unknown arguments: #{inspect(args)}"
      end

      case uuid_version do
        1 -> UUID.uuid1(uuid_format)
        4 -> UUID.uuid4(uuid_format)
        3 -> UUID.uuid3(namespace, name, uuid_format)
        5 -> UUID.uuid5(namespace, name, uuid_format)
        _ -> raise ArgumentError, "unknown UUID version: #{uuid_version}"
      end
      |> iri(uuid_format, prefix)
    end

    defp iri(uuid, :urn, nil), do: IRI.new(uuid)

    defp iri(_uuid, :urn, _),
      do: raise(ArgumentError, "prefix option not support on URN UUIDs")

    defp iri(_, _, nil),
      do: raise(ArgumentError, "missing required :prefix argument on non-URN UUIDs")

    defp iri(uuid, format, prefix) when maybe_module(prefix),
      do: iri(uuid, format, prefix.__base_iri__())

    defp iri(uuid, _, prefix), do: IRI.new(prefix <> uuid)
  end
end
