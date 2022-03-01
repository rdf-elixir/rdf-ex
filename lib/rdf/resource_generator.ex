defmodule RDF.Resource.Generator do
  defmodule Config do
    @enforce_keys [:generator]
    defstruct [:generator, :arguments]

    @type t :: %__MODULE__{generator: module, arguments: any}
  end

  @callback generator_config() :: Config.t()
  @callback generator_config(args :: any) :: Config.t()

  @callback generator_arguments(args :: any, defaults :: any) :: any

  @callback generate() :: RDF.Resource.t()

  @callback generate(args :: any) :: RDF.Resource.t()

  defmacro __using__(_opts) do
    quote do
      @behaviour RDF.Resource.Generator

      @impl RDF.Resource.Generator
      def generator_config(defaults \\ nil) do
        %RDF.Resource.Generator.Config{
          generator: __MODULE__,
          arguments: generator_arguments(defaults, nil)
        }
      end

      @impl RDF.Resource.Generator
      def generator_arguments(args, defaults) when is_list(args) and is_list(defaults),
        do: Keyword.merge(defaults, args)

      def generator_arguments(nil, defaults), do: defaults
      def generator_arguments(args, defaults), do: args

      @impl RDF.Resource.Generator
      def generate(_args), do: generate()

      defoverridable generate: 1, generator_config: 1, generator_arguments: 2
    end
  end

  @doc false
  def config(config) do
    {generator, args} = Keyword.pop!(config, :generator)
    default_args = unless Enum.empty?(args), do: args
    generator.generator_config(default_args)
  end

  @doc false
  def generate(%Config{generator: generator, arguments: defaults}, args),
    do: do_generate(generator, generator.generator_arguments(args, defaults))

  defp do_generate(generator, nil), do: generator.generate()
  defp do_generate(generator, args), do: generator.generate(args)
end
