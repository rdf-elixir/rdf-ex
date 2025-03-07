defmodule RDF.XSD.Datatype do
  @moduledoc """
  A behaviour for XSD datatypes.

  A XSD datatype has three properties:

  - A _value space_, which is a set of values.
  - A _lexical space_, which is a set of _literals_ used to denote the values.
  - A collection of functions associated with the datatype.


  ### Builtin XSD datatypes

  RDF.ex comes with the following builtin implementations of XSD datatypes:

  | `xsd:boolean` | `RDF.XSD.Boolean` |
  | `xsd:float` | `RDF.XSD.Float` |
  | `xsd:double` | `RDF.XSD.Double` |
  | `xsd:decimal` | `RDF.XSD.Decimal` |
  |   `xsd:integer` | `RDF.XSD.Integer` |
  |     `xsd:long` | `RDF.XSD.Long` |
  |       `xsd:int` | `RDF.XSD.Int` |
  |         `xsd:short` | `RDF.XSD.Short` |
  |           `xsd:byte` | `RDF.XSD.Byte` |
  |     `xsd:nonPositiveInteger` | `RDF.XSD.NonPositiveInteger` |
  |       `xsd:negativeInteger` | `RDF.XSD.NegativeInteger` |
  |     `xsd:nonNegativeInteger` | `RDF.XSD.NonNegativeInteger` |
  |       `xsd:positiveInteger` | `RDF.XSD.PositiveInteger` |
  |       `xsd:unsignedLong` | `RDF.XSD.UnsignedLong` |
  |         `xsd:unsignedInt` | `RDF.XSD.UnsignedInt` |
  |           `xsd:unsignedShort` | `RDF.XSD.UnsignedShort` |
  |             `xsd:unsignedByte` | `RDF.XSD.UnsignedByte` |
  | `xsd:string` | `RDF.XSD.String` |
  |   `xsd:normalizedString` | ❌ |
  |     `xsd:token` | ❌ |
  |       `xsd:language` | ❌ |
  |       `xsd:Name` | ❌ |
  |         `xsd:NCName` | ❌ |
  |           `xsd:ID` | ❌ |
  |           `xsd:IDREF` | ❌ |
  |           `xsd:ENTITY` | ❌ |
  |       `xsd:NMTOKEN` | ❌ |
  | `xsd:dateTime` | `RDF.XSD.DateTime` |
  |   `xsd:dateTimeStamp` | ❌ |
  | `xsd:date` | `RDF.XSD.Date` |
  | `xsd:time` | `RDF.XSD.Time` |
  | `xsd:duration` | ❌ |
  |  `xsd:dayTimeDuration` | ❌ |
  |  `xsd:yearMonthDuration` | ❌ |
  | `xsd:gYearMonth` | ❌ |
  | `xsd:gYear` | ❌ |
  | `xsd:gMonthDay` | ❌ |
  | `xsd:gDay` | ❌ |
  | `xsd:gMonth` | ❌ |
  | `xsd:base64Binary` | `RDF.XSD.Base64Binary` |
  | `xsd:hexBinary` | ❌ |
  | `xsd:anyURI` | `RDF.XSD.AnyURI` |
  | `xsd:QName` | ❌ |
  | `xsd:NOTATION` | ❌ |

  There are some notable difference in the implementations of some datatypes compared to
  the original spec:

  - `RDF.XSD.Integer` is not derived from `RDF.XSD.Decimal`, but implemented as a primitive datatype
  - `RDF.XSD.Float` is not implemented as a primitive datatype, but derived from `RDF.XSD.Double`
    without further restrictions instead, since Erlang doesn't have a corresponding datatype

  see <https://www.w3.org/TR/xmlschema11-2/#built-in-datatypes>
  """

  @type t :: module

  @type uncanonical_lexical :: String.t() | nil

  @type literal :: %{
          :__struct__ => t(),
          :value => any(),
          :uncanonical_lexical => uncanonical_lexical()
        }

  import RDF.Utils.Guards

  @doc """
  Returns if the `RDF.XSD.Datatype` is a primitive datatype.
  """
  @callback primitive?() :: boolean

  @doc """
  The base datatype from which a `RDF.XSD.Datatype` is derived.

  Note: Since this library focuses on atomic types and the special `xsd:anyAtomicType`
  specified as the base type of all primitive types in the W3C spec wouldn't serve any
  purpose here, all primitive datatypes just return `nil` instead.
  """
  @callback base :: t() | nil

  @doc """
  The primitive `RDF.XSD.Datatype` from which a `RDF.XSD.Datatype` is derived.

  In case of a primitive `RDF.XSD.Datatype` this function returns this `RDF.XSD.Datatype` itself.
  """
  @callback base_primitive :: t()

  @doc """
  Checks if the `RDF.XSD.Datatype` is directly or indirectly derived from the given `RDF.XSD.Datatype`.

  Note that this is just a basic datatype reflection function on the module level
  and does not work with `RDF.Literal`s. See `c:RDF.Literal.Datatype.datatype?/1` instead.
  """
  @callback derived_from?(t()) :: boolean

  @doc """
  The set of applicable facets of a `RDF.XSD.Datatype`.
  """
  @callback applicable_facets :: [RDF.XSD.Facet.t()]

  @doc """
  A mapping from the lexical space of a `RDF.XSD.Datatype` into its value space.
  """
  @callback lexical_mapping(String.t(), Keyword.t()) :: any

  @doc """
  A mapping from Elixir values into the value space of a `RDF.XSD.Datatype`.

  If the Elixir mapping for the given value can not be mapped into value space of
  the XSD datatype an implementation should return `@invalid_value`
  (which is just `nil` at the moment, so `nil` is never a valid value of a value space).

  Otherwise, a tuple `{value, lexical}` with `value` being the internal representation
  of the mapped value from the value space and `lexical` being the lexical representation
  to be used for the Elixir value or `nil` if `c:init_valid_lexical/3` should be used
  to determine the lexical form in general (i.e. also when initialized with a string
  via the `c:lexical_mapping/2`). Since the later case is most often what you want,
  you can also return `value` directly, as long as it is not a two element tuple.
  """
  @callback elixir_mapping(any, Keyword.t()) :: any | {any, uncanonical_lexical}

  @doc """
  Returns the standard lexical representation for a value of the value space of a `RDF.XSD.Datatype`.
  """
  @callback canonical_mapping(any) :: String.t()

  @doc """
  Produces the lexical representation to be used for a `RDF.XSD.Datatype` literal.

  By default, the lexical representation of a `RDF.XSD.Datatype` is either the
  canonical form in case it is created from a non-string Elixir value or, if it
  is created from a string, just with that string as the lexical form.

  But there can be various reasons for why this should be different for certain
  datatypes. For example, for `RDF.XSD.Double`s given as Elixir floats, we want the
  default lexical representation to be the decimal and not the canonical
  exponential form. Another reason might be that additional options are given
  which should be taken into account in the lexical form.

  If the lexical representation for a given `value` and `lexical` should be the
  canonical one, an implementation should return `nil`.
  """
  @callback init_valid_lexical(any, uncanonical_lexical, Keyword.t()) :: uncanonical_lexical

  @doc """
  Produces the lexical representation of an invalid value.

  The default implementation of the `_using__` macro just returns the `to_string/1`
  representation of the value.
  """
  @callback init_invalid_lexical(any, Keyword.t()) :: String.t()

  @doc """
  Returns the `RDF.XSD.Datatype` for a datatype IRI.
  """
  defdelegate get(id), to: RDF.Literal.Datatype.Registry, as: :xsd_datatype

  @doc false
  def most_specific(left, right)
  def most_specific(datatype, datatype), do: datatype

  def most_specific(left, right) do
    cond do
      left.datatype?(right) -> right
      right.datatype?(left) -> left
      true -> nil
    end
  end

  defmacro __using__(opts) do
    # credo:disable-for-next-line Credo.Check.Refactor.LongQuoteBlocks
    quote generated: true do
      defstruct [:value, :uncanonical_lexical]

      @behaviour unquote(__MODULE__)
      use RDF.Literal.Datatype, unquote(opts)

      @invalid_value nil

      @type invalid_value :: nil
      @type value :: valid_value | invalid_value

      @type t :: %__MODULE__{
              value: value,
              uncanonical_lexical: RDF.XSD.Datatype.uncanonical_lexical()
            }

      @doc !"""
           This function is just used to check if a module is a RDF.XSD.Datatype.

           See `RDF.Literal.Datatype.Registry.is_xsd_datatype?/1`.
           """
      def __xsd_datatype_indicator__, do: true

      @doc """
      Checks if the given literal has this datatype or a datatype that is derived of it.
      """
      @impl RDF.Literal.Datatype
      def datatype?(%RDF.Literal{literal: literal}), do: datatype?(literal)
      def datatype?(%datatype{}), do: datatype?(datatype)
      def datatype?(__MODULE__), do: true

      def datatype?(datatype) when maybe_module(datatype) do
        RDF.XSD.datatype?(datatype) and datatype.derived_from?(__MODULE__)
      end

      def datatype?(_), do: false

      @doc false
      def datatype!(%__MODULE__{}), do: true

      def datatype!(%datatype{} = literal) do
        datatype?(datatype) ||
          raise RDF.XSD.Datatype.MismatchError, value: literal, expected_type: __MODULE__
      end

      def datatype!(value),
        do: raise(RDF.XSD.Datatype.MismatchError, value: value, expected_type: __MODULE__)

      @doc """
      Creates a new `RDF.Literal` with this datatype and the given `value`.
      """
      @impl RDF.Literal.Datatype
      def new(value, opts \\ [])

      def new(lexical, opts) when is_binary(lexical) do
        if Keyword.get(opts, :as_value) do
          from_value(lexical, opts)
        else
          from_lexical(lexical, opts)
        end
      end

      def new(value, opts) do
        from_value(value, opts)
      end

      @doc """
      Creates a new `RDF.Literal` with this datatype and the given `value` or fails when it is not valid.
      """
      @impl RDF.Literal.Datatype
      def new!(value, opts \\ []) do
        literal = new(value, opts)

        if valid?(literal) do
          literal
        else
          raise ArgumentError, "#{inspect(value)} is not a valid #{inspect(__MODULE__)}"
        end
      end

      @doc false
      # Dialyzer causes a warning on all primitives since the facet_conform?/2 call
      # always returns true there, so the other branch is unnecessary. This could
      # be fixed by generating a special version for primitives, but it's not worth
      # maintaining different versions of this function which must be kept in-sync.
      @dialyzer {:nowarn_function, from_lexical: 2}
      def from_lexical(lexical, opts \\ []) when is_binary(lexical) do
        case lexical_mapping(lexical, opts) do
          @invalid_value ->
            build_invalid(lexical, opts)

          value ->
            if facet_conform?(value, lexical) do
              build_valid(value, lexical, opts)
            else
              build_invalid(lexical, opts)
            end
        end
      end

      @doc false
      # Dialyzer causes a warning on all primitives since the facet_conform?/2 call
      # always returns true there, so the other branch is unnecessary. This could
      # be fixed by generating a special version for primitives, but it's not worth
      # maintaining different versions of this function which must be kept in-sync.
      @dialyzer {:nowarn_function, from_value: 2}
      def from_value(value, opts \\ []) do
        case elixir_mapping(value, opts) do
          @invalid_value ->
            build_invalid(value, opts)

          value ->
            {value, lexical} =
              case value do
                {value, lexical} -> {value, lexical}
                value -> {value, nil}
              end

            if facet_conform?(value, lexical) do
              build_valid(value, lexical, opts)
            else
              build_invalid(value, opts)
            end
        end
      end

      @doc false
      @spec build_valid(any, RDF.XSD.Datatype.uncanonical_lexical(), Keyword.t()) ::
              RDF.Literal.t()
      def build_valid(value, lexical, opts) do
        if Keyword.get(opts, :canonicalize) do
          literal(%__MODULE__{value: value})
        else
          initial_lexical = init_valid_lexical(value, lexical, opts)

          literal(%__MODULE__{
            value: value,
            uncanonical_lexical:
              if(initial_lexical && initial_lexical != canonical_mapping(value),
                do: initial_lexical
              )
          })
        end
      end

      @dialyzer {:nowarn_function, build_invalid: 2}
      defp build_invalid(lexical, opts) do
        literal(%__MODULE__{uncanonical_lexical: init_invalid_lexical(lexical, opts)})
      end

      @doc """
      Returns the value of a `RDF.Literal` of this or a derived datatype.
      """
      @impl RDF.Literal.Datatype
      def value(%RDF.Literal{literal: literal}), do: value(literal)
      def value(%__MODULE__{} = literal), do: literal.value

      def value(literal) do
        datatype!(literal)

        literal.value
      end

      @doc """
      Returns the lexical form of a `RDF.Literal` of this datatype.
      """
      @impl RDF.Literal.Datatype
      def lexical(lexical)

      def lexical(%RDF.Literal{literal: literal}), do: lexical(literal)

      def lexical(%__MODULE__{value: value, uncanonical_lexical: nil}),
        do: canonical_mapping(value)

      def lexical(%__MODULE__{uncanonical_lexical: lexical}), do: lexical

      @doc """
      Returns the canonical lexical form of a `RDF.Literal` of this datatype.
      """
      @impl RDF.Literal.Datatype
      def canonical_lexical(%RDF.Literal{literal: literal}), do: canonical_lexical(literal)

      def canonical_lexical(%__MODULE__{value: value}) when not is_nil(value),
        do: canonical_mapping(value)

      def canonical_lexical(_), do: nil

      @doc """
      Produces the canonical representation of a `RDF.Literal` of this datatype.
      """
      @impl RDF.Literal.Datatype
      def canonical(literal)

      def canonical(%RDF.Literal{literal: %__MODULE__{uncanonical_lexical: nil}} = literal),
        do: literal

      def canonical(%RDF.Literal{literal: %__MODULE__{value: @invalid_value}} = literal),
        do: literal

      def canonical(%RDF.Literal{literal: %__MODULE__{} = literal}),
        do: canonical(literal)

      def canonical(%__MODULE__{} = literal),
        do: literal(%__MODULE__{literal | uncanonical_lexical: nil})

      @doc """
      Determines if the lexical form of a `RDF.Literal` of this datatype is the canonical form.
      """
      @impl RDF.Literal.Datatype
      def canonical?(literal)
      def canonical?(%RDF.Literal{literal: literal}), do: canonical?(literal)
      def canonical?(%__MODULE__{uncanonical_lexical: nil}), do: true
      def canonical?(%__MODULE__{}), do: false

      @doc """
      Determines if a `RDF.Literal` of this or a derived datatype has a proper value of its value space.
      """
      @impl RDF.Literal.Datatype
      def valid?(literal)
      def valid?(%RDF.Literal{literal: literal}), do: valid?(literal)
      def valid?(%__MODULE__{value: @invalid_value}), do: false
      def valid?(%__MODULE__{}), do: true

      def valid?(%datatype{} = literal),
        do: datatype?(datatype) and datatype.valid?(literal)

      def valid?(_), do: false

      @doc false
      defp equality_path(left_datatype, right_datatype)
      defp equality_path(datatype, datatype), do: {:same_or_derived, datatype}

      defp equality_path(left_datatype, right_datatype) do
        if RDF.XSD.datatype?(left_datatype) and RDF.XSD.datatype?(right_datatype) do
          if datatype = RDF.XSD.Datatype.most_specific(left_datatype, right_datatype) do
            {:same_or_derived, datatype}
          else
            {:different, left_datatype}
          end
        else
          {:different, left_datatype}
        end
      end

      @doc """
      Compares two `RDF.Literal`s.

      If the first literal is greater than the second `:gt` is returned, if less than `:lt` is returned.
      If both literal are equal `:eq` is returned.
      If the literals can not be compared either `nil` is returned, when they generally can be compared
      due to their datatype, or `:indeterminate` is returned, when the order of the given values is
      not defined on only partially ordered datatypes.
      """
      @spec compare(RDF.Literal.t() | any, RDF.Literal.t() | any) ::
              RDF.Literal.Datatype.comparison_result() | :indeterminate | nil
      def compare(left, right)
      def compare(left, %RDF.Literal{literal: right}), do: compare(left, right)
      def compare(%RDF.Literal{literal: left}, right), do: compare(left, right)

      def compare(left, right) do
        if RDF.XSD.datatype?(left) and RDF.XSD.datatype?(right) and
             RDF.Literal.Datatype.valid?(left) and RDF.Literal.Datatype.valid?(right) do
          do_compare(left, right)
        end
      end

      defimpl Inspect do
        "Elixir.Inspect." <> datatype_name = to_string(__MODULE__)
        @datatype_name datatype_name

        def inspect(literal, _opts) do
          "%#{@datatype_name}{value: #{inspect(literal.value)}, lexical: #{literal |> literal.__struct__.lexical() |> inspect()}}"
        end
      end
    end
  end
end
