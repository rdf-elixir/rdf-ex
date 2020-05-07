defmodule RDF.XSD.Date do
  @moduledoc """
  `RDF.XSD.Datatype` for XSD date.

  Options:

  - `tz` ... it will also overwrite an eventually already present timezone in an input lexical ...
  """

  @type valid_value :: Date.t() | {Date.t(), String.t()}

  use RDF.XSD.Datatype.Primitive,
    name: "date",
    id: RDF.Utils.Bootstrapping.xsd_iri("date"),
    register: false # core datatypes don't need to be registered


  # TODO: Are GMT/UTC actually allowed? Maybe because it is supported by Elixir's Datetime ...
  @grammar ~r/\A(-?\d{4}-\d{2}-\d{2})((?:[\+\-]\d{2}:\d{2})|UTC|GMT|Z)?\Z/
  @tz_grammar ~r/\A((?:[\+\-]\d{2}:\d{2})|UTC|GMT|Z)\Z/

  @impl RDF.XSD.Datatype
  def lexical_mapping(lexical, opts) do
    case Regex.run(@grammar, lexical) do
      [_, date] -> do_lexical_mapping(date, opts)
      [_, date, tz] -> do_lexical_mapping(date, Keyword.put_new(opts, :tz, tz))
      _ -> @invalid_value
    end
  end

  defp do_lexical_mapping(value, opts) do
    case Date.from_iso8601(value) do
      {:ok, date} -> elixir_mapping(date, opts)
      _ -> @invalid_value
    end
    |> case do
      {{_, _} = value, _} -> value
      value -> value
    end
  end

  @impl RDF.XSD.Datatype
  @spec elixir_mapping(Date.t() | any, Keyword.t()) ::
          value | {value, RDF.XSD.Datatype.uncanonical_lexical()}
  def elixir_mapping(value, opts)

  # Special case for date and dateTime, for which 0 is not a valid year
  def elixir_mapping(%Date{year: 0}, _), do: @invalid_value

  def elixir_mapping(%Date{} = value, opts) do
    if tz = Keyword.get(opts, :tz) do
      if valid_timezone?(tz) do
        {{value, timezone_mapping(tz)}, nil}
      else
        @invalid_value
      end
    else
      value
    end
  end

  def elixir_mapping(_, _), do: @invalid_value

  defp valid_timezone?(string), do: Regex.match?(@tz_grammar, string)

  defp timezone_mapping("+00:00"), do: "Z"
  defp timezone_mapping(tz), do: tz

  @impl RDF.XSD.Datatype
  @spec canonical_mapping(valid_value) :: String.t()
  def canonical_mapping(value)
  def canonical_mapping(%Date{} = value), do: Date.to_iso8601(value)
  def canonical_mapping({%Date{} = value, "+00:00"}), do: canonical_mapping(value) <> "Z"
  def canonical_mapping({%Date{} = value, zone}), do: canonical_mapping(value) <> zone

  @impl RDF.XSD.Datatype
  @spec init_valid_lexical(valid_value, RDF.XSD.Datatype.uncanonical_lexical(), Keyword.t()) ::
          RDF.XSD.Datatype.uncanonical_lexical()
  def init_valid_lexical(value, lexical, opts)

  def init_valid_lexical({value, _}, nil, opts) do
    if tz = Keyword.get(opts, :tz) do
      canonical_mapping(value) <> tz
    else
      nil
    end
  end

  def init_valid_lexical(_, nil, _), do: nil

  def init_valid_lexical(_, lexical, opts) do
    if tz = Keyword.get(opts, :tz) do
      # When using the :tz option, we'll have to strip off the original timezone
      case Regex.run(@grammar, lexical) do
        [_, date] -> date
        [_, date, _] -> date
      end <> tz
    else
      lexical
    end
  end

  @impl RDF.XSD.Datatype
  @spec init_invalid_lexical(any, Keyword.t()) :: String.t()
  def init_invalid_lexical(value, opts)

  def init_invalid_lexical({date, tz}, opts) do
    if tz_opt = Keyword.get(opts, :tz) do
      to_string(date) <> tz_opt
    else
      to_string(date) <> to_string(tz)
    end
  end

  def init_invalid_lexical(value, _) when is_binary(value), do: value

  def init_invalid_lexical(value, opts) do
    if tz = Keyword.get(opts, :tz) do
      to_string(value) <> tz
    else
      to_string(value)
    end
  end

  @impl RDF.Literal.Datatype
  def do_cast(value)

  def do_cast(%RDF.XSD.DateTime{} = xsd_datetime) do
    case xsd_datetime.value do
      %NaiveDateTime{} = datetime ->
        datetime
        |> NaiveDateTime.to_date()
        |> new()

      %DateTime{} = datetime ->
        datetime
        |> DateTime.to_date()
        |> new(tz: RDF.XSD.DateTime.tz(xsd_datetime))
    end
  end

  def do_cast(%RDF.XSD.String{} = xsd_string), do: new(xsd_string.value)

  def do_cast(literal_or_value), do: super(literal_or_value)

  @impl RDF.Literal.Datatype
  def do_equal_value?(literal1, literal2)

  def do_equal_value?(
        %__MODULE__{value: nil, uncanonical_lexical: lexical1},
        %__MODULE__{value: nil, uncanonical_lexical: lexical2}
      ) do
    lexical1 == lexical2
  end

  def do_equal_value?(%__MODULE__{value: value1}, %__MODULE__{value: value2})
      when is_nil(value1) or is_nil(value2),
      do: false

  def do_equal_value?(%__MODULE__{value: value1}, %__MODULE__{value: value2}) do
    RDF.XSD.DateTime.equal_value?(
      comparison_normalization(value1),
      comparison_normalization(value2)
    )
  end

  def do_equal_value?(%__MODULE__{}, %RDF.XSD.DateTime{}), do: false
  def do_equal_value?(%RDF.XSD.DateTime{}, %__MODULE__{}), do: false

  def do_equal_value?(_, _), do: nil

  @impl RDF.Literal.Datatype
  def compare(left, right)
  def compare(left, %RDF.Literal{literal: right}), do: compare(left, right)
  def compare(%RDF.Literal{literal: left}, right), do: compare(left, right)

  def compare(
        %__MODULE__{value: value1},
        %__MODULE__{value: value2}
      )
      when is_nil(value1) or is_nil(value2),
      do: nil

  def compare(
        %__MODULE__{value: value1},
        %__MODULE__{value: value2}
      ) do
    RDF.XSD.DateTime.compare(
      comparison_normalization(value1),
      comparison_normalization(value2)
    )
  end

  # It seems quite strange that open-world test date-2 from the SPARQL 1.0 test suite
  #  allows for equality comparisons between dates and datetimes, but disallows
  #  ordering comparisons in the date-3 test. The following implementation would allow
  #  an ordering comparisons between date and datetimes.
  #
  #  def compare(
  #        %__MODULE__{value: date_value},
  #        %RDF.XSD.DateTime{} = datetime_literal
  #      ) do
  #    RDF.XSD.DateTime.compare(
  #      comparison_normalization(date_value),
  #      datetime_literal
  #    )
  #  end
  #
  #  def compare(
  #        %RDF.XSD.DateTime{} = datetime_literal,
  #        %__MODULE__{value: date_value}
  #      ) do
  #    RDF.XSD.DateTime.compare(
  #      datetime_literal,
  #      comparison_normalization(date_value)
  #    )
  #  end

  def compare(_, _), do: nil

  defp comparison_normalization({date, tz}) do
    (Date.to_iso8601(date) <> "T00:00:00" <> tz)
    |> RDF.XSD.DateTime.new()
  end

  defp comparison_normalization(%Date{} = date) do
    (Date.to_iso8601(date) <> "T00:00:00")
    |> RDF.XSD.DateTime.new()
  end

  defp comparison_normalization(_), do: nil
end
