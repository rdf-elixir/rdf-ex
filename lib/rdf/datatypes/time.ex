defmodule RDF.Time do
  @moduledoc """
  `RDF.Datatype` for XSD time.
  """

  use RDF.Datatype, id: RDF.Datatype.NS.XSD.time

  import RDF.Literal.Guards

  @grammar ~r/\A(\d{2}:\d{2}:\d{2}(?:\.\d+)?)((?:[\+\-]\d{2}:\d{2})|UTC|GMT|Z)?\Z/
  @tz_grammar ~r/\A(?:([\+\-])(\d{2}):(\d{2}))\Z/


  @impl RDF.Datatype
  def convert(value, opts)

  def convert(%Time{} = value, %{tz: tz} = opts) do
    {convert(value, Map.delete(opts, :tz)), tz}
  end

  def convert(%Time{} = value, _opts), do: value

  def convert(value, opts) when is_binary(value) do
    case Regex.run(@grammar, value) do
      [_, time] ->
        time
        |> do_convert
        |> convert(opts)
      [_, time, zone] ->
        time
        |> do_convert
        |> with_offset(zone)
        |> convert(Map.put(opts, :tz, true))
      _ ->
        super(value, opts)
    end
  end

  def convert(value, opts), do: super(value, opts)

  defp do_convert(value) do
    case Time.from_iso8601(value) do
      {:ok, time} -> time
      _           -> nil
    end
  end

  defp with_offset(time, zone) when zone in ~W[Z UTC GMT], do: time
  defp with_offset(time, offset) do
    {hour, minute} =
      case Regex.run(@tz_grammar, offset) do
        [_, "-", hour, minute] ->
          {hour, minute} = {String.to_integer(hour), String.to_integer(minute)}
          minute = time.minute + minute
          {rem(time.hour + hour + div(minute, 60), 24), rem(minute, 60)}
        [_, "+", hour, minute] ->
          {hour, minute} = {String.to_integer(hour), String.to_integer(minute)}
          if (minute = time.minute - minute) < 0 do
            {rem(24 + time.hour - hour - 1, 24), minute + 60}
          else
            {time.hour - hour - div(minute, 60), rem(minute, 60)}
          end
      end
    %Time{time | hour: hour, minute: minute}
  end


  @impl RDF.Datatype
  def canonical_lexical(value)

  def canonical_lexical(%Time{} = value) do
    Time.to_iso8601(value)
  end

  def canonical_lexical({%Time{} = value, true}) do
    canonical_lexical(value) <> "Z"
  end


  @impl RDF.Datatype
  def cast(literal)

  def cast(%RDF.Literal{datatype: datatype} = literal) do
    cond do
      not RDF.Literal.valid?(literal) ->
        nil

      is_xsd_time(datatype) ->
        literal

      is_xsd_datetime(datatype) ->
        case literal.value do
          %NaiveDateTime{} = datetime ->
            datetime
            |> NaiveDateTime.to_time()
            |> new()

          %DateTime{} ->
            [_date, time_with_zone] =
              literal
              |> RDF.DateTime.canonical_lexical_with_zone()
              |> String.split("T", parts: 2)
            new(time_with_zone)
        end

      is_xsd_string(datatype) ->
        literal.value
        |> new()

      true ->
        nil
    end
  end

  def cast(_), do: nil


  @doc """
  Extracts the timezone string from a `RDF.Time` literal.
  """
  def tz(time_literal) do
    if valid?(time_literal) do
      time_literal
      |> lexical()
      |> RDF.DateTimeUtils.tz()
    end
  end


  @doc """
  Converts a time literal to a canonical string, preserving the zone information.
  """
  def canonical_lexical_with_zone(%Literal{datatype: datatype} = literal)
      when is_xsd_time(datatype) do
    case tz(literal) do
      nil ->
        nil

      zone when zone in ["Z", "", "+00:00"] ->
        canonical_lexical(literal.value)

      zone ->
        literal
        |> lexical()
        |> String.replace_trailing(zone, "")
        |> Time.from_iso8601!()
        |> canonical_lexical()
        |> Kernel.<>(zone)
    end
  end

end
