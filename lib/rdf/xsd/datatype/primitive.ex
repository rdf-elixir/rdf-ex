defmodule RDF.XSD.Datatype.Primitive do
  @moduledoc """
  Macros for the definition of primitive XSD datatypes.
  """

  @doc """
  Specifies the applicability of the given XSD `facet` on a primitive datatype.

  For a facet with the name `example_facet` this requires a function

      def example_facet_conform?(example_facet_value, literal_value, lexical) do

      end

  to be defined on the primitive datatype.
  """
  defmacro def_applicable_facet(facet) do
    quote do
      @applicable_facets unquote(facet)
      use unquote(facet)
    end
  end

  defmacro __using__(opts) do
    quote do
      use RDF.XSD.Datatype, unquote(opts)

      import unquote(__MODULE__)

      Module.register_attribute(__MODULE__, :applicable_facets, accumulate: true)

      @impl RDF.XSD.Datatype
      def primitive?, do: true

      @impl RDF.XSD.Datatype
      def base, do: nil

      @impl RDF.XSD.Datatype
      def base_primitive, do: __MODULE__

      @impl RDF.XSD.Datatype
      def derived_from?(_), do: false

      @impl RDF.XSD.Datatype
      def init_valid_lexical(value, lexical, opts)
      def init_valid_lexical(_value, nil, _opts), do: nil
      def init_valid_lexical(_value, lexical, _opts), do: lexical

      @impl RDF.XSD.Datatype
      def init_invalid_lexical(value, _opts), do: to_string(value)

      @doc false
      # Optimization: facets are generally unconstrained on primitives
      def facet_conform?(_, _), do: true

      @impl RDF.XSD.Datatype
      def canonical_mapping(value), do: to_string(value)

      @impl RDF.Literal.Datatype
      def do_cast(value) do
        # i.e. derived datatype
        if datatype?(value) do
          build_valid(value.value, value.uncanonical_lexical, [])
        end
      end

      @impl RDF.Literal.Datatype
      def do_equal_value_same_or_derived_datatypes?(
            %left_datatype{} = left,
            %right_datatype{} = right
          ) do
        left_datatype.value(left) == right_datatype.value(right)
      end

      @impl RDF.Literal.Datatype
      def do_equal_value_different_datatypes?(left, right), do: nil

      @impl RDF.Literal.Datatype
      def do_compare(%left_datatype{} = left, %right_datatype{} = right) do
        if left_datatype.datatype?(right_datatype) or right_datatype.datatype?(left_datatype) do
          case {left_datatype.value(left), right_datatype.value(right)} do
            {left_value, right_value} when left_value < right_value ->
              :lt

            {left_value, right_value} when left_value > right_value ->
              :gt

            _ ->
              if left_datatype.equal_value?(left, right), do: :eq
          end
        end
      end

      def do_compare(_, _), do: nil

      defoverridable canonical_mapping: 1,
                     do_cast: 1,
                     init_valid_lexical: 3,
                     init_invalid_lexical: 2,
                     do_equal_value_same_or_derived_datatypes?: 2,
                     do_equal_value_different_datatypes?: 2,
                     do_compare: 2

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      @impl RDF.XSD.Datatype
      def applicable_facets, do: @applicable_facets
    end
  end
end
