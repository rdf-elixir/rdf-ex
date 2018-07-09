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
    invalid: [],
    allow_language: true

  describe "new" do
    test "when given a language tag it produces a rdf:langString" do
      assert RDF.String.new("foo", language: "en") ==
             RDF.LangString.new("foo", language: "en")
    end
  end

  describe "new!" do
    test "when given a language tag it produces a rdf:langString" do
      assert RDF.String.new!("foo", language: "en") ==
             RDF.LangString.new!("foo", language: "en")
    end
  end

end
