defmodule RDF.Turtle.Encoder do
  @moduledoc """
  An encoder for Turtle serializations of RDF.ex data structures.

  As for all encoders of `RDF.Serialization.Format`s, you normally won't use these
  functions directly, but via one of the `write_` functions on the `RDF.Turtle`
  format module or the generic `RDF.Serialization` module.


  ## Options

  - `:prefixes`: Allows to specify the prefixes to be used as a `RDF.PrefixMap` or
    anything from which a `RDF.PrefixMap` can be created with `RDF.PrefixMap.new/1`.
    If not specified the ones from the given graph are used or if these are also not
    present the `RDF.default_prefixes/0`.
  - `:base`: : Allows to specify the base URI to be used for a `@base` directive.
    If not specified the one from the given graph is used or if there is also none
    specified for the graph the `RDF.default_base_iri/0`.
  - `:implicit_base`: This boolean flag allows to use a base URI to get relative IRIs
    without embedding it explicitly in the content with a `@base` directive, so that
    the URIs will be resolved according to the remaining strategy specified in
    section 5.1 of [RFC3986](https://www.ietf.org/rfc/rfc3986.txt) (default: `false`).
  - `:base_description`: Allows to provide a description of the resource denoted by
    the base URI. This option is especially useful when the base URI is actually not
    specified, e.g. in the common use case of wanting to describe the Turtle document
    itself, which should be denoted by the URL where it is hosted as the implicit base
    URI.
  - `:only`: Allows to specify which parts of a Turtle document should be generated.
    Possible values: `:base`, `:prefixes`, `:directives` (means the same as `[:base, :prefixes]`),
    `:triples` or a list with any combination of these values.
  - `:indent`: Allows to specify the number of spaces the output should be indented.

  """

  use RDF.Serialization.Encoder

  alias RDF.Turtle.Encoder.State
  alias RDF.Turtle.Star.CompactGraph
  alias RDF.{BlankNode, Description, Graph, IRI, XSD, Literal, LangString, PrefixMap}

  import RDF.NTriples.Encoder, only: [escape_string: 1]

  @document_structure [
    :base,
    :prefixes,
    :triples
  ]

  @indentation 4

  @native_supported_datatypes [
    XSD.Boolean,
    XSD.Integer,
    XSD.Double,
    XSD.Decimal
  ]
  @rdf_type RDF.Utils.Bootstrapping.rdf_iri("type")
  @rdf_nil RDF.Utils.Bootstrapping.rdf_iri("nil")

  # Defines rdf:type of subjects to be serialized at the beginning of the encoded graph
  @top_classes [RDF.Utils.Bootstrapping.rdfs_iri("Class")]

  # Defines order of predicates at the beginning of a resource description
  @predicate_order [
    @rdf_type,
    RDF.Utils.Bootstrapping.rdfs_iri("label"),
    IRI.new("http://purl.org/dc/terms/title")
  ]
  @ordered_properties MapSet.new(@predicate_order)

  @impl RDF.Serialization.Encoder
  @spec encode(Graph.t() | Description.t(), keyword) :: {:ok, String.t()} | {:error, any}
  def encode(data, opts \\ [])

  def encode(%Description{} = description, opts), do: description |> Graph.new() |> encode(opts)

  def encode(%Graph{} = graph, opts) do
    state = State.new(graph, opts)

    {:ok,
     (Keyword.get(opts, :only) || @document_structure)
     |> compile(state, opts)}
  end

  defp compile(:base, %{base: base} = state, opts), do: base_directive(base, state, opts)

  defp compile(:prefixes, %{prefixes: prefixes} = state, opts),
    do: prefix_directives(prefixes, state, opts)

  defp compile(:triples, state, _opts), do: graph_statements(state)

  defp compile(:directives, state, opts), do: [:base, :prefixes] |> compile(state, opts)

  defp compile(elements, state, opts) when is_list(elements) do
    Enum.map_join(elements, &compile(&1, state, opts))
  end

  defp compile(element, _, _) do
    raise "unknown Turtle document element: #{inspect(element)}"
  end

  defp base_directive(nil, _, _), do: ""
  defp base_directive(_, %{implicit_base: true}, _), do: ""

  defp base_directive(base, state, opts) do
    indent(state) <>
      case Keyword.get(opts, :directive_style) do
        :sparql -> "BASE <#{base}>"
        _ -> "@base <#{base}> ."
      end <> "\n\n"
  end

  defp prefix_directives(prefixes, state, opts) do
    if Enum.empty?(prefixes.map) do
      ""
    else
      PrefixMap.to_header(prefixes, Keyword.get(opts, :directive_style, :turtle),
        indent: state.indentation
      ) <> "\n"
    end
  end

  defp graph_statements(state) do
    indentation = state.indentation || 0
    indent = indent(indentation)

    state.graph
    |> CompactGraph.compact()
    |> Graph.descriptions()
    |> order_descriptions(state)
    |> Enum.map(&description_statements(&1, state, indentation))
    |> Enum.reject(&is_nil/1)
    |> Enum.map_join("\n", &(indent <> &1))
  end

  defp order_descriptions(descriptions, state) do
    base_iri = State.base_iri(state)
    group = Enum.group_by(descriptions, &description_group(&1, base_iri))

    ordered_descriptions =
      (@top_classes
       |> Stream.map(&group[&1])
       |> Stream.reject(&is_nil/1)
       |> Enum.flat_map(&sort_descriptions/1)) ++
        (group |> Map.get(:other, []) |> sort_descriptions())

    case group[:base] do
      [base] -> [base | ordered_descriptions]
      _ -> ordered_descriptions
    end
  end

  defp description_group(%{subject: base_iri}, base_iri), do: :base

  defp description_group(description, _) do
    if types = description.predications[@rdf_type] do
      Enum.find(@top_classes, :other, &Map.has_key?(types, &1))
    else
      :other
    end
  end

  defp sort_descriptions(descriptions), do: Enum.sort(descriptions, &description_order/2)

  defp description_order(%{subject: %IRI{}}, %{subject: %BlankNode{}}), do: true
  defp description_order(%{subject: %BlankNode{}}, %{subject: %IRI{}}), do: false

  defp description_order(%{subject: {s, p, o1}}, %{subject: {s, p, o2}}),
    do: to_string(o1) < to_string(o2)

  defp description_order(%{subject: {s, p1, _}}, %{subject: {s, p2, _}}),
    do: to_string(p1) < to_string(p2)

  defp description_order(%{subject: {s1, _, _}}, %{subject: {s2, _, _}}),
    do: to_string(s1) < to_string(s2)

  defp description_order(%{subject: {_, _, _}}, %{subject: _}), do: false
  defp description_order(%{subject: _}, %{subject: {_, _, _}}), do: true
  defp description_order(%{subject: s1}, %{subject: s2}), do: to_string(s1) < to_string(s2)

  defp description_statements(description, state, nesting) do
    if Description.empty?(description) do
      raise Graph.EmptyDescriptionError, subject: description.subject
    else
      case State.bnode_type(state, description.subject) do
        :unrefed_bnode_subject_term -> unrefed_bnode_subject_term(description, state, nesting)
        :unrefed_bnode_object_term -> nil
        :normal -> full_description_statements(description, state, nesting)
      end
    end
  end

  defp full_description_statements(subject, description, state, nesting) do
    nesting = nesting + @indentation
    subject <> newline_indent(nesting) <> predications(description, state, nesting) <> " .\n"
  end

  defp full_description_statements(description, state, nesting) do
    term(description.subject, state, :subject, nesting)
    |> full_description_statements(description, state, nesting)
  end

  defp blank_node_property_list(description, state, nesting) do
    indented = nesting + @indentation

    if Description.empty?(description) do
      "[]"
    else
      "[" <>
        newline_indent(indented) <>
        predications(description, state, indented) <>
        newline_indent(nesting) <> "]"
    end
  end

  defp predications(description, state, nesting) do
    description.predications
    |> order_predications()
    |> Enum.map_join(" ;" <> newline_indent(nesting), &predication(&1, state, nesting))
  end

  defp order_predications(predications) do
    sorted_predications =
      @predicate_order
      |> Enum.map(fn predicate -> {predicate, predications[predicate]} end)
      |> Enum.reject(fn {_, objects} -> is_nil(objects) end)

    unsorted_predications =
      Enum.reject(predications, fn {predicate, _} ->
        MapSet.member?(@ordered_properties, predicate)
      end)

    sorted_predications ++ unsorted_predications
  end

  defp predication({predicate, objects}, state, nesting) do
    term(predicate, state, :predicate, nesting) <> " " <> objects(objects, state, nesting)
  end

  defp objects(objects, state, nesting) do
    {objects, with_annotations} =
      Enum.map_reduce(objects, false, fn {object, annotation}, with_annotations ->
        if annotation do
          {
            term(object, state, :object, nesting) <>
              " {| #{predications(annotation, state, nesting + 2 * @indentation)} |}",
            true
          }
        else
          {term(object, state, :object, nesting), with_annotations}
        end
      end)

    # TODO: split if the line gets too long
    separator =
      if with_annotations,
        do: "," <> newline_indent(nesting + @indentation),
        else: ", "

    Enum.join(objects, separator)
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
      blank_node_property_list(bnode_description, state, nesting) <> " .\n"
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
      "<#{to_string(iri)}>"
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
    quoted(lang_string.value) <> "@" <> lang_string.language
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
    "<< #{term(s, state, :subject, nesting)} #{term(p, state, :predicate, nesting)} #{term(o, state, :object, nesting)} >>"
  end

  defp term(list, state, _, nesting) when is_list(list) do
    "(" <> Enum.map_join(list, " ", &term(&1, state, :list, nesting)) <> ")"
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

  defp based_name(%IRI{} = iri, base), do: based_name(to_string(iri), base)
  defp based_name(_, nil), do: nil

  defp based_name(iri, base) do
    if String.starts_with?(iri, base) do
      "<#{String.slice(iri, String.length(base)..-1//1)}>"
    end
  end

  defp typed_literal_term(%Literal{} = literal, state, nesting) do
    ~s["#{escape_string(Literal.lexical(literal))}"^^#{literal |> Literal.datatype_id() |> term(state, :datatype, nesting)}]
  end

  def prefixed_name(iri, prefixes) do
    case PrefixMap.prefix_name_pair(prefixes, iri) do
      {prefix, name} -> if valid_pn_local?(name), do: prefix <> ":" <> name
      _ -> nil
    end
  end

  defp valid_pn_local?(name) do
    String.match?(name, ~r/^([[:alpha:]]|[[:digit:]]|_|:)*$/u)
  end

  defp quoted(string) do
    if String.contains?(string, ["\n", "\r"]) do
      ~s["""#{string}"""]
    else
      ~s["#{escape_string(string)}"]
    end
  end

  defp newline_indent(nesting), do: "\n" <> indent(nesting)

  defp indent(%State{indentation: indentation}), do: indent(indentation)
  defp indent(nil), do: ""
  defp indent(count), do: String.duplicate(" ", count)
end
