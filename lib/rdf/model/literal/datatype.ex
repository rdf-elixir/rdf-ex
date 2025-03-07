defmodule RDF.Literal.Datatype do
  @moduledoc """
  A behaviour for datatypes for `RDF.Literal`s.

  An implementation of this behaviour defines a struct for a datatype IRI and the semantics of its
  values via the functions defined by this behaviour.

  There are three important groups of `RDF.Literal.Datatype` implementations:

  - `RDF.XSD.Datatype`: This is another, more specific behaviour for XSD datatypes. RDF.ex comes with
    builtin implementations of this behaviour for the most important XSD datatypes, but you define
    your own custom datatypes by deriving from these builtin datatypes and constraining them via
    `RDF.XSD.Facet`s.
  - Non-XSD datatypes which implement the `RDF.Literal.Datatype` directly.
    There's currently only two builtin datatypes of this category
      - `RDF.LangString` for language tagged RDF literals and
      - `RDF.JSON` for JSON content
  - `RDF.Literal.Generic`: This is a generic implementation which is used for `RDF.Literal`s with a
    datatype that has no own `RDF.Literal.Datatype` implementation defining its semantics.
  """

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
  Callback for datatype specific castings.

  This callback is called by the auto-generated `cast/1` function on the implementations, which already deals with the basic cases.
  So, implementations can assume the passed argument is a valid `RDF.Literal.Datatype` struct,
  a `RDF.IRI` or a `RDF.BlankNode`.

  If the given literal can not be converted into this datatype an implementation should return `nil`.

  A final catch-all clause should delegate to `super`. For example `RDF.XSD.Datatype`s will handle casting from derived
  datatypes in the default implementation.
  """
  @callback do_cast(literal | RDF.IRI.t() | RDF.BlankNode.t()) :: Literal.t() | nil

  @doc """
  Checks if the given `RDF.Literal` has the datatype for which the `RDF.Literal.Datatype` is implemented or is derived from it.

  ## Example

      iex> RDF.XSD.byte(42) |> RDF.XSD.Integer.datatype?()
      true

  """
  @callback datatype?(Literal.t() | t | literal) :: boolean

  @doc """
  The datatype IRI of the given `RDF.Literal`.
  """
  @callback datatype_id(Literal.t() | literal) :: IRI.t()

  @doc """
  The language of the given `RDF.Literal` if present.
  """
  @callback language(Literal.t() | literal) :: String.t() | nil

  @doc """
  Returns the value of a `RDF.Literal`.

  This function also accepts literals of derived datatypes.
  """
  @callback value(Literal.t() | literal) :: any

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
  this always returns `true`.
  """
  @callback canonical?(Literal.t() | literal | any) :: boolean

  @doc """
  Determines if a `RDF.Literal` has a proper value of the value space of its datatype.

  This function also accepts literals of derived datatypes.
  """
  @callback valid?(Literal.t() | literal | any) :: boolean

  @doc """
  Callback for datatype specific `equal_value?/2` comparisons when the given literals have the same or derived datatypes.

  This callback is called by auto-generated `equal_value?/2` function when the given literals have
  the same datatype or one is derived from the other.

  Should return `nil` when the given arguments are not comparable as literals of this
  datatype. This behaviour is particularly important for SPARQL.ex where this
  function is used for the `=` operator, where comparisons between incomparable
  terms are treated as errors and immediately leads to a rejection of a possible
  match.

  See also `c:do_equal_value_different_datatypes?/2`.
  """
  @callback do_equal_value_same_or_derived_datatypes?(literal, literal) :: boolean | nil

  @doc """
  Callback for datatype specific `equal_value?/2` comparisons when the given literals have different datatypes.

  This callback is called by auto-generated `equal_value?/2` function when the given literals have
  different datatypes and are not derived from each other.

  Should return `nil` when the given arguments are not comparable as literals of this
  datatype. This behaviour is particularly important for SPARQL.ex where this
  function is used for the `=` operator, where comparisons between incomparable
  terms are treated as errors and immediately leads to a rejection of a possible
  match.

  See also `c:do_equal_value_same_or_derived_datatypes?/2`.
  """
  @callback do_equal_value_different_datatypes?(literal, literal) :: boolean | nil

  @doc """
  Callback for datatype specific `compare/2` comparisons between two `RDF.Literal`s.

  This callback is called by auto-generated `compare/2` function on the implementations, which already deals with the basic cases.
  So, implementations can assume the passed arguments are valid `RDF.Literal.Datatype` structs and
  have the same datatypes or are derived from each other.

  Should return `:gt` if value of the first literal is greater than the value of the second in
  terms of their datatype and `:lt` for vice versa. If the two literals can be considered equal `:eq` should be returned.
  For datatypes with only partial ordering `:indeterminate` should be returned when the
  order of the given literals is not defined.

  `nil` should be returned when the given arguments are not comparable datatypes or if one them is invalid.

  The default implementation of the `_using__` macro of `RDF.Literal.Datatype`s
  just compares the values of the given literals.
  """
  @callback do_compare(literal | any, literal | any) :: comparison_result | :indeterminate | nil

  @doc """
  Updates the value of a `RDF.Literal` without changing everything else.

  ## Example

      iex> RDF.XSD.integer(42) |> RDF.XSD.Integer.update(fn value -> value + 1 end)
      RDF.XSD.integer(43)
      iex> ~L"foo"de |> RDF.LangString.update(fn _ -> "bar" end)
      ~L"bar"de
      iex> RDF.literal("foo", datatype: "http://example.com/dt") |> RDF.Literal.Generic.update(fn _ -> "bar" end)
      RDF.literal("bar", datatype: "http://example.com/dt")
  """
  @callback update(Literal.t() | literal, fun()) :: Literal.t()

  @doc """
  Updates the value of a `RDF.Literal` without changing anything else.

  This variant of `c:update/2` allows with the `:as` option to specify what will
  be passed to `fun`, e.g. with `as: :lexical` the lexical is passed to the function.

  ## Example

      iex> RDF.XSD.integer(42) |> RDF.XSD.Integer.update(
      ...>   fn value -> value <> "1" end, as: :lexical)
      RDF.XSD.integer(421)
  """
  @callback update(Literal.t() | literal, fun(), keyword) :: Literal.t()

  @doc """
  Returns the `RDF.Literal.Datatype` for a datatype IRI.
  """
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

    # credo:disable-for-next-line Credo.Check.Refactor.LongQuoteBlocks
    quote generated: true do
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
        @doc """
        Checks if the given literal has this datatype.
        """
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

      @doc """
      Returns the canonical lexical form of a `RDF.Literal` of this datatype.
      """
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

      Implementations define the casting for a given value with the `c:RDF.Literal.Datatype.do_cast/1` callback.
      """
      @spec cast(Literal.Datatype.literal() | RDF.Term.t()) :: Literal.t() | nil
      @dialyzer {:nowarn_function, cast: 1}
      def cast(literal_or_value)
      def cast(%Literal{literal: literal}), do: cast(literal)

      def cast(%__MODULE__{} = datatype_literal),
        do: if(valid?(datatype_literal), do: literal(datatype_literal))

      def cast(%struct{} = datatype_literal) do
        if (Literal.datatype?(struct) and Literal.Datatype.valid?(datatype_literal)) or
             struct in [RDF.IRI, RDF.BlankNode] do
          case do_cast(datatype_literal) do
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

      Invalid literals are only considered equal in this relation when both have the exact same
      datatype and the same attributes (lexical form, language etc.).

      Implementations can customize this equivalence relation via the `c:RDF.Literal.Datatype.do_equal_value_different_datatypes?/2`
      and `c:RDF.Literal.Datatype.do_equal_value_different_datatypes?/2` callbacks.
      """
      def equal_value?(left, right)
      def equal_value?(left, %Literal{literal: right}), do: equal_value?(left, right)
      def equal_value?(%Literal{literal: left}, right), do: equal_value?(left, right)
      def equal_value?(nil, _), do: nil
      def equal_value?(_, nil), do: nil

      def equal_value?(left, right) do
        cond do
          not Literal.datatype?(right) and not resource?(right) ->
            equal_value?(left, Literal.coerce(right))

          not Literal.datatype?(left) and not resource?(left) ->
            equal_value?(Literal.coerce(left), right)

          true ->
            left_datatype = left.__struct__
            right_datatype = right.__struct__
            left_valid = resource?(left) or left_datatype.valid?(left)
            right_valid = resource?(right) or right_datatype.valid?(right)

            cond do
              not left_valid and not right_valid ->
                left == right

              left_valid and right_valid ->
                case equality_path(left_datatype, right_datatype) do
                  {:same_or_derived, datatype} ->
                    datatype.do_equal_value_same_or_derived_datatypes?(left, right)

                  {:different, datatype} ->
                    datatype.do_equal_value_different_datatypes?(left, right)
                end

              # one of the given literals is invalid
              true ->
                if left_datatype == right_datatype do
                  false
                end
            end
        end
      end

      # RDF.XSD.Datatype offers another default implementation, but since it is
      # still in a macro implementation defoverridable doesn't work
      unless RDF.XSD.Datatype in @behaviour do
        @impl unquote(__MODULE__)
        def do_equal_value_same_or_derived_datatypes?(left, right), do: left == right

        @impl unquote(__MODULE__)
        def do_equal_value_different_datatypes?(left, right), do: nil

        defoverridable do_equal_value_same_or_derived_datatypes?: 2,
                       do_equal_value_different_datatypes?: 2
      end

      defp equality_path(left_datatype, right_datatype)
      defp equality_path(datatype, datatype), do: {:same_or_derived, datatype}
      defp equality_path(datatype, _), do: {:different, datatype}

      # as opposed to RDF.resource? this does not try to resolve atoms
      defp resource?(%RDF.IRI{}), do: true
      defp resource?(%RDF.BlankNode{}), do: true
      defp resource?(_), do: false

      # RDF.XSD.Datatypes offers another default implementation, but since it is
      # still in a macro implementation defoverridable doesn't work
      unless RDF.XSD.Datatype in @behaviour do
        @spec compare(RDF.Literal.t() | any, RDF.Literal.t() | any) ::
                RDF.Literal.Datatype.comparison_result() | :indeterminate | nil
        def compare(left, right)
        def compare(left, %RDF.Literal{literal: right}), do: compare(left, right)
        def compare(%RDF.Literal{literal: left}, right), do: compare(left, right)

        def compare(left, right) do
          if RDF.Literal.datatype?(left) and RDF.Literal.datatype?(right) and
               RDF.Literal.Datatype.valid?(left) and RDF.Literal.Datatype.valid?(right) do
            do_compare(left, right)
          end
        end

        @impl RDF.Literal.Datatype
        def do_compare(%datatype{} = left, %datatype{} = right) do
          case {datatype.value(left), datatype.value(right)} do
            {left_value, right_value} when left_value < right_value ->
              :lt

            {left_value, right_value} when left_value > right_value ->
              :gt

            _ ->
              if datatype.equal_value?(left, right), do: :eq
          end
        end

        def do_compare(_, _), do: nil

        defoverridable compare: 2,
                       do_compare: 2
      end

      @doc """
      Updates the value of a `RDF.Literal` without changing everything else.
      """
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
                     canonical_lexical: 1,
                     cast: 1,
                     do_cast: 1,
                     equal_value?: 2,
                     equality_path: 2,
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
          @moduledoc false

          def datatype(id), do: unquote(datatype)
        end
      end
    end
  end
end
