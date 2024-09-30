defmodule RDF.TurtleTriG.Encoder do
  @moduledoc !"Shared functions for the Turtle and TriG encoders."

  alias RDF.TurtleTriG.Encoder.{State, Sequencer, CompactStarGraph}
  alias RDF.{BlankNode, Description, Graph, Dataset, IRI, XSD, Literal, LangString, PrefixMap}

  import State,
    only: [
      line_prefixed: 4,
      newline_indentation: 1,
      indentation: 1,
      indented: 2,
      indent: 1
    ]

  @document_structure {:separated, [:directives, :triples]}

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
    - `:line_prefix`: Allows to specify a function returning prefixes for the encoded lines.
      When this function is defined, the `:single_triple_lines` option is implicitly set, so
      that each line encodes at most one triple.
      The function receives three arguments:
      1. `type` - one of the following values specifying the content of the line: `:triple`,
        `:description`, `:graph` (for named graphs in TriG only), `:closing`
      2. `value` - a `type` specific value for the content in this line
          - for `:triple`: the `RDF.Triple` encoded in this line
          - for `:description`: the subject whose description is started in this line
          - for `:graph`: the name of the graph, opened in this line
          - for `:closing`: a value specifying which element is closed in this line
      3. `graph_name` - the name of graph (in Turtle this is always `nil`)
    - `:single_triple_lines`: When set to `true` each line encodes at most one triple, i.e.
       no object lists with multiple objects are used and no Turtle list encodings are used.
       This option is in of itself is not very useful. It is set implicitly when defining
       a `:line_prefix` function which depends on this mode to produce useful results.
    - `:indent`: Allows to specify the number of spaces the output should be indented.
    - `:indent_width`: Allows to specify the number of spaces that should be used for
      indentations (default: 4).
    - `:pn_local_validation`: This option controls how IRIs are validated the check
       whether they can encoded as a prefixed name. Available settings are:
      - `:fast` (default): Provides a quick and efficient validation that covers most
        common cases. It does not handle every possible valid scenario, focusing instead
        on typical structures encountered in prefixed names.
      - `:none`: Disables validation entirely. Use this mode if you are confident that
        all your IRIs are already compliant with prefixed name requirements, allowing you
        to bypass validation checks for increased performance.
      - Note: Currently, a `:strict` mode, which would provide comprehensive validation
        conforming strictly to the Turtle specification, is not implemented.
        Contributions for implementing this mode are welcome.
    - `:rdf_star`: Allows to skip a RDF-star related preprocessing step. This can be
       used to improve performance a little bit when you know the encoded data doesn't
       include any RDF-star statements. Defaults to the returned value of `RDF.star?/0`.
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

  defp compile(nil, _, _, _), do: []
  defp compile(string, _, _, _) when is_binary(string), do: string

  defp compile(element, format, _, _) do
    raise "unknown #{format_label(format)} document element: #{inspect(element)}"
  end

  defp base_directive(nil, _, _), do: []
  defp base_directive(_, %{implicit_base: true}, _), do: []

  defp base_directive(base, state, opts) do
    [
      indentation(state),
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
        indent: state.base_indent,
        iodata: true
      )
    end
  end

  defp graph(%State{graph: %Graph{name: nil}} = state), do: graph_statements(state)

  defp graph(%State{graph: %Graph{name: name}} = state) do
    [
      "GRAPH ",
      term(name, state, :subject),
      " {\n",
      graph_statements(State.indent(state)),
      line_prefixed("}", state, :closing, {:graph, name}),
      "\n"
    ]
    |> line_prefixed(state, :graph, name)
  end

  defp graph_statements(%{single_triple_lines: true} = state) do
    state.graph
    |> CompactStarGraph.compact(state.rdf_star)
    |> Sequencer.descriptions(State.base_iri(state))
    |> Enum.map(
      &(&1
        |> description_statements(state)
        |> line_prefixed(state, :description, &1.subject))
    )
    |> Enum.reject(&Enum.empty?/1)
    |> Enum.intersperse("\n")
  end

  defp graph_statements(state) do
    state.graph
    |> CompactStarGraph.compact(state.rdf_star)
    |> Sequencer.descriptions(State.base_iri(state))
    |> Enum.map(&(&1 |> description_statements(state) |> indented(state)))
    |> Enum.reject(&Enum.empty?/1)
    |> Enum.intersperse("\n")
  end

  defp description_statements(description, state) do
    if Description.empty?(description) do
      raise Graph.EmptyDescriptionError, subject: description.subject
    else
      case State.bnode_type(state, description.subject) do
        :unrefed_bnode_subject_term -> unrefed_bnode_subject_term(description, state)
        :unrefed_bnode_object_term -> []
        :normal -> full_description_statements(description, state)
      end
    end
  end

  defp unrefed_bnode_subject_term(bnode_description, state) do
    if !state.single_triple_lines && State.valid_list_node?(state, bnode_description.subject) do
      bnode_description.subject
      |> list_term(state)
      |> full_description_statements(list_subject_description(bnode_description), state)
    else
      [blank_node_property_list(bnode_description, state), " .\n"]
    end
  end

  defp blank_node_property_list(description, %{single_triple_lines: true} = state) do
    if Description.empty?(description) do
      "[]"
    else
      [
        "[\n",
        predications(description, indent(state)),
        "\n",
        line_prefixed("]", state, :closing, {:blank_node_property_list, description.subject})
      ]
    end
  end

  defp blank_node_property_list(description, state) do
    if Description.empty?(description) do
      "[]"
    else
      indented = indent(state)

      [
        "[",
        newline_indentation(indented),
        predications(description, indented),
        newline_indentation(state),
        "]"
      ]
    end
  end

  defp full_description_statements(description, state) do
    description.subject
    |> term(state, :subject)
    |> full_description_statements(description, state)
  end

  defp full_description_statements(subject, description, %{single_triple_lines: true} = state) do
    [subject, "\n", predications(description, indent(state)), " .\n"]
  end

  defp full_description_statements(subject, description, state) do
    state = indent(state)
    [subject, newline_indentation(state), predications(description, state), " .\n"]
  end

  defp predications(description, state) do
    separator = if state.single_triple_lines, do: " ;\n", else: [" ;", newline_indentation(state)]
    subject = description.subject

    description
    |> Sequencer.predications()
    |> Enum.map(&predication(&1, subject, state))
    |> Enum.intersperse(separator)
  end

  defp predication({predicate, objects}, subject, %{single_triple_lines: true} = state) do
    objects
    |> Enum.map(fn {object, _} = object_tuple ->
      triple = {subject, predicate, object}

      [term(predicate, state, :predicate), " ", object(object_tuple, triple, state)]
      |> line_prefixed(state, :triple, triple)
    end)
    |> Enum.intersperse(" ;\n")
  end

  defp predication({predicate, objects}, _subject, state) do
    [term(predicate, state, :predicate), " " | objects(objects, state)]
  end

  defp objects(objects, state) do
    {objects, with_annotations?} =
      Enum.map_reduce(objects, false, fn {object, annotation}, with_annotations? ->
        if annotation do
          {object_with_annotation(object, annotation, state), true}
        else
          {object_without_annotation(object, state), with_annotations?}
        end
      end)

    separator =
      if with_annotations?,
        do: ["," | state |> State.indent() |> State.newline_indentation()],
        else: ", "

    Enum.intersperse(objects, separator)
  end

  defp object({object, nil}, _, state), do: object_without_annotation(object, state)

  defp object({object, annotation}, triple, state) do
    object_with_annotation(object, Description.change_subject(annotation, triple), state)
  end

  defp object_without_annotation(object, state) do
    term(object, state, :object)
  end

  defp object_with_annotation(object, annotation, state) do
    [
      object_without_annotation(object, state),
      " {|",
      if(state.single_triple_lines, do: "\n", else: " "),
      predications(annotation, state |> State.indent() |> State.indent()),
      " |}"
    ]
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

  defp unrefed_bnode_object_term(bnode, state) do
    if !state.single_triple_lines && State.valid_list_node?(state, bnode) do
      list_term(bnode, state)
    else
      state.graph
      |> Graph.description(bnode)
      |> blank_node_property_list(state)
    end
  end

  defp list_term(head, state) do
    head
    |> State.list_values(state)
    |> term(state, :list)
  end

  defp term(@rdf_type, _, :predicate), do: "a"
  defp term(@rdf_nil, _, _), do: "()"

  defp term(%IRI{} = iri, state, _) do
    based_name(iri, state.base) ||
      prefixed_name(iri, state.prefixes, state.pn_local_validation) ||
      ["<", to_string(iri), ">"]
  end

  defp term(%BlankNode{} = bnode, state, position) when position in ~w[object list]a do
    if State.bnode_type(state, bnode) == :unrefed_bnode_object_term do
      unrefed_bnode_object_term(bnode, state)
    else
      to_string(bnode)
    end
  end

  defp term(%BlankNode{} = bnode, _, _), do: to_string(bnode)

  defp term(%Literal{literal: %LangString{} = lang_string}, _, _) do
    [quoted(lang_string.value), "@", lang_string.language]
  end

  defp term(%Literal{literal: %XSD.String{}} = literal, _, _) do
    literal |> Literal.lexical() |> quoted()
  end

  defp term(%Literal{literal: %datatype{}} = literal, state, _)
       when datatype in @native_supported_datatypes do
    cond do
      not Literal.valid?(literal) -> typed_literal_term(literal, state)
      not Literal.canonical?(literal) -> uncanonical_form(datatype, literal, state)
      true -> Literal.canonical_lexical(literal)
    end
  end

  defp term(%Literal{} = literal, state, _), do: typed_literal_term(literal, state)

  defp term({s, p, o}, state, _) do
    [
      "<< ",
      term(s, state, :subject),
      " ",
      term(p, state, :predicate),
      " ",
      term(o, state, :object),
      " >>"
    ]
  end

  defp term(list, state, :list) do
    [
      "(",
      list
      |> Enum.map(&term(&1, state, :list))
      |> Enum.intersperse(" "),
      ")"
    ]
  end

  defp uncanonical_form(XSD.Double, literal, state) do
    if literal |> Literal.lexical() |> String.contains?(["e", "E"]) do
      Literal.lexical(literal)
    else
      typed_literal_term(literal, state)
    end
  end

  defp uncanonical_form(_, literal, state), do: typed_literal_term(literal, state)

  defp based_name(%IRI{} = iri, base), do: iri |> to_string() |> based_name(base)
  defp based_name(_, nil), do: nil

  defp based_name(iri, base) do
    if String.starts_with?(iri, base) do
      ["<", String.slice(iri, String.length(base)..-1//1), ">"]
    end
  end

  defp typed_literal_term(%Literal{} = literal, state) do
    [
      ~s["],
      escape_string(Literal.lexical(literal)),
      ~s["^^],
      literal
      |> Literal.datatype_id()
      |> term(state, :datatype)
    ]
  end

  def prefixed_name(iri, prefixes, pn_local_validation \\ :fast) do
    case PrefixMap.prefix_name_pair(prefixes, iri) do
      {prefix, name} -> if valid_pn_local?(name, pn_local_validation), do: [prefix, ":", name]
      _ -> nil
    end
  end

  @doc """
  Validates if the local part of a prefixed name is valid according to the Turtle grammar for a `PN_LOCAL`.
  """
  def valid_pn_local?(pn_local, pn_local_validation \\ :fast)

  def valid_pn_local?(_pn_local, :none), do: true
  def valid_pn_local?("", _), do: true

  @fast_pn_local_regex ~r/
     ^[\p{L}\p{Nd}_:%]
      [\p{L}\p{Nd}\p{M}\p{Pc}_.:~\-%]*
      [\p{L}\p{Nd}_:]?$
    /ux

  def valid_pn_local?(pn_local, :fast), do: String.match?(pn_local, @fast_pn_local_regex)

  defp quoted(string) do
    if String.contains?(string, ["\n", "\r"]) do
      [~s["""], escape_string(string, :double, true), ~s["""]]
    else
      [~s["], escape_string(string, :double), ~s["]]
    end
  end

  @doc false
  def escape_string(string, quotes \\ :double, long \\ false) do
    string
    |> String.replace("\\", "\\\\")
    |> String.replace("\b", "\\b")
    |> String.replace("\f", "\\f")
    |> escape_tabs(long)
    |> escape_newlines(long)
    |> escape_quotes(quotes, long)
  end

  defp escape_tabs(string, true), do: string
  defp escape_tabs(string, false), do: String.replace(string, "\t", "\\t")

  defp escape_newlines(string, true), do: string

  defp escape_newlines(string, false) do
    string
    |> String.replace("\n", "\\n")
    |> String.replace("\r", "\\r")
  end

  defp escape_quotes(string, :double, false), do: String.replace(string, ~S["], ~S[\"])
  defp escape_quotes(string, :single, false), do: String.replace(string, ~S['], ~S[\'])

  defp escape_quotes(string, :double, true) do
    string
    |> String.replace(~S["""], ~S[\"""])
    |> escape_ending_quotes(~S["])
  end

  defp escape_quotes(string, :single, true) do
    string
    |> String.replace(~S['''], ~S[\'''])
    |> escape_ending_quotes(~S['])
  end

  defp escape_ending_quotes(string, quote) do
    if String.ends_with?(string, quote) do
      String.slice(string, 0..-2//1) <> "\\" <> quote
    else
      string
    end
  end
end
