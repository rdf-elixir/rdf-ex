defmodule RDF.DataTest do
  use RDF.Test.Case

  describe "RDF.Data protocol implementation of RDF.Description" do
    setup do
      {:ok,
        description: Description.new(EX.S, [
          {EX.p1, [EX.O1, EX.O2]},
          {EX.p2, EX.O3},
          {EX.p3, [~B<foo>, ~L"bar"]},
        ])
      }
    end

    test "delete", %{description: description} do
      assert RDF.Data.delete(description, {EX.S, EX.p1, EX.O2}) ==
              Description.delete(description, {EX.S, EX.p1, EX.O2})

      assert RDF.Data.delete(description, {EX.Other, EX.p1, EX.O2}) == description
    end

    test "deleting a Description with a different subject does nothing", %{description: description} do
      assert RDF.Data.delete(description,
              %Description{description | subject: EX.Other}) == description
    end

    test "pop", %{description: description} do
      assert RDF.Data.pop(description) == Description.pop(description)
    end

    test "include?", %{description: description} do
      assert RDF.Data.include?(description, {EX.S, EX.p1, EX.O2})
      refute RDF.Data.include?(description, {EX.Other, EX.p1, EX.O2})
    end

    test "statements", %{description: description} do
      assert RDF.Data.statements(description) == Description.statements(description)
    end

    test "subjects", %{description: description} do
      assert RDF.Data.subjects(description) == MapSet.new([uri(EX.S)])
    end

    test "predicates", %{description: description} do
      assert RDF.Data.predicates(description) == MapSet.new([EX.p1, EX.p2, EX.p3])
    end

    test "objects", %{description: description} do
      assert RDF.Data.objects(description) ==
              MapSet.new([uri(EX.O1), uri(EX.O2), uri(EX.O3), ~B<foo>])
    end

    test "resources", %{description: description} do
      assert RDF.Data.resources(description) ==
              MapSet.new([uri(EX.S), EX.p1, EX.p2, EX.p3, uri(EX.O1), uri(EX.O2), uri(EX.O3), ~B<foo>])
    end

    test "subject_count", %{description: description} do
      assert RDF.Data.subject_count(description) == 1
    end

    test "statement_count", %{description: description} do
      assert RDF.Data.statement_count(description) == 5
    end
  end

end
