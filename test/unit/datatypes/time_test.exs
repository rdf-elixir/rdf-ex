defmodule RDF.TimeTest do
  use RDF.Datatype.Test.Case, datatype: RDF.Time, id: RDF.NS.XSD.time,
    valid: %{
    # input               => { value                     , lexical             , canonicalized }
      ~T[00:00:00]        => {  ~T[00:00:00]             , nil                 , "00:00:00" },
      ~T[00:00:00.123]    => {  ~T[00:00:00.123]         , nil                 , "00:00:00.123" },
      "00:00:00"          => {  ~T[00:00:00]             , nil                 , "00:00:00" },
      "00:00:00.123"      => {  ~T[00:00:00.123]         , nil                 , "00:00:00.123" },
      "00:00:00Z"         => { {~T[00:00:00], true }     , nil                 , "00:00:00Z" },
      "00:00:00.1234Z"    => { {~T[00:00:00.1234], true }, nil                 , "00:00:00.1234Z" },
      "00:00:00.0000Z"    => { {~T[00:00:00.0000], true }, nil                 , "00:00:00.0000Z" },
      "00:00:00+00:00"    => { {~T[00:00:00], true }     , "00:00:00+00:00"    , "00:00:00Z" },
      "01:00:00+01:00"    => { {~T[00:00:00], true }     , "01:00:00+01:00"    , "00:00:00Z" },
      "23:00:00-01:00"    => { {~T[00:00:00], true }     , "23:00:00-01:00"    , "00:00:00Z" },
      "23:00:00.45-01:00" => { {~T[00:00:00.45], true }  , "23:00:00.45-01:00" , "00:00:00.45Z" },
    },
    invalid: ~w(
        foo
        +2010-01-01Z
        2010-01-01TFOO
        02010-01-01
        2010-1-1
        0000-01-01
        2011-07
        2011
      ) ++ [true, false, 2010, 3.14, "00:00:00Z foo", "foo 00:00:00Z"]


  test "conversion with time zones" do
    [
      { "01:00:00+01:00", ~T[00:00:00] },
      { "01:00:00-01:00", ~T[02:00:00] },
      { "01:00:00-00:01", ~T[01:01:00] },
      { "01:00:00+00:01", ~T[00:59:00] },
      { "00:00:00+01:30", ~T[22:30:00] },
      { "23:00:00-02:30", ~T[01:30:00] },
    ]
    |> Enum.each(fn {input, output} ->
         assert RDF.Time.convert(input, %{}) == {output, true}
    end)
  end

  describe "equality" do
    test "two literals are equal when they have the same datatype and lexical form" do
      [
        { ~T[00:00:00] , "00:00:00" },
      ]
      |> Enum.each(fn {l, r} ->
           assert Time.new(l) == Time.new(r)
         end)
    end

    test "two literals with same value but different lexical form are not equal" do
      [
        { ~T[00:00:00]     , "00:00:00Z" },
        { "00:00:00"       , "00:00:00Z" },
        { "00:00:00.0000"  , "00:00:00Z" },
        { "00:00:00.0000Z" , "00:00:00Z" },
        { "00:00:00+00:00" , "00:00:00Z" },
      ]
      |> Enum.each(fn {l, r} ->
           assert Time.new(l) != Time.new(r)
         end)
    end
  end

  describe "cast/1" do
    test "casting a time returns the input as it is" do
      assert RDF.time("01:00:00") |> RDF.Time.cast() ==
             RDF.time("01:00:00")
    end

    test "casting a string" do
      assert RDF.string("01:00:00") |> RDF.Time.cast() ==
               RDF.time("01:00:00")
      assert RDF.string("01:00:00Z") |> RDF.Time.cast() ==
               RDF.time("01:00:00Z")
      assert RDF.string("01:00:00+01:00") |> RDF.Time.cast() ==
               RDF.time("01:00:00+01:00")
    end

    test "casting a datetime" do
      assert RDF.date_time("2010-01-01T01:00:00") |> RDF.Time.cast() ==
               RDF.time("01:00:00")
      assert RDF.date_time("2010-01-01T00:00:00Z") |> RDF.Time.cast() ==
               RDF.time("00:00:00Z")
      assert RDF.date_time("2010-01-01T00:00:00+00:00") |> RDF.Time.cast() ==
               RDF.time("00:00:00Z")
      assert RDF.date_time("2010-01-01T23:00:00+01:00") |> RDF.Time.cast() ==
               RDF.time("23:00:00+01:00")
    end

    test "with invalid literals" do
      assert RDF.time("25:00:00") |> RDF.Time.cast() == nil
      assert RDF.date_time("02010-01-01T00:00:00") |> RDF.Time.cast() == nil
    end

    test "with literals of unsupported datatypes" do
      assert RDF.false |> RDF.Time.cast() == nil
      assert RDF.integer(1) |> RDF.Time.cast() == nil
      assert RDF.decimal(3.14) |> RDF.Time.cast() == nil
    end

    test "with non-RDF terms" do
      assert RDF.Time.cast(:foo) == nil
    end
  end

end
