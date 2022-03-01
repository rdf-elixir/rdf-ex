defmodule RDF.ResourceId.GeneratorTest do
  use RDF.Test.Case

  doctest RDF.Resource.Generator

  alias RDF.Resource.Generator

  test "RDF.BlankNode as a generator" do
    assert %BlankNode{} = bnode1 = Generator.generate(BlankNode.generator_config(), nil)
    assert %BlankNode{} = bnode2 = Generator.generate(BlankNode.generator_config(), nil)
    assert bnode1 != bnode2
  end

  test "RDF.BlankNode.Generator as a generator" do
    {:ok, generator} = start_supervised({RDF.BlankNode.Generator, RDF.BlankNode.Increment})

    assert RDF.BlankNode.Generator.generator_config(generator)
           |> Generator.generate(nil) ==
             RDF.bnode(0)

    assert RDF.BlankNode.Generator.generator_config(generator)
           |> Generator.generate(nil) ==
             RDF.bnode(1)

    assert RDF.BlankNode.Generator.generator_config(:foo)
           |> Generator.generate(generator) ==
             RDF.bnode(2)
  end
end
