defmodule RDF.DateTime do
  @moduledoc """
  `RDF.Datatype` for XSD dateTime.
  """

  use RDF.Datatype, id: RDF.Datatype.NS.XSD.dateTime


  # Special case for date and dateTime, for which 0 is not a valid year
  def convert(%DateTime{year: 0} = value, opts), do: super(value, opts)
  def convert(%DateTime{} = value, _),           do: value |> strip_microseconds

  # Special case for date and dateTime, for which 0 is not a valid year
  def convert(%NaiveDateTime{year: 0} = value, opts), do: super(value, opts)
  def convert(%NaiveDateTime{} = value, _),           do: value |> strip_microseconds

  def convert(value, opts) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, date_time, _} -> convert(date_time, opts)

      {:error, :missing_offset} ->
        case NaiveDateTime.from_iso8601(value) do
          {:ok, date_time} -> convert(date_time, opts)
          _                -> super(value, opts)
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


  # microseconds are not part of the xsd:dateTime value space
  defp strip_microseconds(%{microsecond: ms} = date_time) when ms != {0, 0},
    do: %{date_time | microsecond: {0, 0}}
  defp strip_microseconds(date_time),
    do: date_time

end
