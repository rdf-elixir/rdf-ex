defmodule RDF.EqualityTest do
  use RDF.Test.Case

  alias RDF.NS.XSD
  alias Decimal, as: D

  describe "RDF.IRI" do
    @term_equal_iris [
      {RDF.iri("http://example.com/"), RDF.iri("http://example.com/")},
    ]
    @term_unequal_iris [
      {RDF.iri("http://example.com/foo"), RDF.iri("http://example.com/bar")},
    ]
    @value_equal_iris [
      {RDF.iri("http://example.com/"),
       RDF.literal("http://example.com/", datatype: XSD.anyURI)},

      {RDF.literal("http://example.com/", datatype: XSD.anyURI),
       RDF.iri("http://example.com/")},

      {RDF.literal("http://example.com/", datatype: XSD.anyURI),
       RDF.literal("http://example.com/", datatype: XSD.anyURI)},
    ]
    @value_unequal_iris [
      {RDF.iri("http://example.com/foo"),
       RDF.literal("http://example.com/bar", datatype: XSD.anyURI)},
    ]
    @incomparable_iris [
      {RDF.iri("http://example.com/"), RDF.string("http://example.com/")},
    ]

    test "term equality",    do: assert_term_equal    @term_equal_iris
    test "term inequality",  do: assert_term_unequal  @term_unequal_iris
    test "value equality",   do: assert_value_equal   @value_equal_iris
    test "value inequality", do: assert_value_unequal @value_unequal_iris
    test "incomparability",  do: assert_incomparable  @incomparable_iris
  end

  describe "RDF.BlankNode" do
    @term_equal_bnodes [
      {RDF.bnode("foo"), RDF.bnode("foo")},
    ]
    @term_unequal_bnodes [
      {RDF.bnode("foo"), RDF.bnode("bar")},
    ]
    @value_equal_bnodes [
    ]
    @value_unequal_bnodes [
    ]
    @incomparable_bnodes [
      {RDF.bnode("foo"),  RDF.string("foo")},
      {RDF.string("foo"), RDF.bnode("foo")},
    ]

    test "term equality",    do: assert_term_equal    @term_equal_bnodes
    test "term inequality",  do: assert_term_unequal  @term_unequal_bnodes
    test "value equality",   do: assert_value_equal   @value_equal_bnodes
    test "value inequality", do: assert_value_unequal @value_unequal_bnodes
    test "incomparability",  do: assert_incomparable  @incomparable_bnodes
  end

  describe "RDF.String and RDF.LangString" do
    @term_equal_strings [
      {RDF.string("foo"), RDF.string("foo")},
      {RDF.lang_string("foo", language: "de"), RDF.lang_string("foo", language: "de")},
    ]
    @term_unequal_strings [
      {RDF.string("foo"), RDF.string("bar")},
      {RDF.lang_string("foo", language: "de"), RDF.lang_string("bar", language: "de")},
    ]
    @value_equal_strings [
    ]
    @value_unequal_strings [
    ]
    @value_equal_strings_by_coercion [
      {RDF.string("foo"), "foo"},
    ]
    @value_unequal_strings_by_coercion [
      {RDF.string("foo"), "bar"},
    ]
    @incomparable_strings [
      {RDF.string("42"), 42},
      {RDF.lang_string("foo", language: "de"), "foo"},
      {RDF.string("foo"), RDF.lang_string("foo", language: "de")},
      {RDF.lang_string("foo", language: "de"), RDF.string("foo")},
      {RDF.string("foo"), RDF.bnode("foo")},
    ]

    test "term equality",            do: assert_term_equal    @term_equal_strings
    test "term inequality",          do: assert_term_unequal  @term_unequal_strings
    test "value equality",           do: assert_value_equal   @value_equal_strings
    test "value inequality",         do: assert_value_unequal @value_unequal_strings
    test "coerced value equality",   do: assert_value_equal   @value_equal_strings_by_coercion
    test "coerced value inequality", do: assert_value_unequal @value_unequal_strings_by_coercion
    test "incomparability",          do: assert_incomparable  @incomparable_strings
  end

  describe "RDF.Boolean" do
    @term_equal_booleans [
      {RDF.true,  RDF.true},
      {RDF.false, RDF.false},
      # invalid literals
      {RDF.boolean("foo"), RDF.boolean("foo")},
    ]
    @term_unequal_booleans [
      {RDF.true,  RDF.false},
      {RDF.false, RDF.true},
      # invalid literals
      {RDF.boolean("foo"), RDF.boolean("bar")},
    ]
    @value_equal_booleans [
      {RDF.true,       RDF.boolean("1")},
      {RDF.boolean(0), RDF.false},
      # invalid literals
      {RDF.boolean("foo"), RDF.boolean("foo")},
    ]
    @value_unequal_booleans [
      {RDF.true,       RDF.boolean("false")},
      {RDF.boolean(0), RDF.true},
      # invalid literals
      {RDF.boolean("foo"), RDF.boolean("bar")},
    ]
    @value_equal_booleans_by_coercion [
      {RDF.true,  true},
      {RDF.false, false},
    ]
    @value_unequal_booleans_by_coercion [
      {RDF.true,  false},
      {RDF.false, true},
    ]
    @incomparable_booleans [
      {RDF.false, nil},
      {RDF.true,  42},
      {RDF.true,  RDF.string("FALSE")},
      {RDF.true,  RDF.integer(0)},
    ]

    test "term equality",            do: assert_term_equal    @term_equal_booleans
    test "term inequality",          do: assert_term_unequal  @term_unequal_booleans
    test "value equality",           do: assert_value_equal   @value_equal_booleans
    test "value inequality",         do: assert_value_unequal @value_unequal_booleans
    test "coerced value equality",   do: assert_value_equal   @value_equal_booleans_by_coercion
    test "coerced value inequality", do: assert_value_unequal @value_unequal_booleans_by_coercion
    test "incomparability",          do: assert_incomparable  @incomparable_booleans
  end

  describe "RDF.Numeric" do
    @term_equal_numerics [
      {RDF.integer(42),    RDF.integer(42)},
      {RDF.integer("042"), RDF.integer("042")},
      # invalid literals
      {RDF.integer("foo"), RDF.integer("foo")},
      {RDF.decimal("foo"), RDF.decimal("foo")},
      {RDF.double("foo"),  RDF.double("foo")},
    ]
    @term_unequal_numerics [
      {RDF.integer(1), RDF.integer(2)},
      # invalid literals
      {RDF.integer("foo"), RDF.integer("bar")},
      {RDF.decimal("foo"), RDF.decimal("bar")},
      {RDF.double("foo"),  RDF.double("bar")},
    ]
    @value_equal_numerics [
      {RDF.integer("42"), RDF.integer("042")},
      {RDF.integer("42"), RDF.double("42")},
      {RDF.integer(42),   RDF.double(42.0)},
      {RDF.integer("42"), RDF.decimal("42")},
      {RDF.integer(42),   RDF.decimal(42.0)},
      {RDF.double(3.14),  RDF.decimal(3.14)},
      {RDF.double("+0"),  RDF.double("-0")},
      {RDF.decimal("+0"), RDF.decimal("-0")},
      # invalid literals
      {RDF.integer("foo"), RDF.integer("foo")},
      {RDF.decimal("foo"), RDF.decimal("foo")},
      {RDF.double("foo"),  RDF.double("foo")},
    ]
    @value_unequal_numerics [
      {RDF.integer("1"), RDF.double("1.1")},
      {RDF.integer("1"), RDF.decimal("1.1")},
      # invalid literals
      {RDF.integer("foo"), RDF.integer("bar")},
      {RDF.decimal("foo"), RDF.decimal("bar")},
      {RDF.double("foo"),  RDF.double("bar")},
    ]
    @value_equal_numerics_by_coercion [
      {RDF.integer(42),   42},
      {RDF.integer(42),   42.0},
      {RDF.integer(42),   D.new(42)},
      {RDF.decimal(42),   42},
      {RDF.decimal(3.14), 3.14},
      {RDF.decimal(3.14), D.from_float(3.14)},
      {RDF.double(42),    42},
      {RDF.double(3.14),  3.14},
      {RDF.double(3.14),  D.from_float(3.14)},
    ]
    @value_unequal_numerics_by_coercion [
      {RDF.integer(3),    3.14},
      {RDF.integer(3),    D.from_float(3.14)},
      {RDF.double(3.14),  3},
      {RDF.decimal(3.14), 3},
    ]
    @incomparable_numerics [
      {RDF.integer("42"), nil},
      {RDF.integer("42"), true},
      {RDF.integer("42"), "42"},
      {RDF.integer("42"), RDF.string("42")},
    ]

    test "term equality",            do: assert_term_equal    @term_equal_numerics
    test "term inequality",          do: assert_term_unequal  @term_unequal_numerics
    test "value equality",           do: assert_value_equal   @value_equal_numerics
    test "value inequality",         do: assert_value_unequal @value_unequal_numerics
    test "coerced value equality",   do: assert_value_equal   @value_equal_numerics_by_coercion
    test "coerced value inequality", do: assert_value_unequal @value_unequal_numerics_by_coercion
    test "incomparability",          do: assert_incomparable  @incomparable_numerics
  end

  describe "RDF.DateTime" do
    @term_equal_datetimes [
      {RDF.date_time("2002-04-02T12:00:00-01:00"), RDF.date_time("2002-04-02T12:00:00-01:00")},
      {RDF.date_time("2002-04-02T12:00:00"),       RDF.date_time("2002-04-02T12:00:00")},
      # invalid literals
      {RDF.date_time("foo"), RDF.date_time("foo")},
    ]
    @term_unequal_datetimes [
      {RDF.date_time("2002-04-02T12:00:00"), RDF.date_time("2002-04-02T17:00:00")},
      # invalid literals
      {RDF.date_time("foo"), RDF.date_time("bar")},
    ]
    @value_equal_datetimes [
      {RDF.date_time("2002-04-02T12:00:00-01:00"), RDF.date_time("2002-04-02T17:00:00+04:00")},
      {RDF.date_time("2002-04-02T23:00:00-04:00"), RDF.date_time("2002-04-03T02:00:00-01:00")},
      {RDF.date_time("1999-12-31T24:00:00"),       RDF.date_time("2000-01-01T00:00:00")},

      {RDF.date_time("2002-04-02T23:00:00Z"),      RDF.date_time("2002-04-02T23:00:00+00:00")},
      {RDF.date_time("2002-04-02T23:00:00Z"),      RDF.date_time("2002-04-02T23:00:00-00:00")},
      {RDF.date_time("2002-04-02T23:00:00+00:00"), RDF.date_time("2002-04-02T23:00:00-00:00")},

      # invalid literals
      {RDF.date_time("foo"), RDF.date_time("foo")},
    ]
    @value_unequal_datetimes [
      {RDF.date_time("2005-04-04T24:00:00"), RDF.date_time("2005-04-04T00:00:00")},
      # invalid literals
      {RDF.date_time("foo"), RDF.date_time("bar")},
    ]
    @value_equal_datetimes_by_coercion [
      {RDF.date_time("2002-04-02T12:00:00-01:00"), elem(DateTime.from_iso8601("2002-04-02T12:00:00-01:00"), 1)},
      {RDF.date_time("2002-04-02T12:00:00"), ~N"2002-04-02T12:00:00"},
      {RDF.date_time("2002-04-02T23:00:00Z"),      elem(DateTime.from_iso8601("2002-04-02T23:00:00+00:00"), 1)},
      {RDF.date_time("2002-04-02T23:00:00+00:00"),      elem(DateTime.from_iso8601("2002-04-02T23:00:00Z"), 1)},
      {RDF.date_time("2002-04-02T23:00:00-00:00"),      elem(DateTime.from_iso8601("2002-04-02T23:00:00Z"), 1)},
      {RDF.date_time("2002-04-02T23:00:00-00:00"), elem(DateTime.from_iso8601("2002-04-02T23:00:00+00:00"), 1)},
    ]
    @value_unequal_datetimes_by_coercion [
      {RDF.date_time("2002-04-02T12:00:00-01:00"), elem(DateTime.from_iso8601("2002-04-02T12:00:00+00:00"), 1)},
    ]
    @incomparable_datetimes [
      {RDF.date_time("2002-04-02T12:00:00"),    RDF.date_time("2002-04-02T12:00:00Z")},
      {RDF.string("2002-04-02T12:00:00-01:00"), RDF.date_time("2002-04-02T12:00:00-01:00")},
      # These are incomparable because of indeterminacy due to missing timezone
      {RDF.date_time("2002-04-02T12:00:00"), RDF.date_time("2002-04-02T23:00:00+00:00")},
    ]

    test "term equality",            do: assert_term_equal    @term_equal_datetimes
    test "term inequality",          do: assert_term_unequal  @term_unequal_datetimes
    test "value equality",           do: assert_value_equal   @value_equal_datetimes
    test "value inequality",         do: assert_value_unequal @value_unequal_datetimes
    test "coerced value equality",   do: assert_value_equal   @value_equal_datetimes_by_coercion
    test "coerced value inequality", do: assert_value_unequal @value_unequal_datetimes_by_coercion
    test "incomparability",          do: assert_incomparable  @incomparable_datetimes
  end

  describe "RDF.Date" do
    @term_equal_dates [
      {RDF.date("2002-04-02-01:00"), RDF.date("2002-04-02-01:00")},
      {RDF.date("2002-04-02"),       RDF.date("2002-04-02")},
      # invalid literals
      {RDF.date("foo"), RDF.date("foo")},
    ]
    @term_unequal_dates [
      {RDF.date("2002-04-01"), RDF.date("2002-04-02")},
      # invalid literals
      {RDF.date("foo"), RDF.date("bar")},
    ]
    @value_equal_dates [
      {RDF.date("2002-04-02-00:00"), RDF.date("2002-04-02+00:00")},
      {RDF.date("2002-04-02Z"),      RDF.date("2002-04-02+00:00")},
      {RDF.date("2002-04-02Z"),      RDF.date("2002-04-02-00:00")},
    ]
    @value_unequal_dates [
      {RDF.date("2002-04-03Z"),      RDF.date("2002-04-02")},
      {RDF.date("2002-04-03"),       RDF.date("2002-04-02Z")},
      {RDF.date("2002-04-03+00:00"), RDF.date("2002-04-02")},
      {RDF.date("2002-04-03-00:00"), RDF.date("2002-04-02")},
      # invalid literals
      {RDF.date("2002.04.02"), RDF.date("2002-04-02")},
    ]
    @value_equal_dates_by_coercion [
      {RDF.date("2002-04-02"),       Date.from_iso8601!("2002-04-02")},
    ]
    @value_unequal_dates_by_coercion [
      {RDF.date("2002-04-02"),       Date.from_iso8601!("2002-04-03")},
      {RDF.date("2002-04-03+01:00"), Date.from_iso8601!("2002-04-02")},
      {RDF.date("2002-04-03Z"),      Date.from_iso8601!("2002-04-02")},
      {RDF.date("2002-04-03+00:00"), Date.from_iso8601!("2002-04-02")},
      {RDF.date("2002-04-03-00:00"), Date.from_iso8601!("2002-04-02")},
    ]
    @incomparable_dates [
      {RDF.date("2002-04-02"), RDF.string("2002-04-02")},
      # These are incomparable because of indeterminacy due to missing timezone
      {RDF.date("2002-04-02Z"),      RDF.date("2002-04-02")},
      {RDF.date("2002-04-02"),       RDF.date("2002-04-02Z")},
      {RDF.date("2002-04-02+00:00"), RDF.date("2002-04-02")},
      {RDF.date("2002-04-02-00:00"), RDF.date("2002-04-02")},
      {RDF.date("2002-04-02+01:00"), Date.from_iso8601!("2002-04-02")},
      {RDF.date("2002-04-02Z"),      Date.from_iso8601!("2002-04-02")},
      {RDF.date("2002-04-02+00:00"), Date.from_iso8601!("2002-04-02")},
      {RDF.date("2002-04-02-00:00"), Date.from_iso8601!("2002-04-02")},
    ]

    test "term equality",            do: assert_term_equal    @term_equal_dates
    test "term inequality",          do: assert_term_unequal  @term_unequal_dates
    test "value equality",           do: assert_value_equal   @value_equal_dates
    test "value inequality",         do: assert_value_unequal @value_unequal_dates
    test "coerced value equality",   do: assert_value_equal   @value_equal_dates_by_coercion
    test "coerced value inequality", do: assert_value_unequal @value_unequal_dates_by_coercion
    test "incomparability",          do: assert_incomparable  @incomparable_dates
  end

  describe "equality between RDF.Date and RDF.DateTime" do
# It seems quite strange that open-world test date-2 from the SPARQL 1.0 test suite
#  allows for equality comparisons between dates and datetimes, but disallows
#  ordering comparisons in the date-3 test.
#
#    @value_equal_dates_and_datetimes [
#      {RDF.date("2002-04-02"),       RDF.datetime("2002-04-02T00:00:00")},
#      {RDF.datetime("2002-04-02T00:00:00"), RDF.date("2002-04-02")},
#      {RDF.date("2002-04-02Z"),       RDF.datetime("2002-04-02T00:00:00Z")},
#      {RDF.datetime("2002-04-02T00:00:00Z"), RDF.date("2002-04-02Z")},
#      {RDF.date("2002-04-02Z"),       RDF.datetime("2002-04-02T00:00:00+00:00")},
#      {RDF.datetime("2002-04-02T00:00:00-00:00"), RDF.date("2002-04-02Z")},
#    ]
#    @value_unequal_dates_and_datetimes [
#      {RDF.date("2002-04-01"),       RDF.datetime("2002-04-02T00:00:00")},
#      {RDF.datetime("2002-04-01T00:00:00"), RDF.date("2002-04-02")},
#      {RDF.date("2002-04-01Z"),       RDF.datetime("2002-04-02T00:00:00Z")},
#      {RDF.datetime("2002-04-01T00:00:00Z"), RDF.date("2002-04-02Z")},
#      {RDF.date("2002-04-01Z"),       RDF.datetime("2002-04-02T00:00:00+00:00")},
#      {RDF.datetime("2002-04-01T00:00:00-00:00"), RDF.date("2002-04-02Z")},
#    ]
#    @incomparable_dates_and_datetimes [
#      {RDF.date("2002-04-02Z"),       RDF.datetime("2002-04-02T00:00:00")},
#      {RDF.datetime("2002-04-02T00:00:00Z"), RDF.date("2002-04-02")},
#      {RDF.date("2002-04-02"),       RDF.datetime("2002-04-02T00:00:00Z")},
#      {RDF.datetime("2002-04-02T00:00:00"), RDF.date("2002-04-02Z")},
#    ]
#
#    test "value equality",   do: assert_value_equal  @value_equal_dates_and_datetimes
#    test "value inequality", do: assert_value_unequal @value_unequal_dates_and_datetimes
#    test "incomparability",  do: assert_incomparable @incomparable_dates_and_datetimes

    @value_unequal_dates_and_datetimes [
      {RDF.date("2002-04-02"),       RDF.datetime("2002-04-02T00:00:00")},
      {RDF.datetime("2002-04-02T00:00:00"), RDF.date("2002-04-02")},
      {RDF.date("2002-04-01"),       RDF.datetime("2002-04-02T00:00:00")},
      {RDF.datetime("2002-04-01T00:00:00"), RDF.date("2002-04-02")},
    ]

    test "value inequality", do: assert_value_unequal @value_unequal_dates_and_datetimes
  end

  describe "RDF.Time" do
    @term_equal_times [
      {RDF.time("12:00:00+01:00"), RDF.time("12:00:00+01:00")},
      {RDF.time("12:00:00"),       RDF.time("12:00:00")},
      # invalid literals
      {RDF.time("foo"), RDF.time("foo")},
    ]
    @term_unequal_times [
      {RDF.time("12:00:00"), RDF.time("13:00:00")},
      # invalid literals
      {RDF.time("foo"), RDF.time("bar")},
    ]
    @value_equal_times [
    ]
    @value_unequal_times [
    ]
    @value_equal_times_by_coercion [
      {RDF.time("12:00:00"), Time.from_iso8601!("12:00:00")},
    ]
    @value_unequal_times_by_coercion [
      {RDF.time("12:00:00"), Time.from_iso8601!("13:00:00")},
    ]
    @incomparable_times [
      {RDF.time("12:00:00"), RDF.string("12:00:00")},
    ]

    test "term equality",            do: assert_term_equal    @term_equal_times
    test "term inequality",          do: assert_term_unequal  @term_unequal_times
    test "value equality",           do: assert_value_equal   @value_equal_times
    test "value inequality",         do: assert_value_unequal @value_unequal_times
    test "coerced value equality",   do: assert_value_equal   @value_equal_times_by_coercion
    test "coerced value inequality", do: assert_value_unequal @value_unequal_times_by_coercion
    test "incomparability",          do: assert_incomparable  @incomparable_times
  end
  
  describe "RDF.Literals with unsupported types" do
    @equal_literals [
      {RDF.literal("foo", datatype: "http://example.com/datatype"),
       RDF.literal("foo", datatype: "http://example.com/datatype")},
    ]
    @unequal_literals [
      {RDF.literal("foo", datatype: "http://example.com/datatype"),
       RDF.literal("bar", datatype: "http://example.com/datatype")},
    ]
    @incomparable_literals [
      {RDF.literal("foo", datatype: "http://example.com/datatype1"),
       RDF.literal("foo", datatype: "http://example.com/datatype2")},
    ]

    test "term equality",    do: assert_term_equal    @equal_literals
    test "term inequality",  do: assert_value_unequal @unequal_literals
    test "incomparability",  do: assert_incomparable  @incomparable_literals
  end


  defp assert_term_equal(examples) do
    Enum.each examples, fn example -> assert_term_equality(example, true) end
    Enum.each examples, fn example -> assert_value_equality(example, true) end
  end

  defp assert_term_unequal(examples) do
    Enum.each examples, fn example -> assert_term_equality(example, false) end
    Enum.each examples, fn example -> assert_value_equality(example, false) end
  end

  defp assert_value_equal(examples) do
    Enum.each examples, fn example -> assert_value_equality(example, true) end
  end

  defp assert_value_unequal(examples) do
    Enum.each examples, fn example -> assert_value_equality(example, false) end
  end

  defp assert_incomparable(examples) do
    Enum.each examples, fn example -> assert_term_equality(example, false) end
    Enum.each examples, fn example -> assert_value_equality(example, nil) end
  end

  defp assert_term_equality({left, right}, expected) do
    result = RDF.Term.equal?(left, right)
    assert result == expected, """
      expected RDF.Term.equal?(
        #{inspect left},
        #{inspect right})
      to be:   #{inspect expected}
      but got: #{inspect result}
      """

    result = RDF.Term.equal?(right, left)
    assert result == expected, """
    expected RDF.Term.equal?(
      #{inspect right},
      #{inspect left})
    to be:   #{inspect expected}
    but got: #{inspect result}
    """
  end

  defp assert_value_equality({left, right}, expected) do
    result = RDF.Term.equal_value?(left, right)
    assert result == expected, """
      expected RDF.Term.equal_value?(
        #{inspect left},
        #{inspect right})
      to be:   #{inspect expected}
      but got: #{inspect result}
      """

    result = RDF.Term.equal_value?(right, left)
    assert result == expected, """
    expected RDF.Term.equal_value?(
      #{inspect right},
      #{inspect left})
    to be:   #{inspect expected}
    but got: #{inspect result}
    """
  end

end
