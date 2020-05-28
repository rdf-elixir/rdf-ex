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

  import RDF.Utils.Guards

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

      @doc !"""
      This function is just used to check if a module is a RDF.XSD.Datatype.

      See `RDF.Literal.Datatype.Registry.is_xsd_datatype?/1`.
      """
      def __xsd_datatype_indicator__, do: true

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
      def datatype!((%datatype{} = literal)) do
        datatype?(datatype) ||
          raise RDF.XSD.Datatype.Mismatch, value: literal, expected_type: __MODULE__
      end
      def datatype!(value),
        do: raise RDF.XSD.Datatype.Mismatch, value: value, expected_type: __MODULE__

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
      @spec build_valid(any, RDF.XSD.Datatype.uncanonical_lexical(), Keyword.t()) :: RDF.Literal.t()
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

      @impl RDF.Literal.Datatype
      def value(%RDF.Literal{literal: literal}), do: value(literal)
      def value(%__MODULE__{} = literal), do: literal.value

      def value(literal) do
        datatype!(literal)

        literal.value
      end

      @impl RDF.Literal.Datatype
      def lexical(lexical)

      def lexical(%RDF.Literal{literal: literal}), do: lexical(literal)

      def lexical(%__MODULE__{value: value, uncanonical_lexical: nil}),
        do: canonical_mapping(value)

      def lexical(%__MODULE__{uncanonical_lexical: lexical}), do: lexical

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
      def valid?((%datatype{} = literal)),
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

      @spec compare(RDF.Literal.t() | any, RDF.Literal.t() | any) :: RDF.Literal.Datatype.comparison_result | :indeterminate | nil
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
          "%#{@datatype_name}{value: #{inspect(literal.value)}, lexical: #{
            literal |> literal.__struct__.lexical() |> inspect()
          }}"
        end
      end
    end
  end
end
