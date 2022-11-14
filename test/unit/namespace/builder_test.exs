defmodule RDF.Namespace.BuilderTest do
  use RDF.Test.Case

  alias RDF.Namespace.Builder
  import RDF.Sigils

  @compile {:no_warn_undefined, ToplevelNS}

  describe "create/3" do
    test "creates a module" do
      assert {:ok, {:module, ToplevelNS, _, _}} =
               Builder.create(
                 ToplevelNS,
                 [foo: ~I<http://example.com/foo>],
                 Macro.Env.location(__ENV__)
               )

      assert Elixir.ToplevelNS.foo() == ~I<http://example.com/foo>
    end

    test "terms with invalid characters" do
      %{
        number_at_start: "42foo",
        colon: "foo:",
        bracket: "f(oo",
        square_bracket: "f[oo"
      }
      |> Enum.each(fn {label, invalid_term} ->
        assert Builder.create(
                 :"NamespaceWithInvalidCharacter#{label}",
                 [{invalid_term, ~I<http://example.com/invalid>}],
                 Macro.Env.location(__ENV__)
               ) ==
                 {:error,
                  %RDF.Namespace.InvalidTermError{
                    message: "invalid term: #{inspect(invalid_term)}"
                  }}
      end)
    end

    test "terms with a special meaning for Elixir" do
      Enum.each(Builder.reserved_terms(), fn invalid_term ->
        assert Builder.create(
                 :"NamespaceWithInvalidTerm#{invalid_term}",
                 [{invalid_term, ~I<http://example.com/invalid>}],
                 Macro.Env.location(__ENV__)
               ) ==
                 {:error,
                  %RDF.Namespace.InvalidTermError{
                    message: "invalid term: #{inspect(invalid_term)}"
                  }}
      end)
    end
  end
end
