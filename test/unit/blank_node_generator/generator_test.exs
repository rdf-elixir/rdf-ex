defmodule RDF.BlankNode.GeneratorTest do
  use RDF.Test.Case

  import RDF, only: [bnode: 1]

  alias RDF.BlankNode.Generator
  alias RDF.BlankNode.Generator.{Increment, Random}

  describe "Increment generator" do
    test "generator without prefix" do
      {:ok, generator} = start_supervised({Generator, Increment})

      assert Generator.generate(generator) == bnode(0)
      assert Generator.generate(generator) == bnode(1)
      assert Generator.generate_for(generator, "foo") == bnode(2)
      assert Generator.generate(generator) == bnode(3)
      assert Generator.generate_for(generator, "bar") == bnode(4)
      assert Generator.generate(generator) == bnode(5)
      assert Generator.generate_for(generator, "foo") == bnode(2)
      assert Generator.generate(generator) == bnode(6)
    end

    test "generator with prefix" do
      {:ok, generator} = start_supervised({Generator, [algorithm: Increment, prefix: "b"]})

      assert Generator.generate(generator) == bnode("b0")
      assert Generator.generate(generator) == bnode("b1")
      assert Generator.generate_for(generator, "foo") == bnode("b2")
      assert Generator.generate(generator) == bnode("b3")
      assert Generator.generate_for(generator, "bar") == bnode("b4")
      assert Generator.generate(generator) == bnode("b5")
      assert Generator.generate_for(generator, "foo") == bnode("b2")
      assert Generator.generate(generator) == bnode("b6")
    end

    test "generator with non-string values" do
      {:ok, generator} = start_supervised({Generator, [algorithm: Increment, prefix: "b"]})

      assert Generator.generate(generator) == bnode("b0")
      assert Generator.generate(generator) == bnode("b1")
      assert Generator.generate_for(generator, {:foo, 42}) == bnode("b2")
      assert Generator.generate(generator) == bnode("b3")
      assert Generator.generate_for(generator, [:bar, 3.14]) == bnode("b4")
      assert Generator.generate(generator) == bnode("b5")
      assert Generator.generate_for(generator, {:foo, 42}) == bnode("b2")
      assert Generator.generate(generator) == bnode("b6")
    end

    test "named generator" do
      {:ok, _} = start_supervised({Generator, {Increment, [name: Foo]}})

      assert Generator.generate(Foo) == bnode(0)
      assert Generator.generate(Foo) == bnode(1)

      {:ok, _} =
        start_supervised({Generator, {[algorithm: Increment, prefix: "b"], [name: Bar]}}, id: :g2)

      assert Generator.generate(Bar) == bnode("b0")
      assert Generator.generate(Bar) == bnode("b1")
    end
  end

  describe "Random generator" do
    test "generator without prefix" do
      {:ok, generator} = start_supervised({Generator, Random})

      assert %RDF.BlankNode{} = bnode1 = Generator.generate(generator)
      assert %RDF.BlankNode{} = bnode2 = Generator.generate(generator)

      assert bnode1 != bnode2

      assert %RDF.BlankNode{} = bnode1 = Generator.generate_for(generator, "foo")
      assert Generator.generate_for(generator, "foo") == bnode1
      assert %RDF.BlankNode{} = bnode2 = Generator.generate_for(generator, "bar")

      assert bnode1 != bnode2
    end

    test "generator with prefix" do
      {:ok, generator} = start_supervised({Generator, [algorithm: Random, prefix: "b"]})

      assert %RDF.BlankNode{value: "b" <> _} = bnode1 = Generator.generate(generator)
      assert %RDF.BlankNode{value: "b" <> _} = bnode2 = Generator.generate(generator)

      assert bnode1 != bnode2
    end

    test "generator with non-string values" do
      {:ok, generator} = start_supervised({Generator, [algorithm: Random, prefix: "b"]})

      assert %RDF.BlankNode{} = bnode = Generator.generate_for(generator, {:foo, 42})
      assert Generator.generate_for(generator, {:foo, 42}) == bnode
    end
  end
end
