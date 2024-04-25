defmodule RDF.TriG.DecoderTest do
  use ExUnit.Case, async: false

  doctest RDF.TriG.Decoder

  import RDF.Sigils

  alias RDF.{TriG, Dataset, Graph, NS, XSD}

  use RDF.Vocabulary.Namespace

  defvocab EX, base_iri: "http://example.org/#", terms: [], strict: false

  defvocab P, base_iri: "http://www.perceive.net/schemas/relationship/", terms: [], strict: false

  test "an empty string is deserialized to an empty graph" do
    assert TriG.Decoder.decode!("") == Dataset.new()
    assert TriG.Decoder.decode!("  \n\r\r\n  ") == Dataset.new()
  end

  test "comments" do
    assert TriG.Decoder.decode!("# just a comment") == Dataset.new()

    assert TriG.Decoder.decode!("""
           { <http://example.org/#S> <http://example.org/#p> _:1 . }# a comment
           """) == Dataset.new({EX.S, EX.p(), RDF.bnode("1")})

    assert TriG.Decoder.decode!("""
           # a comment
           <http://example.org/#S> <http://example.org/#p> <http://example.org/#O> .
           """) == Dataset.new({EX.S, EX.p(), EX.O})

    assert TriG.Decoder.decode!("""
           <http://example.org/#S> <http://example.org/#p> <http://example.org/#O> .
           # a comment
           """) == Dataset.new({EX.S, EX.p(), EX.O})

    assert TriG.Decoder.decode!("""
           # Header line 1
           # Header line 2
           { <http://example.org/#S1> <http://example.org/#p1> <http://example.org/#O1> . }
           # 1st comment
           <http://example.org/#S1> <http://example.org/#p2> <http://example.org/#O2> . # 2nd comment
           # last comment
           """) ==
             Dataset.new([
               {EX.S1, EX.p1(), EX.O1},
               {EX.S1, EX.p2(), EX.O2}
             ])
  end

  test "empty lines" do
    assert TriG.Decoder.decode!("""

           <http://example.org/#spiderman> <http://www.perceive.net/schemas/relationship/enemyOf> <http://example.org/#green_goblin> .
           """) == Dataset.new({EX.spiderman(), P.enemyOf(), EX.green_goblin()})

    assert TriG.Decoder.decode!("""
           { <http://example.org/#spiderman> <http://www.perceive.net/schemas/relationship/enemyOf> <http://example.org/#green_goblin> . }

           """) == Dataset.new({EX.spiderman(), P.enemyOf(), EX.green_goblin()})

    assert TriG.Decoder.decode!("""

           <http://example.org/#S1> <http://example.org/#p1> <http://example.org/#O1> .


           { <http://example.org/#S1> <http://example.org/#p2> <http://example.org/#O2> . }

           """) ==
             Dataset.new([
               {EX.S1, EX.p1(), EX.O1},
               {EX.S1, EX.p2(), EX.O2}
             ])
  end

  describe "statements" do
    test "a N-Triple-style statement" do
      assert TriG.Decoder.decode!(
               "<http://example.org/#Aaron> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://example.org/#Person> ."
             ) == Dataset.new({EX.Aaron, RDF.type(), EX.Person})
    end

    test "a N-Triples-style statement in a default graph block" do
      assert TriG.Decoder.decode!(
               "{ <http://example.org/#Aaron> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://example.org/#Person> . }"
             ) == Dataset.new({EX.Aaron, RDF.type(), EX.Person})

      assert TriG.Decoder.decode!(
               "{ <http://example.org/#Aaron> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://example.org/#Person> }"
             ) == Dataset.new({EX.Aaron, RDF.type(), EX.Person})
    end

    test "a N-Triples-style statement in a named graph block" do
      assert TriG.Decoder.decode!(
               "<http://example.org/#Graph> { <http://example.org/#Aaron> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://example.org/#Person> . }"
             ) == Dataset.new({EX.Aaron, RDF.type(), EX.Person, EX.Graph})

      assert TriG.Decoder.decode!(
               "<http://example.org/#Graph> { <http://example.org/#Aaron> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://example.org/#Person> }"
             ) == Dataset.new({EX.Aaron, RDF.type(), EX.Person, EX.Graph})

      assert """
             <http://example.org/#Graph> {
               <http://example.org/#Aaron> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://example.org/#Person>  .
             }
             """
             |> TriG.Decoder.decode!() == Dataset.new({EX.Aaron, RDF.type(), EX.Person, EX.Graph})
    end

    test "a N-Triples-style statement in a GRAPH block" do
      assert TriG.Decoder.decode!(
               "GRAPH <http://example.org/#Graph> { <http://example.org/#Aaron> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://example.org/#Person> . }"
             ) == Dataset.new({EX.Aaron, RDF.type(), EX.Person, EX.Graph})

      assert TriG.Decoder.decode!(
               "Graph <http://example.org/#Graph> { <http://example.org/#Aaron> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://example.org/#Person> }"
             ) == Dataset.new({EX.Aaron, RDF.type(), EX.Person, EX.Graph})

      assert """
             GRAPH <http://example.org/#Graph>
             {
               <http://example.org/#Aaron> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://example.org/#Person>  .
             }
             """
             |> TriG.Decoder.decode!() == Dataset.new({EX.Aaron, RDF.type(), EX.Person, EX.Graph})

      assert """
             graph <http://example.org/#Graph> {
               <http://example.org/#Aaron> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://example.org/#Person>
             }
             """
             |> TriG.Decoder.decode!() == Dataset.new({EX.Aaron, RDF.type(), EX.Person, EX.Graph})
    end

    test "a statement with the 'a' keyword" do
      assert TriG.Decoder.decode!(
               "<http://example.org/#Graph> { <http://example.org/#Aaron> a <http://example.org/#Person> }"
             ) == Dataset.new({EX.Aaron, RDF.type(), EX.Person, EX.Graph})
    end

    test "multiple N-Triples-style statements in multiple blocks" do
      assert """
             GRAPH <http://example.org/#Graph> {
               <http://example.org/#S1> <http://example.org/#p1> <http://example.org/#O1> .
               <http://example.org/#S1> <http://example.org/#p2> <http://example.org/#O2> .
             }
             """
             |> TriG.Decoder.decode!() ==
               Dataset.new([
                 {EX.S1, EX.p1(), EX.O1, EX.Graph},
                 {EX.S1, EX.p2(), EX.O2, EX.Graph}
               ])

      assert """
             <http://example.org/#Graph> {
               <http://example.org/#S1> <http://example.org/#p1> <http://example.org/#O1> .
               <http://example.org/#S1> <http://example.org/#p2> <http://example.org/#O2>
             }
             """
             |> TriG.Decoder.decode!() ==
               Dataset.new([
                 {EX.S1, EX.p1(), EX.O1, EX.Graph},
                 {EX.S1, EX.p2(), EX.O2, EX.Graph}
               ])

      assert """
             {
               <http://example.org/#S1> <http://example.org/#p1> <http://example.org/#O1> .
               <http://example.org/#S1> <http://example.org/#p1> <http://example.org/#O2>
             }

             GRAPH <http://example.org/#Graph>{
               <http://example.org/#S1> <http://example.org/#p1> <http://example.org/#O3> .
               <http://example.org/#S1> <http://example.org/#p1> <http://example.org/#O4> .
             }

             <http://example.org/#S1> <http://example.org/#p2> <http://example.org/#O5> .
             """
             |> TriG.Decoder.decode!() ==
               Dataset.new([
                 {EX.S1, EX.p1(), EX.O1},
                 {EX.S1, EX.p1(), EX.O2},
                 {EX.S1, EX.p1(), EX.O3, EX.Graph},
                 {EX.S1, EX.p1(), EX.O4, EX.Graph},
                 {EX.S1, EX.p2(), EX.O5}
               ])
    end

    test "statement with multiple objects" do
      assert TriG.Decoder.decode!("""
               { <http://example.org/#Foo> <http://example.org/#bar> "baz", 1, true . }
             """) ==
               Dataset.new([
                 {EX.Foo, EX.bar(), "baz"},
                 {EX.Foo, EX.bar(), 1},
                 {EX.Foo, EX.bar(), true}
               ])
    end

    test "statement with multiple predications" do
      assert """
             GRAPH <http://example.org/#Graph> {
               <http://example.org/#Foo> <http://example.org/#bar> "baz";
                                         <http://example.org/#baz> 42 .
             }
             """
             |> TriG.Decoder.decode!() ==
               Dataset.new([
                 {EX.Foo, EX.bar(), "baz", EX.Graph},
                 {EX.Foo, EX.baz(), 42, EX.Graph}
               ])
    end
  end

  describe "blank node property lists" do
    test "blank node property list on object position" do
      assert TriG.Decoder.decode!("""
               <http://example.org/#Foo> <http://example.org/#bar> [ <http://example.org/#baz> 42 ] .
             """) ==
               Dataset.new([
                 {EX.Foo, EX.bar(), RDF.bnode("b0")},
                 {RDF.bnode("b0"), EX.baz(), 42}
               ])

      assert TriG.Decoder.decode!("""
               { <http://example.org/#Foo> <http://example.org/#bar> [ <http://example.org/#baz> 42 ] }
             """) ==
               Dataset.new([
                 {EX.Foo, EX.bar(), RDF.bnode("b0")},
                 {RDF.bnode("b0"), EX.baz(), 42}
               ])

      assert TriG.Decoder.decode!("""
               <http://example.org/#Graph> { <http://example.org/#Foo> <http://example.org/#bar> [ <http://example.org/#baz> 42 ] . }
             """) ==
               Dataset.new([
                 {EX.Foo, EX.bar(), RDF.bnode("b0"), EX.Graph},
                 {RDF.bnode("b0"), EX.baz(), 42, EX.Graph}
               ])

      assert TriG.Decoder.decode!("""
               GRAPH <http://example.org/#Graph> { <http://example.org/#Foo> <http://example.org/#bar> [ <http://example.org/#baz> 42 ] . }
             """) ==
               Dataset.new([
                 {EX.Foo, EX.bar(), RDF.bnode("b0"), EX.Graph},
                 {RDF.bnode("b0"), EX.baz(), 42, EX.Graph}
               ])
    end

    test "blank node property list on subject position" do
      assert TriG.Decoder.decode!("""
               [ <http://example.org/#baz> 42 ] <http://example.org/#bar> false .
             """) ==
               Dataset.new([
                 {RDF.bnode("b0"), EX.baz(), 42},
                 {RDF.bnode("b0"), EX.bar(), false}
               ])

      assert TriG.Decoder.decode!("""
               { [ <http://example.org/#baz> 42 ] <http://example.org/#bar> false . }
             """) ==
               Dataset.new([
                 {RDF.bnode("b0"), EX.baz(), 42},
                 {RDF.bnode("b0"), EX.bar(), false}
               ])

      assert TriG.Decoder.decode!("""
               <http://example.org/#Graph> { [ <http://example.org/#baz> 42 ] <http://example.org/#bar> false }
             """) ==
               Dataset.new([
                 {RDF.bnode("b0"), EX.baz(), 42, EX.Graph},
                 {RDF.bnode("b0"), EX.bar(), false, EX.Graph}
               ])

      assert TriG.Decoder.decode!("""
               GRAPH <http://example.org/#Graph> { [ <http://example.org/#baz> 42 ] <http://example.org/#bar> false }
             """) ==
               Dataset.new([
                 {RDF.bnode("b0"), EX.baz(), 42, EX.Graph},
                 {RDF.bnode("b0"), EX.bar(), false, EX.Graph}
               ])
    end

    test "a single blank node property list" do
      assert TriG.Decoder.decode!("[ <http://example.org/#foo> 42 ] .") ==
               Dataset.new([{RDF.bnode("b0"), EX.foo(), 42}])

      assert TriG.Decoder.decode!("{ [ <http://example.org/#foo> 42 ] }") ==
               Dataset.new([{RDF.bnode("b0"), EX.foo(), 42}])

      assert TriG.Decoder.decode!(
               "GRAPH <http://example.org/#Graph> { [ <http://example.org/#foo> 42 ] }"
             ) ==
               Dataset.new([{RDF.bnode("b0"), EX.foo(), 42, EX.Graph}])

      assert TriG.Decoder.decode!(
               "<http://example.org/#Graph> { [ <http://example.org/#foo> 42 ] }"
             ) ==
               Dataset.new([{RDF.bnode("b0"), EX.foo(), 42, EX.Graph}])
    end

    test "nested blank node property list" do
      assert TriG.Decoder.decode!("""
               [ <http://example.org/#p1> [ <http://example.org/#p2> <http://example.org/#o2> ] ; <http://example.org/#p> <http://example.org/#o> ].
             """) ==
               Dataset.new([
                 {RDF.bnode("b0"), EX.p1(), RDF.bnode("b1")},
                 {RDF.bnode("b1"), EX.p2(), EX.o2()},
                 {RDF.bnode("b0"), EX.p(), EX.o()}
               ])
    end

    test "blank node via []" do
      assert TriG.Decoder.decode!("""
               [] <http://xmlns.com/foaf/0.1/name> "Aaron Swartz" .
             """) ==
               Dataset.new({RDF.bnode("b0"), ~I<http://xmlns.com/foaf/0.1/name>, "Aaron Swartz"})

      assert TriG.Decoder.decode!("""
               { [  ] <http://xmlns.com/foaf/0.1/name> "Aaron Swartz" . }
             """) ==
               Dataset.new({RDF.bnode("b0"), ~I<http://xmlns.com/foaf/0.1/name>, "Aaron Swartz"})

      assert TriG.Decoder.decode!("""
               GRAPH <http://example.org/#Graph> { <http://example.org/#Foo> <http://example.org/#bar> [] . }
             """) == Dataset.new({EX.Foo, EX.bar(), RDF.bnode("b0"), EX.Graph})

      assert TriG.Decoder.decode!("""
               <http://example.org/#Graph> { <http://example.org/#Foo> <http://example.org/#bar> [    ] }
             """) == Dataset.new({EX.Foo, EX.bar(), RDF.bnode("b0"), EX.Graph})
    end
  end

  test "blank node" do
    assert TriG.Decoder.decode!("""
           { _:foo <http://example.org/#p> <http://example.org/#O> . }
           """) == Dataset.new({RDF.bnode("foo"), EX.p(), EX.O})

    assert TriG.Decoder.decode!("""
           <http://example.org/#S> <http://example.org/#p> _:1 .
           """) == Dataset.new({EX.S, EX.p(), RDF.bnode("1")})

    assert TriG.Decoder.decode!("""
           <http://example.org/#Graph> { _:foo <http://example.org/#p> _:bar . }
           """) == Dataset.new({RDF.bnode("foo"), EX.p(), RDF.bnode("bar"), EX.Graph})
  end

  describe "quoted literals" do
    test "an untyped string literal" do
      assert TriG.Decoder.decode!("""
             { <http://example.org/#spiderman> <http://www.perceive.net/schemas/relationship/realname> "Peter Parker" . }
             """) == Dataset.new({EX.spiderman(), P.realname(), RDF.literal("Peter Parker")})
    end

    test "an untyped long quoted string literal" do
      assert TriG.Decoder.decode!("""
             <http://example.org/#spiderman> <http://www.perceive.net/schemas/relationship/realname> '''Peter Parker''' .
             """) == Dataset.new({EX.spiderman(), P.realname(), RDF.literal("Peter Parker")})
    end

    test "a typed literal" do
      assert TriG.Decoder.decode!("""
             { <http://example.org/#spiderman> <http://example.org/#p> "42"^^<http://www.w3.org/2001/XMLSchema#integer> . }
             """) == Dataset.new({EX.spiderman(), EX.p(), RDF.literal(42)})
    end

    test "a typed literal with type as a prefixed name" do
      assert TriG.Decoder.decode!("""
             PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
             { <http://example.org/#spiderman> <http://example.org/#p> "42"^^xsd:integer . }
             """) ==
               Dataset.new({EX.spiderman(), EX.p(), RDF.literal(42)}, prefixes: %{xsd: NS.XSD})
    end

    test "a language tagged literal" do
      assert TriG.Decoder.decode!("""
             { <http://example.org/#S> <http://example.org/#p> "foo"@en . }
             """) == Dataset.new({EX.S, EX.p(), RDF.literal("foo", language: "en")})
    end

    test "a '@prefix' or '@base' language tagged literal" do
      assert TriG.Decoder.decode!("""
             <http://example.org/#S> <http://example.org/#p> "foo"@prefix .
             """) == Dataset.new({EX.S, EX.p(), RDF.literal("foo", language: "prefix")})

      assert TriG.Decoder.decode!("""
             <http://example.org/#S> <http://example.org/#p> "foo"@base .
             """) == Dataset.new({EX.S, EX.p(), RDF.literal("foo", language: "base")})
    end
  end

  describe "shorthand literals" do
    test "boolean" do
      assert TriG.Decoder.decode!("""
               <http://example.org/#Foo> <http://example.org/#bar> true .
             """) == Dataset.new({EX.Foo, EX.bar(), XSD.true()})

      assert TriG.Decoder.decode!("""
               { <http://example.org/#Foo> <http://example.org/#bar> false . }
             """) == Dataset.new({EX.Foo, EX.bar(), XSD.false()})
    end

    test "integer" do
      assert TriG.Decoder.decode!("""
               <http://example.org/#Graph> { <http://example.org/#Foo> <http://example.org/#bar> 42 }
             """) == Dataset.new({EX.Foo, EX.bar(), XSD.integer(42), EX.Graph})
    end

    test "decimal" do
      assert TriG.Decoder.decode!("""
               GRAPH <http://example.org/#Graph> { <http://example.org/#Foo> <http://example.org/#bar> 3.14 . }
             """) == Dataset.new({EX.Foo, EX.bar(), XSD.decimal("3.14"), EX.Graph})
    end

    test "double" do
      assert TriG.Decoder.decode!("""
               <http://example.org/#Foo> <http://example.org/#bar> 1.2e3 .
             """) == Dataset.new({EX.Foo, EX.bar(), XSD.double("1.2e3")})
    end
  end

  describe "prefixed names" do
    test "non-empty prefixed names" do
      prefixes = RDF.PrefixMap.new(ex: ~I<http://example.org/#>)

      assert TriG.Decoder.decode!("""
               @prefix ex: <http://example.org/#> .
               ex:Aaron <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> ex:Person .
             """) == Dataset.new({EX.Aaron, RDF.type(), EX.Person}, prefixes: prefixes)

      assert TriG.Decoder.decode!("""
               @prefix  ex:  <http://example.org/#> .
               { ex:Aaron <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> ex:Person . }
             """) ==
               Graph.new({EX.Aaron, RDF.type(), EX.Person}, prefixes: prefixes)
               |> Dataset.new()

      assert TriG.Decoder.decode!("""
               PREFIX ex: <http://example.org/#>
               <http://example.org/#Graph> { ex:Aaron <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> ex:Person . }
             """) == Dataset.new({EX.Aaron, RDF.type(), EX.Person, EX.Graph}, prefixes: prefixes)

      assert TriG.Decoder.decode!("""
               prefix ex: <http://example.org/#>
               GRAPH <http://example.org/#Graph> { ex:Aaron <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> ex:Person . }
             """) == Dataset.new({EX.Aaron, RDF.type(), EX.Person, EX.Graph}, prefixes: prefixes)
    end

    test "empty prefixed name" do
      prefixes = RDF.PrefixMap.new("": ~I<http://example.org/#>)

      assert TriG.Decoder.decode!("""
               @prefix : <http://example.org/#> .
               :Aaron <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> :Person .
             """) == Dataset.new({EX.Aaron, RDF.type(), EX.Person}, prefixes: prefixes)

      assert TriG.Decoder.decode!("""
               PREFIX : <http://example.org/#>
               { :Aaron <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> :Person . }
             """) == Dataset.new({EX.Aaron, RDF.type(), EX.Person}, prefixes: prefixes)
    end
  end

  describe "collections" do
    test "non-empty collection" do
      assert TriG.Decoder.decode!("""
               @prefix : <http://example.org/#> .
               :subject :predicate ( :a :b :c ) .
             """) ==
               Dataset.new(
                 [
                   {EX.subject(), EX.predicate(), RDF.bnode("b0")},
                   {RDF.bnode("b0"), RDF.first(), EX.a()},
                   {RDF.bnode("b0"), RDF.rest(), RDF.bnode("b1")},
                   {RDF.bnode("b1"), RDF.first(), EX.b()},
                   {RDF.bnode("b1"), RDF.rest(), RDF.bnode("b2")},
                   {RDF.bnode("b2"), RDF.first(), EX.c()},
                   {RDF.bnode("b2"), RDF.rest(), RDF.nil()}
                 ],
                 prefixes: %{"": ~I<http://example.org/#>}
               )
    end

    test "empty collection" do
      assert TriG.Decoder.decode!("""
               @prefix : <http://example.org/#> .
               { :subject :predicate () . }
             """) ==
               Dataset.new({EX.subject(), EX.predicate(), RDF.nil()},
                 prefixes: %{"": ~I<http://example.org/#>}
               )
    end

    test "nested collection" do
      assert TriG.Decoder.decode!("""
               @prefix : <http://example.org/#> .
               <http://example.org/#Graph> { :subject :predicate ( :a (:b :c) ) . }
             """) ==
               Dataset.new(
                 [
                   {EX.subject(), EX.predicate(), RDF.bnode("b0")},
                   {RDF.bnode("b0"), RDF.first(), EX.a()},
                   {RDF.bnode("b0"), RDF.rest(), RDF.bnode("b3")},
                   {RDF.bnode("b3"), RDF.first(), RDF.bnode("b1")},
                   {RDF.bnode("b3"), RDF.rest(), RDF.nil()},
                   {RDF.bnode("b1"), RDF.first(), EX.b()},
                   {RDF.bnode("b1"), RDF.rest(), RDF.bnode("b2")},
                   {RDF.bnode("b2"), RDF.first(), EX.c()},
                   {RDF.bnode("b2"), RDF.rest(), RDF.nil()}
                 ],
                 prefixes: %{"": ~I<http://example.org/#>},
                 graph: EX.Graph
               )
    end
  end

  describe "relative IRIs" do
    test "without explicit in-doc base and no document_base option option given" do
      assert_raise RuntimeError, fn ->
        TriG.Decoder.decode!(
          "<#Aaron> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <#Person> ."
        )
      end
    end

    test "without explicit in-doc base, but document_base option given" do
      assert TriG.Decoder.decode!(
               """
                 { <#Aaron> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <#Person> . }
               """,
               base: "http://example.org/"
             ) ==
               Graph.new({EX.Aaron, RDF.type(), EX.Person}, base_iri: ~I<http://example.org/>)
               |> Dataset.new()
    end

    test "with @base given" do
      assert TriG.Decoder.decode!("""
               @base <http://example.org/> .
               <#Aaron> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <#Person> .
             """) ==
               Graph.new({EX.Aaron, RDF.type(), EX.Person}, base_iri: ~I<http://example.org/>)
               |> Dataset.new()

      assert TriG.Decoder.decode!("""
               @base <http://example.org/#> .
               <http://example.org/#Graph> { <#Aaron> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <#Person> . }
             """) ==
               Graph.new({EX.Aaron, RDF.type(), EX.Person},
                 base_iri: ~I<http://example.org/#>,
                 name: EX.Graph
               )
               |> Dataset.new()
    end

    test "with BASE given" do
      assert TriG.Decoder.decode!("""
               BASE <http://example.org/>
               { <#Aaron> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <#Person> . }
             """) ==
               Graph.new({EX.Aaron, RDF.type(), EX.Person}, base_iri: ~I<http://example.org/>)
               |> Dataset.new()

      assert TriG.Decoder.decode!("""
               base <http://example.org/#>
               GRAPH <http://example.org/#Graph> { <#Aaron> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <#Person> . }
             """) ==
               Graph.new({EX.Aaron, RDF.type(), EX.Person},
                 base_iri: ~I<http://example.org/#>,
                 name: EX.Graph
               )
               |> Dataset.new()
    end

    test "when a given base is itself relative" do
      assert_raise RuntimeError, fn ->
        TriG.Decoder.decode!("""
        @base <foo> .
        <#Aaron> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <#Person> .
        """)
      end

      assert_raise RuntimeError, fn ->
        TriG.Decoder.decode!(
          "{ <#Aaron> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <#Person> . }",
          base: "foo"
        )
      end
    end
  end
end
