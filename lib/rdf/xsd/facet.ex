defmodule RDF.XSD.Facet do
  @moduledoc """
  A behaviour for XSD restriction facets.

  Here's a list of all the `RDF.XSD.Facet`s RDF.ex implements out-of-the-box:

  | XSD facet        | `RDF.XSD.Facet`                   |
  | :--------------  | :-------------                    |
  | length           | `RDF.XSD.Facets.Length`           |
  | minLength        | `RDF.XSD.Facets.MinLength`        |
  | maxLength        | `RDF.XSD.Facets.MaxLength`        |
  | maxInclusive     | `RDF.XSD.Facets.MaxInclusive`     |
  | maxExclusive     | `RDF.XSD.Facets.MaxExclusive`     |
  | minInclusive     | `RDF.XSD.Facets.MinInclusive`     |
  | minExclusive     | `RDF.XSD.Facets.MinExclusive`     |
  | totalDigits      | `RDF.XSD.Facets.TotalDigits`      |
  | fractionDigits   | `RDF.XSD.Facets.FractionDigits`   |
  | explicitTimezone | `RDF.XSD.Facets.ExplicitTimezone` |
  | pattern          | `RDF.XSD.Facets.Pattern`          |
  | whiteSpace       | ❌                                |
  | enumeration      | ❌                                |
  | assertions       | ❌                                |

  Every `RDF.XSD.Datatype.Primitive` defines a set of applicable constraining facets which are can
  be used on derivations of this primitive or any of its existing derivations:

  | Primitive datatype | Applicable facets |
  | :----------------- | :---------------- |
  |string | `RDF.XSD.Facets.Length`, `RDF.XSD.Facets.MaxLength`, `RDF.XSD.Facets.MinLength`, `RDF.XSD.Facets.Pattern` |
  |boolean | `RDF.XSD.Facets.Pattern` |
  |float | `RDF.XSD.Facets.MaxExclusive`, `RDF.XSD.Facets.MaxInclusive`, `RDF.XSD.Facets.MinExclusive`, `RDF.XSD.Facets.MinInclusive`, `RDF.XSD.Facets.Pattern` |
  |double | `RDF.XSD.Facets.MaxExclusive`, `RDF.XSD.Facets.MaxInclusive`, `RDF.XSD.Facets.MinExclusive`, `RDF.XSD.Facets.MinInclusive`, `RDF.XSD.Facets.Pattern` |
  |decimal | `RDF.XSD.Facets.MaxExclusive`, `RDF.XSD.Facets.MaxInclusive`, `RDF.XSD.Facets.MinExclusive`, `RDF.XSD.Facets.MinInclusive`, `RDF.XSD.Facets.Pattern`, `RDF.XSD.Facets.TotalDigits`, `RDF.XSD.Facets.FractionDigits` |
  |decimal | `RDF.XSD.Facets.MaxExclusive`, `RDF.XSD.Facets.MaxInclusive`, `RDF.XSD.Facets.MinExclusive`, `RDF.XSD.Facets.MinInclusive`, `RDF.XSD.Facets.Pattern`, `RDF.XSD.Facets.TotalDigits` |
  |duration | `RDF.XSD.Facets.MaxExclusive`, `RDF.XSD.Facets.MaxInclusive`, `RDF.XSD.Facets.MinExclusive`, `RDF.XSD.Facets.MinInclusive`, `RDF.XSD.Facets.Pattern` |
  |dateTime | `RDF.XSD.Facets.ExplicitTimezone`, `RDF.XSD.Facets.MaxExclusive`, `RDF.XSD.Facets.MaxInclusive`, `RDF.XSD.Facets.MinExclusive`, `RDF.XSD.Facets.MinInclusive`, `RDF.XSD.Facets.Pattern` |
  |time | `RDF.XSD.Facets.ExplicitTimezone`, `RDF.XSD.Facets.MaxExclusive`, `RDF.XSD.Facets.MaxInclusive`, `RDF.XSD.Facets.MinExclusive`, `RDF.XSD.Facets.MinInclusive`, `RDF.XSD.Facets.Pattern` |
  |date | `RDF.XSD.Facets.ExplicitTimezone`, `RDF.XSD.Facets.MaxExclusive`, `RDF.XSD.Facets.MaxInclusive`, `RDF.XSD.Facets.MinExclusive`, `RDF.XSD.Facets.MinInclusive`, `RDF.XSD.Facets.Pattern` |
  |anyURI | `RDF.XSD.Facets.Length`, `RDF.XSD.Facets.MaxLength`, `RDF.XSD.Facets.MinLength`, `RDF.XSD.Facets.Pattern` |

  <https://www.w3.org/TR/xmlschema11-2/datatypes.html#rf-facets>
  """

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
      Validates if a `value` and `lexical` conforms with a concrete `facet_constraint_value` for this `RDF.XSD.Facet`.

      This function must be implemented on a `RDF.XSD.Datatype` using this `RDF.XSD.Facet`.
      """
      @callback unquote(conform_fun_name(name))(
                  facet_constraint_value :: any,
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
    facet_name = String.to_atom(facet_mod.name())

    quote do
      unless unquote(facet) in @base.applicable_facets(),
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
      applicable_facet_name = String.to_atom(applicable_facet.name())

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
