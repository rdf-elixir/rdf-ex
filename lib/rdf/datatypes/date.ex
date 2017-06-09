defmodule RDF.Date do
  @moduledoc """
  `RDF.Datatype` for XSD date.
  """

  use RDF.Datatype, id: RDF.Datatype.NS.XSD.date

  @grammar ~r/\A(-?\d{4}-\d{2}-\d{2})((?:[\+\-]\d{2}:\d{2})|UTC|GMT|Z)?\Z/


  def convert(%Date{} = value, %{tz: "+00:00"} = opts) do
    {convert(value, Map.delete(opts, :tz)), "Z"}
  end

  def convert(%Date{} = value, %{tz: tz} = opts) do
    {convert(value, Map.delete(opts, :tz)), tz}
  end

  # Special case for date and dateTime, for which 0 is not a valid year
  def convert(%Date{year: 0} = value, opts), do: super(value, opts)
  def convert(%Date{} = value, _),           do: value

  def convert(value, opts) when is_binary(value) do
    case Regex.run(@grammar, value) do
      [_, date] ->
        date
        |> do_convert
        |> convert(opts)
      [_, date, zone] ->
        date
        |> do_convert
        |> convert(Map.put(opts, :tz, zone))
      _ ->
        super(value, opts)
    end
  end

  def convert(value, opts), do: super(value, opts)

  defp do_convert(value) do
    case Date.from_iso8601(value) do
      {:ok, date} -> date
      _           -> nil
    end
  end


  def canonical_lexical(%Date{} = value) do
    Date.to_iso8601(value)
  end

  def canonical_lexical({%Date{} = value, zone}) do
    canonical_lexical(value) <> zone
  end

end
