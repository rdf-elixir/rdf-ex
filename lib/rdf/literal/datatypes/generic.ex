defmodule RDF.Literal.Generic do
  @moduledoc """
  A generic `RDF.Literal.Datatype` for literals of an unknown datatype.
  """

  defstruct [:value, :datatype]

  @behaviour RDF.Literal.Datatype

  alias RDF.Literal.Datatype
  alias RDF.{Literal, IRI}

  @type t :: %__MODULE__{
               value: String.t,
               datatype: String.t
             }

  @impl Datatype
  def literal_type, do: __MODULE__

  @impl Datatype
  def name, do: "generic"

  @impl Datatype
  def id, do: nil

  def new(value, opts \\ []) do
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

  def new!(value, opts \\ []) do
    literal = new(value, opts)

    if valid?(literal) do
      literal
    else
      raise ArgumentError, "#{inspect(value)} with datatype #{inspect literal.literal.datatype} is not a valid #{inspect(__MODULE__)}"
    end
  end

  @impl Datatype
  def datatype(%Literal{literal: literal}), do: datatype(literal)
  def datatype(%__MODULE__{} = literal), do: literal.datatype

  @impl Datatype
  def language(%Literal{literal: literal}), do: language(literal)
  def language(%__MODULE__{}), do: nil

  @impl Datatype
  def value(%Literal{literal: literal}), do: value(literal)
  def value(%__MODULE__{} = literal), do: literal.value

  @impl Datatype
  def lexical(%Literal{literal: literal}), do: lexical(literal)
  def lexical(%__MODULE__{} = literal), do: literal.value

  @impl Datatype
  def canonical(%Literal{literal: %__MODULE__{}} = literal), do: literal
  def canonical(%__MODULE__{} = literal), do: %Literal{literal: literal}

  @impl Datatype
  def canonical?(%Literal{literal: literal}), do: canonical?(literal)
  def canonical?(%__MODULE__{}), do: true

  @impl Datatype
  def valid?(%Literal{literal: %__MODULE__{} = literal}), do: valid?(literal)
  def valid?(%__MODULE__{datatype: %IRI{}}), do: true
  def valid?(_), do: false

  @impl Datatype
  def cast(%Literal{literal: %__MODULE__{}} = literal), do: literal
  def cast(_), do: nil

  @impl Datatype
  def equal_value?(left, %Literal{literal: right}), do: equal_value?(left, right)
  def equal_value?(%Literal{literal: left}, right), do: equal_value?(left, right)
  def equal_value?(%__MODULE__{} = left, right), do: left == right

  @impl Datatype
  def compare(left, %Literal{literal: right}), do: compare(left, right)
  def compare(%Literal{literal: left}, right), do: compare(left, right)
  def compare(%__MODULE__{datatype: datatype} = literal1,
              %__MODULE__{datatype: datatype} = literal2) do
    if valid?(literal1) and valid?(literal2) do
      case {canonical(literal1).literal.value, canonical(literal2).literal.value} do
        {value1, value2} when value1 < value2 -> :lt
        {value1, value2} when value1 > value2 -> :gt
        _ ->
          if equal_value?(literal1, literal2), do: :eq
      end
    end
  end

  def compare(_, _), do: nil

  defimpl String.Chars do
    def to_string(literal) do
      literal.value
    end
  end
end
