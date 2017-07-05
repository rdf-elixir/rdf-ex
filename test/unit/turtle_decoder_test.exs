defmodule RDF.Turtle.DecoderTest do
  use ExUnit.Case, async: false

  doctest RDF.Turtle.Decoder

  import RDF.Sigils

  alias RDF.{Turtle, Graph, TestData}
  alias RDF.NS.{XSD}


  use RDF.Vocabulary.Namespace

  defvocab EX,
    base_uri: "http://example.org/#",
    terms: [], strict: false

  defvocab P,
    base_uri: "http://www.perceive.net/schemas/relationship/",
    terms: [], strict: false


  test "an empty string is deserialized to an empty graph" do
    assert Turtle.Decoder.decode!("") == Graph.new
    assert Turtle.Decoder.decode!("  \n\r\r\n  ") == Graph.new
  end

  test "a single triple with URIs" do
    assert Turtle.Decoder.decode!("""
      <http://example.org/#Person> <http://xmlns.com/foaf/0.1/name> "Aaron Swartz" .
    """) == Graph.new({EX.Person, ~I<http://xmlns.com/foaf/0.1/name>, "Aaron Swartz"})
  end

  test "decoding a single triple with a blank node" do
    assert Turtle.Decoder.decode!("""
      _:foo <http://example.org/#p> <http://example.org/#O> .
      """) == Graph.new({RDF.bnode("foo"), EX.p, EX.O})
    assert Turtle.Decoder.decode!("""
      <http://example.org/#S> <http://example.org/#p> _:1 .
      """) == Graph.new({EX.S, EX.p, RDF.bnode("1")})
    assert Turtle.Decoder.decode!("""
      _:foo <http://example.org/#p> _:bar .
      """) == Graph.new({RDF.bnode("foo"), EX.p, RDF.bnode("bar")})
  end

  test "decoding a single triple with an untyped string literal" do
    assert Turtle.Decoder.decode!("""
      <http://example.org/#spiderman> <http://www.perceive.net/schemas/relationship/realname> "Peter Parker" .
      """) == Graph.new({EX.spiderman, P.realname, RDF.literal("Peter Parker")})
  end

  test "decoding a single triple with an untyped long quoted string literal" do
    assert Turtle.Decoder.decode!("""
      <http://example.org/#spiderman> <http://www.perceive.net/schemas/relationship/realname> '''Peter Parker''' .
      """) == Graph.new({EX.spiderman, P.realname, RDF.literal("Peter Parker")})
  end

  test "decoding a single triple with a typed literal" do
    assert Turtle.Decoder.decode!("""
      <http://example.org/#spiderman> <http://example.org/#p> "42"^^<http://www.w3.org/2001/XMLSchema#integer> .
      """) == Graph.new({EX.spiderman, EX.p, RDF.literal(42)})
  end

  test "decoding a single triple with a language tagged literal" do
    assert Turtle.Decoder.decode!("""
      <http://example.org/#S> <http://example.org/#p> "foo"@en .
      """) == Graph.new({EX.S, EX.p, RDF.literal("foo", language: "en")})
  end

  test "decoding a single triple with a '@prefix' or '@base' language tagged literal" do
    assert Turtle.Decoder.decode!("""
      <http://example.org/#S> <http://example.org/#p> "foo"@prefix .
      """) == Graph.new({EX.S, EX.p, RDF.literal("foo", language: "prefix")})

    assert Turtle.Decoder.decode!("""
      <http://example.org/#S> <http://example.org/#p> "foo"@base .
      """) == Graph.new({EX.S, EX.p, RDF.literal("foo", language: "base")})
  end


  test "decoding multiple triples" do
    assert Turtle.Decoder.decode!("""
      <http://example.org/#S1> <http://example.org/#p1> <http://example.org/#O1> .
      <http://example.org/#S1> <http://example.org/#p2> <http://example.org/#O2> .
      """) == Graph.new([
        {EX.S1, EX.p1, EX.O1},
        {EX.S1, EX.p2, EX.O2},
      ])
    assert Turtle.Decoder.decode!("""
      <http://example.org/#S1> <http://example.org/#p1> <http://example.org/#O1> .
      <http://example.org/#S1> <http://example.org/#p2> <http://example.org/#O2> .
      <http://example.org/#S2> <http://example.org/#p3> <http://example.org/#O3> .
      """) == Graph.new([
        {EX.S1, EX.p1, EX.O1},
        {EX.S1, EX.p2, EX.O2},
        {EX.S2, EX.p3, EX.O3}
      ])
  end


  test "a statement with the 'a' keyword" do
    assert Turtle.Decoder.decode!("""
      <http://example.org/#Aaron> a <http://example.org/#Person> .
    """) == Graph.new({EX.Aaron, RDF.type, EX.Person})
  end

  test "a statement with a blank node via []" do
    assert Turtle.Decoder.decode!("""
      [] <http://xmlns.com/foaf/0.1/name> "Aaron Swartz" .
    """) == Graph.new({RDF.bnode("b0"), ~I<http://xmlns.com/foaf/0.1/name>, "Aaron Swartz"})

    assert Turtle.Decoder.decode!("""
      <http://example.org/#Foo> <http://example.org/#bar> [] .
    """) == Graph.new({EX.Foo, EX.bar, RDF.bnode("b0")})

    assert Turtle.Decoder.decode!("""
      <http://example.org/#Foo> <http://example.org/#bar> [    ] .
    """) == Graph.new({EX.Foo, EX.bar, RDF.bnode("b0")})
  end

  test "a statement with a boolean" do
    assert Turtle.Decoder.decode!("""
      <http://example.org/#Foo> <http://example.org/#bar> true .
    """) == Graph.new({EX.Foo, EX.bar, RDF.Boolean.new(true)})
    assert Turtle.Decoder.decode!("""
      <http://example.org/#Foo> <http://example.org/#bar> false .
    """) == Graph.new({EX.Foo, EX.bar, RDF.Boolean.new(false)})
  end

  test "a statement with an integer" do
    assert Turtle.Decoder.decode!("""
      <http://example.org/#Foo> <http://example.org/#bar> 42 .
    """) == Graph.new({EX.Foo, EX.bar, RDF.Integer.new(42)})
  end

  test "a statement with a decimal" do
    assert Turtle.Decoder.decode!("""
      <http://example.org/#Foo> <http://example.org/#bar> 3.14 .
    """) == Graph.new({EX.Foo, EX.bar, RDF.Literal.new("3.14", datatype: XSD.decimal)})
  end

  test "a statement with a double" do
    assert Turtle.Decoder.decode!("""
      <http://example.org/#Foo> <http://example.org/#bar> 1.2e3 .
    """) == Graph.new({EX.Foo, EX.bar, RDF.Double.new("1.2e3")})
  end

  test "a statement with multiple objects" do
    assert Turtle.Decoder.decode!("""
      <http://example.org/#Foo> <http://example.org/#bar> "baz", 1, true .
    """) == Graph.new([
              {EX.Foo, EX.bar, "baz"},
              {EX.Foo, EX.bar, 1},
              {EX.Foo, EX.bar, true},
            ])
  end

  test "a statement with multiple predications" do
    assert Turtle.Decoder.decode!("""
      <http://example.org/#Foo> <http://example.org/#bar> "baz";
                                <http://example.org/#baz> 42 .
    """) == Graph.new([
              {EX.Foo, EX.bar, "baz"},
              {EX.Foo, EX.baz, 42},
            ])
  end

  test "a statement with a blank node property list on object position" do
    assert Turtle.Decoder.decode!("""
      <http://example.org/#Foo> <http://example.org/#bar> [ <http://example.org/#baz> 42 ] .
    """) == Graph.new([
              {EX.Foo, EX.bar, RDF.bnode("b0")},
              {RDF.bnode("b0"), EX.baz, 42},
            ])
  end

  test "a statement with a blank node property list on subject position" do
    assert Turtle.Decoder.decode!("""
      [ <http://example.org/#baz> 42 ] <http://example.org/#bar> false .
    """) == Graph.new([
              {RDF.bnode("b0"), EX.baz, 42},
              {RDF.bnode("b0"), EX.bar, false},
            ])
  end

  test "a single blank node property list" do
    assert Turtle.Decoder.decode!("[ <http://example.org/#foo> 42 ] .") ==
            Graph.new([{RDF.bnode("b0"), EX.foo, 42}])
  end

  test "a statement with prefixed names" do
    assert Turtle.Decoder.decode!("""
      @prefix ex: <http://example.org/#> .
      ex:Aaron <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> ex:Person .
    """) == Graph.new({EX.Aaron, RDF.type, EX.Person})

    assert Turtle.Decoder.decode!("""
      @prefix  ex:  <http://example.org/#> .
      ex:Aaron <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> ex:Person .
    """) == Graph.new({EX.Aaron, RDF.type, EX.Person})

    assert Turtle.Decoder.decode!("""
      PREFIX ex: <http://example.org/#>
      ex:Aaron <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> ex:Person .
    """) == Graph.new({EX.Aaron, RDF.type, EX.Person})

    assert Turtle.Decoder.decode!("""
      prefix ex: <http://example.org/#>
      ex:Aaron <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> ex:Person .
    """) == Graph.new({EX.Aaron, RDF.type, EX.Person})

  end

  test "a statement with an empty prefixed name" do
    assert Turtle.Decoder.decode!("""
      @prefix : <http://example.org/#> .
      :Aaron <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> :Person .
    """) == Graph.new({EX.Aaron, RDF.type, EX.Person})

    assert Turtle.Decoder.decode!("""
      PREFIX : <http://example.org/#>
      :Aaron <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> :Person .
    """) == Graph.new({EX.Aaron, RDF.type, EX.Person})
  end

  test "a statement with a collection" do
    assert Turtle.Decoder.decode!("""
      @prefix : <http://example.org/#> .
      :subject :predicate ( :a :b :c ) .
    """) == Graph.new([
      {EX.subject, EX.predicate, RDF.bnode("b0")},
      {RDF.bnode("b0"), RDF.first, EX.a},
      {RDF.bnode("b0"), RDF.rest, RDF.bnode("b1")},
      {RDF.bnode("b1"), RDF.first, EX.b},
      {RDF.bnode("b1"), RDF.rest, RDF.bnode("b2")},
      {RDF.bnode("b2"), RDF.first, EX.c},
      {RDF.bnode("b2"), RDF.rest, RDF.nil},
    ])
  end

  test "a statement with an empty collection" do
    assert Turtle.Decoder.decode!("""
      @prefix : <http://example.org/#> .
      :subject :predicate () .
    """) == Graph.new({EX.subject, EX.predicate, RDF.nil})
  end


  test "decoding comments" do
    assert Turtle.Decoder.decode!("# just a comment") == Graph.new

    assert Turtle.Decoder.decode!("""
      <http://example.org/#S> <http://example.org/#p> _:1 . # a comment
      """) == Graph.new({EX.S, EX.p, RDF.bnode("1")})

    assert Turtle.Decoder.decode!("""
      # a comment
      <http://example.org/#S> <http://example.org/#p> <http://example.org/#O> .
      """) == Graph.new({EX.S, EX.p, EX.O})

    assert Turtle.Decoder.decode!("""
      <http://example.org/#S> <http://example.org/#p> <http://example.org/#O> .
      # a comment
      """) == Graph.new({EX.S, EX.p, EX.O})

    assert Turtle.Decoder.decode!("""
      # Header line 1
      # Header line 2
      <http://example.org/#S1> <http://example.org/#p1> <http://example.org/#O1> .
      # 1st comment
      <http://example.org/#S1> <http://example.org/#p2> <http://example.org/#O2> . # 2nd comment
      # last comment
      """) == Graph.new([
        {EX.S1, EX.p1, EX.O1},
        {EX.S1, EX.p2, EX.O2},
      ])
  end

  test "empty lines" do
    assert Turtle.Decoder.decode!("""

      <http://example.org/#spiderman> <http://www.perceive.net/schemas/relationship/enemyOf> <http://example.org/#green_goblin> .
      """) == Graph.new({EX.spiderman, P.enemyOf, EX.green_goblin})

    assert Turtle.Decoder.decode!("""
      <http://example.org/#spiderman> <http://www.perceive.net/schemas/relationship/enemyOf> <http://example.org/#green_goblin> .

      """) == Graph.new({EX.spiderman, P.enemyOf, EX.green_goblin})

    assert Turtle.Decoder.decode!("""

      <http://example.org/#S1> <http://example.org/#p1> <http://example.org/#O1> .


      <http://example.org/#S1> <http://example.org/#p2> <http://example.org/#O2> .

      """) == Graph.new([
        {EX.S1, EX.p1, EX.O1},
        {EX.S1, EX.p2, EX.O2},
      ])
  end

end
