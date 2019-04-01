defmodule RDF.SerializationTest do
  use ExUnit.Case

  doctest RDF.Serialization

  use RDF.Vocabulary.Namespace

  defvocab EX,
    base_iri: "http://example.org/",
    terms: [], strict: false

  @example_turtle_file "test/data/cbd.ttl"
  @example_turtle_string """
  @prefix ex: <http://example.org/#> .
  ex:Aaron <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> ex:Person .
  """

  @example_graph RDF.Graph.new [{EX.S, EX.p, EX.O}]
  @example_graph_turtle """
  @prefix : <#{to_string(EX.__base_iri__)}> .

  :S
      :p :O .
  """

  defp file(name), do: System.tmp_dir!() |> Path.join(name)


  describe "read_string/2" do
    test "with correct format name" do
      assert {:ok, %RDF.Graph{}} =
        RDF.Serialization.read_string(@example_turtle_string, format: :turtle)
    end

    test "with wrong format name" do
      assert {:error, "N-Triple scanner error" <> _} =
        RDF.Serialization.read_string(@example_turtle_string, format: :ntriples)
    end

    test "with invalid format name" do
      assert {:error, "unable to detect serialization format"} ==
        RDF.Serialization.read_string(@example_turtle_string, format: :foo)
    end

    test "with media_type" do
      assert {:ok, %RDF.Graph{}} =
        RDF.Serialization.read_string(@example_turtle_string, media_type: "text/turtle")
    end
  end

  describe "read_string!/2" do
    test "with correct format name" do
      assert %RDF.Graph{} =
        RDF.Serialization.read_string!(@example_turtle_string, format: :turtle)
    end

    test "with wrong format name" do
      assert_raise RuntimeError, ~r/^N-Triple scanner error.*/, fn ->
        RDF.Serialization.read_string!(@example_turtle_string, format: :ntriples)
      end
    end

    test "with invalid format name" do
      assert_raise RuntimeError, "unable to detect serialization format", fn ->
        RDF.Serialization.read_string!(@example_turtle_string, format: :foo)
      end
    end

    test "with media_type" do
      assert %RDF.Graph{} =
        RDF.Serialization.read_string!(@example_turtle_string, media_type: "text/turtle")
    end
  end

  describe "read_file/2" do
    test "without arguments, i.e. via correct file extension" do
      assert {:ok, %RDF.Graph{}} = RDF.Serialization.read_file(@example_turtle_file)
    end

    test "with correct format name" do
      assert {:ok, %RDF.Graph{}} =
        RDF.Serialization.read_file(@example_turtle_file, format: :turtle)
    end

    test "with wrong format name" do
      assert {:error, "N-Triple scanner error" <> _} =
        RDF.Serialization.read_file(@example_turtle_file, format: :ntriples)
    end

    test "with invalid format name, but correct file extension" do
      assert {:ok, %RDF.Graph{}} = RDF.Serialization.read_file(@example_turtle_file, format: :foo)
    end

    test "with media_type" do
      assert {:ok, %RDF.Graph{}} =
        RDF.Serialization.read_file(@example_turtle_file, media_type: "text/turtle")
    end
  end

  describe "read_file!/2" do
    test "without arguments, i.e. via correct file extension" do
      assert %RDF.Graph{} = RDF.Serialization.read_file!(@example_turtle_file)
    end

    test "with correct format name" do
      assert %RDF.Graph{} =
        RDF.Serialization.read_file!(@example_turtle_file, format: :turtle)
    end

    test "with wrong format name" do
      assert_raise RuntimeError, ~r/^N-Triple scanner error.*/, fn ->
        RDF.Serialization.read_file!(@example_turtle_file, format: :ntriples)
      end
    end

    test "with media_type name" do
      assert %RDF.Graph{} =
        RDF.Serialization.read_file!(@example_turtle_file, media_type: "text/turtle")
    end
  end

  describe "write_string/2" do
    test "with name of available format" do
      assert RDF.Serialization.write_string(@example_graph, format: :turtle,
              prefixes: %{"" => EX.__base_iri__}) ==
                {:ok, @example_graph_turtle}
    end

    test "with invalid format name" do
      assert RDF.Serialization.write_string(@example_graph, format: :foo,
              prefixes: %{"" => EX.__base_iri__}) ==
                {:error, "unable to detect serialization format"}
    end

    test "with media type" do
      assert RDF.Serialization.write_string(@example_graph, media_type: "text/turtle",
              prefixes: %{"" => EX.__base_iri__}) ==
                {:ok, @example_graph_turtle}
    end
  end

  describe "write_string!/2" do
    test "with name of available format" do
      assert RDF.Serialization.write_string!(@example_graph, format: :turtle,
              prefixes: %{"" => EX.__base_iri__}) ==
                @example_graph_turtle
    end

    test "with invalid format name" do
      assert_raise RuntimeError, "unable to detect serialization format", fn ->
        RDF.Serialization.write_string!(@example_graph, format: :foo,
                      prefixes: %{"" => EX.__base_iri__})
      end
    end

    test "with media type" do
      assert RDF.Serialization.write_string!(@example_graph, media_type: "text/turtle",
              prefixes: %{"" => EX.__base_iri__}) ==
                @example_graph_turtle
    end
  end

  describe "write_file/2" do
    test "without arguments, i.e. via file extension" do
      file = file("write_file_test.ttl")
      if File.exists?(file), do: File.rm(file)
      assert RDF.Serialization.write_file(@example_graph, file,
              prefixes: %{"" => EX.__base_iri__}) == :ok
      assert File.exists?(file)
      assert File.read!(file) == @example_graph_turtle
      File.rm(file)
    end

    test "with format name" do
      file = file("write_file_test.nt")
      if File.exists?(file), do: File.rm(file)
      assert RDF.Serialization.write_file(@example_graph, file, format: :turtle,
              prefixes: %{"" => EX.__base_iri__}) == :ok
      assert File.exists?(file)
      assert File.read!(file) == @example_graph_turtle
      File.rm(file)
    end
  end

  describe "write_file!/2" do
    test "without arguments, i.e. via file extension" do
      file = file("write_file_test.ttl")
      if File.exists?(file), do: File.rm(file)
      assert RDF.Serialization.write_file!(@example_graph, file,
              prefixes: %{"" => EX.__base_iri__}) == :ok
      assert File.exists?(file)
      assert File.read!(file) == @example_graph_turtle
      File.rm(file)
    end

    test "with format name" do
      file = file("write_file_test.nt")
      if File.exists?(file), do: File.rm(file)
      assert RDF.Serialization.write_file!(@example_graph, file, format: :turtle,
              prefixes: %{"" => EX.__base_iri__}) == :ok
      assert File.exists?(file)
      assert File.read!(file) == @example_graph_turtle
      File.rm(file)
    end
  end
end
