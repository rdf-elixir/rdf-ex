defmodule RDF.XSD.DateTime do
  @moduledoc """
  `RDF.XSD.Datatype` for `xsd:dateTime`.

  See: <https://www.w3.org/TR/xmlschema11-2/#dateTime>
  """

  @type valid_value :: DateTime.t() | NaiveDateTime.t()

  use RDF.XSD.Datatype.Primitive,
    name: "dateTime",
    id: RDF.Utils.Bootstrapping.xsd_iri("dateTime")

  alias RDF.XSD

  def_applicable_facet XSD.Facets.ExplicitTimezone
  def_applicable_facet XSD.Facets.Pattern

  @doc false
  def explicit_timezone_conform?(:required, %DateTime{}, _), do: true
  def explicit_timezone_conform?(:required, _, _), do: false
  def explicit_timezone_conform?(:prohibited, %NaiveDateTime{}, _), do: true
  def explicit_timezone_conform?(:prohibited, _, _), do: false
  def explicit_timezone_conform?(:optional, _, _), do: true

  @doc false
  def pattern_conform?(pattern, _value, lexical) do
    XSD.Facets.Pattern.conform?(pattern, lexical)
  end

  @impl XSD.Datatype
  def lexical_mapping(lexical, opts)

  def lexical_mapping("+" <> _, _), do: @invalid_value

  def lexical_mapping(lexical, opts) do
    case DateTime.from_iso8601(lexical) do
      {:ok, datetime, _} ->
        elixir_mapping(datetime, opts)

      {:error, :missing_offset} ->
        case NaiveDateTime.from_iso8601(lexical) do
          {:ok, datetime} -> elixir_mapping(datetime, opts)
          _ -> @invalid_value
        end

      {:error, :invalid_format} ->
        if String.ends_with?(lexical, "-00:00") do
          lexical
          |> String.replace_trailing("-00:00", "Z")
          |> lexical_mapping(opts)
        else
          @invalid_value
        end

      {:error, :invalid_time} ->
        if String.contains?(lexical, "T24:00:00") do
          with [day, tz] <- String.split(lexical, "T24:00:00", parts: 2),
               {:ok, day} <- Date.from_iso8601(day) do
            lexical_mapping("#{day |> Date.add(1) |> Date.to_string()}T00:00:00#{tz}", opts)
          else
            _ -> @invalid_value
          end
        else
          @invalid_value
        end

      _ ->
        @invalid_value
    end
  end

  @impl XSD.Datatype
  @spec elixir_mapping(valid_value | any, Keyword.t()) :: value
  def elixir_mapping(value, _)
  # Special case for date and dateTime, for which 0 is not a valid year
  def elixir_mapping(%DateTime{year: 0}, _), do: @invalid_value
  def elixir_mapping(%DateTime{} = value, _), do: value
  # Special case for date and dateTime, for which 0 is not a valid year
  def elixir_mapping(%NaiveDateTime{year: 0}, _), do: @invalid_value
  def elixir_mapping(%NaiveDateTime{} = value, _), do: value
  def elixir_mapping(_, _), do: @invalid_value

  @impl XSD.Datatype
  @spec canonical_mapping(valid_value) :: String.t()
  def canonical_mapping(value)
  def canonical_mapping(%DateTime{} = value), do: DateTime.to_iso8601(value)
  def canonical_mapping(%NaiveDateTime{} = value), do: NaiveDateTime.to_iso8601(value)

  @impl RDF.Literal.Datatype
  def do_cast(value)

  def do_cast(%XSD.String{} = xsd_string), do: new(xsd_string.value)

  def do_cast(literal) do
    if XSD.Date.datatype?(literal) do
      case literal.value do
        {value, zone} ->
          (value |> XSD.Date.new() |> XSD.Date.canonical_lexical()) <> "T00:00:00" <> zone

        value ->
          (value |> XSD.Date.new() |> XSD.Date.canonical_lexical()) <> "T00:00:00"
      end
      |> new()
    else
      super(literal)
    end
  end

  @doc """
  Builds a `RDF.XSD.DateTime` literal for current moment in time.
  """
  @spec now() :: RDF.Literal.t()
  def now() do
    new(DateTime.utc_now())
  end

  @doc """
  Extracts the timezone string from a `RDF.XSD.DateTime` value.
  """
  @spec tz(RDF.Literal.t() | t()) :: String.t() | nil
  def tz(xsd_datetime)
  def tz(%RDF.Literal{literal: xsd_datetime}), do: tz(xsd_datetime)
  def tz(%__MODULE__{value: %NaiveDateTime{}}), do: ""

  def tz(date_time_literal) do
    if valid?(date_time_literal) do
      date_time_literal
      |> lexical()
      |> XSD.Utils.DateTime.tz()
    end
  end

  @doc """
  Converts a datetime literal to a canonical string, preserving the zone information.
  """
  @spec canonical_lexical_with_zone(RDF.Literal.t() | t()) :: String.t() | nil
  def canonical_lexical_with_zone(%RDF.Literal{literal: xsd_datetime}),
    do: canonical_lexical_with_zone(xsd_datetime)

  def canonical_lexical_with_zone(%__MODULE__{} = xsd_datetime) do
    case tz(xsd_datetime) do
      nil ->
        nil

      zone when zone in ["Z", "", "+00:00", "-00:00"] ->
        canonical_lexical(xsd_datetime)

      zone ->
        xsd_datetime
        |> lexical()
        |> String.replace_trailing(zone, "Z")
        |> DateTime.from_iso8601()
        |> elem(1)
        |> new()
        |> canonical_lexical()
        |> String.replace_trailing("Z", zone)
    end
  end

  @impl RDF.Literal.Datatype
  def do_equal_value_same_or_derived_datatypes?(
        %{value: %type{} = left_value},
        %{value: %type{} = right_value}
      ) do
    type.compare(left_value, right_value) == :eq
  end

  # This is another quirk for the open-world test date-2 from the SPARQL 1.0 test suite:
  # comparisons between one date with tz and another one without a tz are incomparable
  # when the unequal, but comparable and returning false when equal.
  # What's the reasoning behind this madness?
  def do_equal_value_same_or_derived_datatypes?(left_literal, right_literal) do
    case compare(left_literal, right_literal) do
      :lt -> false
      :gt -> false
      # This actually can't/shouldn't happen.
      :eq -> true
      _ -> nil
    end
  end

  @impl RDF.Literal.Datatype
  def do_equal_value_different_datatypes?(left, right) do
    if XSD.Date.datatype?(left) or XSD.Date.datatype?(right) do
      false
    else
      super(left, right)
    end
  end

  @impl RDF.Literal.Datatype
  def do_compare(left, right)

  def do_compare(%{value: %type{} = value1}, %{value: %type{} = value2}) do
    type.compare(value1, value2)
  end

  # It seems quite strange that open-world test date-2 from the SPARQL 1.0 test suite
  #  allows for equality comparisons between dates and datetimes, but disallows
  #  ordering comparisons in the date-3 test. The following implementation would allow
  #  an ordering comparisons between date and datetimes.
  #
  #  def do_compare(%__MODULE__{} = literal1, %XSD.Date{} = literal2) do
  #    XSD.Date.do_compare(literal1, literal2)
  #  end
  #
  #  def do_compare(%XSD.Date{} = literal1, %__MODULE__{} = literal2) do
  #    XSD.Date.do_compare(literal1, literal2)
  #  end

  def do_compare(%{value: %DateTime{}} = left, %{value: %NaiveDateTime{} = right_value}) do
    cond do
      do_compare(left, new(to_datetime(right_value, "+")).literal) == :lt -> :lt
      do_compare(left, new(to_datetime(right_value, "-")).literal) == :gt -> :gt
      true -> :indeterminate
    end
  end

  def do_compare(%{value: %NaiveDateTime{} = left}, %{value: %DateTime{}} = right_literal) do
    cond do
      do_compare(new(to_datetime(left, "-")).literal, right_literal) == :lt -> :lt
      do_compare(new(to_datetime(left, "+")).literal, right_literal) == :gt -> :gt
      true -> :indeterminate
    end
  end

  def do_compare(_, _), do: nil

  defp to_datetime(naive_datetime, offset) do
    (NaiveDateTime.to_iso8601(naive_datetime) <> offset <> "14:00")
    |> DateTime.from_iso8601()
    |> elem(1)
  end
end
