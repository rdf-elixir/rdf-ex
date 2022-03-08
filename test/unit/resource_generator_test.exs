defmodule RDF.ResourceId.GeneratorTest do
  use RDF.Test.Case

  doctest RDF.Resource.Generator

  alias RDF.Resource.Generator

  describe "RDF.BlankNode as a generator" do
    test "generate/0" do
      assert %BlankNode{} = bnode1 = Generator.generate(generator: BlankNode)
      assert %BlankNode{} = bnode2 = Generator.generate(generator: BlankNode)
      assert bnode1 != bnode2
    end

    test "generate/1" do
      assert_raise Generator.ConfigError, fn ->
        Generator.generate([generator: BlankNode], "test1")
      end
    end
  end

  describe "RDF.BlankNode.Generator as a generator" do
    test "generate/0" do
      {:ok, generator} = start_supervised({RDF.BlankNode.Generator, RDF.BlankNode.Increment})

      config = [generator: BlankNode.Generator, pid: generator]

      assert Generator.generate(config) == RDF.bnode(0)
      assert Generator.generate(config) == RDF.bnode(1)
    end

    test "generate/1" do
      {:ok, generator} = start_supervised({RDF.BlankNode.Generator, RDF.BlankNode.Increment})

      config = [generator: BlankNode.Generator, pid: generator]

      assert Generator.generate(config, "test1") == RDF.bnode(0)
      assert Generator.generate(config, "test2") == RDF.bnode(1)
      assert Generator.generate(config, "test1") == RDF.bnode(0)
    end
  end
end
