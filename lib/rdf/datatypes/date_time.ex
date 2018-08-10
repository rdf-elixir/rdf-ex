defmodule RDF.DateTime do
  @moduledoc """
  `RDF.Datatype` for XSD dateTime.
  """

  use RDF.Datatype, id: RDF.Datatype.NS.XSD.dateTime


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

  def tz(datetime_literal) do
    if valid?(datetime_literal) do
      lexical = lexical(datetime_literal)
      case Regex.run(~r/([+-])(\d\d:\d\d)/, lexical) do
        [_, sign, zone] ->
          sign <> zone
        _ ->
          if String.ends_with?(lexical, "Z") do
            "Z"
          else
            ""
          end
      end
    end
  end

end
