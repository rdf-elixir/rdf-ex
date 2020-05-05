defmodule RDF.XSD.Facet do
  @type t :: module

  @doc """
  The name of a `RDF.XSD.Facet`.
  """
  @callback name :: String.t()

  defmacro __using__(opts) do
    name = Keyword.fetch!(opts, :name)
    type_ast = Keyword.fetch!(opts, :type)

    quote bind_quoted: [], unquote: true do
      @behaviour RDF.XSD.Facet

      @doc """
      Returns the value of this `RDF.XSD.Facet` on specific `RDF.XSD.Datatype`.
      """
      @callback unquote(name)() :: unquote(type_ast) | nil

      @doc """
      Validates if a `value` and `lexical` conforms with a concrete `facet_constaint_value` for this `RDF.XSD.Facet`.

      This function must be implemented on a `RDF.XSD.Datatype` using this `RDF.XSD.Facet`.
      """
      @callback unquote(conform_fun_name(name))(
                  facet_constaint_value :: any,
                  value :: any,
                  RDF.XSD.Datatype.uncanonical_lexical()
                ) :: boolean

      @name unquote(Atom.to_string(name))
      @impl RDF.XSD.Facet
      def name, do: @name

      @doc """
      Checks if a `value` and `lexical` conforms with the `c:#{unquote(conform_fun_name(name))}/3` implementation on the `datatype` `RDF.XSD.Datatype`.
      """
      @spec conform?(RDF.XSD.Datatype.t(), any, RDF.XSD.Datatype.uncanonical_lexical()) :: boolean
      def conform?(datatype, value, lexical) do
        constrain_value = apply(datatype, unquote(name), [])

        is_nil(constrain_value) or
          apply(datatype, unquote(conform_fun_name(name)), [constrain_value, value, lexical])
      end

      defmacro __using__(_opts) do
        import unquote(__MODULE__)
        default_facet_impl(__MODULE__, unquote(name))
      end
    end
  end

  defp conform_fun_name(facet_name), do: :"#{facet_name}_conform?"

  @doc """
  Macro for the definition of concrete constraining `value` for a `RDF.XSD.Facet` on a `RDF.XSD.Datatype`.
  """
  defmacro def_facet_constraint(facet, value) do
    facet_mod = Macro.expand_once(facet, __CALLER__)
    facet_name = String.to_atom(facet_mod.name)

    quote do
      unless unquote(facet) in @base.applicable_facets,
        do: raise("#{unquote(facet_name)} is not an applicable facet of #{@base}")

      @facets unquote(facet_name)

      @impl unquote(facet)
      def unquote(facet_name)(), do: unquote(value)
    end
  end

  @doc false
  def default_facet_impl(facet_mod, facet_name) do
    quote do
      @behaviour unquote(facet_mod)

      Module.put_attribute(__MODULE__, unquote(facet_mod), nil)
      @impl unquote(facet_mod)
      def unquote(facet_name)(), do: nil

      defoverridable [{unquote(facet_name), 0}]
    end
  end

  @doc false

  def restriction_impl(facets, applicable_facets) do
    Enum.map(applicable_facets, fn applicable_facet ->
      applicable_facet_name = String.to_atom(applicable_facet.name)

      quote do
        @behaviour unquote(applicable_facet)

        unless unquote(applicable_facet_name in facets) do
          @impl unquote(applicable_facet)
          def unquote(applicable_facet_name)(),
            do: apply(@base, unquote(applicable_facet_name), [])
        end

        @impl unquote(applicable_facet)
        def unquote(conform_fun_name(applicable_facet_name))(constrain_value, value, lexical) do
          apply(@base, unquote(conform_fun_name(applicable_facet_name)), [
            constrain_value,
            value,
            lexical
          ])
        end
      end
    end)
  end
end
