defmodule RDF.TurtleTriG.Encoder do
  @moduledoc !"Shared functions for the Turtle and TriG encoders."

  alias RDF.TurtleTriG.Encoder.{State, Sequencer, CompactStarGraph}
  alias RDF.{BlankNode, Description, Graph, Dataset, IRI, XSD, Literal, LangString, PrefixMap}

  import RDF.NTriples.Encoder, only: [escape_string: 1]

  @document_structure {:separated, [:directives, :triples]}

  @indentation 4

  @native_supported_datatypes [
    XSD.Boolean,
    XSD.Integer,
    XSD.Double,
    XSD.Decimal
  ]
  @rdf_type RDF.Utils.Bootstrapping.rdf_iri("type")
  @rdf_nil RDF.Utils.Bootstrapping.rdf_iri("nil")

  def options_doc do
    """
    - `:directive_style`: Specifies the style of directives to be used in the document.
      Possible values are `:turtle` and `:sparql` (default: `:turtle`).
    - `:implicit_base`: This boolean flag allows to use a base URI to get relative IRIs
      without embedding it explicitly in the content with a `@base` directive, so that
      the URIs will be resolved according to the remaining strategy specified in
      section 5.1 of [RFC3986](https://www.ietf.org/rfc/rfc3986.txt) (default: `false`).
    - `:base_description`: Allows to provide a description of the resource denoted by
      the base URI. This option is especially useful when the base URI is actually not
      specified, e.g. in the common use case of wanting to describe the document
      itself, which should be denoted by the URL where it is hosted as the implicit base
      URI.
    - `:indent`: Allows to specify the number of spaces the output should be indented.
    """
  end

  def format_label(:turtle), do: "Turtle"
  def format_label(:trig), do: "TriG"

  @type format :: :turtle | :trig

  @spec encode(Dataset.t() | Graph.t() | Description.t(), format, keyword) ::
          {:ok, String.t()} | {:error, any}
  def encode(data, format, opts \\ [])

  def encode(%Description{} = description, format, opts),
    do: description |> Graph.new() |> encode(format, opts)

  def encode(%Graph{} = graph, :trig, opts),
    do: graph |> Dataset.new() |> encode(:trig, opts)

  def encode(data, format, opts) do
    state = State.new(format, data, opts)
    document_structure = Keyword.get(opts, :content) || @document_structure
    compiled = compile(document_structure, format, state, opts)
    {:ok, IO.iodata_to_binary(compiled)}
  end

  defp compile(:directives, format, state, opts),
    do: compile({:separated, [:base, :prefixes]}, format, state, opts)

  defp compile(:base, _, %{base: base} = state, opts),
    do: base_directive(base, state, opts)

  defp compile(:prefixes, _, %{prefixes: prefixes} = state, opts),
    do: prefix_directives(prefixes, state, opts)

  defp compile(:triples, :turtle, state, _opts),
    do: graph_statements(state)

  defp compile(:triples, :trig, state, opts),
    do: compile(:graphs, :trig, state, opts)

  defp compile(:graphs, :trig, state, opts),
    do: compile({:separated, [:default_graph, :named_graphs]}, :trig, state, opts)

  defp compile(:default_graph, :trig, state, _opts) do
    state
    |> State.set_current_graph(Dataset.default_graph(state.data))
    |> graph()
  end

  defp compile(:named_graphs, :trig, state, _opts) do
    state.data
    |> Dataset.named_graphs()
    |> Enum.map(&(state |> State.set_current_graph(&1) |> graph()))
    |> Enum.intersperse("\n")
  end

  defp compile({:separated, elements}, format, state, opts) do
    compile({:separated, "\n", elements}, format, state, opts)
  end

  defp compile({:separated, separator, elements}, format, state, opts) do
    elements
    |> Enum.map(&compile(&1, format, state, opts))
    |> Enum.reject(&Enum.empty?/1)
    |> Enum.intersperse(separator)
  end

  defp compile(elements, format, state, opts) when is_list(elements) do
    Enum.map(elements, &compile(&1, format, state, opts))
  end

  defp compile(string, _, _, _) when is_binary(string), do: string

  defp compile(element, format, _, _) do
    raise "unknown #{format_label(format)} document element: #{inspect(element)}"
  end

  defp base_directive(nil, _, _), do: []
  defp base_directive(_, %{implicit_base: true}, _), do: []

  defp base_directive(base, state, opts) do
    [
      indent(state),
      case Keyword.get(opts, :directive_style) do
        :sparql -> ["BASE <", base, ">"]
        _ -> ["@base <", base, "> ."]
      end,
      "\n"
    ]
  end

  defp prefix_directives(prefixes, state, opts) do
    if Enum.empty?(prefixes.map) do
      []
    else
      PrefixMap.to_header(prefixes, Keyword.get(opts, :directive_style, :turtle),
        indent: state.indentation,
        iodata: true
      )
    end
  end

  defp graph(%State{graph: %Graph{name: nil}} = state), do: graph_statements(state)

  defp graph(%State{graph: %Graph{name: name}} = state) do
    [
      indent(state),
      "GRAPH ",
      term(name, state, :subject, state.indentation),
      " {\n",
      graph_statements(State.indent(state, @indentation)),
      indent(state),
      "}\n"
    ]
  end

  defp graph_statements(state) do
    indentation = state.indentation || 0

    state.graph
    |> CompactStarGraph.compact()
    |> Sequencer.descriptions(State.base_iri(state))
    |> Enum.map(&(&1 |> description_statements(state, indentation) |> indent(indentation)))
    |> Enum.reject(&Enum.empty?/1)
    |> Enum.intersperse("\n")
  end

  defp description_statements(description, state, nesting) do
    if Description.empty?(description) do
      raise Graph.EmptyDescriptionError, subject: description.subject
    else
      case State.bnode_type(state, description.subject) do
        :unrefed_bnode_subject_term -> unrefed_bnode_subject_term(description, state, nesting)
        :unrefed_bnode_object_term -> []
        :normal -> full_description_statements(description, state, nesting)
      end
    end
  end

  defp full_description_statements(description, state, nesting) do
    term(description.subject, state, :subject, nesting)
    |> full_description_statements(description, state, nesting)
  end

  defp full_description_statements(subject, description, state, nesting) do
    nesting = nesting + @indentation
    [subject, newline_indent(nesting), predications(description, state, nesting), " .\n"]
  end

  defp blank_node_property_list(description, state, nesting) do
    indented = nesting + @indentation

    if Description.empty?(description) do
      "[]"
    else
      [
        "[",
        newline_indent(indented),
        predications(description, state, indented),
        newline_indent(nesting),
        "]"
      ]
    end
  end

  defp predications(description, state, nesting) do
    description
    |> Sequencer.predications()
    |> Enum.map(&predication(&1, state, nesting))
    |> Enum.intersperse([" ;", newline_indent(nesting)])
  end

  defp predication({predicate, objects}, %{no_object_lists: true} = state, nesting) do
    objects
    |> Enum.map(&[term(predicate, state, :predicate, nesting), " ", object(&1, state, nesting)])
    |> Enum.intersperse([" ;", newline_indent(nesting)])
  end

  defp predication({predicate, objects}, state, nesting) do
    [term(predicate, state, :predicate, nesting), " " | objects(objects, state, nesting)]
  end

  defp objects(objects, state, nesting) do
    {objects, with_annotations?} =
      Enum.map_reduce(objects, false, fn {object, annotation}, with_annotations? ->
        if annotation do
          {object_with_annotation(object, annotation, state, nesting), true}
        else
          {object_without_annotation(object, state, nesting), with_annotations?}
        end
      end)

    separator =
      if with_annotations?,
        do: [",", newline_indent(nesting + @indentation)],
        else: ", "

    Enum.intersperse(objects, separator)
  end

  defp object({object, nil}, state, nesting),
    do: object_without_annotation(object, state, nesting)

  defp object({object, annotation}, state, nesting),
    do: object_with_annotation(object, annotation, state, nesting)

  defp object_without_annotation(object, state, nesting) do
    term(object, state, :object, nesting)
  end

  defp object_with_annotation(object, annotation, state, nesting) do
    [
      object_without_annotation(object, state, nesting),
      " {| ",
      predications(annotation, state, nesting + 2 * @indentation),
      " |}"
    ]
  end

  defp unrefed_bnode_subject_term(bnode_description, state, nesting) do
    if State.valid_list_node?(state, bnode_description.subject) do
      bnode_description.subject
      |> list_term(state, nesting)
      |> full_description_statements(
        list_subject_description(bnode_description),
        state,
        nesting
      )
    else
      [blank_node_property_list(bnode_description, state, nesting), " .\n"]
    end
  end

  defp list_subject_description(description) do
    description = Description.delete_predicates(description, [RDF.first(), RDF.rest()])

    if Description.empty?(description) do
      # since the Turtle grammar doesn't allow bare lists, we add a statement
      description |> RDF.type(RDF.List)
    else
      description
    end
  end

  defp unrefed_bnode_object_term(bnode, state, nesting) do
    if State.valid_list_node?(state, bnode) do
      list_term(bnode, state, nesting)
    else
      state.graph
      |> Graph.description(bnode)
      |> blank_node_property_list(state, nesting)
    end
  end

  defp list_term(head, state, nesting) do
    head
    |> State.list_values(state)
    |> term(state, :list, nesting)
  end

  defp term(@rdf_type, _, :predicate, _), do: "a"
  defp term(@rdf_nil, _, _, _), do: "()"

  defp term(%IRI{} = iri, state, _, _) do
    based_name(iri, state.base) ||
      prefixed_name(iri, state.prefixes) ||
      ["<", to_string(iri), ">"]
  end

  defp term(%BlankNode{} = bnode, state, position, nesting) when position in ~w[object list]a do
    if State.bnode_type(state, bnode) == :unrefed_bnode_object_term do
      unrefed_bnode_object_term(bnode, state, nesting)
    else
      to_string(bnode)
    end
  end

  defp term(%BlankNode{} = bnode, _, _, _),
    do: to_string(bnode)

  defp term(%Literal{literal: %LangString{} = lang_string}, _, _, _) do
    [quoted(lang_string.value), "@", lang_string.language]
  end

  defp term(%Literal{literal: %XSD.String{}} = literal, _, _, _) do
    literal |> Literal.lexical() |> quoted()
  end

  defp term(%Literal{literal: %datatype{}} = literal, state, _, nesting)
       when datatype in @native_supported_datatypes do
    cond do
      not Literal.valid?(literal) -> typed_literal_term(literal, state, nesting)
      not Literal.canonical?(literal) -> uncanonical_form(datatype, literal, state, nesting)
      true -> Literal.canonical_lexical(literal)
    end
  end

  defp term(%Literal{} = literal, state, _, nesting),
    do: typed_literal_term(literal, state, nesting)

  defp term({s, p, o}, state, _, nesting) do
    [
      "<< ",
      term(s, state, :subject, nesting),
      " ",
      term(p, state, :predicate, nesting),
      " ",
      term(o, state, :object, nesting),
      " >>"
    ]
  end

  defp term(list, %{no_object_lists: true} = state, _, nesting) when is_list(list) do
    indentation = nesting + @indentation

    [
      "(",
      newline_indent(indentation),
      list
      |> Enum.map(&term(&1, state, :list, indentation))
      |> Enum.intersperse(newline_indent(indentation)),
      newline_indent(nesting),
      ")"
    ]
  end

  defp term(list, state, _, nesting) when is_list(list) do
    [
      "(",
      list
      |> Enum.map(&term(&1, state, :list, nesting))
      |> Enum.intersperse(" "),
      ")"
    ]
  end

  defp uncanonical_form(XSD.Double, literal, state, nesting) do
    if literal |> Literal.lexical() |> String.contains?(["e", "E"]) do
      Literal.lexical(literal)
    else
      typed_literal_term(literal, state, nesting)
    end
  end

  defp uncanonical_form(_, literal, state, nesting),
    do: typed_literal_term(literal, state, nesting)

  defp based_name(%IRI{} = iri, base), do: iri |> to_string() |> based_name(base)
  defp based_name(_, nil), do: nil

  defp based_name(iri, base) do
    if String.starts_with?(iri, base) do
      ["<", String.slice(iri, String.length(base)..-1//1), ">"]
    end
  end

  defp typed_literal_term(%Literal{} = literal, state, nesting) do
    [
      ~s["],
      escape_string(Literal.lexical(literal)),
      ~s["^^],
      literal
      |> Literal.datatype_id()
      |> term(state, :datatype, nesting)
    ]
  end

  def prefixed_name(iri, prefixes) do
    case PrefixMap.prefix_name_pair(prefixes, iri) do
      {prefix, name} -> if valid_pn_local?(name), do: [prefix, ":", name]
      _ -> nil
    end
  end

  defp valid_pn_local?(name) do
    String.match?(name, ~r/^([[:alpha:]]|[[:digit:]]|_|:)*$/u)
  end

  defp quoted(string) do
    if String.contains?(string, ["\n", "\r"]) do
      [~s["""], string, ~s["""]]
    else
      [~s["], escape_string(string), ~s["]]
    end
  end

  defp newline_indent(nesting), do: ["\n", indent(nesting)]

  defp indent(%State{indentation: indentation}), do: indent(indentation)
  defp indent(nil), do: ""
  defp indent(0), do: ""
  defp indent(count), do: String.duplicate(" ", count)

  defp indent([], _), do: []
  defp indent(iolist, nil), do: iolist
  defp indent(iolist, 0), do: iolist
  defp indent(iolist, count), do: [indent(count) | iolist]
end
