defmodule RDF.Literal.Generic do
  @moduledoc """
  A generic `RDF.Literal.Datatype` for literals of an unknown datatype.
  """

  defstruct [:value, :datatype]

  use RDF.Literal.Datatype,
    name: "generic",
    id: nil

  alias RDF.Literal.Datatype
  alias RDF.{Literal, IRI}

  @type t :: %__MODULE__{
               value: String.t,
               datatype: String.t
             }

  @impl Datatype
  @spec new(any, String.t | IRI.t | keyword) :: Literal.t
  def new(value, datatype_or_opts \\ [])
  def new(value, datatype) when is_binary(datatype), do: new(value, datatype: datatype)
  def new(value, %IRI{} = datatype), do: new(value, datatype: datatype)
  def new(value, opts) do
    %Literal{
      literal: %__MODULE__{
        value: value,
        datatype: Keyword.get(opts, :datatype) |> normalize_datatype()
      }
    }
  end

  defp normalize_datatype(nil), do: nil
  defp normalize_datatype(""), do: nil
  defp normalize_datatype(datatype), do: IRI.new(datatype)

  @impl Datatype
  @spec new!(any, String.t | IRI.t | keyword) :: Literal.t
  def new!(value, datatype_or_opts \\ []) do
    literal = new(value, datatype_or_opts)

    if valid?(literal) do
      literal
    else
      raise ArgumentError, "#{inspect(value)} with datatype #{inspect literal.literal.datatype} is not a valid #{inspect(__MODULE__)}"
    end
  end

  @impl Datatype
  def datatype_id(%Literal{literal: literal}), do: datatype_id(literal)
  def datatype_id(%__MODULE__{} = literal), do: literal.datatype

  @impl Datatype
  def value(%Literal{literal: literal}), do: value(literal)
  def value(%__MODULE__{} = literal), do: literal.value

  @impl Datatype
  def lexical(%Literal{literal: literal}), do: lexical(literal)
  def lexical(%__MODULE__{} = literal), do: literal.value

  @impl Datatype
  def canonical(%Literal{literal: %__MODULE__{}} = literal), do: literal
  def canonical(%__MODULE__{} = literal), do: literal(literal)

  @impl Datatype
  def canonical?(%Literal{literal: literal}), do: canonical?(literal)
  def canonical?(%__MODULE__{}), do: true

  @impl Datatype
  def valid?(%Literal{literal: %__MODULE__{} = literal}), do: valid?(literal)
  def valid?(%__MODULE__{datatype: %IRI{}}), do: true
  def valid?(_), do: false

  @doc """
  Since generic literals don't support casting, always returns `nil`.
  """
  def cast(_), do: nil

  @impl Datatype
  def do_cast(_), do: nil

  @impl Datatype
  def do_equal_value?(%__MODULE__{datatype: datatype} = left,
                      %__MODULE__{datatype: datatype} = right), do: left == right
  def do_equal_value?(_, _), do: nil

  @impl Datatype
  def compare(left, %Literal{literal: right}), do: compare(left, right)
  def compare(%Literal{literal: left}, right), do: compare(left, right)
  def compare(%__MODULE__{datatype: datatype} = literal1,
              %__MODULE__{datatype: datatype} = literal2) do
    if valid?(literal1) and valid?(literal2) do
      case {literal1.value, literal2.value} do
        {value1, value2} when value1 < value2 -> :lt
        {value1, value2} when value1 > value2 -> :gt
        _ ->
          if equal_value?(literal1, literal2), do: :eq
      end
    end
  end

  def compare(_, _), do: nil

  @impl Datatype
  def update(literal, fun, opts \\ [])
  def update(%Literal{literal: literal}, fun, opts), do: update(literal, fun, opts)
  def update(%__MODULE__{} = literal, fun, _opts) do
    literal
    |> value()
    |> fun.()
    |> new(datatype: literal.datatype)
  end
end
