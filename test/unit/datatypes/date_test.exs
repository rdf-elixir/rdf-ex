defmodule RDF.DateTest do
  use RDF.Datatype.Test.Case, datatype: RDF.Date, id: RDF.NS.XSD.date,
    valid: %{
    # input              => { value                      , lexical                    , canonicalized }
      ~D[2010-01-01]     => {  ~D[2010-01-01]            , nil                , "2010-01-01"       },
      "2010-01-01"       => {  ~D[2010-01-01]            , nil                , "2010-01-01"       },
      "2010-01-01Z"      => { {~D[2010-01-01], "Z"}      , nil                , "2010-01-01Z"      },
      "2010-01-01+00:00" => { {~D[2010-01-01], "Z"}      , "2010-01-01+00:00" , "2010-01-01Z"      },
      "2010-01-01-00:00" => { {~D[2010-01-01], "-00:00"} , nil                , "2010-01-01-00:00" },
      "2010-01-01+01:00" => { {~D[2010-01-01], "+01:00"} , nil                , "2010-01-01+01:00" },
      "2009-12-31-01:00" => { {~D[2009-12-31], "-01:00"} , nil                , "2009-12-31-01:00" },
      "2014-09-01-08:00" => { {~D[2014-09-01], "-08:00"} , nil                , "2014-09-01-08:00" },
# TODO: DateTime doesn't support negative years (at least with the iso8601 conversion functions)
#      "-2010-01-01Z"     => {  ~D[-2010-01-01]           , nil                , "-2010-01-01Z"     },
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
      ) ++ [true, false, 2010, 3.14, "2010-01-01Z foo", "foo 2010-01-01Z"]


  describe "equality" do
    test "two literals are equal when they have the same datatype and lexical form" do
      [
        { ~D[2010-01-01] , "2010-01-01" },
      ]
      |> Enum.each(fn {l, r} ->
           assert Date.new(l) == Date.new(r)
         end)
    end

    test "two literals with same value but different lexical form are not equal" do
      [
        { ~D[2010-01-01]     , "2010-01-01Z"      },
        { ~D[2010-01-01]     , "2010-01-01+00:00" },
        { "2010-01-01"       , "00:00:00Z"        },
        { "2010-01-01+00:00" , "00:00:00Z"        },
        { "2010-01-01-00:00" , "00:00:00Z"        },
        { "2010-01-01+00:00" , "00:00:00"         },
        { "2010-01-01-00:00" , "00:00:00"         },
      ]
      |> Enum.each(fn {l, r} ->
           assert Date.new(l) != Date.new(r)
         end)
    end
  end

end
