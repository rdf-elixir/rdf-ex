defmodule RDF.Resource.Generator do
  @moduledoc """
  A configurable and customizable way to generate resource identifiers.

  The basis are different implementations of the behaviour defined in this
  module for configurable resource identifier generation methods.

  Generally two kinds of identifiers are differentiated:

  1. parameter-less identifiers which are generally random
  2. identifiers which are based on some value, where every attempt to create
     an identifier for the same value, should produce the same identifier

  Not all implementations must support both kind of identifiers.

  The `RDF.Resource.Generator` module provides two `generate` functions for the
  kindes of identifiers, `generate/1` for random-based and `generate/2` for
  value-based identifiers.
  The `config` keyword list they take must contain a `:generator` key, which
  provides the module implementing the `RDF.Resource.Generator` behaviour.
  All other keywords are specific to the generator implementation.
  When the generator is configured differently for the different
  identifier types, the identifier-type specific configuration can be put under
  the keys `:random_based` and `:value_based` respectively.
  The `RDF.Resource.Generator.generate` implementations will be called with the
  general configuration options from the top-level merged with the identifier-type
  specific configuration.

  The `generate` functions however are usually not called directly.
  See the [guide](https://rdf-elixir.dev/rdf-ex/resource-generators.html) on
  how they are meant to be used.

  The following `RDF.Resource.Generator` implementations are provided with RDF.ex:

  - `RDF.BlankNode`
  - `RDF.BlankNode.Generator`
  - `RDF.IRI.UUID.Generator`

  """

  @type id_type :: :random_based | :value_based

  @doc """
  Generates a random resource identifier based on the given `config`.
  """
  @callback generate(config :: any) :: RDF.Resource.t()

  @doc """
  Generates a resource identifier based on the given `config` and `value`.
  """
  @callback generate(config :: any, value :: binary) :: RDF.Resource.t()

  @doc """
  Allows to normalize the configuration.

  This callback is optional. A default implementation is generated which
  returns the configuration as-is.
  """
  @callback generator_config(id_type, keyword) :: any

  defmacro __using__(_opts) do
    quote do
      @behaviour RDF.Resource.Generator

      @impl RDF.Resource.Generator
      def generator_config(_, config), do: config

      defoverridable generator_config: 2
    end
  end

  @doc """
  Generates a random resource identifier based on the given `config`.

  See the [guide](https://rdf-elixir.dev/rdf-ex/resource-generators.html) on
  how it is meant to be used.
  """
  def generate(config) do
    {generator, config} = config(:random_based, config)
    generator.generate(config)
  end

  @doc """
  Generates a resource identifier based on the given `config` and `value`.

  See the [guide](https://rdf-elixir.dev/rdf-ex/resource-generators.html) on
  how it is meant to be used.
  """
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
