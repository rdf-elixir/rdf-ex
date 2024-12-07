defmodule RDF.JSON do
  @moduledoc """
  `RDF.Literal.Datatype` for `rdf:JSON`.

  As specified in RDF 1.2, this datatype allows JSON content as literal values.
  The lexical forms must conform to [RFC 7493 (I-JSON)](https://www.rfc-editor.org/rfc/rfc7493).

  See: <https://www.w3.org/TR/rdf12-concepts/#section-json>

  > ### Note {: .warning}
  >
  > Most functions in this module require OTP 25 or later, since JSON canonicalization (JCS)
  > relies on it.
  """

  defstruct [:lexical]

  use RDF.Literal.Datatype,
    name: "JSON",
    id: RDF.Utils.Bootstrapping.rdf_iri("JSON")

  alias RDF.Literal.Datatype
  alias RDF.Literal

  @type lexical :: String.t()
  @type value :: String.t() | number | boolean | map | list | nil

  @type t :: %__MODULE__{lexical: lexical()}

  @doc """
  Creates a new `RDF.JSON` literal.

  When given a string it is interpreted as a JSON encoding by default, unless
  the `as_value` option is set to `true`.

  ## Options

  - `:as_value` - when `true`, strings are encoded as JSON strings instead of
    being interpreted as JSON
  - `:jason_encode` - when `true`, uses Jason for encoding (instead of JCS), which enables:
    - encoding of custom types implementing the `Jason.Encoder` protocol
    - passing of encoding options to `Jason.encode/2`
  - `:pretty` - when `true`, values are encoded in a more readable format (not canonical!)
  - `:canonicalize` - when `true`, the value is canonicalized according to JCS;
    cannot be combined with the `:pretty` option

  - `:jason_encode` - when `true`, uses `Jason.Encoder` instead of JCS encoding

  ## Examples

      iex> RDF.JSON.new(%{foo: 42})

      iex> RDF.JSON.new(~s({"foo": 42}))

      iex> RDF.JSON.new("not JSON") |> RDF.JSON.valid?()
      false

      iex> RDF.JSON.new("null") |> RDF.JSON.value()
      nil

      iex> RDF.JSON.new("null", as_value: true)  |> RDF.JSON.value()
      "null"

      iex> RDF.JSON.new(%{a: 1}, pretty: true)

      # assuming we have a Jason.Encoder protocol implementation of our CustomJSON struct
      iex> RDF.JSON.new(%CustomJSON{value: 42}, jason_encode: true, escape: :html_safe)
  """
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

  @doc """
  Like `new/2` but raises an `ArgumentError` when the value is invalid.

  ## Examples

      iex> RDF.JSON.new!(%{foo: 1})
      RDF.JSON.new(%{foo: 1})

      iex> RDF.JSON.new!("not JSON")
      ** (ArgumentError) "not JSON" is not a valid RDF.JSON
  """
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

  @doc """
  Returns the value of a JSON literal.

  When the given literal is invalid, `:invalid` is returned.

  ## Options

  All options are passed to `Jason.decode/2`.

  ## Examples

      iex> RDF.JSON.new(~s({"foo": 1})) |> RDF.JSON.value()
      %{"foo" => 1}

      iex> RDF.JSON.new(~s({"foo": 1})) |> RDF.JSON.value(keys: :atoms)
      %{foo: 1}
  """
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

  @doc """
  Returns the lexical value of a JSON literal.
  """
  @impl Datatype
  @spec lexical(Literal.t() | t()) :: String.t()
  def lexical(%Literal{literal: literal}), do: lexical(literal)
  def lexical(%__MODULE__{} = json), do: json.lexical

  @doc """
  Returns a JCS canonicalized version of a JSON literal.

  When the given literal is invalid, it is returned unchanged.
  """
  @impl Datatype
  @spec canonical(Literal.t() | t()) :: Literal.t()
  def canonical(%Literal{literal: literal}), do: canonical(literal)

  def canonical(%__MODULE__{} = json) do
    case value(json) do
      :invalid -> new(json)
      value -> from_value(value)
    end
  end

  @doc """
  Returns a prettified version of a JSON literal.

  When the given literal is invalid, it is returned unchanged.
  """
  @spec prettified(Literal.t() | t()) :: Literal.t()
  def prettified(%Literal{literal: literal}), do: prettified(literal)

  def prettified(%__MODULE__{} = json) do
    case value(json) do
      :invalid -> new(json)
      value -> new(value, pretty: true)
    end
  end

  @doc """
  Determines if the lexical form of a JSON literal is in the canonical form.
  """
  @impl Datatype
  @spec canonical?(Literal.t() | t()) :: boolean | nil
  def canonical?(%Literal{literal: literal}), do: canonical?(literal)

  def canonical?(%__MODULE__{} = json) do
    if valid?(json) do
      json.lexical == json |> canonical() |> lexical()
    end
  end

  @doc """
  Determines if a JSON literal is valid with respect to [RFC 7493 (I-JSON)](https://www.rfc-editor.org/rfc/rfc7493).
  """
  @spec valid?(Literal.t() | t()) :: boolean | nil
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
