defmodule RDF.XSD.Date do
  @moduledoc """
  `RDF.XSD.Datatype` for `xsd:date`.

  Options:

  - `tz`: this allows to specify a timezone which is not supported by Elixir's `Date` struct; note,
    that it will also overwrite an eventually already present timezone in an input lexical

  See: <https://www.w3.org/TR/xmlschema11-2/#date>
  """

  @type valid_value :: Date.t() | {Date.t(), String.t()}

  use RDF.XSD.Datatype.Primitive,
    name: "date",
    id: RDF.Utils.Bootstrapping.xsd_iri("date")

  alias RDF.XSD

  def_applicable_facet XSD.Facets.ExplicitTimezone
  def_applicable_facet XSD.Facets.Pattern

  @doc false
  def explicit_timezone_conform?(:required, {_, _}, _), do: true
  def explicit_timezone_conform?(:required, _, _), do: false
  def explicit_timezone_conform?(:prohibited, {_, _}, _), do: false
  def explicit_timezone_conform?(:prohibited, _, _), do: true
  def explicit_timezone_conform?(:optional, _, _), do: true

  @doc false
  def pattern_conform?(pattern, _value, lexical) do
    XSD.Facets.Pattern.conform?(pattern, lexical)
  end

  # TODO: Are GMT/UTC actually allowed? Maybe because it is supported by Elixir's Datetime ...
  @grammar ~r/\A(-?\d{4}-\d{2}-\d{2})((?:[\+\-]\d{2}:\d{2})|UTC|GMT|Z)?\Z/
  @tz_grammar ~r/\A((?:[\+\-]\d{2}:\d{2})|UTC|GMT|Z)\Z/

  @impl XSD.Datatype
  def lexical_mapping(lexical, opts) do
    case RDF.Utils.Regex.run(@grammar, lexical) do
      [_, date] -> do_lexical_mapping(date, opts)
      [_, date, tz] -> do_lexical_mapping(date, Keyword.put_new(opts, :tz, tz))
      _ -> @invalid_value
    end
  end

  defp do_lexical_mapping(value, opts) do
    case Date.from_iso8601(value) do
      {:ok, date} -> elixir_mapping(date, opts)
      _ -> @invalid_value
    end
    |> case do
      {{_, _} = value, _} -> value
      value -> value
    end
  end

  @impl XSD.Datatype
  @spec elixir_mapping(Date.t() | valid_value | any, Keyword.t()) ::
          value | {value, XSD.Datatype.uncanonical_lexical()}
  def elixir_mapping(value, opts)

  # Special case for date and dateTime, for which 0 is not a valid year
  def elixir_mapping(%Date{year: 0}, _), do: @invalid_value
  def elixir_mapping({%Date{year: 0}, _}, _), do: @invalid_value

  def elixir_mapping(%Date{} = value, opts) do
    if tz = Keyword.get(opts, :tz) do
      elixir_mapping({value, tz}, opts)
    else
      value
    end
  end

  def elixir_mapping({%Date{} = value, tz}, _opts) when is_binary(tz) do
    if valid_timezone?(tz) do
      {{value, timezone_mapping(tz)}, nil}
    else
      @invalid_value
    end
  end

  def elixir_mapping(_, _), do: @invalid_value

  defp valid_timezone?(string), do: RDF.Utils.Regex.match?(@tz_grammar, string)

  defp timezone_mapping("+00:00"), do: "Z"
  defp timezone_mapping(tz), do: tz

  @impl XSD.Datatype
  @spec canonical_mapping(valid_value) :: String.t()
  def canonical_mapping(value)
  def canonical_mapping(%Date{} = value), do: Date.to_iso8601(value)
  def canonical_mapping({%Date{} = value, "+00:00"}), do: canonical_mapping(value) <> "Z"
  def canonical_mapping({%Date{} = value, zone}), do: canonical_mapping(value) <> zone

  @impl XSD.Datatype
  @spec init_valid_lexical(valid_value, XSD.Datatype.uncanonical_lexical(), Keyword.t()) ::
          XSD.Datatype.uncanonical_lexical()
  def init_valid_lexical(value, lexical, opts)

  def init_valid_lexical({value, _}, nil, opts) do
    if tz = Keyword.get(opts, :tz) do
      canonical_mapping(value) <> tz
    end
  end

  def init_valid_lexical(_, nil, _), do: nil

  def init_valid_lexical(_, lexical, opts) do
    if tz = Keyword.get(opts, :tz) do
      # When using the :tz option, we'll have to strip off the original timezone
      case RDF.Utils.Regex.run(@grammar, lexical) do
        [_, date] -> date
        [_, date, _] -> date
      end <> tz
    else
      lexical
    end
  end

  @impl XSD.Datatype
  @spec init_invalid_lexical(any, Keyword.t()) :: String.t()
  def init_invalid_lexical(value, opts)

  def init_invalid_lexical({date, tz}, opts) do
    if tz_opt = Keyword.get(opts, :tz) do
      to_string(date) <> tz_opt
    else
      to_string(date) <> to_string(tz)
    end
  end

  def init_invalid_lexical(value, _) when is_binary(value), do: value

  def init_invalid_lexical(value, opts) do
    if tz = Keyword.get(opts, :tz) do
      to_string(value) <> tz
    else
      to_string(value)
    end
  end

  @impl RDF.Literal.Datatype
  def do_cast(value)

  def do_cast(%XSD.String{} = xsd_string), do: new(xsd_string.value)

  def do_cast(literal) do
    if XSD.DateTime.datatype?(literal) do
      case literal.value do
        %NaiveDateTime{} = datetime ->
          datetime
          |> NaiveDateTime.to_date()
          |> new()

        %DateTime{} = datetime ->
          datetime
          |> DateTime.to_date()
          |> new(tz: XSD.DateTime.tz(literal))
      end
    else
      super(literal)
    end
  end

  @impl RDF.Literal.Datatype
  def do_equal_value_same_or_derived_datatypes?(left, right) do
    XSD.DateTime.equal_value?(
      comparison_normalization(left.value),
      comparison_normalization(right.value)
    )
  end

  @impl RDF.Literal.Datatype
  def do_equal_value_different_datatypes?(left, right) do
    if XSD.DateTime.datatype?(left) or XSD.DateTime.datatype?(right) do
      false
    else
      super(left, right)
    end
  end

  @impl RDF.Literal.Datatype
  def do_compare(%{value: value1}, %{value: value2}) do
    XSD.DateTime.compare(
      comparison_normalization(value1),
      comparison_normalization(value2)
    )
  end

  # It seems quite strange that open-world test date-2 from the SPARQL 1.0 test suite
  #  allows for equality comparisons between dates and datetimes, but disallows
  #  ordering comparisons in the date-3 test. The following implementation would allow
  #  an ordering comparisons between date and datetimes.
  #
  #  def do_compare(
  #        %__MODULE__{value: date_value},
  #        %XSD.DateTime{} = datetime_literal
  #      ) do
  #    XSD.DateTime.compare(
  #      comparison_normalization(date_value).literal,
  #      datetime_literal
  #    )
  #  end
  #
  #  def do_compare(
  #        %XSD.DateTime{} = datetime_literal,
  #        %__MODULE__{value: date_value}
  #      ) do
  #    XSD.DateTime.do_compare(
  #      datetime_literal,
  #      comparison_normalization(date_value).literal
  #    )
  #  end

  def do_compare(_, _), do: nil

  defp comparison_normalization({date, tz}) do
    (Date.to_iso8601(date) <> "T00:00:00" <> tz)
    |> XSD.DateTime.new()
  end

  defp comparison_normalization(%Date{} = date) do
    (Date.to_iso8601(date) <> "T00:00:00")
    |> XSD.DateTime.new()
  end

  defp comparison_normalization(_), do: nil
end
