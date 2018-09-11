defmodule RDF.DateTime do
  @moduledoc """
  `RDF.Datatype` for XSD dateTime.
  """

  use RDF.Datatype, id: RDF.Datatype.NS.XSD.dateTime

  import RDF.Literal.Guards


  def now() do
    new(DateTime.utc_now())
  end

  # Special case for date and dateTime, for which 0 is not a valid year
  def convert(%DateTime{year: 0} = value, opts), do: super(value, opts)
  def convert(%DateTime{} = value, _),           do: value

  # Special case for date and dateTime, for which 0 is not a valid year
  def convert(%NaiveDateTime{year: 0} = value, opts), do: super(value, opts)
  def convert(%NaiveDateTime{} = value, _),           do: value

  def convert(value, opts) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, date_time, _} -> convert(date_time, opts)

      {:error, :missing_offset} ->
        case NaiveDateTime.from_iso8601(value) do
          {:ok, date_time} -> convert(date_time, opts)
          _                -> super(value, opts)
        end

      {:error, :invalid_time} ->
        if String.contains?(value, "T24:00:00") do
          with [day, tz]  <- String.split(value, "T24:00:00", parts: 2),
               {:ok, day} <- Date.from_iso8601(day)
          do
            "#{day |> Date.add(1) |> Date.to_string()}T00:00:00#{tz}"
            |> convert(opts)
          else
            _ -> super(value, opts)
          end

        else
          super(value, opts)
        end
      _ ->
        super(value, opts)
    end
  end

  def convert(value, opts), do: super(value, opts)


  def canonical_lexical(%DateTime{} = value) do
    DateTime.to_iso8601(value)
  end

  def canonical_lexical(%NaiveDateTime{} = value) do
    NaiveDateTime.to_iso8601(value)
  end

  def tz(%Literal{value: %NaiveDateTime{}}), do: ""

  def tz(datetime_literal) do
    if valid?(datetime_literal) do
      datetime_literal
      |> lexical()
      |> RDF.DateTimeUtils.tz()
    end
  end

  @doc """
  Converts a datetime literal to a canonical string, preserving the zone information.
  """
  def canonical_lexical_with_zone(%Literal{datatype: datatype} = literal)
      when is_xsd_datetime(datatype) do
    case tz(literal) do
      nil ->
        nil

      zone when zone in ["Z", "", "+00:00"] ->
        canonical_lexical(literal.value)

      zone ->
        literal
        |> lexical()
        |> String.replace_trailing(zone, "Z")
        |> DateTime.from_iso8601()
        |> elem(1)
        |> canonical_lexical()
        |> String.replace_trailing("Z", zone)
    end
  end

end
