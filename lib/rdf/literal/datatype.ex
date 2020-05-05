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
  Casts a datatype literal or coercible value of one type into a datatype literal of another type.

  If the given literal or value is invalid or can not be converted into this datatype an
  implementation should return `nil`.

  This function is called by auto-generated `cast/1` function on the implementations,
  which already deals with basic cases and coercion.
  """
  @callback do_cast(literal | any) :: Literal.t() | nil

  @doc """
  The datatype IRI of the given `RDF.Literal`.
  """
  @callback datatype(Literal.t | literal) :: IRI.t()

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
  @callback do_equal_value?(literal, literal) :: boolean

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

  defmacro __using__(opts) do
    name = Keyword.fetch!(opts, :name)
    id = Keyword.fetch!(opts, :id)

    quote do
      @behaviour unquote(__MODULE__)

      @name unquote(name)
      @impl unquote(__MODULE__)
      def name, do: @name

      @id if unquote(id), do: RDF.IRI.new(unquote(id))
      @impl unquote(__MODULE__)
      def id, do: @id

      @impl unquote(__MODULE__)
      def datatype(%Literal{literal: literal}), do: datatype(literal)
      def datatype(%__MODULE__{}), do: @id

      @impl unquote(__MODULE__)
      def language(%Literal{literal: literal}), do: language(literal)
      def language(%__MODULE__{}), do: nil

      @doc """
      Casts a datatype literal or coercible value of one type into a datatype literal of another type.

      Returns `nil` when the given arguments are not comparable as literals of this
      datatype or when the given argument is an invalid literal.

      Implementations define the casting for a given value with the `c:do_cast/1` callback.
      """
      def cast(literal_or_value)
      def cast(%Literal{literal: literal}), do: cast(literal)
      def cast(%__MODULE__{} = datatype_literal),
          do: if(valid?(datatype_literal), do: literal(datatype_literal))
      def cast(nil), do: nil
      def cast(value) do
        case do_cast(value) do
          %__MODULE__{} = literal -> if valid?(literal), do: literal(literal)
          %Literal{literal: %__MODULE__{}} = literal -> if valid?(literal), do: literal
          _ -> nil
        end
      end

      @impl unquote(__MODULE__)
      def do_cast(value) do
        value |> Literal.coerce() |> cast()
      end

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
          not RDF.literal?(right) -> equal_value?(left, Literal.coerce(right))
          not RDF.literal?(left) -> equal_value?(Literal.coerce(left), right)
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

      @spec less_than?(t, t) :: boolean
      def less_than?(literal1, literal2), do: Literal.less_than?(literal1, literal2)

      @spec greater_than?(t, t) :: boolean
      def greater_than?(literal1, literal2), do: Literal.greater_than?(literal1, literal2)

      defp literal(datatype_literal), do: %Literal{literal: datatype_literal}

      defoverridable datatype: 1,
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
    end
  end
end
