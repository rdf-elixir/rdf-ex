defmodule RDF.Star.Turtle.EncoderTest do
  use RDF.Test.Case

  alias RDF.Turtle

  test "quoted triple on subject position" do
    assert RDF.graph({{EX.s(), EX.p(), EX.o()}, EX.q(), EX.z()}, prefixes: [nil: EX])
           |> Turtle.Encoder.encode!() ==
             """
             @prefix : <http://example.com/> .

             << :s :p :o >>
                 :q :z .
             """

    assert RDF.graph({{EX.s(), EX.p(), "foo"}, EX.q(), "foo"}, prefixes: [nil: EX])
           |> Turtle.Encoder.encode!() ==
             """
             @prefix : <http://example.com/> .

             << :s :p "foo" >>
                 :q "foo" .
             """
  end

  test "blank nodes in quoted triples" do
    assert RDF.graph({{EX.s(), EX.p(), ~B"foo"}, EX.q(), ~B"foo"}, prefixes: [nil: EX])
           |> Turtle.Encoder.encode!() ==
             """
             @prefix : <http://example.com/> .

             << :s :p _:foo >>
                 :q _:foo .
             """

    # TODO: _:foo could be encoded as []
    assert RDF.graph({{~B"foo", EX.p(), ~B"bar"}, EX.q(), ~B"baz"}, prefixes: [nil: EX])
           |> Turtle.Encoder.encode!() ==
             """
             @prefix : <http://example.com/> .

             << _:foo :p [] >>
                 :q [] .
             """
  end

  test "quoted triple on object position" do
    assert RDF.graph({EX.a(), EX.q(), {EX.s(), EX.p(), EX.o()}}, prefixes: [nil: EX])
           |> Turtle.Encoder.encode!() ==
             """
             @prefix : <http://example.com/> .

             :a
                 :q << :s :p :o >> .
             """
  end

  test "single annotation" do
    assert RDF.graph(
             [
               {EX.s(), EX.p(), EX.o()},
               {{EX.s(), EX.p(), EX.o()}, EX.q(), EX.z()}
             ],
             prefixes: [nil: EX]
           )
           |> Turtle.Encoder.encode!() ==
             """
             @prefix : <http://example.com/> .

             :s
                 :p :o {| :q :z |} .
             """

    assert RDF.graph(
             [
               {EX.s(), EX.p(), "foo"},
               {{EX.s(), EX.p(), "foo"}, EX.q(), "foo"}
             ],
             prefixes: [nil: EX]
           )
           |> Turtle.Encoder.encode!() ==
             """
             @prefix : <http://example.com/> .

             :s
                 :p "foo" {| :q "foo" |} .
             """

    assert RDF.graph(
             [
               {EX.s(), EX.p(), EX.o1()},
               {EX.s(), EX.p(), EX.o2()},
               {{EX.s(), EX.p(), EX.o2()}, EX.a(), EX.b()}
             ],
             prefixes: [nil: EX]
           )
           |> Turtle.Encoder.encode!() ==
             """
             @prefix : <http://example.com/> .

             :s
                 :p :o1,
                     :o2 {| :a :b |} .
             """
  end

  test "multiple annotations" do
    assert RDF.graph(
             [
               {EX.s(), EX.p(), EX.o()},
               {EX.s(), EX.p2(), EX.o2()},
               {EX.s(), EX.p2(), EX.o3()},
               {{EX.s(), EX.p(), EX.o()}, EX.a(), EX.b()},
               {{EX.s(), EX.p2(), EX.o2()}, EX.a2(), EX.b2()},
               {{EX.s(), EX.p2(), EX.o3()}, EX.a3(), EX.b3()}
             ],
             prefixes: [nil: EX]
           )
           |> Turtle.Encoder.encode!() ==
             """
             @prefix : <http://example.com/> .

             :s
                 :p :o {| :a :b |} ;
                 :p2 :o2 {| :a2 :b2 |},
                     :o3 {| :a3 :b3 |} .
             """
  end

  test "annotations with blank nodes" do
    assert RDF.graph(
             [
               {EX.s(), EX.p(), EX.o()},
               {~B"foo", EX.graph(), ~I<http://host1/>},
               {~B"foo", EX.date(), XSD.date("2020-01-20")},
               {~B"bar", EX.graph(), ~I<http://host2/>},
               {~B"bar", EX.date(), XSD.date("2020-12-31")},
               {{EX.s(), EX.p(), EX.o()}, EX.source(), ~B"foo"},
               {{EX.s(), EX.p(), EX.o()}, EX.source(), ~B"bar"}
             ],
             prefixes: [nil: EX, xsd: NS.XSD]
           )
           |> Turtle.Encoder.encode!() ==
             """
             @prefix : <http://example.com/> .
             @prefix xsd: <#{NS.XSD.__base_iri__()}> .

             :s
                 :p :o {| :source [
                             :date "2020-12-31"^^xsd:date ;
                             :graph <http://host2/>
                         ], [
                             :date "2020-01-20"^^xsd:date ;
                             :graph <http://host1/>
                         ] |} .
             """
  end

  test "nested annotations" do
    assert RDF.graph(
             [
               {EX.s(), EX.p(), EX.o()},
               {{EX.s(), EX.p(), EX.o()}, EX.a(), EX.b()},
               {{{EX.s(), EX.p(), EX.o()}, EX.a(), EX.b()}, EX.a2(), EX.b2()},
               {{{{EX.s(), EX.p(), EX.o()}, EX.a(), EX.b()}, EX.a2(), EX.b2()}, EX.a3(), EX.b3()}
             ],
             prefixes: [nil: EX]
           )
           |> Turtle.Encoder.encode!() ==
             """
             @prefix : <http://example.com/> .

             :s
                 :p :o {| :a :b {| :a2 :b2 {| :a3 :b3 |} |} |} .
             """

    # test for a nested annotation where an inner annotation is moved inside the CompactGraph before the outer
    # Since every map with less than Erlang's configured MAP_SMALL_MAP_LIMIT number of elements behaves
    # ordered in Erlang, this case won't happen for smaller graphs, so, we're creating a graph with a
    # sufficiently large number of triples that this case will happen very likely.
    series = 1..99

    assert """
           @prefix : <http://example.com/> .

           :s
           """ <> predications =
             Enum.flat_map(series, fn i ->
               [
                 {EX.s(), apply(EX, String.to_atom("p#{i}"), []), i},
                 {{EX.s(), apply(EX, String.to_atom("p#{i}"), []), i}, EX.a(), EX.b()},
                 {{{EX.s(), apply(EX, String.to_atom("p#{i}"), []), i}, EX.a(), EX.b()}, EX.a2(),
                  EX.b2()},
                 {
                   {
                     {{EX.s(), apply(EX, String.to_atom("p#{i}"), []), i}, EX.a(), EX.b()},
                     EX.a2(),
                     EX.b2()
                   },
                   EX.a34(),
                   EX.b3()
                 },
                 {
                   {
                     {
                       {{EX.s(), apply(EX, String.to_atom("p#{i}"), []), i}, EX.a(), EX.b()},
                       EX.a2(),
                       EX.b2()
                     },
                     EX.a34(),
                     EX.b3()
                   },
                   EX.a34(),
                   EX.b4()
                 }
               ]
             end)
             |> RDF.graph(prefixes: [nil: EX])
             |> Turtle.Encoder.encode!()

    Enum.each(series, fn i ->
      assert predications =~
               "    :p#{i} #{i} {| :a :b {| :a2 :b2 {| :a34 :b3 {| :a34 :b4 |} |} |} |}"
    end)
  end

  test "quoted triple in annotation" do
    assert RDF.graph(
             [
               {EX.s(), EX.p(), EX.o()},
               {{EX.s(), EX.p(), EX.o()}, EX.r(), {EX.s1(), EX.p1(), EX.o1()}}
             ],
             prefixes: [nil: EX]
           )
           |> Turtle.Encoder.encode!() ==
             """
             @prefix : <http://example.com/> .

             :s
                 :p :o {| :r << :s1 :p1 :o1 >> |} .
             """
  end

  test "annotation of a statement with a quoted triple" do
    assert RDF.graph(
             [
               {{EX.s1(), EX.p1(), EX.o1()}, EX.p(), EX.o()},
               {{{EX.s1(), EX.p1(), EX.o1()}, EX.p(), EX.o()}, EX.r(), EX.z()}
             ],
             prefixes: [nil: EX]
           )
           |> Turtle.Encoder.encode!() ==
             """
             @prefix : <http://example.com/> .

             << :s1 :p1 :o1 >>
                 :p :o {| :r :z |} .
             """

    assert RDF.graph(
             [
               {EX.s(), EX.p(), {EX.s2(), EX.p2(), EX.o2()}},
               {{EX.s(), EX.p(), {EX.s2(), EX.p2(), EX.o2()}}, EX.r(), EX.z()}
             ],
             prefixes: [nil: EX]
           )
           |> Turtle.Encoder.encode!() ==
             """
             @prefix : <http://example.com/> .

             :s
                 :p << :s2 :p2 :o2 >> {| :r :z |} .
             """
  end

  test ":no_object_lists option" do
    assert RDF.graph(
             [
               {EX.s(), EX.p(), EX.o()},
               {~B"foo", EX.graph(), ~I<http://host1/>},
               {~B"foo", EX.date(), XSD.date("2020-01-20")},
               {~B"bar", EX.graph(), ~I<http://host2/>},
               {~B"bar", EX.date(), XSD.date("2020-12-31")},
               {{EX.s(), EX.p(), EX.o()}, EX.source(), ~B"foo"},
               {{EX.s(), EX.p(), EX.o()}, EX.source(), ~B"bar"},
               {EX.s2(), EX.p2(), EX.o1()},
               {EX.s2(), EX.p2(), EX.o2()},
               {{EX.s2(), EX.p2(), EX.o1()}, EX.q(), EX.z()},
               {{EX.s2(), EX.p2(), EX.o2()}, EX.q(), EX.z()}
             ],
             prefixes: [nil: EX, xsd: NS.XSD]
           )
           |> Turtle.Encoder.encode!(no_object_lists: true) ==
             """
             @prefix : <http://example.com/> .
             @prefix xsd: <#{NS.XSD.__base_iri__()}> .

             :s
                 :p :o {|
                         :source [
                             :date "2020-12-31"^^xsd:date ;
                             :graph <http://host2/>
                         ] ;
                         :source [
                             :date "2020-01-20"^^xsd:date ;
                             :graph <http://host1/>
                         ] |} .

             :s2
                 :p2 :o1 {|
                         :q :z |} ;
                 :p2 :o2 {|
                         :q :z |} .
             """
  end

  test ":line_prefix option" do
    assert RDF.graph(
             [
               {EX.s1(), EX.p(), EX.o()},
               {~B"foo", EX.graph(), ~I<http://host1/>},
               {~B"foo", EX.date(), XSD.date("2020-01-20")},
               {{EX.s1(), EX.p(), EX.o()}, EX.source(), ~B"foo"},
               {{EX.s1(), EX.p(), EX.o()}, EX.source(), 42},
               {EX.s2(), EX.p2(), EX.o1()},
               {EX.s2(), EX.p2(), EX.o2()},
               {{EX.s2(), EX.p2(), EX.o1()}, EX.q(), EX.z()},
               {{EX.s2(), EX.p2(), EX.o2()}, EX.q(), EX.z()}
             ],
             prefixes: [nil: EX, xsd: NS.XSD]
           )
           |> Turtle.Encoder.encode!(
             line_prefix: fn
               :triple, {{as, _, _}, _, _}, nil -> "AT#{as |> to_string() |> String.at(-1)} "
               :triple, {_s, _p, _o}, nil -> "T   "
               :description, {_, _, _}, nil -> "THIS SHOULD NOT HAPPEN"
               :description, subject, nil -> "D#{subject |> to_string() |> String.at(-1)}  "
               :closing, _, nil -> "C   "
             end
           ) ==
             """
             @prefix : <http://example.com/> .
             @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

             D1  :s1
             T       :p :o {|
             AT1             :source 42 ;
             AT1             :source [
             T                   :date "2020-01-20"^^xsd:date ;
             T                   :graph <http://host1/>
             C               ] |} .

             D2  :s2
             T       :p2 :o1 {|
             AT2             :q :z |} ;
             T       :p2 :o2 {|
             AT2             :q :z |} .
             """
  end
end
