defmodule RDF.SerializationTest do
  use RDF.Test.Case

  doctest RDF.Serialization

  alias RDF.{Serialization, NTriples, Turtle}

  @example_graph Graph.new([{EX.S, RDF.type(), EX.O}], prefixes: %{"" => EX})
  @example_ntriples_file "test/data/serialization_test_graph.nt"
  @example_turtle_file "test/data/serialization_test_graph.ttl"
  @example_turtle_string """
  @prefix : <#{to_string(EX.__base_iri__())}> .

  :S
      a :O .
  """
  @example_ntriples_string """
  <#{IRI.to_string(EX.S)}> <#{IRI.to_string(RDF.type())}> <#{IRI.to_string(EX.O)}> .
  """

  defp file(name), do: System.tmp_dir!() |> Path.join(name)

  describe "read_string/2" do
    test "with correct format name" do
      assert Serialization.read_string(@example_turtle_string, format: :turtle) ==
               {:ok, @example_graph}
    end

    test "with wrong format name" do
      assert {:error, "N-Triple scanner error" <> _} =
               Serialization.read_string(@example_turtle_string, format: :ntriples)
    end

    test "with invalid format name" do
      assert {:error, "unable to detect serialization format"} ==
               Serialization.read_string(@example_turtle_string, format: :foo)
    end

    test "with media_type" do
      assert Serialization.read_string(@example_turtle_string, media_type: "text/turtle") ==
               {:ok, @example_graph}
    end
  end

  describe "read_string!/2" do
    test "with correct format name" do
      assert Serialization.read_string!(@example_turtle_string, format: :turtle) ==
               @example_graph
    end

    test "with wrong format name" do
      assert_raise RuntimeError, ~r/^N-Triple scanner error.*/, fn ->
        Serialization.read_string!(@example_turtle_string, format: :ntriples)
      end
    end

    test "with invalid format name" do
      assert_raise RuntimeError, "unable to detect serialization format", fn ->
        Serialization.read_string!(@example_turtle_string, format: :foo)
      end
    end

    test "with media_type" do
      assert Serialization.read_string!(@example_turtle_string, media_type: "text/turtle") ==
               @example_graph
    end
  end

  describe "read_stream/2" do
    test "with correct format name" do
      assert @example_ntriples_string
             |> string_to_stream()
             |> Serialization.read_stream(format: :ntriples) ==
               {:ok, Graph.clear_metadata(@example_graph)}
    end

    test "with wrong format name" do
      assert {:error, "N-Triple scanner error" <> _} =
               @example_turtle_string
               |> string_to_stream()
               |> Serialization.read_stream(format: :ntriples)
    end

    test "with invalid format name" do
      assert {:error, "unable to detect serialization format"} ==
               Serialization.read_stream(@example_ntriples_string, format: :foo)
    end

    test "with media_type" do
      assert @example_ntriples_string
             |> string_to_stream()
             |> Serialization.read_stream(media_type: "application/n-triples") ==
               {:ok, Graph.clear_metadata(@example_graph)}
    end
  end

  describe "read_stream!/2" do
    test "with correct format name" do
      assert @example_ntriples_string
             |> string_to_stream()
             |> Serialization.read_stream!(format: :ntriples) ==
               Graph.clear_metadata(@example_graph)
    end

    test "with wrong format name" do
      assert_raise RuntimeError, fn ->
        @example_ntriples_string
        |> string_to_stream()
        |> Serialization.read_stream!(format: :turtle)
      end
    end

    test "with invalid format name" do
      assert_raise RuntimeError, "unable to detect serialization format", fn ->
        Serialization.read_stream!(@example_ntriples_string, format: :foo)
      end
    end

    test "with media_type" do
      assert @example_ntriples_string
             |> string_to_stream()
             |> Serialization.read_stream!(media_type: "application/n-triples") ==
               Graph.clear_metadata(@example_graph)
    end
  end

  describe "read_file/2" do
    test "without arguments, i.e. via correct file extension" do
      assert Serialization.read_file(@example_turtle_file) == {:ok, @example_graph}
    end

    test "with correct format name" do
      assert Serialization.read_file(@example_turtle_file, format: :turtle) ==
               {:ok, @example_graph}
    end

    test "with wrong format name" do
      assert {:error, "N-Triple scanner error" <> _} =
               Serialization.read_file(@example_turtle_file, format: :ntriples)
    end

    test "with invalid format name, but correct file extension" do
      assert Serialization.read_file(@example_turtle_file, format: :foo) ==
               {:ok, @example_graph}
    end

    test "with media_type" do
      assert Serialization.read_file(@example_ntriples_file, media_type: "application/n-triples") ==
               {:ok, Graph.clear_metadata(@example_graph)}
    end
  end

  describe "read_file!/2" do
    test "without arguments, i.e. via correct file extension" do
      assert Serialization.read_file!(@example_ntriples_file) ==
               Graph.clear_metadata(@example_graph)
    end

    test "with correct format name" do
      assert Serialization.read_file!(@example_turtle_file, format: :turtle) ==
               @example_graph
    end

    test "with wrong format name" do
      assert_raise RuntimeError, ~r/^N-Triple scanner error.*/, fn ->
        Serialization.read_file!(@example_turtle_file, format: :ntriples)
      end
    end

    test "with media_type name" do
      assert Serialization.read_file!(@example_turtle_file, media_type: "text/turtle") ==
               @example_graph
    end
  end

  describe "write_string/2" do
    test "with name of available format" do
      assert Serialization.write_string(@example_graph,
               format: :turtle,
               prefixes: %{"" => EX.__base_iri__()}
             ) ==
               {:ok, @example_turtle_string}
    end

    test "with invalid format name" do
      assert Serialization.write_string(@example_graph,
               format: :foo,
               prefixes: %{"" => EX.__base_iri__()}
             ) ==
               {:error, "unable to detect serialization format"}
    end

    test "with media type" do
      assert Serialization.write_string(@example_graph, media_type: "application/n-triples") ==
               {:ok, @example_ntriples_string}
    end
  end

  describe "write_string!/2" do
    test "with name of available format" do
      assert Serialization.write_string!(@example_graph, format: :ntriples) ==
               @example_ntriples_string
    end

    test "with invalid format name" do
      assert_raise RuntimeError, "unable to detect serialization format", fn ->
        Serialization.write_string!(@example_graph,
          format: :foo,
          prefixes: %{"" => EX.__base_iri__()}
        )
      end
    end

    test "with media type" do
      assert Serialization.write_string!(@example_graph,
               media_type: "text/turtle",
               prefixes: %{"" => EX.__base_iri__()}
             ) ==
               @example_turtle_string
    end
  end

  describe "write_stream/2" do
    test "with name of available format" do
      assert Serialization.write_stream(@example_graph, format: :ntriples)
             |> stream_to_string() == @example_ntriples_string
    end

    test "with invalid format name" do
      assert_raise RuntimeError, "unable to detect serialization format", fn ->
        Serialization.write_stream(@example_graph, format: :foo)
      end
    end

    test "with media type" do
      assert Serialization.write_stream(@example_graph, media_type: "application/n-triples")
             |> stream_to_string() == @example_ntriples_string
    end
  end

  describe "write_file/2" do
    test "without :format option, i.e. via file extension and with streaming" do
      file = file("write_file_test.nt")
      if File.exists?(file), do: File.rm(file)

      assert Serialization.write_file(@example_graph, file, stream: true) == :ok
      assert File.exists?(file)
      assert File.read!(file) == @example_ntriples_string
      File.rm(file)
    end

    test "with format name and without streaming" do
      file = file("write_file_test.nt")
      if File.exists?(file), do: File.rm(file)

      assert Serialization.write_file(@example_graph, file,
               format: :turtle,
               prefixes: %{"" => EX.__base_iri__()}
             ) == :ok

      assert File.exists?(file)
      assert File.read!(file) == @example_turtle_string
      File.rm(file)
    end
  end

  describe "write_file!/2" do
    test "without :format option, i.e. via file extension and without streaming" do
      file = file("write_file_test.ttl")
      if File.exists?(file), do: File.rm(file)

      assert Serialization.write_file!(@example_graph, file, prefixes: %{"" => EX.__base_iri__()}) ==
               :ok

      assert File.exists?(file)
      assert File.read!(file) == @example_turtle_string
      File.rm(file)
    end

    test "with format name and with streaming" do
      file = file("write_file_test.nt")
      if File.exists?(file), do: File.rm(file)

      assert Serialization.write_file!(@example_graph, file, format: :ntriples) == :ok
      assert File.exists?(file)
      assert File.read!(file) == @example_ntriples_string
      File.rm(file)
    end
  end

  test ":gzip opt" do
    # first ensure that :gzip is not ignored on both read and write which would lead to a false positive
    file = file("gzip_test.gz")
    Serialization.write_file!(@example_graph, file, format: :turtle, gzip: true, force: true)
    assert_raise RuntimeError, fn -> Serialization.read_file!(file, format: :turtle) end

    Serialization.write_file!(@example_graph, file,
      format: :ntriples,
      gzip: true,
      stream: true,
      force: true
    )

    # Why do we get an UndefinedFunctionError (function :unicode.format_error/1 is undefined or private)
    assert_raise UndefinedFunctionError, fn ->
      Serialization.read_file!(file, format: :ntriples, stream: true)
    end

    :ok = Serialization.write_file(@example_graph, file, format: :turtle, gzip: true, force: true)
    assert {:error, _} = Serialization.read_file(file, format: :turtle)

    :ok =
      Serialization.write_file(@example_graph, file,
        format: :ntriples,
        gzip: true,
        stream: true,
        force: true
      )

    assert {:error, _} = Serialization.read_file(file, format: :ntriples, stream: true)

    # start of the actual tests
    assert :ok =
             Serialization.write_file(@example_graph, file,
               format: :turtle,
               gzip: true,
               force: true
             )

    assert Serialization.read_file(file, format: :turtle, gzip: true) == {:ok, @example_graph}

    assert :ok =
             Serialization.write_file(@example_graph, file,
               format: :ntriples,
               gzip: true,
               stream: true,
               force: true
             )

    assert Serialization.read_file(file, format: :ntriples, stream: true, gzip: true) ==
             {:ok, Graph.clear_metadata(@example_graph)}

    assert :ok =
             Serialization.write_file!(@example_graph, file,
               format: :turtle,
               gzip: true,
               force: true
             )

    assert Serialization.read_file!(file, format: :turtle, gzip: true) == @example_graph

    assert :ok =
             Serialization.write_file!(@example_graph, file,
               format: :ntriples,
               gzip: true,
               stream: true,
               force: true
             )

    assert Serialization.read_file!(file, format: :ntriples, stream: true, gzip: true) ==
             Graph.clear_metadata(@example_graph)
  end

  describe "use_file_streaming/2" do
    test "without opts" do
      refute Serialization.use_file_streaming(NTriples.Decoder, [])
      refute Serialization.use_file_streaming(NTriples.Encoder, [])
      refute Serialization.use_file_streaming(Turtle.Decoder, [])
      refute Serialization.use_file_streaming(Turtle.Encoder, [])
    end

    test "when stream: true and format does support streams" do
      assert Serialization.use_file_streaming(NTriples.Decoder, stream: :iolist)
      assert Serialization.use_file_streaming(NTriples.Encoder, stream: :string)
    end

    test "when stream: true and format does not support streams" do
      assert_raise RuntimeError, "RDF.Turtle.Decoder does not support streams", fn ->
        Serialization.use_file_streaming(Turtle.Decoder, stream: true)
      end

      assert_raise RuntimeError, "RDF.Turtle.Encoder does not support streams", fn ->
        Serialization.use_file_streaming(Turtle.Encoder, stream: true)
      end
    end
  end

  describe "use_file_streaming!/2" do
    test "without opts" do
      assert Serialization.use_file_streaming!(NTriples.Decoder, [])
      assert Serialization.use_file_streaming!(NTriples.Encoder, [])
      refute Serialization.use_file_streaming!(Turtle.Decoder, [])
      refute Serialization.use_file_streaming!(Turtle.Encoder, [])
    end

    test "when stream: true and format does support streams" do
      assert Serialization.use_file_streaming!(NTriples.Decoder, stream: true) == true
      assert Serialization.use_file_streaming!(NTriples.Encoder, stream: true) == true
      assert Serialization.use_file_streaming!(NTriples.Encoder, stream: :iodata) == :iodata
      assert Serialization.use_file_streaming!(NTriples.Encoder, stream: :string) == :string
    end

    test "when stream: true and format does not support streams" do
      assert_raise RuntimeError, "RDF.Turtle.Decoder does not support streams", fn ->
        Serialization.use_file_streaming!(Turtle.Decoder, stream: true)
      end

      assert_raise RuntimeError, "RDF.Turtle.Encoder does not support streams", fn ->
        Serialization.use_file_streaming!(Turtle.Encoder, stream: true)
      end
    end
  end
end
