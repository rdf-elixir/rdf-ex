defmodule RDF.LiteralComparisonTest do
  use RDF.Test.Case

  describe "RDF.String and RDF.LangString" do
    @ordered_strings [
      {"a", "b"},
      {"0", "1"},
    ]

    test "valid comparisons between string literals" do
      Enum.each @ordered_strings, fn {left, right} ->
        assert_order({RDF.string(left), RDF.string(right)})
      end

      assert_equal {RDF.string("foo"), RDF.string("foo")}
    end

    test "valid comparisons between language tagged literals" do
      Enum.each @ordered_strings, fn {left, right} ->
        assert_order({RDF.lang_string(left, language: "en"), RDF.lang_string(right, language: "en")})
      end

      assert_equal {RDF.lang_string("foo", language: "en"), RDF.lang_string("foo", language: "en")}
    end

    test "invalid comparisons between string and language tagged literals" do
      Enum.each @ordered_strings, fn {left, right} ->
        assert_incomparable({RDF.string(left), RDF.lang_string(right, language: "en")})
      end

      assert_incomparable {RDF.string("foo"), RDF.lang_string("foo", language: "en")}
    end

    test "invalid comparisons between language tagged literals of different languages" do
      Enum.each @ordered_strings, fn {left, right} ->
        assert_incomparable({RDF.lang_string(left, language: "en"), RDF.lang_string(right, language: "de")})
      end

      assert_incomparable {RDF.lang_string("foo", language: "en"), RDF.lang_string("foo", language: "de")}
    end
  end

  describe "RDF.Boolean comparisons" do
    test "when unequal" do
      assert_order {RDF.false, RDF.true}
    end

    test "when equal" do
      assert_equal {RDF.false, RDF.false}
      assert_equal {RDF.true, RDF.true}
    end
  end

  describe "RDF.Numeric comparisons" do
    test "when unequal" do
      Enum.each [
        {RDF.integer(0),   RDF.integer(1)},
        {RDF.integer("3"), RDF.integer("007")},
        {RDF.double(1.1),  RDF.double(2.2)},
        {RDF.decimal(1.1), RDF.decimal(2.2)},
        {RDF.decimal(1.1), RDF.double(2.2)},
        {RDF.double(3.14), RDF.integer(42)},
        {RDF.decimal(3.14), RDF.integer(42)},
# TODO: We need support for other derived numeric datatypes
#        {RDF.literal(0, datatype: XSD.byte), RDF.integer(1)},
      ], &assert_order/1
    end

    test "when equal" do
      Enum.each [
        {RDF.integer(42),   RDF.integer(42)},
        {RDF.integer("42"), RDF.integer("042")},
        {RDF.integer("42"), RDF.double("42")},
        {RDF.integer(42),   RDF.double(42.0)},
        {RDF.integer("42"), RDF.decimal("42")},
        {RDF.integer(42),   RDF.decimal(42.0)},
        {RDF.double(3.14),  RDF.decimal(3.14)},
        {RDF.double("+0"),  RDF.double("-0")},
        {RDF.decimal("+0"), RDF.decimal("-0")},
      ], &assert_equal/1
    end
  end

  describe "RDF.DateTime comparisons" do
    test "when unequal" do
      assert_order {RDF.date_time("2002-04-02T12:00:00"), RDF.date_time("2002-04-02T17:00:00")}
      assert_order {RDF.date_time("2002-04-02T12:00:00+01:00"), RDF.date_time("2002-04-02T12:00:00+00:00")}
      assert_order {RDF.date_time("2000-01-15T12:00:00"), RDF.date_time("2000-01-16T12:00:00Z")}
    end

    test "when unequal due to missing time zone" do
      assert_order {RDF.date_time("2000-01-15T00:00:00"), RDF.date_time("2000-02-15T00:00:00")}
    end

    test "when equal" do
      assert_equal {RDF.date_time("2002-04-02T12:00:00-01:00"), RDF.date_time("2002-04-02T12:00:00-01:00")}
      assert_equal {RDF.date_time("2002-04-02T12:00:00"),       RDF.date_time("2002-04-02T12:00:00")}
      assert_equal {RDF.date_time("2002-04-02T12:00:00-01:00"), RDF.date_time("2002-04-02T17:00:00+04:00")}
      assert_equal {RDF.date_time("2002-04-02T23:00:00-04:00"), RDF.date_time("2002-04-03T02:00:00-01:00")}
      assert_equal {RDF.date_time("1999-12-31T24:00:00"),       RDF.date_time("2000-01-01T00:00:00")}
      # TODO: Assume that the dynamic context provides an implicit timezone value of -05:00
#      assert_equal {RDF.date_time("2002-04-02T12:00:00"),       RDF.date_time("2002-04-02T23:00:00+06:00")}
    end

    test "when indeterminate" do
      assert_indeterminate {RDF.date_time("2000-01-01T12:00:00"), RDF.date_time("1999-12-31T23:00:00Z")}
      assert_indeterminate {RDF.date_time("2000-01-16T12:00:00"), RDF.date_time("2000-01-16T12:00:00Z")}
      assert_indeterminate {RDF.date_time("2000-01-16T00:00:00"), RDF.date_time("2000-01-16T12:00:00Z")}
    end
  end

  describe "RDF.Date comparisons" do
    test "when unequal" do
      assert_order {RDF.date("2002-04-02"),       RDF.date("2002-04-03")}
      assert_order {RDF.date("2002-04-02+01:00"), RDF.date("2002-04-03+00:00")}
      assert_order {RDF.date("2002-04-02"),       RDF.date("2002-04-03Z")}
    end

    test "when equal" do
      assert_equal {RDF.date("2002-04-02-01:00"), RDF.date("2002-04-02-01:00")}
      assert_equal {RDF.date("2002-04-02"),       RDF.date("2002-04-02")}
# TODO:
      assert_equal {RDF.date("2002-04-02-00:00"), RDF.date("2002-04-02+00:00")}
      assert_equal {RDF.date("2002-04-02Z"),      RDF.date("2002-04-02+00:00")}
      assert_equal {RDF.date("2002-04-02Z"),      RDF.date("2002-04-02-00:00")}
    end

    test "when indeterminate" do
      assert_indeterminate {RDF.date("2002-04-02Z"),      RDF.date("2002-04-02")}
      assert_indeterminate {RDF.date("2002-04-02+00:00"), RDF.date("2002-04-02")}
      assert_indeterminate {RDF.date("2002-04-02-00:00"), RDF.date("2002-04-02")}
    end
  end

  describe "RDF.Time comparisons" do
    test "when unequal" do
      assert_order {RDF.time("12:00:00+01:00"), RDF.time("13:00:00+01:00")}
      assert_order {RDF.time("12:00:00"),       RDF.time("13:00:00")}
    end

    test "when equal" do
      assert_equal {RDF.time("12:00:00+01:00"), RDF.time("12:00:00+01:00")}
      assert_equal {RDF.time("12:00:00"),       RDF.time("12:00:00")}
    end

    test "when indeterminate" do
      assert_indeterminate {RDF.date("2002-04-02Z"),      RDF.date("2002-04-02")}
      assert_indeterminate {RDF.date("2002-04-02+00:00"), RDF.date("2002-04-02")}
      assert_indeterminate {RDF.date("2002-04-02-00:00"), RDF.date("2002-04-02")}
    end
  end

  describe "comparisons on RDF.Literals with unsupported types" do
    test "when unequal" do
      assert_order {RDF.literal("a", datatype: "http://example.com/datatype"),
                    RDF.literal("b", datatype: "http://example.com/datatype")}
    end

    test "when equal" do
      assert_equal {RDF.literal("a", datatype: "http://example.com/datatype"),
                    RDF.literal("a", datatype: "http://example.com/datatype")}
    end
  end

  describe "incomparable " do
    test "when comparing incomparable types" do
      Enum.each [
        {RDF.string("http://example.com/"), RDF.iri("http://example.com/")},
        {RDF.string("foo"),  RDF.bnode("foo")},
        {RDF.string("true"), RDF.true},
        {RDF.string("42"),   RDF.integer(42)},
        {RDF.string("3.14"), RDF.decimal(3.14)},
        {RDF.string("2002-04-02T12:00:00"), RDF.date_time("2002-04-02T12:00:00")},
        {RDF.string("2002-04-02"),          RDF.date("2002-04-02")},
        {RDF.string("12:00:00"),            RDF.time("12:00:00")},
        {RDF.false, nil},
        {RDF.true,  RDF.integer(42)},
        {RDF.true,  RDF.decimal(3.14)},
        {RDF.date_time("2002-04-02T12:00:00"), RDF.true},
        {RDF.date_time("2002-04-02T12:00:00"), RDF.integer(42)},
        {RDF.date_time("2002-04-02T12:00:00"), RDF.decimal(3.14)},
        {RDF.date("2002-04-02"), RDF.true},
        {RDF.date("2002-04-02"), RDF.integer(42)},
        {RDF.date("2002-04-02"), RDF.decimal(3.14)},
        {RDF.time("12:00:00"), RDF.true},
        {RDF.time("12:00:00"), RDF.integer(42)},
        {RDF.time("12:00:00"), RDF.decimal(3.14)},
      ], &assert_incomparable/1
    end

    test "when comparing invalid literals" do
      Enum.each [
        {RDF.true,  RDF.boolean(42)},
        {RDF.date_time("2002-04-02T12:00:00"), RDF.date_time("2002.04.02 12:00")},
        {RDF.date("2002-04-02"), RDF.date("2002.04.02")},
        {RDF.time("12:00:00"), RDF.time("12-00-00")},
      ], &assert_incomparable/1
    end
  end


  defp assert_order({left, right}) do
    assert_compare_result({left, right}, :lt)
    assert_compare_result({right, left}, :gt)

    assert_less_than({left, right}, true)
    assert_less_than({right, left}, false)

    assert_greater_than({left, right}, false)
    assert_greater_than({right, left}, true)
  end

  defp assert_equal({left, right}) do
    assert_compare_result({left, right}, :eq)
    assert_compare_result({right, left}, :eq)

    assert_less_than({left, right}, false)
    assert_less_than({right, left}, false)

    assert_greater_than({left, right}, false)
    assert_greater_than({right, left}, false)
  end

  defp assert_incomparable({left, right}) do
    assert_compare_result({left, right}, nil)
    assert_compare_result({right, left}, nil)

    assert_greater_than({left, right}, nil)
    assert_greater_than({right, left}, nil)

    assert_less_than({left, right}, nil)
    assert_less_than({right, left}, nil)
  end

  defp assert_indeterminate({left, right}) do
    assert_compare_result({left, right}, :indeterminate)
    assert_compare_result({right, left}, :indeterminate)

    assert_greater_than({left, right}, false)
    assert_greater_than({right, left}, false)

    assert_less_than({left, right}, false)
    assert_less_than({right, left}, false)
  end

  defp assert_compare_result({left, right}, expected) do
    result = RDF.Literal.compare(left, right)
    assert result == expected, """
    expected RDF.Literal.compare(
      #{inspect left},
      #{inspect right})
    to be:   #{inspect expected}
    but got: #{inspect result}
    """
  end

  defp assert_less_than({left, right}, expected) do
    result = RDF.Literal.less_than?(left, right)
    assert result == expected, """
    expected RDF.Literal.less_than?(
      #{inspect left},
      #{inspect right})
    to be:   #{inspect expected}
    but got: #{inspect result}
    """
  end

  defp assert_greater_than({left, right}, expected) do
    result = RDF.Literal.greater_than?(left, right)
    assert result == expected, """
    expected RDF.Literal.greater_than?(
      #{inspect left},
      #{inspect right})
    to be:   #{inspect expected}
    but got: #{inspect result}
    """
  end

end
