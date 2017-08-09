defmodule RDF.Turtle.Encoder.State do
  @moduledoc false

  alias RDF.{Literal, BlankNode, Description, List}


  def start_link(data, base, prefixes) do
    Agent.start_link(fn -> %{data: data, base: base, prefixes: prefixes} end)
  end

  def stop(state) do
    Agent.stop(state)
  end

  def data(state),              do: Agent.get(state, &(&1.data))
  def base(state),              do: Agent.get(state, &(&1.base))
  def prefixes(state),          do: Agent.get(state, &(&1.prefixes))
  def list_nodes(state),        do: Agent.get(state, &(&1.list_nodes))
  def bnode_ref_counter(state), do: Agent.get(state, &(&1.bnode_ref_counter))

  def bnode_ref_counter(state, bnode) do
    bnode_ref_counter(state) |> Map.get(bnode, 0)
  end

  def list_values(head, state), do: Agent.get(state, &(&1.list_values[head]))

  def preprocess(state) do
    with data = data(state),
         {bnode_ref_counter, list_parents} = bnode_info(data),
         {list_nodes, list_values} = valid_lists(list_parents, bnode_ref_counter, data)
    do
      Agent.update(state, &Map.put(&1, :bnode_ref_counter, bnode_ref_counter))
      Agent.update(state, &Map.put(&1, :list_nodes, list_nodes))
      Agent.update(state, &Map.put(&1, :list_values, list_values))
    end
  end

  defp bnode_info(data) do
    data
    |> RDF.Data.descriptions
    |> Enum.reduce({%{}, %{}},
         fn %Description{subject: subject} = description,
                  {bnode_ref_counter, list_parents} ->

           list_parents =
             if match?(%BlankNode{}, subject) and
                  to_list?(description, Map.get(bnode_ref_counter, subject, 0)),
                 do: Map.put_new(list_parents, subject, nil),
               else: list_parents

           Enum.reduce(description.predications, {bnode_ref_counter, list_parents}, fn
             ({predicate, objects}, {bnode_ref_counter, list_parents}) ->
               Enum.reduce(Map.keys(objects), {bnode_ref_counter, list_parents}, fn
                 (%BlankNode{} = object, {bnode_ref_counter, list_parents}) ->
                   {
                     # Note: The following conditional produces imprecise results
                     # (sometimes the occurrence in the subject counts, sometimes it doesn't),
                     # but is sufficient for the current purpose of handling the
                     # case of a statement with the same subject and object bnode.
                     Map.update(bnode_ref_counter, object,
                       (if subject == object, do: 2, else: 1), &(&1 + 1)),
                     if predicate == RDF.rest do
                       Map.put_new(list_parents, object, subject)
                     else
                       list_parents
                     end
                   }
                 (_, {bnode_ref_counter, list_parents}) ->
                   {bnode_ref_counter, list_parents}
               end)
           end)
         end)
  end

  @list_properties MapSet.new([RDF.first, RDF.rest])

  defp to_list?(%Description{} = description, 1) do
    Description.count(description) == 2 and
      Description.predicates(description) |> MapSet.equal?(@list_properties)
  end

  defp to_list?(%Description{} = description, 0),
    do: RDF.list?(description)

  defp to_list?(_, _),
    do: false


  defp valid_lists(list_parents, bnode_ref_counter, data) do
    head_nodes = for {list_node, nil} <- list_parents, do: list_node

    all_list_nodes = MapSet.new(
      for {list_node, _} <- list_parents, Map.get(bnode_ref_counter, list_node, 0) < 2 do
        list_node
      end)

    Enum.reduce head_nodes, {MapSet.new, %{}},
      fn head_node, {valid_list_nodes, list_values} ->
        with list when not is_nil(list) <-
                RDF.List.new(head_node, data),
             list_nodes =
                RDF.List.nodes(list),
             true <-
                Enum.all?(list_nodes, fn
                  %BlankNode{} = list_node ->
                    MapSet.member?(all_list_nodes, list_node)
                  _ ->
                    false
                end)
        do
          {
            Enum.reduce(list_nodes, valid_list_nodes, fn list_node, valid_list_nodes ->
              MapSet.put(valid_list_nodes, list_node)
            end),
            Map.put(list_values, head_node, RDF.List.values(list)),
          }
        else
          _ -> {valid_list_nodes, list_values}
        end
      end
  end

end
