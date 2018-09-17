defmodule RDF.Date do
  @moduledoc """
  `RDF.Datatype` for XSD date.
  """

  use RDF.Datatype, id: RDF.Datatype.NS.XSD.date

  import RDF.Literal.Guards

  @grammar ~r/\A(-?\d{4}-\d{2}-\d{2})((?:[\+\-]\d{2}:\d{2})|UTC|GMT|Z)?\Z/


  @impl RDF.Datatype
  def convert(value, opts)

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


  @impl RDF.Datatype
  def canonical_lexical(value)

  def canonical_lexical(%Date{} = value) do
    Date.to_iso8601(value)
  end

  def canonical_lexical({%Date{} = value, zone}) do
    canonical_lexical(value) <> zone
  end


  @impl RDF.Datatype
  def cast(literal)

  def cast(%RDF.Literal{datatype: datatype} = literal) do
    cond do
      not RDF.Literal.valid?(literal) ->
        nil

      is_xsd_date(datatype) ->
        literal

      is_xsd_datetime(datatype) ->
        case literal.value do
          %NaiveDateTime{} = datetime ->
            datetime
            |> NaiveDateTime.to_date()
            |> new()

          %DateTime{} = datetime ->
            datetime
            |> DateTime.to_date()
            |> new(%{tz: RDF.DateTime.tz(literal)})
        end

      is_xsd_string(datatype) ->
        literal.value
        |> new()

      true ->
        nil
    end
  end

  def cast(_), do: nil

end
