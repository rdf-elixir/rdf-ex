defmodule RDF.DateTime do
  @moduledoc """
  `RDF.Datatype` for XSD dateTime.
  """

  use RDF.Datatype, id: RDF.Datatype.NS.XSD.dateTime

  import RDF.Literal.Guards

  @xsd_date RDF.Datatype.NS.XSD.date


  @impl RDF.Datatype
  def convert(value, opts)

  # Special case for date and dateTime, for which 0 is not a valid year
  def convert(%DateTime{year: 0} = value, opts), do: super(value, opts)
  def convert(%DateTime{} = value, _),           do: value

  # Special case for date and dateTime, for which 0 is not a valid year
  def convert(%NaiveDateTime{year: 0} = value, opts), do: super(value, opts)
  def convert(%NaiveDateTime{} = value, _),           do: value

  def convert(value, opts) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _} -> convert(datetime, opts)

      {:error, :missing_offset} ->
        case NaiveDateTime.from_iso8601(value) do
          {:ok, datetime} -> convert(datetime, opts)
          _               -> super(value, opts)
        end

      {:error, :invalid_format} ->
        if String.ends_with?(value, "-00:00") do
          String.replace_trailing(value, "-00:00", "Z")
          |> convert(opts)
        else
          super(value, opts)
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


  @impl RDF.Datatype
  def canonical_lexical(value)

  def canonical_lexical(%DateTime{} = value) do
    DateTime.to_iso8601(value)
  end

  def canonical_lexical(%NaiveDateTime{} = value) do
    NaiveDateTime.to_iso8601(value)
  end


  @impl RDF.Datatype
  def cast(literal)

  def cast(%RDF.Literal{datatype: datatype} = literal) do
    cond do
      not RDF.Literal.valid?(literal) ->
        nil

      is_xsd_datetime(datatype) ->
        literal

      is_xsd_date(datatype) ->
        case literal.value do
          {value, zone} ->
            RDF.Date.canonical_lexical(value) <> "T00:00:00" <> zone
          value ->
            RDF.Date.canonical_lexical(value) <> "T00:00:00"
        end
        |> new()

      is_xsd_string(datatype) ->
        literal.value
        |> new()
        |> validate_cast()

      true ->
        nil
    end
  end

  def cast(_), do: nil


  @doc """
  Builds a `RDF.DateTime` literal for current moment in time.
  """
  def now() do
    new(DateTime.utc_now())
  end


  @doc """
  Extracts the timezone string from a `RDF.DateTime` literal.
  """
  def tz(literal)

  def tz(%Literal{value: %NaiveDateTime{}}), do: ""

  def tz(date_time_literal) do
    if valid?(date_time_literal) do
      date_time_literal
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

      zone when zone in ["Z", "", "+00:00", "-00:00"] ->
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


  @impl RDF.Datatype
  def equal_value?(literal1, literal2)

  def equal_value?(%Literal{datatype: @id, value: %type{} = value1},
                   %Literal{datatype: @id, value: %type{} = value2})
    do
    type.compare(value1, value2) == :eq
  end

  def equal_value?(%Literal{datatype: @id, value: nil, uncanonical_lexical: lexical1},
                   %Literal{datatype: @id, value: nil, uncanonical_lexical: lexical2}) do
    lexical1 == lexical2
  end

  def equal_value?(%Literal{datatype: @id} = literal1, %Literal{datatype: @id} = literal2) do
    case compare(literal1, literal2) do
      :lt -> false
      :gt -> false
      :eq -> true  # This actually can't/shouldn't happen.
      _   -> nil
    end
  end

  def equal_value?(%Literal{datatype: @id}, %Literal{datatype: @xsd_date}), do: false
  def equal_value?(%Literal{datatype: @xsd_date}, %Literal{datatype: @id}), do: false

  def equal_value?(%RDF.Literal{} = left, right) when not is_nil(right) do
    unless RDF.Term.term?(right) do
      equal_value?(left, RDF.Term.coerce(right))
    end
  end

  def equal_value?(_, _), do: nil


  @impl RDF.Datatype
  def compare(left, right)

  def compare(%Literal{datatype: @id, value: %type{} = value1},
              %Literal{datatype: @id, value: %type{} = value2}) do
    type.compare(value1, value2)
  end

# It seems quite strange that open-world test date-2 from the SPARQL 1.0 test suite
#  allows for equality comparisons between dates and datetimes, but disallows
#  ordering comparisons in the date-3 test. The following implementation would allow
#  an ordering comparisons between date and datetimes.
#
#  def compare(%Literal{datatype: @id} = literal1,
#              %Literal{datatype: @xsd_date} = literal2) do
#    RDF.Date.compare(literal1, literal2)
#  end
#
#  def compare(%Literal{datatype: @xsd_date} = literal1,
#              %Literal{datatype: @id} = literal2) do
#    RDF.Date.compare(literal1, literal2)
#  end

  def compare(%Literal{datatype: @id, value: %DateTime{}} = literal1,
              %Literal{datatype: @id, value: %NaiveDateTime{} = value2}) do
    cond do
      compare(literal1, new(to_datetime(value2, "+"))) == :lt -> :lt
      compare(literal1, new(to_datetime(value2, "-"))) == :gt -> :gt
      true                                                    -> :indeterminate
    end
  end

  def compare(%Literal{datatype: @id, value: %NaiveDateTime{} = value1},
              %Literal{datatype: @id, value: %DateTime{}} = literal2) do
    cond do
      compare(new(to_datetime(value1, "-")), literal2) == :lt -> :lt
      compare(new(to_datetime(value1, "+")), literal2) == :gt -> :gt
      true                                                    -> :indeterminate
    end
  end

  def compare(_, _), do: nil


  defp to_datetime(naive_datetime, offset) do
    (NaiveDateTime.to_iso8601(naive_datetime) <> offset <> "14:00")
    |> DateTime.from_iso8601()
    |> elem(1)
  end
  
end
