defmodule RDF.StringTest do
  use RDF.Datatype.Test.Case, datatype: RDF.String, id: RDF.NS.XSD.string,
    valid: %{
    # input => { value   , lexical , canonicalized }
      "foo" => { "foo"   , nil     , "foo"   },
      0     => { "0"     , nil     , "0"     },
      42    => { "42"    , nil     , "42"    },
      3.14  => { "3.14"  , nil     , "3.14"  },
      true  => { "true"  , nil     , "true"  },
      false => { "false" , nil     , "false" },
    },
    invalid: []

end
