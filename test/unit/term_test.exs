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

    test "with boolean" do
      assert RDF.Term.coerce(true) == RDF.true
      assert RDF.Term.coerce(false) == RDF.false
    end

    test "with string" do
      assert RDF.Term.coerce("foo") == ~L"foo"
    end

    test "with integer" do
      assert RDF.Term.coerce(42) == RDF.integer(42)
    end

    test "with float" do
      assert RDF.Term.coerce(3.14) == RDF.double(3.14)
    end

    test "with decimal" do
      assert D.new(3.14) |> RDF.Term.coerce() == RDF.decimal(3.14)
    end

    test "with datetime" do
      assert DateTime.from_iso8601("2002-04-02T12:00:00+00:00") |> elem(1) |> RDF.Term.coerce() ==
             DateTime.from_iso8601("2002-04-02T12:00:00+00:00") |> elem(1) |> RDF.datetime()
      assert ~N"2002-04-02T12:00:00" |> RDF.Term.coerce() ==
             ~N"2002-04-02T12:00:00" |> RDF.datetime()
    end

    test "with date" do
      assert ~D"2002-04-02" |> RDF.Term.coerce() ==
             ~D"2002-04-02" |> RDF.date()
    end

    test "with time" do
      assert ~T"12:00:00" |> RDF.Term.coerce() ==
             ~T"12:00:00" |> RDF.time()
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
      assert RDF.integer("foo") |> RDF.Term.value() == "foo"
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
      assert D.new(3.14) |> RDF.Term.value() == D.new(3.14)
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
