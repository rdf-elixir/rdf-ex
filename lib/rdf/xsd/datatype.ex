defmodule RDF.XSD.Datatype do
  @moduledoc """
  The behaviour of all XSD datatypes.
  """

  @type t :: module

  @type uncanonical_lexical :: String.t() | nil

  @type literal :: %{
          :__struct__ => t(),
          :value => any(),
          :uncanonical_lexical => uncanonical_lexical()
        }

  @type comparison_result :: :lt | :gt | :eq


  @doc """
  Returns if the `RDF.XSD.Datatype` is a primitive datatype.
  """
  @callback primitive?() :: boolean

  @doc """
  The base datatype from which a `RDF.XSD.Datatype` is derived.
  """
  @callback base :: t() | nil

  @doc """
  The primitive `RDF.XSD.Datatype` from which a `RDF.XSD.Datatype` is derived.

  In case of a primitive `RDF.XSD.Datatype` this function returns this `RDF.XSD.Datatype` itself.
  """
  @callback base_primitive :: t()

  @doc """
  Checks if a `RDF.XSD.Datatype` is directly or indirectly derived from another `RDF.XSD.Datatype`.
  """
  @callback derived_from?(t()) :: boolean

  @doc """
  Checks if the datatype of a given literal is derived from a `RDF.XSD.Datatype`.
  """
  @callback derived?(RDF.XSD.Literal.t()) :: boolean

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
  """
  @callback elixir_mapping(any, Keyword.t()) :: any | {any, uncanonical_lexical}

  @doc """
  Returns the standard lexical representation for a value of the value space of a `RDF.XSD.Datatype`.
  """
  @callback canonical_mapping(any) :: String.t()

  @doc """
  Produces the lexical representation to be used as for a `RDF.XSD.Datatype` literal.
  """
  @callback init_valid_lexical(any, uncanonical_lexical, Keyword.t()) :: uncanonical_lexical

  @doc """
  Produces the lexical representation of an invalid value.

  The default implementation of the `_using__` macro just returns `to_string/1`
  representation of the value.
  """
  @callback init_invalid_lexical(any, Keyword.t()) :: String.t()

  @doc """
  Matches the lexical form of the given `RDF.XSD.Datatype` literal against a XPath and XQuery regular expression pattern.

  The regular expression language is defined in _XQuery 1.0 and XPath 2.0 Functions and Operators_.

  see <https://www.w3.org/TR/xpath-functions/#func-matches>
  """
  @callback matches?(RDF.XSD.Literal.t(), pattern :: String.t()) :: boolean

  @doc """
  Matches the lexical form of the given `RDF.XSD.Datatype` literal against a XPath and XQuery regular expression pattern with flags.

  The regular expression language is defined in _XQuery 1.0 and XPath 2.0 Functions and Operators_.

  see <https://www.w3.org/TR/xpath-functions/#func-matches>
  """
  @callback matches?(RDF.XSD.Literal.t(), pattern :: String.t(), flags :: String.t()) :: boolean


  defmacro __using__(opts) do
    quote do
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

      @impl unquote(__MODULE__)
      def derived_from?(datatype)

      def derived_from?(__MODULE__), do: true

      def derived_from?(datatype) do
        base = base()
        not is_nil(base) and base.derived_from?(datatype)
      end

      @impl unquote(__MODULE__)
      def derived?(literal), do: RDF.XSD.Datatype.derived_from?(literal, __MODULE__)

      # Dialyzer causes a warning on all primitives since the facet_conform?/2 call
      # always returns true there, so the other branch is unnecessary. This could
      # be fixed by generating a special version for primitives, but it's not worth
      # maintaining different versions of this function which must be kept in-sync.
      @dialyzer {:nowarn_function, new: 2}
      @impl RDF.Literal.Datatype
      def new(value, opts \\ [])

      def new(lexical, opts) when is_binary(lexical) do
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

      def new(value, opts) do
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
      @spec build_valid(any, RDF.XSD.Datatype.uncanonical_lexical(), Keyword.t()) :: t()
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

      defp build_invalid(lexical, opts) do
        literal(%__MODULE__{uncanonical_lexical: init_invalid_lexical(lexical, opts)})
      end

      def cast(literal_or_value)
      def cast(%RDF.Literal{literal: literal}), do: cast(literal)
      # Invalid values can not be casted in general
      def cast(%{value: @invalid_value}), do: nil
      def cast(%__MODULE__{} = datatype_literal), do: literal(datatype_literal)
      def cast(nil), do: nil
      def cast(value) do
        case do_cast(value) do
          %__MODULE__{} = literal -> if valid?(literal), do: literal(literal)
          %RDF.Literal{literal: %__MODULE__{}} = literal -> if valid?(literal), do: literal
          _ -> nil
        end
      end

      @impl RDF.Literal.Datatype
      def value(%RDF.Literal{literal: literal}), do: value(literal)
      def value(%__MODULE__{} = literal), do: literal.value

      @impl RDF.Literal.Datatype
      def lexical(lexical)

      def lexical(%RDF.Literal{literal: literal}), do: lexical(literal)

      def lexical(%__MODULE__{value: value, uncanonical_lexical: nil}),
        do: canonical_mapping(value)

      def lexical(%__MODULE__{uncanonical_lexical: lexical}), do: lexical

      @impl RDF.Literal.Datatype
      @spec canonical(t()) :: t()
      def canonical(literal)

      def canonical(%RDF.Literal{literal: %__MODULE__{uncanonical_lexical: nil}} = literal),
        do: literal

      def canonical(%RDF.Literal{literal: %__MODULE__{value: @invalid_value}} = literal),
        do: literal

      def canonical(%RDF.Literal{literal: %__MODULE__{} = literal}),
        do: canonical(literal)

      def canonical(%__MODULE__{} = literal),
        do: literal(%__MODULE__{literal | uncanonical_lexical: nil})

      @impl RDF.Literal.Datatype
      def canonical?(literal)
      def canonical?(%RDF.Literal{literal: literal}), do: canonical?(literal)
      def canonical?(%__MODULE__{uncanonical_lexical: nil}), do: true
      def canonical?(%__MODULE__{}), do: false

      @impl RDF.Literal.Datatype
      def valid?(literal)
      def valid?(%RDF.Literal{literal: literal}), do: valid?(literal)
      def valid?(%__MODULE__{value: @invalid_value}), do: false
      def valid?(%__MODULE__{}), do: true
      def valid?(_), do: false

      def canonical_lexical(literal)
      def canonical_lexical(%RDF.Literal{literal: literal}), do: canonical_lexical(literal)
      def canonical_lexical(%__MODULE__{value: nil}), do: nil

      def canonical_lexical(%__MODULE__{value: value, uncanonical_lexical: nil}),
        do: canonical_mapping(value)

      def canonical_lexical(%__MODULE__{} = literal),
        do: literal |> canonical() |> lexical()

      def canonical_lexical(_), do: nil

      @doc """
      Matches the string representation of the given value against a XPath and XQuery regular expression pattern.

      The regular expression language is defined in _XQuery 1.0 and XPath 2.0 Functions and Operators_.

      see <https://www.w3.org/TR/xpath-functions/#func-matches>
      """
      @impl RDF.XSD.Datatype
      def matches?(literal, pattern, flags \\ "")
      def matches?(%RDF.Literal{literal: literal}, pattern, flags), do: matches?(literal, pattern, flags)
      def matches?(%__MODULE__{} = literal, pattern, flags) do
        literal
        |> lexical()
        |> RDF.XSD.Utils.Regex.matches?(pattern, flags)
      end

      defimpl Inspect do
        "Elixir.Inspect." <> datatype_name = to_string(__MODULE__)
        @datatype_name datatype_name

        def inspect(literal, _opts) do
          "%#{@datatype_name}{value: #{inspect(literal.value)}, lexical: #{
            literal |> literal.__struct__.lexical() |> inspect()
          }}"
        end
      end
    end
  end

  @spec base_primitive(t()) :: t()
  def base_primitive(%RDF.Literal{literal: literal}), do: base_primitive(literal)
  def base_primitive(%datatype{}), do: base_primitive(datatype)
  def base_primitive(datatype), do: datatype.base_primitive()

  @spec derived_from?(t() | literal() | RDF.Literal.t(), t()) :: boolean
  def derived_from?(%RDF.Literal{literal: literal}, super_datatype), do: derived_from?(literal, super_datatype)
  def derived_from?(%datatype{}, super_datatype), do: derived_from?(datatype, super_datatype)
  def derived_from?(datatype, super_datatype) when is_atom(datatype), do: datatype.derived_from?(super_datatype)
end
