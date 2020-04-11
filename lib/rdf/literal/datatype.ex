defmodule RDF.Literal.Datatype do
  alias RDF.{Literal, IRI}

  @type t :: module

  @type literal :: %{:__struct__ => t(), optional(atom()) => any()}

  @type comparison_result :: :lt | :gt | :eq

  @doc false
  @callback literal_type :: module

  @doc """
  The name of the datatype.
  """
  @callback name :: String.t()

  @doc """
  The IRI of the datatype.
  """
  @callback id :: String.t() | nil

  @doc """
  The datatype IRI of the given datatype literal.
  """
  @callback datatype(Literal.t | literal) :: IRI.t()

  @doc """
  The language of the given datatype literal if present.
  """
  @callback language(Literal.t | literal) :: String.t() | nil

  @doc """
  Returns the value of a datatype literal.
  """
  @callback value(Literal.t | literal) :: any

  @doc """
  Returns the lexical form of a datatype literal.
  """
  @callback lexical(Literal.t() | literal) :: String.t()

  @doc """
  Produces the canonical representation of a datatype literal.
  """
  @callback canonical(Literal.t() | literal) :: Literal.t()

  @doc """
  Determines if the lexical form of a datatype literal is the canonical form.

  Note: For `RDF.Literal.Generic` literals with the canonical form not defined,
  this always return `true`.
  """
  @callback canonical?(Literal.t() | literal | any) :: boolean

  @doc """
  Determines if the lexical form of a datatype literal is a member of its lexical value space.
  """
  @callback valid?(Literal.t() | literal | any) :: boolean

  @doc """
  Casts a datatype literal or coercible value of one type into a datatype literal of another type.

  If the given literal or value is invalid or can not be converted into this datatype an
  implementation should return `nil`.
  """
  @callback cast(Literal.t() | literal | any) :: Literal.t() | nil

  @doc """
  Checks if two datatype literals are equal in terms of the values of their value space.

  Non-`RDF.Literal.Datatype` literals are tried to be coerced via `RDF.Term.coerce/1` before comparison.
  """
  @callback equal_value?(Literal.t() | literal, Literal.t() | literal | any) :: boolean

  @doc """
  Compares two datatype literals.

  Returns `:gt` if value of the first literal is greater than the value of the second in
  terms of their datatype and `:lt` for vice versa. If the two literals are equal `:eq` is returned.
  For datatypes with only partial ordering `:indeterminate` is returned when the
  order of the given literals is not defined.

  Returns `nil` when the given arguments are not comparable datatypes or if one
  them is invalid.
  """
  @callback compare(Literal.t() | literal, Literal.t() | literal) :: comparison_result | :indeterminate | nil
end
