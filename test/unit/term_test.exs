defmodule RDF.TermTest do
  use RDF.Test.Case

  doctest RDF.Term

  alias Decimal, as: D

  describe "coerce/1" do
    test "with RDF.IRI" do
      assert RDF.Term.coerce(~I<http://example.com/>) == ~I<http://example.com/>
    end

    test "with RDF.BlankNode" do
      assert RDF.Term.coerce(~B<foo>) == ~B<foo>
    end

    test "with RDF.Literal" do
      assert RDF.Term.coerce(~L"foo") == ~L"foo"
    end

    test "with a resolvable vocabulary namespace term atom" do
      assert RDF.Term.coerce(EX.Foo) == RDF.iri(EX.Foo)
    end

    test "with a non-resolvable atom" do
      refute RDF.Term.coerce(nil)
      refute RDF.Term.coerce(Foo)
      refute RDF.Term.coerce(:foo)
    end

    test "with boolean" do
      assert RDF.Term.coerce(true) == XSD.true
      assert RDF.Term.coerce(false) == XSD.false
    end

    test "with string" do
      assert RDF.Term.coerce("foo") == ~L"foo"
    end

    test "with integer" do
      assert RDF.Term.coerce(42) == XSD.integer(42)
    end

    test "with float" do
      assert RDF.Term.coerce(3.14) == XSD.double(3.14)
    end

    test "with decimal" do
      assert D.from_float(3.14) |> RDF.Term.coerce() == XSD.decimal(3.14)
    end

    test "with datetime" do
      assert DateTime.from_iso8601("2002-04-02T12:00:00+00:00") |> elem(1) |> RDF.Term.coerce() ==
             DateTime.from_iso8601("2002-04-02T12:00:00+00:00") |> elem(1) |> XSD.datetime()
      assert ~N"2002-04-02T12:00:00" |> RDF.Term.coerce() ==
             ~N"2002-04-02T12:00:00" |> XSD.datetime()
    end

    test "with date" do
      assert ~D"2002-04-02" |> RDF.Term.coerce() ==
             ~D"2002-04-02" |> XSD.date()
    end

    test "with time" do
      assert ~T"12:00:00" |> RDF.Term.coerce() ==
             ~T"12:00:00" |> XSD.time()
    end

    test "with reference" do
      ref = make_ref()
      assert RDF.Term.coerce(ref) == RDF.bnode(ref)
    end

    test "with inconvertible values" do
      assert self() |> RDF.Term.coerce() == nil
    end
  end

  describe "value/1" do
    test "with RDF.IRI" do
      assert RDF.Term.value(~I<http://example.com/>) == "http://example.com/"
    end

    test "with RDF.BlankNode" do
      assert RDF.Term.value(~B<foo>) == "_:foo"
    end

    test "with a valid RDF.Literal" do
      assert RDF.Term.value(~L"foo") == "foo"
    end

    test "with an invalid RDF.Literal" do
      assert XSD.integer("foo") |> RDF.Term.value() == "foo"
    end

    test "with a resolvable vocabulary namespace term atom" do
      assert RDF.Term.value(EX.Foo) == EX.Foo |> RDF.iri() |> to_string()
    end

    test "with a non-resolvable atom" do
      refute RDF.Term.value(nil)
      refute RDF.Term.value(Foo)
      refute RDF.Term.value(:foo)
    end

    test "with boolean" do
      assert RDF.Term.value(true) == true
      assert RDF.Term.value(false) == false
    end

    test "with string" do
      assert RDF.Term.value("foo") == "foo"
    end

    test "with integer" do
      assert RDF.Term.value(42) == 42
    end

    test "with float" do
      assert RDF.Term.value(3.14) == 3.14
    end

    test "with decimal" do
      assert D.from_float(3.14) |> RDF.Term.value() == D.from_float(3.14)
    end

    test "with datetime" do
      assert DateTime.from_iso8601("2002-04-02T12:00:00+00:00") |> elem(1) |> RDF.Term.value() ==
             DateTime.from_iso8601("2002-04-02T12:00:00+00:00") |> elem(1)
      assert ~N"2002-04-02T12:00:00" |> RDF.Term.value() == ~N"2002-04-02T12:00:00"
    end

    test "with date" do
      assert ~D"2002-04-02" |> RDF.Term.value() == ~D"2002-04-02"
    end

    test "with time" do
      assert ~T"12:00:00" |> RDF.Term.value() == ~T"12:00:00"
    end

    test "with reference" do
      ref = make_ref()
      assert RDF.Term.value(ref) == ref
    end

    test "with inconvertible values" do
      assert self() |> RDF.Term.value() == nil
    end
  end
end
