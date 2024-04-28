defmodule RDF.TurtleTriG.EncoderTest do
  use ExUnit.Case, async: false

  alias RDF.TurtleTriG

  doctest TurtleTriG.Encoder

  alias RDF.PrefixMap

  import RDF.Sigils

  use RDF.Vocabulary.Namespace

  defvocab EX, base_iri: "http://example.org/#", terms: [], strict: false

  describe "prefixed_name/2" do
    setup do
      {:ok,
       prefixes:
         PrefixMap.new(
           ex: EX,
           ex2: ~I<http://example.org/>
         )}
    end

    test "hash iri with existing prefix", %{prefixes: prefixes} do
      assert TurtleTriG.Encoder.prefixed_name(EX.foo(), prefixes) |> IO.iodata_to_binary() ==
               "ex:foo"
    end

    test "hash iri namespace without name", %{prefixes: prefixes} do
      assert TurtleTriG.Encoder.prefixed_name(RDF.iri(EX.__base_iri__()), prefixes)
             |> IO.iodata_to_binary() ==
               "ex:"
    end

    test "hash iri with non-existing prefix" do
      refute TurtleTriG.Encoder.prefixed_name(EX.foo(), PrefixMap.new())
    end

    test "slash iri with existing prefix", %{prefixes: prefixes} do
      assert TurtleTriG.Encoder.prefixed_name(~I<http://example.org/foo>, prefixes)
             |> IO.iodata_to_binary() ==
               "ex2:foo"
    end

    test "slash iri namespace without name", %{prefixes: prefixes} do
      assert TurtleTriG.Encoder.prefixed_name(~I<http://example.org/>, prefixes)
             |> IO.iodata_to_binary() ==
               "ex2:"
    end

    test "slash iri with non-existing prefix" do
      refute TurtleTriG.Encoder.prefixed_name(~I<http://example.org/foo>, PrefixMap.new())
    end
  end
end
