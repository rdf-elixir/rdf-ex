defmodule RDF.DecimalTest do
# TODO: Why can't we use the Decimal alias in the use options? Maybe it's the special ExUnit.CaseTemplate.using/2 macro in RDF.Datatype.Test.Case?
#  alias Elixir.Decimal, as: D
  use RDF.Datatype.Test.Case, datatype: RDF.Decimal, id: RDF.NS.XSD.decimal,
    valid: %{
    # input                   => { value                             lexical        canonicaized }
      0                       => {Elixir.Decimal.new(0),             "0",           "0.0"},
      1                       => {Elixir.Decimal.new(1),             "1",           "1.0"},
      -1                      => {Elixir.Decimal.new(-1),            "-1",          "-1.0"},
      1.0                     => {Elixir.Decimal.new(1.0),           nil,           "1.0"},
      -3.14                   => {Elixir.Decimal.new(-3.14),         nil,           "-3.14"},
      0.0E2                   => {Elixir.Decimal.new(0.0E2),         nil,           "0.0"},
      1.2E3                   => {Elixir.Decimal.new(1.2E3),         nil,           "1200.0"},
      Elixir.Decimal.new(1.0) => {Elixir.Decimal.new(1.0),           nil,           "1.0"},
      "1"                     => {Elixir.Decimal.new(1),             "1",           "1.0" },
      "01"                    => {Elixir.Decimal.new(1),             "01",          "1.0" },
      "0123"                  => {Elixir.Decimal.new(123),           "0123",        "123.0" },
      "-1"                    => {Elixir.Decimal.new(-1),            "-1",          "-1.0" },
      "1."                    => {Elixir.Decimal.new(1),             "1.",          "1.0" },
      "1.0"                   => {Elixir.Decimal.new(1.0),           nil,           "1.0" },
      "1.000000000"           => {Elixir.Decimal.new("1.000000000"), "1.000000000", "1.0" },
      "+001.00"               => {Elixir.Decimal.new("1.00"),        "+001.00",     "1.0" },
      "123.456"               => {Elixir.Decimal.new(123.456),       nil,           "123.456" },
      "0123.456"              => {Elixir.Decimal.new(123.456),       "0123.456",    "123.456" },
      "010.020"               => {Elixir.Decimal.new("10.020"),      "010.020",     "10.02" },
      "2.3"                   => {Elixir.Decimal.new(2.3),           nil,           "2.3" },
      "2.345"                 => {Elixir.Decimal.new(2.345),         nil,           "2.345" },
      "2.234000005"           => {Elixir.Decimal.new(2.234000005),   nil,           "2.234000005" },
      "1.234567890123456789012345789"
                              => {Elixir.Decimal.new("1.234567890123456789012345789"),
                                                                     nil,           "1.234567890123456789012345789" },
      ".3"                    => {Elixir.Decimal.new(0.3),           ".3",          "0.3" },
      "-.3"                   => {Elixir.Decimal.new(-0.3),          "-.3",         "-0.3" },
    },
    invalid: ~w(foo 10.1e1 12.xyz 3,5 NaN Inf) ++ [true, false, "1.0 foo", "foo 1.0",
              Elixir.Decimal.new("NaN"), Elixir.Decimal.new("Inf")]


  describe "equality" do
    test "two literals are equal when they have the same datatype and lexical form" do
      [
        {"1.0"   , 1.0},
        {"-42.0" , -42.0},
        {"1.0"   , 1.0},
      ]
      |> Enum.each(fn {l, r} ->
           assert Decimal.new(l) == Decimal.new(r)
         end)
    end

    test "two literals with same value but different lexical form are not equal" do
      [
        {"1"     , 1.0},
        {"01"    , 1.0},
        {"1.0E0" , 1.0},
        {"1.0E0" , "1.0"},
        {"+42"   , 42.0},
      ]
      |> Enum.each(fn {l, r} ->
           assert Decimal.new(l) != Decimal.new(r)
         end)
    end
  end


  defmacrop sigil_d(str, _opts) do
    quote do
      Elixir.Decimal.new(unquote(str))
    end
  end

  test "Decimal.canonical_lexical/1" do
    assert Decimal.canonical_lexical(~d"0") == "0.0"
    assert Decimal.canonical_lexical(~d"0.0") == "0.0"
    assert Decimal.canonical_lexical(~d"0.001") == "0.001"
    assert Decimal.canonical_lexical(~d"-0") == "-0.0"
    assert Decimal.canonical_lexical(~d"-1") == "-1.0"
    assert Decimal.canonical_lexical(~d"-0.00") == "-0.0"
    assert Decimal.canonical_lexical(~d"1.00") == "1.0"
    assert Decimal.canonical_lexical(~d"1000") == "1000.0"
    assert Decimal.canonical_lexical(~d"1000.000000") == "1000.0"
    assert Decimal.canonical_lexical(~d"12345.000") == "12345.0"
    assert Decimal.canonical_lexical(~d"42") == "42.0"
    assert Decimal.canonical_lexical(~d"42.42") == "42.42"
    assert Decimal.canonical_lexical(~d"0.42") == "0.42"
    assert Decimal.canonical_lexical(~d"0.0042") == "0.0042"
    assert Decimal.canonical_lexical(~d"010.020") == "10.02"
    assert Decimal.canonical_lexical(~d"-1.23") == "-1.23"
    assert Decimal.canonical_lexical(~d"-0.0123") == "-0.0123"
    assert Decimal.canonical_lexical(~d"1E+2") == "100.0"
    assert Decimal.canonical_lexical(~d"-42E+3") == "-42000.0"
    assert Decimal.canonical_lexical(~d"nan") == "NaN"
    assert Decimal.canonical_lexical(~d"-nan") == "-NaN"
    assert Decimal.canonical_lexical(~d"-inf") == "-Infinity"
  end

end
