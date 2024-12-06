defmodule RDF.JSON do
  defstruct [:lexical]

  use RDF.Literal.Datatype,
    name: "JSON",
    id: RDF.Utils.Bootstrapping.rdf_iri("JSON")

  alias RDF.Literal.Datatype
  alias RDF.Literal

  @type lexical :: String.t()
  @type value :: String.t() | number | boolean | map | list | nil

  @type t :: %__MODULE__{lexical: lexical()}

  @impl RDF.Literal.Datatype
  @spec new(t() | lexical() | value(), keyword) :: Literal.t()
  def new(value_or_lexical, opts \\ [])

  def new(%__MODULE__{} = json, _opts), do: %Literal{literal: json}

  def new(value, opts)
      when is_number(value) or is_boolean(value) or is_nil(value) or is_list(value) or
             is_map(value) do
    from_value(value, opts)
  end

  def new(value_or_lexical, opts) when is_binary(value_or_lexical) do
    if Keyword.get(opts, :as_value, false) do
      from_value(value_or_lexical, opts)
    else
      %Literal{literal: %__MODULE__{lexical: value_or_lexical}}
      |> handle_canonicalize(opts)
      |> handle_pretty(opts)
    end
  end

  def new(value, _opts), do: from_invalid(value)

  defp from_value(value, opts \\ []) do
    {jason_encode, opts} = Keyword.pop(opts, :jason_encode, false)
    pretty = Keyword.get(opts, :pretty, false)

    cond do
      pretty && Keyword.get(opts, :canonicalize) ->
        raise ArgumentError, ":pretty and :canonicalize opts cannot be combined"

      jason_encode || pretty ->
        case Jason.encode(value, opts) do
          {:ok, encoded} ->
            %Literal{literal: %__MODULE__{lexical: encoded}}
            |> handle_canonicalize(opts)

          _ ->
            from_invalid(value)
        end

      true ->
        try do
          %Literal{literal: %__MODULE__{lexical: Jcs.encode(value)}}
        rescue
          _ -> from_invalid(value)
        end
    end
  end

  defp from_invalid(value) when is_binary(value),
    do: %Literal{literal: %__MODULE__{lexical: value}}

  defp from_invalid(value), do: value |> inspect() |> from_invalid()

  defp handle_canonicalize(literal, opts) do
    if Keyword.get(opts, :canonicalize, false) do
      canonical(literal)
    else
      literal
    end
  end

  defp handle_pretty(literal, opts) do
    if Keyword.get(opts, :pretty, false) do
      prettified(literal)
    else
      literal
    end
  end

  @impl RDF.Literal.Datatype
  @spec new!(lexical() | value(), keyword) :: Literal.t()
  def new!(value_or_lexical, opts \\ []) do
    literal = new(value_or_lexical, opts)

    if valid?(literal) do
      literal
    else
      raise ArgumentError, "#{inspect(value_or_lexical)} is not a valid #{inspect(__MODULE__)}"
    end
  end

  @impl Datatype
  @spec value(Literal.t() | t(), keyword) :: value() | :invalid
  def value(literal, opts \\ [])

  def value(%Literal{literal: literal}, opts), do: value(literal, opts)

  def value(%__MODULE__{} = json, opts) do
    case Jason.decode(json.lexical, opts) do
      {:ok, value} -> value
      _ -> :invalid
    end
  end

  @impl Datatype
  def lexical(%Literal{literal: literal}), do: lexical(literal)
  def lexical(%__MODULE__{} = json), do: json.lexical

  @impl Datatype
  def canonical(%Literal{literal: literal}), do: canonical(literal)

  def canonical(%__MODULE__{} = json) do
    case value(json) do
      :invalid -> new(json)
      value -> from_value(value)
    end
  end

  def prettified(%Literal{literal: literal}), do: prettified(literal)

  def prettified(%__MODULE__{} = json) do
    case value(json) do
      :invalid -> new(json)
      value -> new(value, pretty: true)
    end
  end

  @impl Datatype
  def canonical?(%Literal{literal: literal}), do: canonical?(literal)

  def canonical?(%__MODULE__{} = json) do
    if valid?(json) do
      json.lexical == json |> canonical() |> lexical()
    end
  end

  @impl Datatype
  def valid?(%Literal{literal: %__MODULE__{} = literal}), do: valid?(literal)
  def valid?(%__MODULE__{} = json), do: value(json) != :invalid
  def valid?(_), do: false

  @impl Datatype
  def language(%Literal{literal: literal}), do: language(literal)
  def language(%__MODULE__{}), do: nil

  @impl Datatype
  def do_cast(_), do: nil

  @impl Datatype
  def do_equal_value_same_or_derived_datatypes?(%__MODULE__{} = left, %__MODULE__{} = right) do
    canonical(left).literal == canonical(right).literal
  end

  def do_equal_value_same_or_derived_datatypes?(_, _), do: nil

  @impl Datatype
  def do_compare(%__MODULE__{} = left, %__MODULE__{} = right) do
    case {value(left), value(right)} do
      {:invalid, _} ->
        nil

      {_, :invalid} ->
        nil

      {value, value} ->
        :eq

      {left_value, right_value} ->
        left_jcs = Jcs.encode(left_value)
        right_jcs = Jcs.encode(right_value)

        cond do
          left_jcs < right_jcs -> :lt
          left_jcs > right_jcs -> :gt
          true -> :eq
        end
    end
  end

  def do_compare(_, _), do: nil

  @impl Datatype
  def update(literal, fun, opts \\ [])
  def update(%Literal{literal: literal}, fun, opts), do: update(literal, fun, opts)

  def update(%__MODULE__{} = literal, fun, _opts) do
    literal
    |> value()
    |> fun.()
    |> new(as_value: true)
  end
end
