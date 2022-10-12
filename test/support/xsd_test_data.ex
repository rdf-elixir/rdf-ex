defmodule RDF.XSD.TestData do
  @moduledoc """
  Shared definitions for the `RDF.XSD.Datatype` tests.
  """

  @zero %{
    0 => {0, nil, "0"},
    "0" => {0, nil, "0"},
    "+0" => {0, "+0", "0"},
    "-0" => {0, "-0", "0"},
    "000" => {0, "000", "0"}
  }

  @basic_valid_positive_integers %{
                                   # input => { value, lexical, canonicalized }
                                   1 => {1, nil, "1"},
                                   "1" => {1, nil, "1"},
                                   "01" => {1, "01", "1"},
                                   "0123" => {123, "0123", "123"},
                                   "+1" => {1, "+1", "1"}
                                 }
                                 |> Map.merge(@zero)

  @basic_valid_negative_integers %{
                                   -1 => {-1, nil, "-1"},
                                   "-1" => {-1, nil, "-1"},
                                   "-01" => {-1, "-01", "-1"},
                                   "-0123" => {-123, "-0123", "-123"}
                                 }
                                 |> Map.merge(@zero)

  @valid_unsigned_bytes %{
                          255 => {255, nil, "255"},
                          "0255" => {255, "0255", "255"}
                        }
                        |> Map.merge(@basic_valid_positive_integers)

  @valid_unsigned_shorts %{
                           65535 => {65535, nil, "65535"}
                         }
                         |> Map.merge(@valid_unsigned_bytes)

  @valid_unsigned_ints %{
                         4_294_967_295 => {4_294_967_295, nil, "4294967295"}
                       }
                       |> Map.merge(@valid_unsigned_shorts)

  @valid_unsigned_longs %{
                          18_446_744_073_709_551_615 =>
                            {18_446_744_073_709_551_615, nil, "18446744073709551615"}
                        }
                        |> Map.merge(@valid_unsigned_ints)

  @valid_bytes Map.merge(@basic_valid_positive_integers, @basic_valid_negative_integers)

  @valid_shorts %{
                  32767 => {32767, nil, "32767"},
                  -32768 => {-32768, nil, "-32768"}
                }
                |> Map.merge(@valid_bytes)

  @valid_ints %{
                2_147_483_647 => {2_147_483_647, nil, "2147483647"},
                -2_147_483_648 => {-2_147_483_648, nil, "-2147483648"}
              }
              |> Map.merge(@valid_bytes)

  @valid_longs %{
                 9_223_372_036_854_775_807 =>
                   {9_223_372_036_854_775_807, nil, "9223372036854775807"},
                 -9_223_372_036_854_775_808 =>
                   {-9_223_372_036_854_775_808, nil, "-9223372036854775808"}
               }
               |> Map.merge(@valid_bytes)

  @valid_non_negative_integers %{
                                 200_000_000_000_000_000_000_000 =>
                                   {200_000_000_000_000_000_000_000, nil,
                                    "200000000000000000000000"}
                               }
                               |> Map.merge(@valid_unsigned_longs)

  @valid_non_positive_integers %{
                                 -200_000_000_000_000_000_000_000 =>
                                   {-200_000_000_000_000_000_000_000, nil,
                                    "-200000000000000000000000"}
                               }
                               |> Map.merge(@basic_valid_negative_integers)

  @valid_positive_integers Map.drop(@valid_non_negative_integers, Map.keys(@zero))
  @valid_negative_integers Map.drop(@valid_non_positive_integers, Map.keys(@zero))

  @valid_integers @zero
                  |> Map.merge(@valid_non_negative_integers)
                  |> Map.merge(@valid_non_positive_integers)

  @basic_invalid_integers [
    "foo",
    "10.1",
    "12xyz",
    true,
    false,
    3.14,
    "1 2",
    "foo 1",
    "1 foo"
  ]

  @invalid_bytes [128, "128", -129, "-129"] ++ @basic_invalid_integers
  @invalid_shorts [32768, "32768", -32769, "-32769"] ++ @basic_invalid_integers
  @invalid_ints [2_147_483_648, "2147483648", -21_474_836_489, "-2147483649"] ++
                  @basic_invalid_integers
  @invalid_longs [
                   9_223_372_036_854_775_808,
                   "9223372036854775808",
                   -9_223_372_036_854_775_809,
                   "-92233720368547758089"
                 ] ++ @basic_invalid_integers

  @invalid_non_negative_integers [-1, "-1"] ++ @basic_invalid_integers
  @invalid_non_positive_integers [1, "1", "+1"] ++ @basic_invalid_integers
  @invalid_positive_integers [0, "0"] ++ @invalid_non_negative_integers
  @invalid_negative_integers [0, "0"] ++ @invalid_non_positive_integers

  @invalid_unsigned_bytes [256, "256"] ++ @invalid_non_negative_integers
  @invalid_unsigned_shorts [65536, "65536"] ++ @invalid_non_negative_integers
  @invalid_unsigned_ints [4_294_967_296, "4294967296"] ++ @invalid_non_negative_integers
  @invalid_unsigned_longs [18_446_744_073_709_551_616, "18446744073709551616"] ++
                            @invalid_non_negative_integers

  @valid_floats %{
    # input => { value, lexical, canonicalized }
    0 => {0.0, "0.0", "0.0E0"},
    42 => {42.0, "42.0", "4.2E1"},
    0.0e0 => {0.0, "0.0", "0.0E0"},
    1.0e0 => {1.0, "1.0", "1.0E0"},
    :positive_infinity => {:positive_infinity, nil, "INF"},
    :negative_infinity => {:negative_infinity, nil, "-INF"},
    :nan => {:nan, nil, "NaN"},
    "1.0E0" => {1.0e0, nil, "1.0E0"},
    "0.0" => {0.0, "0.0", "0.0E0"},
    "1" => {1.0e0, "1", "1.0E0"},
    "01" => {1.0e0, "01", "1.0E0"},
    "0123" => {1.23e2, "0123", "1.23E2"},
    "-1" => {-1.0e0, "-1", "-1.0E0"},
    "+01.000" => {1.0e0, "+01.000", "1.0E0"},
    "1.0" => {1.0e0, "1.0", "1.0E0"},
    "-0" =>
      if String.to_integer(System.otp_release()) >= 24 do
        {0.0e0, "-0", "-0.0E0"}
      else
        # This is actual wrong, but we won't fix this wrong behaviour in older Elixir versions
        {0.0e0, "-0", "0.0E0"}
      end,
    "0." => {0.0e0, "0.", "0.0E0"},
    ".0" => {0.0e0, ".0", "0.0E0"},
    ".0E0" => {0.0e0, ".0E0", "0.0E0"},
    "123.456" => {1.23456e2, "123.456", "1.23456E2"},
    "1.0e+1" => {1.0e1, "1.0e+1", "1.0E1"},
    "1.0e-10" => {1.0e-10, "1.0e-10", "1.0E-10"},
    "123.456e4" => {1.23456e6, "123.456e4", "1.23456E6"},
    "1.E-8" => {1.0e-8, "1.E-8", "1.0E-8"},
    "3E1" => {3.0e1, "3E1", "3.0E1"},
    "INF" => {:positive_infinity, nil, "INF"},
    "Inf" => {:positive_infinity, "Inf", "INF"},
    "-INF" => {:negative_infinity, nil, "-INF"},
    "NaN" => {:nan, nil, "NaN"}
  }

  @invalid_floats ["foo", "12.xyz", "1.0ez", "+INF", true, false, "1.1e1 foo", "foo 1.1e1"]

  def valid_integers, do: @valid_integers
  def valid_non_negative_integers, do: @valid_non_negative_integers
  def valid_non_positive_integers, do: @valid_non_positive_integers
  def valid_positive_integers, do: @valid_positive_integers
  def valid_negative_integers, do: @valid_negative_integers
  def valid_bytes, do: @valid_bytes
  def valid_shorts, do: @valid_shorts
  def valid_ints, do: @valid_ints
  def valid_longs, do: @valid_longs
  def valid_unsigned_bytes, do: @valid_unsigned_bytes
  def valid_unsigned_shorts, do: @valid_unsigned_shorts
  def valid_unsigned_ints, do: @valid_unsigned_ints
  def valid_unsigned_longs, do: @valid_unsigned_longs
  def valid_floats, do: @valid_floats

  def invalid_integers, do: @basic_invalid_integers
  def invalid_non_negative_integers, do: @invalid_non_negative_integers
  def invalid_non_positive_integers, do: @invalid_non_positive_integers
  def invalid_positive_integers, do: @invalid_positive_integers
  def invalid_negative_integers, do: @invalid_negative_integers
  def invalid_bytes, do: @invalid_bytes
  def invalid_shorts, do: @invalid_shorts
  def invalid_ints, do: @invalid_ints
  def invalid_longs, do: @invalid_longs
  def invalid_unsigned_bytes, do: @invalid_unsigned_bytes
  def invalid_unsigned_shorts, do: @invalid_unsigned_shorts
  def invalid_unsigned_ints, do: @invalid_unsigned_ints
  def invalid_unsigned_longs, do: @invalid_unsigned_longs
  def invalid_floats, do: @invalid_floats
end
