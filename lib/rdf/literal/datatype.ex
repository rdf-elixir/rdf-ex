defmodule RDF.Literal.Datatype do
  alias RDF.{Literal, IRI}

  @type t :: module

  @type literal :: %{:__struct__ => t(), optional(atom()) => any()}

  @type comparison_result :: :lt | :gt | :eq

  @doc """
  The name of the datatype.
  """
  @callback name :: String.t()

  @doc """
  The IRI of the datatype.
  """
  @callback id :: IRI.t() | nil

  @callback new(any) :: Literal.t()
  @callback new(any, Keyword.t()) :: Literal.t()

  @callback new!(any) :: Literal.t()
  @callback new!(any, Keyword.t()) :: Literal.t()

  @doc """
  Casts a datatype literal of one type into a datatype literal of another type.

  This function is called by the auto-generated `cast/1` function on the implementations, which already deals with the basic cases.
  So, implementations can assume the passed argument is a valid `RDF.Literal.Datatype` struct.

  If the given literal can not be converted into this datatype an implementation should return `nil`.

  A final catch-all clause should delegate to `super`. For example `RDF.XSD.Datatype`s will handle casting from derived
  datatypes in the default implementation.
  """
  @callback do_cast(literal) :: Literal.t() | nil

  @doc """
  Checks if the given `RDF.Literal` has the datatype for which the `RDF.Literal.Datatype` is implemented or is derived from it.

  ## Example

      iex> RDF.XSD.byte(42) |> RDF.XSD.Integer.datatype?()
      true

  """
  @callback datatype?(Literal.t | t | literal) :: boolean

  @doc """
  The datatype IRI of the given `RDF.Literal`.
  """
  @callback datatype_id(Literal.t | literal) :: IRI.t()

  @doc """
  The language of the given `RDF.Literal` if present.
  """
  @callback language(Literal.t | literal) :: String.t() | nil

  @doc """
  Returns the value of a `RDF.Literal`.
  """
  @callback value(Literal.t | literal) :: any

  @doc """
  Returns the lexical form of a `RDF.Literal`.
  """
  @callback lexical(Literal.t() | literal) :: String.t()

  @doc """
  Produces the canonical representation of a `RDF.Literal`.
  """
  @callback canonical(Literal.t() | literal) :: Literal.t()

  @doc """
  Returns the canonical lexical form of a `RDF.Literal`.

  If the given literal is invalid, `nil` is returned.
  """
  @callback canonical_lexical(Literal.t() | literal) :: String.t() | nil

  @doc """
  Determines if the lexical form of a `RDF.Literal` is the canonical form.

  Note: For `RDF.Literal.Generic` literals with the canonical form not defined,
  this always return `true`.
  """
  @callback canonical?(Literal.t() | literal | any) :: boolean

  @doc """
  Determines if the lexical form of a `RDF.Literal` is a member of its lexical value space.
  """
  @callback valid?(Literal.t() | literal | any) :: boolean

  @doc """
  Checks if two datatype literals are equal in terms of the values of their value space.

  Should return `nil` when the given arguments are not comparable as literals of this
  datatype. This behaviour is particularly important for SPARQL.ex where this
  function is used for the `=` operator, where comparisons between incomparable
  terms are treated as errors and immediately leads to a rejection of a possible
  match.

  This function is called by auto-generated `equal_value?/2` function on the
  implementations, which already deals with basic cases and coercion.
  """
  @callback do_equal_value?(literal, literal) :: boolean | nil

  @doc """
  Compares two `RDF.Literal`s.

  Returns `:gt` if value of the first literal is greater than the value of the second in
  terms of their datatype and `:lt` for vice versa. If the two literals are equal `:eq` is returned.
  For datatypes with only partial ordering `:indeterminate` is returned when the
  order of the given literals is not defined.

  Returns `nil` when the given arguments are not comparable datatypes or if one
  them is invalid.

  The default implementation of the `_using__` macro of `RDF.XSD.Datatype`s
  compares the values of the `canonical/1` forms of the given literals of this datatype.
  """
  @callback compare(Literal.t() | literal, Literal.t() | literal) :: comparison_result | :indeterminate | nil

  @doc """
  Updates the value of a `RDF.Literal` without changing everything else.

  ## Example

      iex> RDF.XSD.integer(42) |> RDF.XSD.Integer.update(fn value -> value + 1 end)
      RDF.XSD.integer(42)
      iex> RDF.literal("foo", language: "de") |> RDF.LangString.update(fn _ -> "bar" end)
      RDF.literal("bar", language: "de")
      iex> RDF.literal("foo", datatype: "http://example.com/dt") |> RDF.LangString.update(fn _ -> "bar" end)
      RDF.literal("bar", datatype: "http://example.com/dt")
  """
  @callback update(Literal.t() | literal, fun()) :: Literal.t

  @doc """
  Updates the value of a `RDF.Literal` without changing everything else.

  This variant of `c:update/2` allows with the `:as` option to specify what will
  be passed to `fun`, eg. with `as: :lexical` the lexical is passed to the function.

  ## Example

      iex> RDF.XSD.integer(42) |> RDF.XSD.Integer.update(
      ...>   fn value -> value <> "1" end, as: lexical)
      RDF.XSD.integer(421)
  """
  @callback update(Literal.t() | literal, fun(), keyword) :: Literal.t

  defdelegate get(id), to: Literal.Datatype.Registry, as: :datatype

  @doc !"""
  As opposed to RDF.Literal.valid?/1 this function operates on the datatype structs ...

  It's meant for internal use only and doesn't perform checks if the struct
  passed is actually a `RDF.Literal.Datatype` struct.
  """
  def valid?(%datatype{} = datatype_literal), do: datatype.valid?(datatype_literal)


  defmacro __using__(opts) do
    name = Keyword.fetch!(opts, :name)
    id = Keyword.fetch!(opts, :id)
    do_register = Keyword.get(opts, :register, not is_nil(id))
    datatype = __CALLER__.module

    # TODO: find an alternative to Code.eval_quoted - We want to support that id can be passed via a function call
    unquoted_id =
      if do_register do
        id
        |> Code.eval_quoted([], __ENV__)
        |> elem(0)
        |> to_string()
      end

    quote do
      @behaviour unquote(__MODULE__)

      @doc !"""
      This function is just used to check if a module is a RDF.Literal.Datatype.

      See `RDF.Literal.Datatype.Registry.is_rdf_literal_datatype?/1`.
      """
      def __rdf_literal_datatype_indicator__, do: true

      @name unquote(name)
      @impl unquote(__MODULE__)
      def name, do: @name

      @id if unquote(id), do: RDF.IRI.new(unquote(id))
      @impl unquote(__MODULE__)
      def id, do: @id

      # RDF.XSD.Datatypes offers another default implementation, but since it is
      # still in a macro implementation defoverridable doesn't work
      unless RDF.XSD.Datatype in @behaviour do
        @impl unquote(__MODULE__)
        def datatype?(%Literal{literal: literal}), do: datatype?(literal)
        def datatype?(%datatype{}), do: datatype?(datatype)
        def datatype?(__MODULE__), do: true
        def datatype?(_), do: false
      end

      @impl unquote(__MODULE__)
      def datatype_id(%Literal{literal: literal}), do: datatype_id(literal)
      def datatype_id(%__MODULE__{}), do: @id

      @impl unquote(__MODULE__)
      def language(%Literal{literal: literal}), do: language(literal)
      def language(%__MODULE__{}), do: nil

      @impl unquote(__MODULE__)
      def canonical_lexical(literal)
      def canonical_lexical(%Literal{literal: literal}), do: canonical_lexical(literal)

      def canonical_lexical(%__MODULE__{} = literal) do
        if valid?(literal) do
          literal |> canonical() |> lexical()
        end
      end
      def canonical_lexical(_), do: nil

      @doc """
      Casts a datatype literal of one type into a datatype literal of another type.

      Returns `nil` when the given arguments are not castable into this datatype or when the given argument is an
      invalid literal.

      Implementations define the casting for a given value with the `c:do_cast/1` callback.
      """
      @spec cast(Literal.t | Literal.Datatype.literal) :: Literal.t() | nil
      @dialyzer {:nowarn_function, cast: 1}
      def cast(literal_or_value)
      def cast(%Literal{literal: literal}), do: cast(literal)
      def cast(%__MODULE__{} = datatype_literal),
          do: if(valid?(datatype_literal), do: literal(datatype_literal))
      def cast(%struct{} = datatype_literal) do
        if Literal.datatype?(struct) and Literal.Datatype.valid?(datatype_literal) do
          case do_cast(datatype_literal) do
            %__MODULE__{} = literal -> if valid?(literal), do: literal(literal)
            %Literal{literal: %__MODULE__{}} = literal -> if valid?(literal), do: literal
            _ -> nil
          end
        end
      end

      def cast(_), do: nil

      @impl unquote(__MODULE__)
      def do_cast(value), do: nil

      @doc """
      Checks if two datatype literals are equal in terms of the values of their value space.

      Non-`RDF.Literal`s  are tried to be coerced via `RDF.Literal.coerce/1` before comparison.

      Returns `nil` when the given arguments are not comparable as literals of this
      datatype.

      Implementations define this equivalence relation via the `c:do_equal_value?/2` callback.
      """
      def equal_value?(left, right)
      def equal_value?(left, %Literal{literal: right}), do: equal_value?(left, right)
      def equal_value?(%Literal{literal: left}, right), do: equal_value?(left, right)
      def equal_value?(nil, _), do: nil
      def equal_value?(_, nil), do: nil
      def equal_value?(left, right) do
        cond do
          not Literal.datatype?(right) and not RDF.term?(right) -> equal_value?(left, Literal.coerce(right))
          not Literal.datatype?(left) and not RDF.term?(left) -> equal_value?(Literal.coerce(left), right)
          true -> do_equal_value?(left, right)
        end
      end

      # RDF.XSD.Datatypes offers another default implementation, but since it is
      # still in a macro implementation defoverridable doesn't work
      unless RDF.XSD.Datatype in @behaviour do
        @impl unquote(__MODULE__)
        def do_equal_value?(left, right)
        def do_equal_value?(%__MODULE__{} = left, %__MODULE__{} = right), do: left == right
        def do_equal_value?(_, _), do: nil

        defoverridable do_equal_value?: 2
      end

      @impl unquote(__MODULE__)
      def update(literal, fun, opts \\ [])
      def update(%Literal{literal: literal}, fun, opts), do: update(literal, fun, opts)
      def update(%__MODULE__{} = literal, fun, opts) do
        case Keyword.get(opts, :as) do
          :lexical -> lexical(literal)
          nil -> value(literal)
        end
        |> fun.()
        |> new()
      end

      # This is a private RDF.Literal constructor, which should be used to build
      # the RDF.Literals from the datatype literal structs instead of the
      # RDF.Literal/new/1, to bypass the unnecessary datatype checks.
      defp literal(datatype_literal), do: %Literal{literal: datatype_literal}

      defoverridable datatype_id: 1,
                     language: 1,
                     cast: 1,
                     do_cast: 1,
                     equal_value?: 2,
                     update: 2,
                     update: 3

      defimpl String.Chars do
        def to_string(literal) do
          literal.__struct__.lexical(literal)
        end
      end

      if unquote(do_register) do
        import ProtocolEx

        defimpl_ex Registration, unquote(unquoted_id),
                   for: RDF.Literal.Datatype.Registry.Registration do
          def datatype(id), do: unquote(datatype)
        end
      end
    end
  end
end
