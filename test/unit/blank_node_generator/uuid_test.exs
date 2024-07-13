defmodule RDF.BlankNode.Generator.UUIDTest do
  use RDF.Test.Case

  import RDF, only: [bnode: 1]

  alias RDF.BlankNode.Generator.UUID

  describe "generate/1" do
    test "without prefix" do
      assert {%BlankNode{}, %UUID{}} = UUID.generate(%UUID{})
    end

    test "with prefix" do
      assert {%BlankNode{value: "b" <> _}, %UUID{prefix: "b"}} =
               UUID.generate(%UUID{prefix: "b"})
    end
  end

  describe "generate_for/2" do
    test "returns the same id for the same value" do
      assert {%BlankNode{value: "b12df7fcd25a15b2d84b9db6d881aefdc"}, %UUID{}} =
               UUID.generate_for(%UUID{}, "foo")

      assert UUID.generate_for(%UUID{}, "foo") ==
               UUID.generate_for(%UUID{}, "foo")

      assert UUID.generate_for(%UUID{}, {:foo, "foo", ~U[2024-07-13 02:21:45.085932Z]}) ==
               UUID.generate_for(%UUID{}, {:foo, "foo", ~U[2024-07-13 02:21:45.085932Z]})
    end

    test "with prefix" do
      assert {%BlankNode{value: "x03c964986571507facc25bcf9ae8e8a6"}, %UUID{prefix: "x"}} =
               UUID.generate_for(%UUID{prefix: "x"}, "bar")

      assert UUID.generate_for(%UUID{prefix: "x"}, "foo") ==
               {bnode("x12df7fcd25a15b2d84b9db6d881aefdc"), %UUID{prefix: "x"}}
    end
  end
end
