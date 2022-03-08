defmodule RDF.Resource.Generator do
  @type id_type :: :random_based | :value_based

  @callback generate(config :: any) :: RDF.Resource.t()

  @callback generate(config :: any, value :: binary) :: RDF.Resource.t()

  @callback generator_config(id_type, keyword) :: any

  defmacro __using__(_opts) do
    quote do
      @behaviour RDF.Resource.Generator

      @impl RDF.Resource.Generator
      def generator_config(_, config), do: config

      defoverridable generator_config: 2
    end
  end

  def generate(config) do
    {generator, config} = config(:random_based, config)
    generator.generate(config)
  end

  def generate(config, value) do
    {generator, config} = config(:value_based, config)
    generator.generate(config, value)
  end

  defp config(id_type, config) do
    {random_config, config} = Keyword.pop(config, :random_based)
    {value_based_config, config} = Keyword.pop(config, :value_based)

    {generator, config} =
      id_type
      |> merge_config(config, random_config, value_based_config)
      |> Keyword.pop!(:generator)

    {generator, generator.generator_config(id_type, config)}
  end

  defp merge_config(:random_based, config, nil, _), do: config

  defp merge_config(:random_based, config, random_config, _),
    do: Keyword.merge(config, random_config)

  defp merge_config(:value_based, config, _, nil), do: config

  defp merge_config(:value_based, config, _, value_based_config),
    do: Keyword.merge(config, value_based_config)
end
