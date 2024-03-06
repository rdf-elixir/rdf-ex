defmodule RDF.XSD.Time do
  @moduledoc """
  `RDF.XSD.Datatype` for `xsd:time`.

  Options:

  - `tz`: this allows to specify a timezone which is not supported by Elixir's `Time` struct; note,
    that it will also overwrite an eventually already present timezone in an input lexical

  See: <https://www.w3.org/TR/xmlschema11-2/#time>
  """

  @type valid_value :: Time.t() | {Time.t(), true}

  use RDF.XSD.Datatype.Primitive,
    name: "time",
    id: RDF.Utils.Bootstrapping.xsd_iri("time")

  alias RDF.XSD

  # TODO: Are GMT/UTC actually allowed? Maybe because it is supported by Elixir's Datetime ...
  @grammar ~r/\A(\d{2}:\d{2}:\d{2}(?:\.\d+)?)((?:[\+\-]\d{2}:\d{2})|UTC|GMT|Z)?\Z/
  @tz_number_grammar ~r/\A(?:([\+\-])(\d{2}):(\d{2}))\Z/

  def_applicable_facet XSD.Facets.ExplicitTimezone
  def_applicable_facet XSD.Facets.Pattern

  @doc false
  def explicit_timezone_conform?(:required, {_, true}, _), do: true
  def explicit_timezone_conform?(:required, _, _), do: false
  def explicit_timezone_conform?(:prohibited, {_, true}, _), do: false
  def explicit_timezone_conform?(:prohibited, _, _), do: true
  def explicit_timezone_conform?(:optional, _, _), do: true

  @doc false
  def pattern_conform?(pattern, _value, lexical) do
    XSD.Facets.Pattern.conform?(pattern, lexical)
  end

  @impl XSD.Datatype
  def lexical_mapping(lexical, opts) do
    case RDF.Utils.Regex.run(@grammar, lexical) do
      [_, time] -> do_lexical_mapping(time, nil, opts)
      [_, time, tz] -> do_lexical_mapping(time, tz, opts)
      _ -> @invalid_value
    end
  end

  defp do_lexical_mapping(value, tz, opts) do
    do_lexical_mapping(value, Keyword.get(opts, :tz, tz))
  end

  defp do_lexical_mapping(value, tz) do
    case Time.from_iso8601(value) do
      {:ok, time} -> time_value(time, tz)
      _ -> @invalid_value
    end
  end

  @impl XSD.Datatype
  @spec elixir_mapping(valid_value | any, Keyword.t()) ::
          value | {value, XSD.Datatype.uncanonical_lexical()}
  def elixir_mapping(value, opts)

  def elixir_mapping(%Time{} = value, opts) do
    if tz = Keyword.get(opts, :tz) do
      elixir_mapping({value, tz}, opts)
    else
      value
    end
  end

  def elixir_mapping({%Time{} = time, tz}, _opts) do
    case time_value(time, tz) do
      @invalid_value -> @invalid_value
      time_with_tz -> {time_with_tz, Time.to_iso8601(time) <> if(tz == true, do: "Z", else: tz)}
    end
  end

  def elixir_mapping(_, _), do: @invalid_value

  defp time_value(time, nil), do: time
  defp time_value(time, false), do: time
  defp time_value(time, true), do: {time, true}

  defp time_value(time, zone) when is_binary(zone) do
    case with_offset(time, zone) do
      @invalid_value -> @invalid_value
      time -> {time, true}
    end
  end

  defp time_value(_, _), do: @invalid_value

  defp with_offset(time, zone) when zone in ~W[Z UTC GMT], do: time

  defp with_offset(time, offset) do
    case RDF.Utils.Regex.run(@tz_number_grammar, offset) do
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

  @impl XSD.Datatype
  @spec canonical_mapping(valid_value) :: String.t()
  def canonical_mapping(value)
  def canonical_mapping(%Time{} = value), do: Time.to_iso8601(value)
  def canonical_mapping({%Time{} = value, true}), do: canonical_mapping(value) <> "Z"

  @impl XSD.Datatype
  @spec init_valid_lexical(valid_value, XSD.Datatype.uncanonical_lexical(), Keyword.t()) ::
          XSD.Datatype.uncanonical_lexical()
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
      case RDF.Utils.Regex.run(@grammar, lexical) do
        [_, time] -> time
        [_, time, _] -> time
      end <> tz
    else
      lexical
    end
  end

  @impl XSD.Datatype
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

  def do_cast(%XSD.String{} = xsd_string), do: new(xsd_string.value)

  def do_cast(literal) do
    if XSD.DateTime.datatype?(literal) do
      case literal.value do
        %NaiveDateTime{} = datetime ->
          datetime
          |> NaiveDateTime.to_time()
          |> new()

        %DateTime{} ->
          [_date, time_with_zone] =
            literal
            |> XSD.DateTime.canonical_lexical_with_zone()
            |> String.split("T", parts: 2)

          new(time_with_zone)
      end
    else
      super(literal)
    end
  end

  @impl RDF.Literal.Datatype
  def do_equal_value_same_or_derived_datatypes?(left, right)

  def do_equal_value_same_or_derived_datatypes?(%{value: %{}}, %{value: tz_tuple})
      when is_tuple(tz_tuple),
      do: nil

  def do_equal_value_same_or_derived_datatypes?(%{value: tz_tuple}, %{value: %{}})
      when is_tuple(tz_tuple),
      do: nil

  def do_equal_value_same_or_derived_datatypes?(left, right), do: super(left, right)

  @doc """
  Extracts the timezone string from a `RDF.XSD.Time` value.
  """
  def tz(time_literal) do
    if valid?(time_literal) do
      time_literal
      |> lexical()
      |> XSD.Utils.DateTime.tz()
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
