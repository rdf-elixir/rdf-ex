defmodule RDF.Time do
  use RDF.Datatype, id: RDF.Datatype.NS.XSD.time

  @grammar ~r/\A(\d{2}:\d{2}:\d{2}(?:\.\d+)?)((?:[\+\-]\d{2}:\d{2})|UTC|GMT|Z)?\Z/
  @tz_grammar ~r/\A(?:([\+\-])(\d{2}):(\d{2}))\Z/


  def convert(%Time{} = value, %{tz: tz} = opts) do
    {convert(value, Map.delete(opts, :tz)), tz}
  end

  def convert(%Time{} = value, _opts) do
    value |> strip_microseconds
  end

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

  # microseconds are not part of the xsd:dateTime value space
  defp strip_microseconds(%{microsecond: ms} = date_time) when ms != {0, 0},
    do: %{date_time | microsecond: {0, 0}}
  defp strip_microseconds(date_time),
    do: date_time


  def canonical_lexical(%Time{} = value) do
    Time.to_iso8601(value)
  end

  def canonical_lexical({%Time{} = value, true}) do
    canonical_lexical(value) <> "Z"
  end

end
