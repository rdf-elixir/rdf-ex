defmodule RDF.XSD.Datatype.Primitive do
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
        if RDF.XSD.literal?(value) do
          if derived?(value) do
            build_valid(value.value, value.uncanonical_lexical, [])
          end
        else
          value |> RDF.Literal.coerce() |> cast()
        end
      end

      @impl RDF.Literal.Datatype
      def do_equal_value?(left, right)

      def do_equal_value?(
            %datatype{uncanonical_lexical: lexical1, value: nil},
            %datatype{uncanonical_lexical: lexical2, value: nil}
          ) do
        lexical1 == lexical2
      end

      def do_equal_value?(%datatype{} = literal1, %datatype{} = literal2) do
        literal1 |> datatype.canonical() |> datatype.value() ==
          literal2 |> datatype.canonical() |> datatype.value()
      end

      def do_equal_value?(_, _), do: nil

      @impl RDF.Literal.Datatype
      def compare(left, right)
      def compare(left, %RDF.Literal{literal: right}), do: compare(left, right)
      def compare(%RDF.Literal{literal: left}, right), do: compare(left, right)

      def compare(
            %__MODULE__{value: left_value} = left,
            %__MODULE__{value: right_value} = right
          )
          when not (is_nil(left_value) or is_nil(right_value)) do
        case {left |> canonical() |> value(), right |> canonical() |> value()} do
          {value1, value2} when value1 < value2 -> :lt
          {value1, value2} when value1 > value2 -> :gt
          _ -> if equal_value?(left, right), do: :eq
        end
      end

      def compare(_, _), do: nil

      defoverridable canonical_mapping: 1,
                     do_cast: 1,
                     init_valid_lexical: 3,
                     init_invalid_lexical: 2,
                     do_equal_value?: 2,
                     compare: 2

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
