defmodule RDF.Date do
  @moduledoc """
  `RDF.Datatype` for XSD date.
  """

  use RDF.Datatype, id: RDF.Datatype.NS.XSD.date

  import RDF.Literal.Guards

  @grammar ~r/\A(-?\d{4}-\d{2}-\d{2})((?:[\+\-]\d{2}:\d{2})|UTC|GMT|Z)?\Z/
  @xsd_datetime RDF.Datatype.NS.XSD.dateTime


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


  @impl RDF.Datatype
  def equal_value?(literal1, literal2)

  def equal_value?(%Literal{datatype: @id, value: nil, uncanonical_lexical: lexical1},
                   %Literal{datatype: @id, value: nil, uncanonical_lexical: lexical2}) do
    lexical1 == lexical2
  end

  def equal_value?(%Literal{datatype: @id, value: value1},
                   %Literal{datatype: @id, value: value2})
      when is_nil(value1) or is_nil(value2), do: false

  def equal_value?(%Literal{datatype: @id, value: value1},
                   %Literal{datatype: @id, value: value2}) do
    RDF.DateTime.equal_value?(
      comparison_normalization(value1),
      comparison_normalization(value2)
    )
  end

  def equal_value?(%Literal{datatype: @id}, %Literal{datatype: @xsd_datetime}), do: false
  def equal_value?(%Literal{datatype: @xsd_datetime}, %Literal{datatype: @id}), do: false

  def equal_value?(_, _), do: nil


  @impl RDF.Datatype
  def compare(left, right)

  def compare(%Literal{datatype: @id, value: value1},
              %Literal{datatype: @id, value: value2})
      when is_nil(value1) or is_nil(value2), do: nil

  def compare(%Literal{datatype: @id, value: value1},
              %Literal{datatype: @id, value: value2}) do
    RDF.DateTime.compare(
      comparison_normalization(value1),
      comparison_normalization(value2)
    )
  end

# It seems quite strange that open-world test date-2 from the SPARQL 1.0 test suite
#  allows for equality comparisons between dates and datetimes, but disallows
#  ordering comparisons in the date-3 test. The following implementation would allow
#  an ordering comparisons between date and datetimes.
#
#  def compare(%Literal{datatype: @id, value: date_value},
#              %Literal{datatype: @xsd_datetime} = datetime_literal) do
#    RDF.DateTime.compare(
#      comparison_normalization(date_value),
#      datetime_literal
#    )
#  end
#
#  def compare(%Literal{datatype: @xsd_datetime} = datetime_literal,
#              %Literal{datatype: @id, value: date_value}) do
#    RDF.DateTime.compare(
#      datetime_literal,
#      comparison_normalization(date_value)
#    )
#  end

  def compare(_, _), do: nil


  defp comparison_normalization({date, tz}) do
    (Date.to_iso8601(date) <> "T00:00:00" <> tz)
    |> RDF.DateTime.new()
  end

  defp comparison_normalization(%Date{} = date) do
    (Date.to_iso8601(date) <> "T00:00:00")
    |> RDF.DateTime.new()
  end

  defp comparison_normalization(_), do: nil

end
