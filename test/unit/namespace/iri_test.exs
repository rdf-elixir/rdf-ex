defmodule RDF.Namespace.IRITest do
  use RDF.Test.Case

  doctest RDF.Namespace.IRI

  import RDF.Namespace.IRI

  describe "term_to_iri/1" do
    test "with a property function from a vocabulary namespace" do
      assert term_to_iri(EX.foo()) == EX.foo()
      assert term_to_iri(RDF.NS.OWL.sameAs()) == RDF.NS.OWL.sameAs()
    end

    test "with a term atom from a vocabulary namespace" do
      assert term_to_iri(EX.Foo) == RDF.iri(EX.Foo)
    end

    test "constant function calls from non-vocabulary namespace module results in a compile error" do
      assert_raise ArgumentError, ~r[forbidden expression in RDF.Guard.term_to_iri/1], fn ->
        ast =
          quote do
            import RDF.Guards

            term_to_iri(Mix.env())
          end

        Code.eval_quoted(ast, [], __ENV__)
      end
    end

    test "other forms result in a compile error" do
      assert_raise ArgumentError, ~r[forbidden expression in RDF.Guard.term_to_iri/1], fn ->
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
