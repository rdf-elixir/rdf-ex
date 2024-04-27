defmodule RDF.TurtleTriG.Encoder.BnodeInfo do
  @moduledoc false

  defstruct [:bnode_ref_counter, :list_nodes, :list_values]

  alias RDF.{BlankNode, List, Description, Graph, Dataset}

  def new(data) do
    {bnode_ref_counter, nesting_parents, list_parents} = check(data)

    {bnode_ref_counter, list_nodes, list_values} =
      if match?(%Dataset{}, data) do
        data
        |> Dataset.graphs()
        |> Enum.reduce({bnode_ref_counter, %{}, %{}}, fn
          graph, {bnode_ref_counter, list_nodes, list_values} ->
            bnode_ref_counter =
              handle_bnode_cycles(nesting_parents, bnode_ref_counter)

            {graph_list_nodes, graph_list_values} =
              valid_lists(list_parents[graph.name], bnode_ref_counter, graph)

            {
              bnode_ref_counter,
              Map.put(list_nodes, graph.name, graph_list_nodes),
              Map.put(list_values, graph.name, graph_list_values)
            }
        end)
      else
        bnode_ref_counter = handle_bnode_cycles(nesting_parents, bnode_ref_counter)
        {list_nodes, list_values} = valid_lists(list_parents, bnode_ref_counter, data)
        {bnode_ref_counter, %{data.name => list_nodes}, %{data.name => list_values}}
      end

    %__MODULE__{
      bnode_ref_counter: bnode_ref_counter,
      list_nodes: list_nodes,
      list_values: list_values
    }
  end

  def bnode_type(bnode_info, %BlankNode{} = bnode) do
    case bnode_ref_counter(bnode_info.bnode_ref_counter, bnode) do
      0 -> :unrefed_bnode_subject_term
      1 -> :unrefed_bnode_object_term
      _ -> :normal
    end
  end

  def bnode_type(_, _), do: :normal

  def list_values(bnode_info, graph_name, head), do: bnode_info.list_values[graph_name][head]

  def valid_list_node?(bnode_info, graph_name, bnode),
    do: MapSet.member?(bnode_info.list_nodes[graph_name], bnode)

  defp check(%Dataset{} = dataset) do
    dataset
    |> Dataset.graphs()
    |> Enum.reduce({%{}, %{}, %{}}, fn
      graph, {bnode_ref_counter, nesting_parents, list_parents} ->
        {bnode_ref_counter, nesting_parents, graph_list_parents} =
          check(graph, {bnode_ref_counter, nesting_parents, %{}})

        {bnode_ref_counter, nesting_parents,
         Map.put(list_parents, graph.name, graph_list_parents)}
    end)
  end

  defp check(%Graph{} = graph, acc \\ {%{}, %{}, %{}}) do
    graph
    |> Graph.descriptions()
    |> Enum.reduce(acc, &check_description/2)
  end

  defp check_description(
         %Description{subject: subject} = description,
         {bnode_ref_counter, nesting_parents, list_parents}
       ) do
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

  defp to_list?(%Description{} = description, 0), do: List.node?(description)
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
      with list when not is_nil(list) <- List.new(head_node, graph),
           list_nodes = List.nodes(list),
           true <-
             Enum.all?(list_nodes, fn
               %BlankNode{} = list_node -> MapSet.member?(all_list_nodes, list_node)
               _ -> false
             end) do
        {
          Enum.reduce(list_nodes, valid_list_nodes, &MapSet.put(&2, &1)),
          Map.put(list_values, head_node, List.values(list))
        }
      else
        _ -> {valid_list_nodes, list_values}
      end
    end)
  end

  defp bnode_ref_counter(bnode_ref_counter, bnode) do
    Map.get(bnode_ref_counter, bnode, 0)
  end

  defp incr_bnode_ref_counter(bnode_ref_counter, bnode, count \\ 1) do
    Map.update(bnode_ref_counter, bnode, 1, &(&1 + count))
  end
end
