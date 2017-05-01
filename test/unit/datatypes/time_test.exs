defmodule RDF.TimeTest do
  use RDF.Datatype.Test.Case, datatype: RDF.Time, id: RDF.NS.XSD.time,
    valid: %{
    # input            => { value                 , lexical          , canonicalized }
      ~T[00:00:00]     => {  ~T[00:00:00]         , nil              , "00:00:00" },
      "00:00:00"       => {  ~T[00:00:00]         , nil              , "00:00:00" },
      "00:00:00Z"      => { {~T[00:00:00], true } , nil              , "00:00:00Z" },
      "00:00:00.0000Z" => { {~T[00:00:00], true } , "00:00:00.0000Z" , "00:00:00Z" },
      "00:00:00+00:00" => { {~T[00:00:00], true } , "00:00:00+00:00" , "00:00:00Z" },
      "01:00:00+01:00" => { {~T[00:00:00], true } , "01:00:00+01:00" , "00:00:00Z" },
      "23:00:00-01:00" => { {~T[00:00:00], true } , "23:00:00-01:00" , "00:00:00Z" },
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

end
