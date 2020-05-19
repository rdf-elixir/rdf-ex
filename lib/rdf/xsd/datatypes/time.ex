defmodule RDF.XSD.Time do
  @moduledoc """
  `RDF.XSD.Datatype` for XSD times.
  """

  @type valid_value :: Time.t() | {Time.t(), true}

  use RDF.XSD.Datatype.Primitive,
    name: "time",
    id: RDF.Utils.Bootstrapping.xsd_iri("time")

  # TODO: Are GMT/UTC actually allowed? Maybe because it is supported by Elixir's Datetime ...
  @grammar ~r/\A(\d{2}:\d{2}:\d{2}(?:\.\d+)?)((?:[\+\-]\d{2}:\d{2})|UTC|GMT|Z)?\Z/
  @tz_number_grammar ~r/\A(?:([\+\-])(\d{2}):(\d{2}))\Z/

  @impl RDF.XSD.Datatype
  def lexical_mapping(lexical, opts) do
    case Regex.run(@grammar, lexical) do
      [_, time] ->
        do_lexical_mapping(time, opts)

      [_, time, tz] ->
        do_lexical_mapping(
          time,
          opts |> Keyword.put_new(:tz, tz) |> Keyword.put_new(:lexical_present, true)
        )

      _ ->
        @invalid_value
    end
  end

  defp do_lexical_mapping(value, opts) do
    case Time.from_iso8601(value) do
      {:ok, time} -> elixir_mapping(time, opts)
      _ -> @invalid_value
    end
    |> case do
      {{_, true} = value, _} -> value
      value -> value
    end
  end

  @impl RDF.XSD.Datatype
  @spec elixir_mapping(valid_value | any, Keyword.t()) ::
          value | {value, RDF.XSD.Datatype.uncanonical_lexical()}
  def elixir_mapping(value, opts)

  def elixir_mapping(%Time{} = value, opts) do
    if tz = Keyword.get(opts, :tz) do
      case with_offset(value, tz) do
        @invalid_value ->
          @invalid_value

        time ->
          {{time, true}, unless(Keyword.get(opts, :lexical_present), do: Time.to_iso8601(value))}
      end
    else
      value
    end
  end

  def elixir_mapping(_, _), do: @invalid_value

  defp with_offset(time, zone) when zone in ~W[Z UTC GMT], do: time

  defp with_offset(time, offset) do
    case Regex.run(@tz_number_grammar, offset) do
      [_, "-", hour, minute] ->
        {hour, minute} = {String.to_integer(hour), String.to_integer(minute)}
        minute = time.minute + minute
        {rem(time.hour + hour + div(minute, 60), 24), rem(minute, 60)}

      [_, "+", hour, minute] ->
        {hour, minute} = {String.to_integer(hour), String.to_integer(minute)}

        if (minute = time.minute - minute) < 0 do
          {rem(24 + time.hour - hour - 1, 24), minute + 60}
        else
          {rem(24 + time.hour - hour - div(minute, 60), 24), rem(minute, 60)}
        end

      nil ->
        @invalid_value
    end
    |> case do
      {hour, minute} -> %Time{time | hour: hour, minute: minute}
      @invalid_value -> @invalid_value
    end
  end

  @impl RDF.XSD.Datatype
  @spec canonical_mapping(valid_value) :: String.t()
  def canonical_mapping(value)
  def canonical_mapping(%Time{} = value), do: Time.to_iso8601(value)
  def canonical_mapping({%Time{} = value, true}), do: canonical_mapping(value) <> "Z"

  @impl RDF.XSD.Datatype
  @spec init_valid_lexical(valid_value, RDF.XSD.Datatype.uncanonical_lexical(), Keyword.t()) ::
          RDF.XSD.Datatype.uncanonical_lexical()
  def init_valid_lexical(value, lexical, opts)

  def init_valid_lexical({value, _}, nil, opts) do
    if tz = Keyword.get(opts, :tz) do
      canonical_mapping(value) <> tz
    end
  end

  def init_valid_lexical(_, nil, _), do: nil

  def init_valid_lexical(_, lexical, opts) do
    if tz = Keyword.get(opts, :tz) do
      # When using the :tz option, we'll have to strip off the original timezone
      case Regex.run(@grammar, lexical) do
        [_, time] -> time
        [_, time, _] -> time
      end <> tz
    else
      lexical
    end
  end

  @impl RDF.XSD.Datatype
  @spec init_invalid_lexical(any, Keyword.t()) :: String.t()
  def init_invalid_lexical(value, opts)

  def init_invalid_lexical({time, tz}, opts) do
    if tz_opt = Keyword.get(opts, :tz) do
      to_string(time) <> tz_opt
    else
      to_string(time) <> to_string(tz)
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
        |> NaiveDateTime.to_time()
        |> new()

      %DateTime{} ->
        [_date, time_with_zone] =
          xsd_datetime
          |> RDF.XSD.DateTime.canonical_lexical_with_zone()
          |> String.split("T", parts: 2)

        new(time_with_zone)
    end
  end

  def do_cast(%RDF.XSD.String{} = xsd_string), do: new(xsd_string.value)

  def do_cast(literal_or_value), do: super(literal_or_value)

  @impl RDF.Literal.Datatype
  def do_equal_value?(literal1, literal2)

  def do_equal_value?(%__MODULE__{value: %_{}}, %__MODULE__{value: tz_tuple})
    when is_tuple(tz_tuple),
    do: nil

  def do_equal_value?(%__MODULE__{value: tz_tuple}, %__MODULE__{value: %_{}})
    when is_tuple(tz_tuple),
    do: nil

  def do_equal_value?(left, right), do: super(left, right)

  @doc """
  Extracts the timezone string from a `RDF.XSD.Time` value.
  """
  def tz(time_literal) do
    if valid?(time_literal) do
      time_literal
      |> lexical()
      |> RDF.XSD.Utils.DateTime.tz()
    end
  end

  @doc """
  Converts a time literal to a canonical string, preserving the zone information.
  """
  @spec canonical_lexical_with_zone(RDF.Literal.t() | t()) :: String.t() | nil
  def canonical_lexical_with_zone(%RDF.Literal{literal: xsd_time}),
      do: canonical_lexical_with_zone(xsd_time)
  def canonical_lexical_with_zone(%__MODULE__{} = xsd_time) do
    case tz(xsd_time) do
      nil ->
        nil

      zone when zone in ["Z", "", "+00:00"] ->
        canonical_lexical(xsd_time)

      zone ->
        xsd_time
        |> lexical()
        |> String.replace_trailing(zone, "")
        |> Time.from_iso8601!()
        |> new()
        |> canonical_lexical()
        |> Kernel.<>(zone)
    end
  end
end