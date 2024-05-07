defmodule RDF.TurtleTriG.Encoder.State do
  @moduledoc false

  defstruct [
    :format,
    :data,
    :graph,
    :base,
    :implicit_base,
    :prefixes,
    :pn_local_validation,
    :single_triple_lines,
    :line_prefix,
    :base_indent,
    :indentation,
    :indent_step,
    :bnode_info,
    :rdf_star
  ]

  @default_indent_width 4

  @implicit_default_base "http://this-implicit-default-base-iri-should-never-appear-in-a-document"

  alias RDF.{IRI, Description, Graph, Dataset, Data, PrefixMap}
  alias RDF.TurtleTriG.Encoder.BnodeInfo

  def new(format, data, opts) do
    base =
      Keyword.get(opts, :base, Keyword.get(opts, :base_iri))
      |> base_iri(data)
      |> init_base_iri()

    prefixes = Keyword.get(opts, :prefixes) |> prefixes(data)

    {data, base, opts} =
      add_base_description(data, base, Keyword.get(opts, :base_description), opts)

    line_prefix = Keyword.get(opts, :line_prefix)

    %__MODULE__{
      format: format,
      data: data,
      graph: if(format == :turtle, do: data),
      base: base,
      implicit_base: Keyword.get(opts, :implicit_base),
      prefixes: prefixes,
      pn_local_validation: Keyword.get(opts, :pn_local_validation, :fast),
      base_indent: Keyword.get(opts, :indent),
      indent_step: opts |> Keyword.get(:indent_width, @default_indent_width) |> indent_string(),
      line_prefix: line_prefix,
      single_triple_lines: !!line_prefix || Keyword.get(opts, :single_triple_lines),
      bnode_info: BnodeInfo.new(data),
      rdf_star: Keyword.get(opts, :rdf_star, RDF.star?())
    }
    |> init_indentation()
  end

  defp base_iri(nil, %Graph{base_iri: base_iri}) when not is_nil(base_iri), do: base_iri
  defp base_iri(nil, _), do: RDF.default_base_iri()
  defp base_iri(base_iri, _), do: IRI.coerce_base(base_iri)

  defp init_base_iri(nil), do: nil
  defp init_base_iri(base_iri), do: to_string(base_iri)

  defp prefixes(nil, %PrefixMap{} = prefix_map) do
    if PrefixMap.empty?(prefix_map), do: RDF.default_prefixes(), else: prefix_map
  end

  defp prefixes(nil, %Graph{prefixes: prefixes}), do: prefixes(nil, prefixes)
  defp prefixes(nil, %Dataset{} = dataset), do: prefixes(nil, Dataset.prefixes(dataset))
  defp prefixes(nil, _), do: RDF.default_prefixes()
  defp prefixes(prefixes, _), do: PrefixMap.new(prefixes)

  defp add_base_description(data, base, nil, opts), do: {data, base, opts}

  defp add_base_description(data, nil, base_description, opts) do
    add_base_description(
      data,
      @implicit_default_base,
      base_description,
      Keyword.put(opts, :implicit_base, true)
    )
  end

  defp add_base_description(data, base, base_description, opts) do
    {Data.merge(data, Description.new(base, init: base_description)), base, opts}
  end

  def base_iri(state) do
    if base = state.base do
      IRI.new(base)
    end
  end

  def graph_name(%__MODULE__{format: :turtle}), do: nil
  def graph_name(%__MODULE__{graph: graph}), do: graph.name

  def set_current_graph(%__MODULE__{} = state, graph), do: %__MODULE__{state | graph: graph}

  def init_indentation(%__MODULE__{} = state),
    do: %__MODULE__{state | indentation: []} |> indent(state.base_indent)

  def indent(%__MODULE__{} = state),
    do: %__MODULE__{state | indentation: [state.indent_step | state.indentation]}

  def indent(%__MODULE__{} = state, nil), do: state
  def indent(%__MODULE__{} = state, 0), do: state

  def indent(%__MODULE__{} = state, count),
    do: %__MODULE__{state | indentation: [indent_string(count) | state.indentation]}

  defp indent_string(count), do: String.duplicate(" ", count)

  def indented([], _), do: []
  def indented(iolist, %{indentation: []}), do: iolist
  def indented(iolist, state), do: [state.indentation | iolist]

  def line_prefixed([], _, _, _), do: []
  def line_prefixed(iolist, %{line_prefix: nil} = state, _, _), do: indented(iolist, state)

  def line_prefixed(iolist, %{line_prefix: line_prefix} = state, type, value)
      when is_function(line_prefix) do
    [line_prefix.(type, value, graph_name(state)) | indented(iolist, state)]
  end

  def indentation(%{indentation: indentation}), do: indentation
  def newline_indentation(%{indentation: indentation}), do: ["\n" | indentation]

  def bnode_type(state, bnode), do: BnodeInfo.bnode_type(state.bnode_info, bnode)

  def list_values(head, state),
    do: BnodeInfo.list_values(state.bnode_info, state.graph.name, head)

  def valid_list_node?(state, bnode),
    do: BnodeInfo.valid_list_node?(state.bnode_info, state.graph.name, bnode)
end
