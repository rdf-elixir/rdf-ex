defmodule RDF.Turtle.DecoderTest do
  use ExUnit.Case, async: false

  doctest RDF.Turtle.Decoder

  import RDF.Sigils

  alias RDF.{Turtle, Graph}
  alias RDF.NS.{XSD}


  use RDF.Vocabulary.Namespace

  defvocab EX,
    base_iri: "http://example.org/#",
    terms: [], strict: false

  defvocab P,
    base_iri: "http://www.perceive.net/schemas/relationship/",
    terms: [], strict: false


  test "an empty string is deserialized to an empty graph" do
    assert Turtle.Decoder.decode!("") == Graph.new
    assert Turtle.Decoder.decode!("  \n\r\r\n  ") == Graph.new
  end

  test "comments" do
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


  describe "statements" do
    test "a N-Triple-style statement" do
      assert Turtle.Decoder.decode!(
          "<http://example.org/#Aaron> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://example.org/#Person> ."
        ) == Graph.new({EX.Aaron, RDF.type, EX.Person})
    end

    test "a statement with the 'a' keyword" do
      assert Turtle.Decoder.decode!("""
        <http://example.org/#Aaron> a <http://example.org/#Person> .
      """) == Graph.new({EX.Aaron, RDF.type, EX.Person})
    end

    test "multiple N-Triple-style statement" do
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

    test "statement with multiple objects" do
      assert Turtle.Decoder.decode!("""
        <http://example.org/#Foo> <http://example.org/#bar> "baz", 1, true .
      """) == Graph.new([
                {EX.Foo, EX.bar, "baz"},
                {EX.Foo, EX.bar, 1},
                {EX.Foo, EX.bar, true},
              ])
    end

    test "statement with multiple predications" do
      assert Turtle.Decoder.decode!("""
        <http://example.org/#Foo> <http://example.org/#bar> "baz";
                                  <http://example.org/#baz> 42 .
      """) == Graph.new([
                {EX.Foo, EX.bar, "baz"},
                {EX.Foo, EX.baz, 42},
              ])
    end
  end

  describe "blank node property lists" do
    test "blank node property list on object position" do
      assert Turtle.Decoder.decode!("""
        <http://example.org/#Foo> <http://example.org/#bar> [ <http://example.org/#baz> 42 ] .
      """) == Graph.new([
                {EX.Foo, EX.bar, RDF.bnode("b0")},
                {RDF.bnode("b0"), EX.baz, 42},
              ])
    end

    test "blank node property list on subject position" do
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

    test "nested blank node property list" do
      assert Turtle.Decoder.decode!("""
        [ <http://example.org/#p1> [ <http://example.org/#p2> <http://example.org/#o2> ] ; <http://example.org/#p> <http://example.org/#o> ].
      """) == Graph.new([
                {RDF.bnode("b0"), EX.p1, RDF.bnode("b1")},
                {RDF.bnode("b1"), EX.p2, EX.o2},
                {RDF.bnode("b0"), EX.p,  EX.o},
              ])
    end

    test "blank node via []" do
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
  end


  test "blank node" do
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

  describe "quoted literals" do
    test "an untyped string literal" do
      assert Turtle.Decoder.decode!("""
        <http://example.org/#spiderman> <http://www.perceive.net/schemas/relationship/realname> "Peter Parker" .
        """) == Graph.new({EX.spiderman, P.realname, RDF.literal("Peter Parker")})
    end

    test "an untyped long quoted string literal" do
      assert Turtle.Decoder.decode!("""
        <http://example.org/#spiderman> <http://www.perceive.net/schemas/relationship/realname> '''Peter Parker''' .
        """) == Graph.new({EX.spiderman, P.realname, RDF.literal("Peter Parker")})
    end

    test "a typed literal" do
      assert Turtle.Decoder.decode!("""
        <http://example.org/#spiderman> <http://example.org/#p> "42"^^<http://www.w3.org/2001/XMLSchema#integer> .
        """) == Graph.new({EX.spiderman, EX.p, RDF.literal(42)})
    end

    test "a typed literal with type as a prefixed name" do
      assert Turtle.Decoder.decode!("""
        PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
        <http://example.org/#spiderman> <http://example.org/#p> "42"^^xsd:integer .
        """) == Graph.new({EX.spiderman, EX.p, RDF.literal(42)}, prefixes: %{xsd: XSD})
    end

    test "a language tagged literal" do
      assert Turtle.Decoder.decode!("""
        <http://example.org/#S> <http://example.org/#p> "foo"@en .
        """) == Graph.new({EX.S, EX.p, RDF.literal("foo", language: "en")})
    end

    test "a '@prefix' or '@base' language tagged literal" do
      assert Turtle.Decoder.decode!("""
        <http://example.org/#S> <http://example.org/#p> "foo"@prefix .
        """) == Graph.new({EX.S, EX.p, RDF.literal("foo", language: "prefix")})

      assert Turtle.Decoder.decode!("""
        <http://example.org/#S> <http://example.org/#p> "foo"@base .
        """) == Graph.new({EX.S, EX.p, RDF.literal("foo", language: "base")})
    end
  end

  describe "shorthand literals" do
    test "boolean" do
      assert Turtle.Decoder.decode!("""
        <http://example.org/#Foo> <http://example.org/#bar> true .
      """) == Graph.new({EX.Foo, EX.bar, RDF.Boolean.new(true)})
      assert Turtle.Decoder.decode!("""
        <http://example.org/#Foo> <http://example.org/#bar> false .
      """) == Graph.new({EX.Foo, EX.bar, RDF.Boolean.new(false)})
    end

    test "integer" do
      assert Turtle.Decoder.decode!("""
        <http://example.org/#Foo> <http://example.org/#bar> 42 .
      """) == Graph.new({EX.Foo, EX.bar, RDF.Integer.new(42)})
    end

    test "decimal" do
      assert Turtle.Decoder.decode!("""
        <http://example.org/#Foo> <http://example.org/#bar> 3.14 .
      """) == Graph.new({EX.Foo, EX.bar, RDF.Literal.new("3.14", datatype: XSD.decimal)})
    end

    test "double" do
      assert Turtle.Decoder.decode!("""
        <http://example.org/#Foo> <http://example.org/#bar> 1.2e3 .
      """) == Graph.new({EX.Foo, EX.bar, RDF.Double.new("1.2e3")})
    end
  end


  describe "prefixed names" do
    test "non-empty prefixed names" do
      prefixes = RDF.PrefixMap.new(ex: ~I<http://example.org/#>)
      assert Turtle.Decoder.decode!("""
        @prefix ex: <http://example.org/#> .
        ex:Aaron <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> ex:Person .
      """) == Graph.new({EX.Aaron, RDF.type, EX.Person}, prefixes: prefixes)

      assert Turtle.Decoder.decode!("""
        @prefix  ex:  <http://example.org/#> .
        ex:Aaron <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> ex:Person .
      """) == Graph.new({EX.Aaron, RDF.type, EX.Person}, prefixes: prefixes)

      assert Turtle.Decoder.decode!("""
        PREFIX ex: <http://example.org/#>
        ex:Aaron <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> ex:Person .
      """) == Graph.new({EX.Aaron, RDF.type, EX.Person}, prefixes: prefixes)

      assert Turtle.Decoder.decode!("""
        prefix ex: <http://example.org/#>
        ex:Aaron <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> ex:Person .
      """) == Graph.new({EX.Aaron, RDF.type, EX.Person}, prefixes: prefixes)
    end

    test "empty prefixed name" do
      prefixes = RDF.PrefixMap.new("": ~I<http://example.org/#>)
      assert Turtle.Decoder.decode!("""
        @prefix : <http://example.org/#> .
        :Aaron <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> :Person .
      """) == Graph.new({EX.Aaron, RDF.type, EX.Person}, prefixes: prefixes)

      assert Turtle.Decoder.decode!("""
        PREFIX : <http://example.org/#>
        :Aaron <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> :Person .
      """) == Graph.new({EX.Aaron, RDF.type, EX.Person}, prefixes: prefixes)
    end
  end

  describe "collections" do
    test "non-empty collection" do
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
      ], prefixes: %{"": ~I<http://example.org/#>})
    end

    test "empty collection" do
      assert Turtle.Decoder.decode!("""
        @prefix : <http://example.org/#> .
        :subject :predicate () .
      """) == Graph.new({EX.subject, EX.predicate, RDF.nil}, prefixes: %{"": ~I<http://example.org/#>})
    end

    test "nested collection" do
      assert Turtle.Decoder.decode!("""
        @prefix : <http://example.org/#> .
        :subject :predicate ( :a (:b :c) ) .
      """) == Graph.new([
        {EX.subject, EX.predicate, RDF.bnode("b0")},
        {RDF.bnode("b0"), RDF.first, EX.a},
        {RDF.bnode("b0"), RDF.rest, RDF.bnode("b3")},
        {RDF.bnode("b3"), RDF.first, RDF.bnode("b1")},
        {RDF.bnode("b3"), RDF.rest, RDF.nil},

        {RDF.bnode("b1"), RDF.first, EX.b},
        {RDF.bnode("b1"), RDF.rest, RDF.bnode("b2")},
        {RDF.bnode("b2"), RDF.first, EX.c},
        {RDF.bnode("b2"), RDF.rest, RDF.nil},
      ], prefixes: %{"": ~I<http://example.org/#>})
    end
  end


  describe "relative IRIs" do
    test "without explicit in-doc base and no document_base option option given" do
      assert_raise RuntimeError, fn ->
        Turtle.Decoder.decode!(
          "<#Aaron> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <#Person> .")
      end
    end

    test "without explicit in-doc base, but document_base option given" do
      assert Turtle.Decoder.decode!("""
        <#Aaron> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <#Person> .
      """, base: "http://example.org/") ==
        Graph.new({EX.Aaron, RDF.type, EX.Person}, base_iri: ~I<http://example.org/>)
    end

    test "with @base given" do
      assert Turtle.Decoder.decode!("""
        @base <http://example.org/> .
        <#Aaron> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <#Person> .
      """) == Graph.new({EX.Aaron, RDF.type, EX.Person}, base_iri: ~I<http://example.org/>)

      assert Turtle.Decoder.decode!("""
        @base <http://example.org/#> .
        <#Aaron> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <#Person> .
      """) == Graph.new({EX.Aaron, RDF.type, EX.Person}, base_iri: ~I<http://example.org/#>)
    end

    test "with BASE given" do
      assert Turtle.Decoder.decode!("""
        BASE <http://example.org/>
        <#Aaron> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <#Person> .
      """) == Graph.new({EX.Aaron, RDF.type, EX.Person}, base_iri: ~I<http://example.org/>)

      assert Turtle.Decoder.decode!("""
        base <http://example.org/#>
        <#Aaron> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <#Person> .
      """) == Graph.new({EX.Aaron, RDF.type, EX.Person}, base_iri: ~I<http://example.org/#>)
    end

    test "when a given base is itself relative" do
      assert_raise RuntimeError, fn ->
        Turtle.Decoder.decode!("""
          @base <foo> .
          <#Aaron> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <#Person> .
          """)
      end
      assert_raise RuntimeError, fn ->
        Turtle.Decoder.decode!(
          "<#Aaron> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <#Person> .",
          base: "foo")
      end
    end
  end

end
