defmodule RDF.EqualityTest do
  use RDF.Test.Case

  alias RDF.NS.XSD


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
    @incomparable_strings [
      {RDF.string("foo"), RDF.lang_string("foo", language: "de")},
      {RDF.lang_string("foo", language: "de"), RDF.string("foo")},
      {RDF.string("foo"), RDF.bnode("foo")},
    ]

    test "term equality",    do: assert_term_equal    @term_equal_strings
    test "term inequality",  do: assert_term_unequal  @term_unequal_strings
    test "value equality",   do: assert_value_equal   @value_equal_strings
    test "value inequality", do: assert_value_unequal @value_unequal_strings
    test "incomparability",  do: assert_incomparable  @incomparable_strings
  end

  describe "RDF.Boolean" do
    @term_equal_booleans [
      {RDF.true,       RDF.true},
      {RDF.false,      RDF.false},
    ]
    @term_unequal_booleans [
      {RDF.true,       RDF.false},
      {RDF.false,      RDF.true},
    ]
    @value_equal_booleans [
      {RDF.true,       RDF.boolean("TRUE")},
      {RDF.boolean(1), RDF.true},
    ]
    @value_unequal_booleans [
      {RDF.true,       RDF.boolean("FALSE")},
      {RDF.boolean(0), RDF.true},
    ]
    @incomparable_booleans [
      {RDF.true,       nil},
      {nil,            RDF.true},
      {RDF.true,       RDF.string("FALSE")},
      {RDF.integer(0), RDF.true},
    ]

    test "term equality",    do: assert_term_equal    @term_equal_booleans
    test "term inequality",  do: assert_term_unequal  @term_unequal_booleans
    test "value equality",   do: assert_value_equal   @value_equal_booleans
    test "value inequality", do: assert_value_unequal @value_unequal_booleans
    test "incomparability",  do: assert_incomparable  @incomparable_booleans
  end

  describe "RDF.Numeric" do
    @term_equal_numerics [
      {RDF.integer(42),    RDF.integer(42)},
      {RDF.integer("042"), RDF.integer("042")},
    ]
    @term_unequal_numerics [
      {RDF.integer(1), RDF.integer(2)},
    ]
    @value_equal_numerics [
      {RDF.integer("42"), RDF.integer("042")},
      {RDF.double("+0"),  RDF.double("-0")},
      {RDF.integer("42"), RDF.double("42")},
      {RDF.integer(42),   RDF.double(42.0)},
    ]
    @value_unequal_numerics [
      {RDF.integer("1"), RDF.double("1.1")},
    ]
    @incomparable_numerics [
      {RDF.string("42"),  RDF.integer(42)},
      {RDF.integer("42"), RDF.string("42")},
    ]

    test "term equality",    do: assert_term_equal    @term_equal_numerics
    test "term inequality",  do: assert_term_unequal  @term_unequal_numerics
    test "value equality",   do: assert_value_equal   @value_equal_numerics
    test "value inequality", do: assert_value_unequal @value_unequal_numerics
    test "incomparability",  do: assert_incomparable  @incomparable_numerics
  end

  describe "RDF.DateTime" do
    @term_equal_datetimes [
      {RDF.date_time("2002-04-02T12:00:00-01:00"), RDF.date_time("2002-04-02T12:00:00-01:00")},
      {RDF.date_time("2002-04-02T12:00:00"),       RDF.date_time("2002-04-02T12:00:00")},
    ]
    @term_unequal_datetimes [
     {RDF.date_time("2002-04-02T12:00:00"), RDF.date_time("2002-04-02T17:00:00")},
    ]
    @value_equal_datetimes [
      {RDF.date_time("2002-04-02T12:00:00-01:00"), RDF.date_time("2002-04-02T17:00:00+04:00")},
      {RDF.date_time("2002-04-02T23:00:00-04:00"), RDF.date_time("2002-04-03T02:00:00-01:00")},
      {RDF.date_time("1999-12-31T24:00:00"),       RDF.date_time("2000-01-01T00:00:00")},
# TODO: Assume that the dynamic context provides an implicit timezone value of -05:00
#      {RDF.date_time("2002-04-02T12:00:00"),       RDF.date_time("2002-04-02T23:00:00+06:00")},
    ]
    @value_unequal_datetimes [
      {RDF.date_time("2005-04-04T24:00:00"), RDF.date_time("2005-04-04T00:00:00")},
    ]
    @incomparable_datetimes [
      {RDF.string("2002-04-02T12:00:00-01:00"),    RDF.date_time("2002-04-02T12:00:00-01:00")},
      {RDF.date_time("2002-04-02T12:00:00-01:00"), RDF.string("2002-04-02T12:00:00-01:00")},
    ]

    test "term equality",    do: assert_term_equal    @term_equal_datetimes
    test "term inequality",  do: assert_term_unequal  @term_unequal_datetimes
    test "value equality",   do: assert_value_equal   @value_equal_datetimes
    test "value inequality", do: assert_value_unequal @value_unequal_datetimes
    test "incomparability",  do: assert_incomparable  @incomparable_datetimes
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
  end

end
