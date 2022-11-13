defmodule RDF.Namespace.IRITest do
  use RDF.Test.Case

  doctest RDF.Namespace.IRI

  import RDF.Namespace.IRI

  alias RDF.TestNamespaces.SimpleNS

  describe "term_to_iri/1" do
    test "with a property function from a vocabulary namespace" do
      assert term_to_iri(EX.foo()) == EX.foo()
      assert term_to_iri(RDF.NS.OWL.sameAs()) == RDF.NS.OWL.sameAs()
    end

    test "with a term atom from a RDF.Namespace" do
      assert term_to_iri(SimpleNS.foo()) == ~I<http://example.com/foo>
      assert term_to_iri(SimpleNS.Baz) == ~I<http://example.com/Baz>
    end

    test "with a term atom from a RDF.Vocabulary.Namespace" do
      assert term_to_iri(EX.Foo) == RDF.iri(EX.Foo)
    end

    test "constant function calls from non-vocabulary namespace module results in a compile error" do
      assert_raise ArgumentError, "Mix is not a RDF.Namespace", fn ->
        ast =
          quote do
            import RDF.Guards

            term_to_iri(Mix.env())
          end

        Code.eval_quoted(ast, [], __ENV__)
      end
    end

    test "other forms result in a compile error" do
      assert_raise ArgumentError,
                   "forbidden expression in RDF.Namespace.IRI.term_to_iri/1 call: var",
                   fn ->
                     ast =
                       quote do
                         import RDF.Guards
                         var = ~I<http://example.com>
                         term_to_iri(var)
                       end

                     Code.eval_quoted(ast, [], __ENV__)
                   end
    end

    test "in pattern matches" do
      assert term_to_iri(EX.Foo) = RDF.iri(EX.Foo)
      assert term_to_iri(EX.foo()) = RDF.iri(EX.foo())
    end

    test "in function clause pattern matches" do
      fun = fn
        term_to_iri(EX.Foo) -> :Foo
        term_to_iri(EX.bar()) -> :bar
        _ -> :unexpected
      end

      assert fun.(RDF.iri(EX.Foo)) == :Foo
      assert fun.(EX.bar()) == :bar
    end

    test "in case pattern matches" do
      assert (case EX.foo() do
                term_to_iri(EX.foo()) -> "match"
                _ -> {:mismatch, term_to_iri(EX.foo())}
              end) == "match"

      assert (case RDF.iri(EX.Bar) do
                term_to_iri(EX.Bar) -> "match"
                _ -> {:mismatch, term_to_iri(EX.Bar)}
              end) == "match"
    end
  end
end
