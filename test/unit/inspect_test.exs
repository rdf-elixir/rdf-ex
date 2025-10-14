defmodule RDF.InspectTest do
  use RDF.Test.Case

  alias RDF.{Turtle, TriG}
  alias RDF.NS.RDFS

  @test_description EX.S
                    |> RDF.type(RDFS.Class)
                    |> EX.p("foo", 42)

  @test_graph Graph.new(
                [
                  EX.S1
                  |> EX.p1(EX.O1)
                  |> EX.p2("foo", 42),
                  EX.S2
                  |> EX.p3(EX.O3)
                ],
                prefixes: [ex: EX]
              )

  describe "RDF.Description" do
    test "it includes a header" do
      {header, _} = inspect_parts(@test_description)
      assert header == "#RDF.Description<subject: #{inspect(@test_description.subject)}"
    end

    test "it encodes the description in Turtle" do
      {_, body} = inspect_parts(@test_description)

      assert body ==
               "  " <>
                 (Turtle.write_string!(@test_description, content: :triples, indent: 2)
                  |> String.trim()) <> "\n>"
    end

    test "it includes the subject when empty" do
      assert inspect(Description.new(EX.Foo)) =~
               "#RDF.Description<subject: #{inspect(RDF.iri(EX.Foo))}>"
    end

    test "it encodes the RDF-star graphs and descriptions in Turtle-star" do
      {_, triples} = inspect_parts(annotation_description(), limit: 2)
      assert triples =~ "<< <http://example.com/S> <http://example.com/P> \"Foo\" >>"
    end

    test ":limit option" do
      {_, triples} = inspect_parts(@test_description, limit: 2)

      assert triples ==
               "  " <>
                 (EX.S
                  |> EX.p("foo", 42)
                  |> Turtle.write_string!(content: :triples, indent: 2)
                  |> String.trim()) <>
                 "..\n...\n>"
    end
  end

  describe "RDF.Graph" do
    test "it includes a header with the graph name" do
      {header, _} = inspect_parts(@test_graph)
      assert header == "#RDF.Graph<name: nil"

      graph_name = RDF.iri(EX.Graph)
      {header, _} = @test_graph |> Graph.change_name(graph_name) |> inspect_parts()
      assert header == "#RDF.Graph<name: #{inspect(graph_name)}"
    end

    test "it encodes the graph in Turtle" do
      {_, body} = inspect_parts(@test_graph)

      assert body ==
               "  " <>
                 (Turtle.write_string!(@test_graph, indent: 2) |> String.trim()) <> "\n>"
    end

    test ":limit option" do
      {_, body} = inspect_parts(@test_graph, limit: 2)

      assert body ==
               "  " <>
                 (Graph.new(
                    EX.S1
                    |> EX.p1(EX.O1)
                    |> EX.p2(42),
                    prefixes: [ex: EX]
                  )
                  |> Turtle.write_string!(indent: 2)
                  |> String.trim()) <>
                 "..\n...\n>"

      graph = Graph.new(Enum.map(1..100, &{~i<http://example.com/S#{&1}>, EX.p(), EX.O}))
      {_, body} = inspect_parts(graph, limit: :infinity)
      assert body == "  " <> (Turtle.write_string!(graph, indent: 2) |> String.trim()) <> "\n>"
    end

    test ":content_only option" do
      result = inspect(@test_graph, custom_options: [content_only: true])
      refute result =~ "#RDF.Graph"
      assert result =~ "ex:S1"
    end

    test ":no_metadata option" do
      result = inspect(@test_graph, custom_options: [no_metadata: true])
      refute result =~ "@prefix"
      assert result =~ "ex:S1"
    end
  end

  describe "RDF.Dataset" do
    test "it includes a header with the dataset name" do
      dataset = Dataset.new([{EX.S1, EX.p1(), EX.O1}, {EX.S2, EX.p2(), EX.O2, EX.Graph}])
      {header, _} = inspect_parts(dataset)
      assert header == "#RDF.Dataset<name: nil"

      dataset_name = RDF.iri(EX.Dataset)
      {header, _} = dataset |> Dataset.change_name(dataset_name) |> inspect_parts()
      assert header == "#RDF.Dataset<name: #{inspect(dataset_name)}"
    end

    test "it encodes the dataset in TriG" do
      dataset = Dataset.new([{EX.S1, EX.p1(), EX.O1}, {EX.S2, EX.p2(), EX.O2, EX.Graph}])
      {_, body} = inspect_parts(dataset)

      assert body ==
               "  " <>
                 (TriG.write_string!(dataset, indent: 2) |> String.trim()) <> "\n>"
    end

    test ":limit option" do
      dataset =
        Dataset.new([
          # Default graph: 2 statements
          {EX.S1, EX.p1(), EX.O1},
          {EX.S1, EX.p2(), EX.O2},
          # Graph1: 6 statements
          {EX.S2, EX.p1(), EX.O3, EX.Graph1},
          {EX.S2, EX.p2(), EX.O4, EX.Graph1},
          {EX.S2, EX.p3(), EX.O5, EX.Graph1},
          {EX.S2, EX.p4(), EX.O6, EX.Graph1},
          {EX.S2, EX.p5(), EX.O7, EX.Graph1},
          {EX.S2, EX.p6(), EX.O8, EX.Graph1},
          # Graph2: 4 statements
          {EX.S3, EX.p1(), EX.O9, EX.Graph2},
          {EX.S3, EX.p2(), EX.O10, EX.Graph2},
          {EX.S3, EX.p3(), EX.O11, EX.Graph2},
          {EX.S3, EX.p4(), EX.O12, EX.Graph2}
        ])

      {_, body} = inspect_parts(dataset, limit: 8)

      # Proportional limiting: 12 total, limit 8, cut_off 4
      # Default graph (2): round(4 * 2/12) = 1 cut off → shows 1
      # Graph1 (6): round(4 * 6/12) = 2 cut off → shows 4
      # Graph2 (4): round(4 * 4/12) = 1 cut off → shows 3
      limited_dataset =
        Dataset.new([
          {EX.S1, EX.p1(), EX.O1},
          {EX.S2, EX.p1(), EX.O3, EX.Graph1},
          {EX.S2, EX.p2(), EX.O4, EX.Graph1},
          {EX.S2, EX.p3(), EX.O5, EX.Graph1},
          {EX.S2, EX.p4(), EX.O6, EX.Graph1},
          {EX.S3, EX.p1(), EX.O9, EX.Graph2},
          {EX.S3, EX.p2(), EX.O10, EX.Graph2},
          {EX.S3, EX.p3(), EX.O11, EX.Graph2}
        ])

      assert body ==
               "  " <>
                 (TriG.write_string!(limited_dataset, indent: 2) |> String.trim()) <>
                 "\n\n...\n>"

      dataset = Dataset.new(Enum.map(1..100, &{~i<http://example.com/S#{&1}>, EX.p(), EX.O}))
      {_, body} = inspect_parts(dataset, limit: :infinity)
      assert body == "  " <> (TriG.write_string!(dataset, indent: 2) |> String.trim()) <> "\n>"
    end

    test ":content_only option" do
      dataset = Dataset.new([{EX.S1, EX.p1(), EX.O1}, {EX.S2, EX.p2(), EX.O2, EX.Graph}])
      result = inspect(dataset, custom_options: [content_only: true])
      refute result =~ "#RDF.Dataset"
      assert result =~ "<http://example.com/S1>"
    end

    test ":no_metadata option" do
      dataset = Dataset.new([{EX.S1, EX.p1(), EX.O1}, {EX.S2, EX.p2(), EX.O2, EX.Graph}])
      result = inspect(dataset, custom_options: [no_metadata: true])
      refute result =~ "@prefix"
      assert result =~ "<http://example.com/S1>"
    end
  end

  test "RDF.IRI" do
    %{
      ~I<http://example.com/> => "~I<http://example.com/>"
    }
    |> assert_valid_literal_inspections()
  end

  test "RDF.BlankNode" do
    %{
      ~B<foo> => "~B<foo>",
      BlankNode.new(42) => "~B<b42>"
    }
    |> assert_valid_literal_inspections()
  end

  test "RDF.Literal" do
    alias RDF.TestDatatypes.UsZipcode

    %{
      ~L"foo" => ~s[~L"foo"],
      ~L"foo"en => ~s[~L"foo"en],
      RDF.LangString.new("foo", language: "en-US") =>
        ~s[RDF.LangString.new("foo", language: "en-us")],
      XSD.boolean(true) => "RDF.XSD.Boolean.new(true)",
      XSD.boolean(false) => "RDF.XSD.Boolean.new(false)",
      XSD.boolean("0") => ~s[RDF.XSD.Boolean.new("0")],
      XSD.boolean("1") => ~s[RDF.XSD.Boolean.new("1")],
      XSD.boolean("2") => ~s[RDF.XSD.Boolean.new("2")],
      XSD.integer(42) => "RDF.XSD.Integer.new(42)",
      XSD.integer("042") => ~s[RDF.XSD.Integer.new("042")],
      XSD.integer("foo") => ~s[RDF.XSD.Integer.new("foo")],
      XSD.decimal(3.14) => ~s[RDF.XSD.Decimal.new(Decimal.new("3.14"))],
      XSD.decimal(".1") => ~s[RDF.XSD.Decimal.new(".1")],
      XSD.decimal("foo") => ~s[RDF.XSD.Decimal.new("foo")],
      UsZipcode.new("20521") => ~s[RDF.TestDatatypes.UsZipcode.new("20521")],
      Literal.new("foo", datatype: "http://example.com/dt") =>
        ~s[RDF.Literal.new("foo", datatype: "http://example.com/dt")]
    }
    |> assert_valid_literal_inspections()
  end

  defp assert_valid_literal_inspections(inspection) do
    Enum.each(inspection, &assert_valid_literal_inspection/1)
  end

  defp assert_valid_literal_inspection({literal, inspection}) do
    assert inspect(literal) == inspection
    {evaluated, _} = Code.eval_string(inspection, [], __ENV__)
    assert evaluated === literal
  end

  def inspect_parts(graph, opts \\ []) do
    inspect_form = inspect(graph, opts)
    [header, body] = String.split(inspect_form, "\n", parts: 2)
    {header, body}
  end
end
