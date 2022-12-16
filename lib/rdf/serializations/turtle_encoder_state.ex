defmodule RDF.Turtle.Encoder.State do
  @moduledoc false

  defstruct [
    :graph,
    :base,
    :prefixes,
    :implicit_base,
    :bnode_ref_counter,
    :list_nodes,
    :list_values,
    :indentation
  ]

  @implicit_default_base "http://this-implicit-default-base-iri-should-never-appear-in-a-document"

  alias RDF.{IRI, BlankNode, Description, Graph, PrefixMap}

  def new(graph, opts) do
    base =
      Keyword.get(opts, :base, Keyword.get(opts, :base_iri))
      |> base_iri(graph)
      |> init_base_iri()

    prefixes = Keyword.get(opts, :prefixes) |> prefixes(graph)

    {graph, base, opts} =
      add_base_description(graph, base, Keyword.get(opts, :base_description), opts)

    {bnode_ref_counter, nesting_parents, list_parents} = bnode_info(graph)
    bnode_ref_counter = handle_bnode_cycles(nesting_parents, bnode_ref_counter)
    {list_nodes, list_values} = valid_lists(list_parents, bnode_ref_counter, graph)

    %__MODULE__{
      graph: graph,
      base: base,
      implicit_base: Keyword.get(opts, :implicit_base),
      prefixes: prefixes,
      bnode_ref_counter: bnode_ref_counter,
      list_nodes: list_nodes,
      list_values: list_values,
      indentation: Keyword.get(opts, :indent)
    }
  end

  defp base_iri(nil, %Graph{base_iri: base_iri}) when not is_nil(base_iri), do: base_iri
  defp base_iri(nil, _), do: RDF.default_base_iri()
  defp base_iri(base_iri, _), do: IRI.coerce_base(base_iri)

  defp init_base_iri(nil), do: nil
  defp init_base_iri(base_iri), do: to_string(base_iri)

  defp prefixes(nil, %Graph{prefixes: prefixes}) when not is_nil(prefixes), do: prefixes

  defp prefixes(nil, _), do: RDF.default_prefixes()
  defp prefixes(prefixes, _), do: PrefixMap.new(prefixes)

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

  def base_iri(state) do
    if base = state.base do
      RDF.iri(base)
    end
  end

  def list_values(head, state), do: state.list_values[head]

  def valid_list_node?(state, bnode) do
    MapSet.member?(state.list_nodes, bnode)
  end

  def bnode_type(state, %BlankNode{} = bnode) do
    case bnode_ref_counter(state.bnode_ref_counter, bnode) do
      0 -> :unrefed_bnode_subject_term
      1 -> :unrefed_bnode_object_term
      _ -> :normal
    end
  end

  def bnode_type(_, _), do: :normal

  defp bnode_ref_counter(bnode_ref_counter, bnode) do
    Map.get(bnode_ref_counter, bnode, 0)
  end

  defp incr_bnode_ref_counter(bnode_ref_counter, bnode, count \\ 1) do
    Map.update(bnode_ref_counter, bnode, 1, &(&1 + count))
  end

  defp bnode_info(graph) do
    graph
    |> Graph.descriptions()
    |> Enum.reduce(
      {%{}, %{}, %{}},
      fn %Description{subject: subject} = description,
         {bnode_ref_counter, nesting_parents, list_parents} ->
        # We don't count blank node subjects, because when a blank node only occurs as a subject in
        # multiple triples, we still can and want to use the square bracket syntax for its encoding.

        blank_node_subject = match?(%BlankNode{}, subject)

        list_parents =
          if blank_node_subject and
               to_list?(description, bnode_ref_counter(bnode_ref_counter, subject)),
             do: Map.put_new(list_parents, subject, nil),
             else: list_parents

        bnode_ref_counter = handle_quoted_triples(subject, bnode_ref_counter)

        Enum.reduce(
          description.predications,
          {bnode_ref_counter, nesting_parents, list_parents},
          fn {predicate, objects}, {bnode_ref_counter, nesting_parents, list_parents} ->
            Enum.reduce(Map.keys(objects), {bnode_ref_counter, nesting_parents, list_parents}, fn
              {_, _, _} = quoted_triple, {bnode_ref_counter, nesting_parents, list_parents} ->
                {handle_quoted_triples(quoted_triple, bnode_ref_counter), nesting_parents,
                 list_parents}

              %BlankNode{} = object, {bnode_ref_counter, nesting_parents, list_parents} ->
                {
                  incr_bnode_ref_counter(bnode_ref_counter, object),
                  if blank_node_subject do
                    Map.update(nesting_parents, object, [subject], &[subject | &1])
                  else
                    nesting_parents
                  end,
                  if predicate == RDF.rest() do
                    Map.put_new(list_parents, object, subject)
                  else
                    list_parents
                  end
                }

              _, acc ->
                acc
            end)
          end
        )
      end
    )
  end

  defp handle_quoted_triples({s, _, o}, bnode_ref_counter) do
    bnode_ref_counter =
      case s do
        %BlankNode{} -> incr_bnode_ref_counter(bnode_ref_counter, s)
        _ -> bnode_ref_counter
      end

    case o do
      %BlankNode{} -> incr_bnode_ref_counter(bnode_ref_counter, o)
      _ -> bnode_ref_counter
    end
  end

  defp handle_quoted_triples(_, bnode_ref_counter), do: bnode_ref_counter

  defp handle_bnode_cycles(nesting_parents, bnode_ref_counter) do
    Enum.reduce(nesting_parents, bnode_ref_counter, fn {object, subject}, bnode_ref_counter ->
      if bnode_cycle = bnode_cycle(subject, nesting_parents, bnode_ref_counter, [object]) do
        Enum.reduce(bnode_cycle, bnode_ref_counter, &incr_bnode_ref_counter(&2, &1, 2))
      else
        bnode_ref_counter
      end
    end)
  end

  defp bnode_cycle(nil, _, _, _), do: nil

  defp bnode_cycle(bnodes, nesting_parents, ref_counter, path) when is_list(bnodes) do
    Enum.find_value(bnodes, &bnode_cycle(&1, nesting_parents, ref_counter, path))
  end

  defp bnode_cycle(bnode, nesting_parents, ref_counter, path) do
    cond do
      bnode in path -> path
      bnode_ref_counter(ref_counter, bnode) > 1 -> nil
      true -> bnode_cycle(nesting_parents[bnode], nesting_parents, ref_counter, [bnode | path])
    end
  end

  @list_properties MapSet.new([
                     RDF.Utils.Bootstrapping.rdf_iri("first"),
                     RDF.Utils.Bootstrapping.rdf_iri("rest")
                   ])

  defp to_list?(%Description{} = description, 1) do
    Description.count(description) == 2 and
      Description.predicates(description) |> MapSet.equal?(@list_properties)
  end

  defp to_list?(%Description{} = description, 0), do: RDF.list?(description)
  defp to_list?(_, _), do: false

  defp valid_lists(list_parents, bnode_ref_counter, graph) do
    head_nodes = for {list_node, nil} <- list_parents, do: list_node

    all_list_nodes =
      for {list_node, _} <- list_parents,
          bnode_ref_counter(bnode_ref_counter, list_node) < 2,
          into: MapSet.new() do
        list_node
      end

    Enum.reduce(head_nodes, {MapSet.new(), %{}}, fn head_node, {valid_list_nodes, list_values} ->
      with list when not is_nil(list) <- RDF.List.new(head_node, graph),
           list_nodes = RDF.List.nodes(list),
           true <-
             Enum.all?(list_nodes, fn
               %BlankNode{} = list_node -> MapSet.member?(all_list_nodes, list_node)
               _ -> false
             end) do
        {
          Enum.reduce(list_nodes, valid_list_nodes, &MapSet.put(&2, &1)),
          Map.put(list_values, head_node, RDF.List.values(list))
        }
      else
        _ -> {valid_list_nodes, list_values}
      end
    end)
  end
end
