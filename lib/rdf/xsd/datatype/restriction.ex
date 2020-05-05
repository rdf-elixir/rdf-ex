defmodule RDF.XSD.Datatype.Restriction do
  defmacro __using__(opts) do
    base = Keyword.fetch!(opts, :base)

    quote do
      use RDF.XSD.Datatype, unquote(opts)

      import RDF.XSD.Facet, only: [def_facet_constraint: 2]

      @type valid_value :: unquote(base).valid_value()

      @base unquote(base)
      @impl RDF.XSD.Datatype
      @spec base :: RDF.XSD.Datatype.t()
      def base, do: @base

      @impl RDF.XSD.Datatype
      def primitive?, do: false

      @impl RDF.XSD.Datatype
      def base_primitive, do: @base.base_primitive()

      @impl RDF.XSD.Datatype
      def applicable_facets, do: @base.applicable_facets()

      @impl RDF.XSD.Datatype
      def init_valid_lexical(value, lexical, opts),
        do: @base.init_valid_lexical(value, lexical, opts)

      @impl RDF.XSD.Datatype
      def init_invalid_lexical(value, opts),
        do: @base.init_invalid_lexical(value, opts)

      @doc false
      def facet_conform?(value, lexical) do
        Enum.all?(applicable_facets(), fn facet ->
          facet.conform?(__MODULE__, value, lexical)
        end)
      end

      @impl RDF.XSD.Datatype
      def lexical_mapping(lexical, opts),
        do: @base.lexical_mapping(lexical, opts)

      @impl RDF.XSD.Datatype
      def elixir_mapping(value, opts),
        do: @base.elixir_mapping(value, opts)

      @impl RDF.XSD.Datatype
      def canonical_mapping(value),
        do: @base.canonical_mapping(value)

      @impl RDF.Literal.Datatype
      def do_cast(literal_or_value) do
        # Note: This direct call of the cast/1 implementation of the base_primitive
        # is an optimization to not have go through the whole derivation chain and
        # doing potentially a lot of redundant validations, but this relies on
        # cast/1 not being overridden on restrictions.
        case base_primitive().cast(literal_or_value) do
          nil ->
            nil

          %RDF.Literal{literal: %{value: value, uncanonical_lexical: lexical}} ->
            if facet_conform?(value, lexical) do
              build_valid(value, lexical, [])
            end
        end
      end

      # TODO: This makes it impossible to define do_equal_value definitions on derivations,
      # but we need to overwrite this to reach for example the XSD.Numeric delegation.
      def equal_value?(literal1, literal2), do: @base.equal_value?(literal1, literal2)

      @impl RDF.Literal.Datatype
      def do_equal_value?(left, right), do: nil # unused; see comment on equal_value?/2

      @impl RDF.Literal.Datatype
      def compare(left, right), do: @base.compare(left, right)

      defoverridable canonical_mapping: 1,
                     do_cast: 1,
                     equal_value?: 2,
                     compare: 2

      Module.register_attribute(__MODULE__, :facets, accumulate: true)

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(env) do
    import RDF.XSD.Facet

    restriction_impl(
      Module.get_attribute(env.module, :facets),
      Module.get_attribute(env.module, :base).applicable_facets
    )
  end
end
