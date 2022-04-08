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
    specified, eg. in the common use case of wanting to describe the Turtle document
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

  @indentation_char " "
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
    RDF.iri("http://purl.org/dc/terms/title")
  ]
  @ordered_properties MapSet.new(@predicate_order)

  @implicit_default_base "http://this-implicit-default-base-iri-should-never-appear-in-a-document"

  @impl RDF.Serialization.Encoder
  @spec encode(Graph.t() | Description.t(), keyword) :: {:ok, String.t()} | {:error, any}
  def encode(data, opts \\ [])

  def encode(%Description{} = description, opts), do: description |> Graph.new() |> encode(opts)

  def encode(%Graph{} = graph, opts) do
    base =
      Keyword.get(opts, :base, Keyword.get(opts, :base_iri))
      |> base_iri(graph)
      |> init_base_iri()

    prefixes =
      Keyword.get(opts, :prefixes)
      |> prefixes(graph)

    {graph, base, opts} =
      add_base_description(graph, base, Keyword.get(opts, :base_description), opts)

    {:ok, state} = State.start_link(graph, base, prefixes)

    try do
      State.preprocess(state)

      {:ok,
       (Keyword.get(opts, :only) || @document_structure)
       |> compile(base, prefixes, state, opts)}
    after
      State.stop(state)
    end
  end

  defp compile(:base, base, _, _, opts), do: base_directive(base, opts)
  defp compile(:prefixes, _, prefixes, _, opts), do: prefix_directives(prefixes, opts)
  defp compile(:triples, _, _, state, opts), do: graph_statements(state, opts)

  defp compile(:directives, base, prefixes, state, opts),
    do: [:base, :prefixes] |> compile(base, prefixes, state, opts)

  defp compile(elements, base, prefixes, state, opts) when is_list(elements) do
    Enum.map_join(elements, &compile(&1, base, prefixes, state, opts))
  end

  defp compile(element, _, _, _, _) do
    raise "unknown Turtle document element: #{inspect(element)}"
  end

  defp base_iri(nil, %Graph{base_iri: base_iri}) when not is_nil(base_iri), do: base_iri
  defp base_iri(nil, _), do: RDF.default_base_iri()
  defp base_iri(base_iri, _), do: IRI.coerce_base(base_iri)

  defp init_base_iri(nil), do: nil
  defp init_base_iri(base_iri), do: to_string(base_iri)

  defp prefixes(nil, %Graph{prefixes: prefixes}) when not is_nil(prefixes), do: prefixes

  defp prefixes(nil, _), do: RDF.default_prefixes()
  defp prefixes(prefixes, _), do: PrefixMap.new(prefixes)

  defp base_directive(nil, _), do: ""

  defp base_directive(base, opts) do
    if Keyword.get(opts, :implicit_base, false) do
      ""
    else
      indent(opts) <>
        case Keyword.get(opts, :directive_style) do
          :sparql -> "BASE <#{base}>"
          _ -> "@base <#{base}> ."
        end <> "\n\n"
    end
  end

  defp prefix_directive({prefix, ns}, opts) do
    indent(opts) <>
      case Keyword.get(opts, :directive_style) do
        :sparql -> "PREFIX #{prefix}: <#{to_string(ns)}>\n"
        _ -> "@prefix #{prefix}: <#{to_string(ns)}> .\n"
      end
  end

  defp prefix_directives(prefixes, opts) do
    case Enum.map(prefixes, &prefix_directive(&1, opts)) do
      [] -> ""
      prefixes -> Enum.join(prefixes, "") <> "\n"
    end
  end

  defp add_base_description(graph, base, nil, opts), do: {graph, base, opts}

  defp add_base_description(graph, nil, base_description, opts) do
    add_base_description(
      graph,
      @implicit_default_base,
      base_description,
      Keyword.put(opts, :implicit_base, true)
    )
  end

  defp add_base_description(graph, base, base_description, opts) do
    {Graph.add(graph, Description.new(base, init: base_description)), base, opts}
  end

  defp graph_statements(state, opts) do
    indent = indent(opts)

    State.data(state)
    |> CompactGraph.compact()
    |> RDF.Data.descriptions()
    |> order_descriptions(state)
    |> Enum.map(&description_statements(&1, state, Keyword.get(opts, :indent, 0)))
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
      with %BlankNode{} <- description.subject,
           ref_count when ref_count < 2 <- State.bnode_ref_counter(state, description.subject) do
        unrefed_bnode_subject_term(description, ref_count, state, nesting)
      else
        _ -> full_description_statements(description, state, nesting)
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
    |> Enum.map(&predication(&1, state, nesting))
    |> Enum.join(" ;" <> newline_indent(nesting))
  end

  @dialyzer {:nowarn_function, order_predications: 1}
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

  defp unrefed_bnode_subject_term(bnode_description, ref_count, state, nesting) do
    if valid_list_node?(bnode_description.subject, state) do
      case ref_count do
        0 ->
          bnode_description.subject
          |> list_term(state, nesting)
          |> full_description_statements(
            list_subject_description(bnode_description),
            state,
            nesting
          )

        1 ->
          nil

        _ ->
          raise "Internal error: This shouldn't happen. Please raise an issue in the RDF.ex project with the input document causing this error."
      end
    else
      case ref_count do
        0 ->
          blank_node_property_list(bnode_description, state, nesting) <> " .\n"

        1 ->
          nil

        _ ->
          raise "Internal error: This shouldn't happen. Please raise an issue in the RDF.ex project with the input document causing this error."
      end
    end
  end

  @dialyzer {:nowarn_function, list_subject_description: 1}
  defp list_subject_description(description) do
    description = Description.delete_predicates(description, [RDF.first(), RDF.rest()])

    if Description.empty?(description) do
      # since the Turtle grammar doesn't allow bare lists, we add a statement
      description |> RDF.type(RDF.List)
    else
      description
    end
  end

  defp unrefed_bnode_object_term(bnode, ref_count, state, nesting) do
    if valid_list_node?(bnode, state) do
      list_term(bnode, state, nesting)
    else
      if ref_count == 1 do
        State.data(state)
        |> RDF.Data.description(bnode)
        |> blank_node_property_list(state, nesting)
      else
        raise "Internal error: This shouldn't happen. Please raise an issue in the RDF.ex project with the input document causing this error."
      end
    end
  end

  defp valid_list_node?(bnode, state) do
    MapSet.member?(State.list_nodes(state), bnode)
  end

  defp list_term(head, state, nesting) do
    head
    |> State.list_values(state)
    |> term(state, :list, nesting)
  end

  defp term(@rdf_type, _, :predicate, _), do: "a"
  defp term(@rdf_nil, _, _, _), do: "()"

  defp term(%IRI{} = iri, state, _, _) do
    based_name(iri, State.base(state)) ||
      prefixed_name(iri, State.prefixes(state)) ||
      "<#{to_string(iri)}>"
  end

  defp term(%BlankNode{} = bnode, state, position, nesting)
       when position in ~w[object list]a do
    if (ref_count = State.bnode_ref_counter(state, bnode)) <= 1 do
      unrefed_bnode_object_term(bnode, ref_count, state, nesting)
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
    if Literal.valid?(literal) do
      Literal.canonical_lexical(literal)
    else
      typed_literal_term(literal, state, nesting)
    end
  end

  defp term(%Literal{} = literal, state, _, nesting),
    do: typed_literal_term(literal, state, nesting)

  defp term({s, p, o}, state, _, nesting) do
    "<< #{term(s, state, :subject, nesting)} #{term(p, state, :predicate, nesting)} #{term(o, state, :object, nesting)} >>"
  end

  defp term(list, state, _, nesting) when is_list(list) do
    "(" <>
      (list
       |> Enum.map(&term(&1, state, :list, nesting))
       |> Enum.join(" ")) <>
      ")"
  end

  defp based_name(%IRI{} = iri, base), do: based_name(to_string(iri), base)
  defp based_name(_, nil), do: nil

  defp based_name(iri, base) do
    if String.starts_with?(iri, base) do
      "<#{String.slice(iri, String.length(base)..-1)}>"
    end
  end

  defp typed_literal_term(%Literal{} = literal, state, nesting) do
    ~s["#{Literal.lexical(literal)}"^^#{literal |> Literal.datatype_id() |> term(state, :datatype, nesting)}]
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

  defp newline_indent(nesting),
    do: "\n" <> String.duplicate(@indentation_char, nesting)

  defp indent(opts) when is_list(opts), do: opts |> Keyword.get(:indent) |> indent()
  defp indent(nil), do: ""
  defp indent(count), do: String.duplicate(" ", count)
end
