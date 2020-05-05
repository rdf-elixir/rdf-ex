defmodule RDF.XSD.ComparisonTest do
  use ExUnit.Case

  alias RDF.XSD

  describe "XSD.String" do
    @ordered_strings [
      {"a", "b"},
      {"0", "1"}
    ]

    test "valid comparisons between string literals" do
      Enum.each(@ordered_strings, fn {left, right} ->
        assert_order({XSD.string(left), XSD.string(right)})
      end)

      assert_equal({XSD.string("foo"), XSD.string("foo")})
    end
  end

  describe "XSD.Boolean" do
    test "when unequal" do
      assert_order({XSD.false(), XSD.true()})
    end

    test "when equal" do
      assert_equal({XSD.false(), XSD.false()})
      assert_equal({XSD.true(), XSD.true()})
    end
  end

  describe "XSD.Numeric" do
    test "when unequal" do
      Enum.each(
        [
          {XSD.integer(0), XSD.integer(1)},
          {XSD.integer("3"), XSD.integer("007")},
          {XSD.double(1.1), XSD.double(2.2)},
          {XSD.float(1.1), XSD.float(2.2)},
          {XSD.decimal(1.1), XSD.decimal(2.2)},
          {XSD.decimal(1.1), XSD.double(2.2)},
          {XSD.float(1.1), XSD.decimal(2.2)},
          {XSD.double(3.14), XSD.integer(42)},
          {XSD.float(3.14), XSD.integer(42)},
          {XSD.decimal(3.14), XSD.integer(42)},
          {XSD.non_negative_integer(0), XSD.integer(1)},
          {XSD.integer(0), XSD.positive_integer(1)},
          {XSD.non_negative_integer(0), XSD.positive_integer(1)},
          {XSD.positive_integer(1), XSD.non_negative_integer(2)}
        ],
        &assert_order/1
      )
    end

    test "when equal" do
      Enum.each(
        [
          {XSD.integer(42), XSD.integer(42)},
          {XSD.integer("42"), XSD.integer("042")},
          {XSD.integer("42"), XSD.double("42")},
          {XSD.integer(42), XSD.double(42.0)},
          {XSD.integer(42), XSD.float(42.0)},
          {XSD.integer("42"), XSD.decimal("42")},
          {XSD.integer(42), XSD.decimal(42.0)},
          {XSD.double(3.14), XSD.decimal(3.14)},
          {XSD.float(3.14), XSD.decimal(3.14)},
          {XSD.double("+0"), XSD.double("-0")},
          {XSD.decimal("+0"), XSD.decimal("-0")},
          {XSD.non_negative_integer(0), XSD.integer(0)},
          {XSD.integer(1), XSD.positive_integer(1)},
          {XSD.non_negative_integer(1), XSD.positive_integer(1)},
          {XSD.positive_integer(1), XSD.non_negative_integer(1)}
        ],
        &assert_equal/1
      )
    end
  end

  describe "XSD.DateTime" do
    test "when unequal" do
      assert_order({XSD.datetime("2002-04-02T12:00:00"), XSD.datetime("2002-04-02T17:00:00")})

      assert_order(
        {XSD.datetime("2002-04-02T12:00:00+01:00"), XSD.datetime("2002-04-02T12:00:00+00:00")}
      )

      assert_order({XSD.datetime("2000-01-15T12:00:00"), XSD.datetime("2000-01-16T12:00:00Z")})
    end

    test "when unequal due to missing time zone" do
      assert_order({XSD.datetime("2000-01-15T00:00:00"), XSD.datetime("2000-02-15T00:00:00")})
    end

    test "when equal" do
      assert_equal(
        {XSD.datetime("2002-04-02T12:00:00-01:00"), XSD.datetime("2002-04-02T12:00:00-01:00")}
      )

      assert_equal({XSD.datetime("2002-04-02T12:00:00"), XSD.datetime("2002-04-02T12:00:00")})

      assert_equal(
        {XSD.datetime("2002-04-02T12:00:00-01:00"), XSD.datetime("2002-04-02T17:00:00+04:00")}
      )

      assert_equal(
        {XSD.datetime("2002-04-02T23:00:00-04:00"), XSD.datetime("2002-04-03T02:00:00-01:00")}
      )

      assert_equal({XSD.datetime("1999-12-31T24:00:00"), XSD.datetime("2000-01-01T00:00:00")})
      # TODO: Assume that the dynamic context provides an implicit timezone value of -05:00
      #      assert_equal {XSD.datetime("2002-04-02T12:00:00"),       XSD.datetime("2002-04-02T23:00:00+06:00")}
    end

    test "when indeterminate" do
      assert_indeterminate(
        {XSD.datetime("2000-01-01T12:00:00"), XSD.datetime("1999-12-31T23:00:00Z")}
      )

      assert_indeterminate(
        {XSD.datetime("2000-01-16T12:00:00"), XSD.datetime("2000-01-16T12:00:00Z")}
      )

      assert_indeterminate(
        {XSD.datetime("2000-01-16T00:00:00"), XSD.datetime("2000-01-16T12:00:00Z")}
      )
    end
  end

  describe "XSD.Date" do
    test "when unequal" do
      assert_order({XSD.date("2002-04-02"), XSD.date("2002-04-03")})
      assert_order({XSD.date("2002-04-02+01:00"), XSD.date("2002-04-03+00:00")})
      assert_order({XSD.date("2002-04-02"), XSD.date("2002-04-03Z")})
    end

    test "when equal" do
      assert_equal({XSD.date("2002-04-02-01:00"), XSD.date("2002-04-02-01:00")})
      assert_equal({XSD.date("2002-04-02"), XSD.date("2002-04-02")})
      assert_equal({XSD.date("2002-04-02-00:00"), XSD.date("2002-04-02+00:00")})
      assert_equal({XSD.date("2002-04-02Z"), XSD.date("2002-04-02+00:00")})
      assert_equal({XSD.date("2002-04-02Z"), XSD.date("2002-04-02-00:00")})
    end

    test "when indeterminate" do
      assert_indeterminate({XSD.date("2002-04-02Z"), XSD.date("2002-04-02")})
      assert_indeterminate({XSD.date("2002-04-02+00:00"), XSD.date("2002-04-02")})
      assert_indeterminate({XSD.date("2002-04-02-00:00"), XSD.date("2002-04-02")})
    end
  end

  # It seems quite strange that open-world test date-2 from the SPARQL 1.0 test suite
  #  allows for equality comparisons between dates and datetimes, but disallows
  #  ordering comparisons in the date-3 test.
  #
  #  describe "comparisons XSD.DateTime between XSD.Date and XSD.DateTime" do
  #    test "when unequal" do
  #      # without timezone
  #      assert_order({XSD.datetime("2000-01-14T00:00:00"), XSD.date("2000-02-15")})
  #      assert_order({XSD.date("2000-01-15"), XSD.datetime("2000-01-15T00:00:01")})
  #      # with timezone
  #      assert_order({XSD.datetime("2000-01-14T00:00:00"), XSD.date("2000-02-15")})
  #      assert_order({XSD.datetime("2000-01-14T00:00:00"), XSD.date("2000-02-15Z")})
  #      assert_order({XSD.datetime("2000-01-14T00:00:00"), XSD.date("2000-02-15+01:00")})
  #      assert_order({XSD.datetime("2000-01-14T00:00:00Z"), XSD.date("2000-02-15")})
  #      assert_order({XSD.datetime("2000-01-14T00:00:00Z"), XSD.date("2000-02-15Z")})
  #      assert_order({XSD.datetime("2000-01-14T00:00:00Z"), XSD.date("2000-02-15+01:00")})
  #    end
  #
  #    test "when equal" do
  #      assert_equal({XSD.datetime("2000-01-15T00:00:00"), XSD.date("2000-01-15")})
  #      assert_equal({XSD.datetime("2000-01-15T00:00:00Z"), XSD.date("2000-01-15Z")})
  #      assert_equal({XSD.datetime("2000-01-15T00:00:00Z"), XSD.date("2000-01-15+00:00")})
  #      assert_equal({XSD.datetime("2000-01-15T00:00:00Z"), XSD.date("2000-01-15-00:00")})
  #    end
  #
  #    test "when indeterminate" do
  #      assert_indeterminate({XSD.datetime("2000-01-15T00:00:00"), XSD.date("2000-01-15Z")})
  #      assert_indeterminate({XSD.datetime("2000-01-15T00:00:00Z"), XSD.date("2000-01-15")})
  #    end
  #  end

  describe "XSD.Time" do
    test "when unequal" do
      assert_order({XSD.time("12:00:00+01:00"), XSD.time("13:00:00+01:00")})
      assert_order({XSD.time("12:00:00"), XSD.time("13:00:00")})
    end

    test "when equal" do
      assert_equal({XSD.time("12:00:00+01:00"), XSD.time("12:00:00+01:00")})
      assert_equal({XSD.time("12:00:00"), XSD.time("12:00:00")})
    end

    test "when indeterminate" do
      assert_indeterminate({XSD.date("2002-04-02Z"), XSD.date("2002-04-02")})
      assert_indeterminate({XSD.date("2002-04-02+00:00"), XSD.date("2002-04-02")})
      assert_indeterminate({XSD.date("2002-04-02-00:00"), XSD.date("2002-04-02")})
    end
  end

  describe "incomparable" do
    test "when comparing incomparable types" do
      Enum.each(
        [
          {XSD.string("true"), XSD.true()},
          {XSD.string("42"), XSD.integer(42)},
          {XSD.string("3.14"), XSD.decimal(3.14)},
          {XSD.string("2002-04-02T12:00:00"), XSD.datetime("2002-04-02T12:00:00")},
          {XSD.string("2002-04-02"), XSD.date("2002-04-02")},
          {XSD.string("12:00:00"), XSD.time("12:00:00")},
          {XSD.true(), XSD.integer(42)},
          {XSD.true(), XSD.decimal(3.14)},
          {XSD.datetime("2002-04-02T12:00:00"), XSD.true()},
          {XSD.datetime("2002-04-02T12:00:00"), XSD.integer(42)},
          {XSD.datetime("2002-04-02T12:00:00"), XSD.decimal(3.14)},
          {XSD.date("2002-04-02"), XSD.true()},
          {XSD.date("2002-04-02"), XSD.integer(42)},
          {XSD.date("2002-04-02"), XSD.decimal(3.14)},
          {XSD.time("12:00:00"), XSD.true()},
          {XSD.time("12:00:00"), XSD.integer(42)},
          {XSD.time("12:00:00"), XSD.decimal(3.14)}
        ],
        &assert_incomparable/1
      )
    end

    test "when comparing invalid literals" do
      Enum.each(
        [
          {XSD.true(), XSD.boolean(42)},
          {XSD.datetime("2002-04-02T12:00:00"), XSD.datetime("2002.04.02 12:00")},
          {XSD.date("2002-04-02"), XSD.date("2002.04.02")},
          {XSD.time("12:00:00"), XSD.time("12-00-00")}
        ],
        &assert_incomparable/1
      )
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

    assert_greater_than({left, right}, false)
    assert_greater_than({right, left}, false)

    assert_less_than({left, right}, false)
    assert_less_than({right, left}, false)
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
      #{inspect(left)},
      #{inspect(right)})
    to be:   #{inspect(expected)}
    but got: #{inspect(result)}
    """
  end

  defp assert_less_than({left, right}, expected) do
    result = RDF.Literal.less_than?(left, right)

    assert result == expected, """
    expected RDF.Literal.less_than?(
      #{inspect(left)},
      #{inspect(right)})
    to be:   #{inspect(expected)}
    but got: #{inspect(result)}
    """
  end

  defp assert_greater_than({left, right}, expected) do
    result = RDF.Literal.greater_than?(left, right)

    assert result == expected, """
    expected RDF.Literal.greater_than?(
      #{inspect(left)},
      #{inspect(right)})
    to be:   #{inspect(expected)}
    but got: #{inspect(result)}
    """
  end
end
