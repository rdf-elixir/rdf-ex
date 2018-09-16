defmodule RDF.TermTest do
  use RDF.Test.Case

  doctest RDF.Term

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
end
