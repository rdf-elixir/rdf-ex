defmodule RDF.TurtleTriG.Decoder.AST do
  @moduledoc false

  alias RDF.{Graph, Dataset, IRI, Literal}
  alias RDF.TurtleTriG.Decoder.State

  def build_dataset(ast, base_iri, opts \\ []) do
    {dataset, %State{namespaces: namespaces, base_iri: base_iri}} =
      Enum.reduce(ast, {Dataset.new(), State.new(base_iri, opts)}, fn
        {:triples, triples_ast}, {dataset, state} ->
          {statements, state} = triples(triples_ast, state)
          {Dataset.add(dataset, statements), state}

        {:graph, graph_name_ast, graph_ast}, {dataset, state} ->
          {graph_name, state} = resolve_node(graph_name_ast, state)
          {graph, state} = do_build_graph(graph_ast, Graph.new(name: graph_name), state)
          {Dataset.add(dataset, graph), state}

        {:directive, directive_ast}, {dataset, state} ->
          {dataset, directive(directive_ast, state)}
      end)

    {:ok, set_graph_directives(dataset, base_iri, namespaces)}
  rescue
    error -> {:error, Exception.message(error)}
  end

  def build_graph(ast, base_iri, opts \\ []) do
    {graph, %State{namespaces: namespaces, base_iri: base_iri}} =
      do_build_graph(ast, Graph.new(), State.new(base_iri, opts))

    {:ok, set_graph_directives(graph, base_iri, namespaces)}
  rescue
    error -> {:error, Exception.message(error)}
  end

  defp do_build_graph(ast, graph, state) do
    Enum.reduce(ast, {graph, state}, fn
      {:triples, triples_ast}, {graph, state} ->
        {statements, state} = triples(triples_ast, state)
        {Graph.add(graph, statements), state}

      {:directive, directive_ast}, {graph, state} ->
        {graph, directive(directive_ast, state)}
    end)
  end

  defp set_graph_directives(%Dataset{} = dataset, base_iri, namespaces) do
    Dataset.update_all_graphs(dataset, &set_graph_directives(&1, base_iri, namespaces))
  end

  defp set_graph_directives(%Graph{} = graph, base_iri, namespaces) do
    if Enum.empty?(namespaces) do
      graph
    else
      Graph.add_prefixes(graph, namespaces)
    end
    |> Graph.set_base_iri(base_iri)
  end

  defp directive({:prefix, {:prefix_ns, _, ns}, iri}, state) do
    absolute_iri =
      if IRI.absolute?(iri) do
        iri
      else
        iri |> IRI.absolute(state.base_iri) |> to_string()
      end

    State.add_namespace(state, ns, absolute_iri)
  end

  defp directive({:base, iri}, %State{base_iri: base_iri} = state) do
    cond do
      IRI.absolute?(iri) -> %State{state | base_iri: RDF.iri(iri)}
      not is_nil(base_iri) -> %State{state | base_iri: IRI.absolute(iri, base_iri)}
      true -> raise "Could not resolve relative IRI '#{iri}', no base iri provided"
    end
  end

  defp triples({:blankNodePropertyList, _} = ast, state) do
    {_, statements, state} = resolve_node(ast, [], state)
    {statements, state}
  end

  defp triples({subject, predications}, state) do
    {subject, statements, state} = resolve_node(subject, [], state)

    predications(subject, predications, statements, state)
  end

  defp predications(subject, predications, statements, state) do
    Enum.reduce(predications, {statements, state}, fn
      {predicate, objects}, {statements, state} ->
        {predicate, statements, state} = resolve_node(predicate, statements, state)

        Enum.reduce(objects, {statements, state}, fn
          {:annotation, annotation}, {[last_statement | _] = statements, state} ->
            predications(last_statement, annotation, statements, state)

          object, {statements, state} ->
            {object, statements, state} = resolve_node(object, statements, state)
            {[{subject, predicate, object} | statements], state}
        end)
    end)
  end

  # this variant can be used to resolve asts, which can not be a collection or a blankNodePropertyLists
  defp resolve_node(ast, state) do
    {node, _, state} = resolve_node(ast, nil, state)
    {node, state}
  end

  defp resolve_node({:prefix_ln, line_number, {prefix, name}}, statements, state) do
    if ns = State.ns(state, prefix) do
      {RDF.iri(ns <> local_name_unescape(name)), statements, state}
    else
      raise "line #{line_number}: undefined prefix #{inspect(prefix)}"
    end
  end

  defp resolve_node({:prefix_ns, line_number, prefix}, statements, state) do
    if ns = State.ns(state, prefix) do
      {RDF.iri(ns), statements, state}
    else
      raise "line #{line_number}: undefined prefix #{inspect(prefix)}"
    end
  end

  defp resolve_node({:relative_iri, relative_iri}, _, %State{base_iri: nil}) do
    raise "Could not resolve relative IRI '#{relative_iri}', no base iri provided"
  end

  defp resolve_node({:relative_iri, relative_iri}, statements, state) do
    {IRI.absolute(relative_iri, state.base_iri), statements, state}
  end

  defp resolve_node({:anon}, statements, state) do
    {node, state} = State.next_bnode(state)
    {node, statements, state}
  end

  defp resolve_node({:blankNodePropertyList, property_list}, statements, state) do
    {subject, state} = State.next_bnode(state)
    {new_statements, state} = triples({subject, property_list}, state)
    {subject, statements ++ new_statements, state}
  end

  defp resolve_node(
         {{:string_literal_quote, _line, value}, {:datatype, datatype}},
         statements,
         state
       ) do
    {datatype, statements, state} = resolve_node(datatype, statements, state)
    {Literal.new(value, datatype: datatype), statements, state}
  end

  defp resolve_node({:collection, []}, statements, state) do
    {RDF.nil(), statements, state}
  end

  defp resolve_node({:collection, elements}, statements, state) do
    {first_list_node, state} = State.next_bnode(state)
    [first_element | rest_elements] = elements
    {first_element_node, statements, state} = resolve_node(first_element, statements, state)
    first_statement = [{first_list_node, RDF.first(), first_element_node}]

    {last_list_node, statements, state} =
      Enum.reduce(
        rest_elements,
        {first_list_node, statements ++ first_statement, state},
        fn element, {list_node, statements, state} ->
          {element_node, statements, state} = resolve_node(element, statements, state)
          {next_list_node, state} = State.next_bnode(state)

          {next_list_node,
           statements ++
             [
               {list_node, RDF.rest(), next_list_node},
               {next_list_node, RDF.first(), element_node}
             ], state}
        end
      )

    {first_list_node, statements ++ [{last_list_node, RDF.rest(), RDF.nil()}], state}
  end

  defp resolve_node({:quoted_triple, s_node, p_node, o_node}, statements, state) do
    {subject, statements, state} = resolve_node(s_node, statements, state)
    {predicate, statements, state} = resolve_node(p_node, statements, state)
    {object, statements, state} = resolve_node(o_node, statements, state)
    {{subject, predicate, object}, statements, state}
  end

  defp resolve_node({:ok, %IRI{} = iri}, statements, state), do: {iri, statements, state}
  defp resolve_node({:error, error}, _statements, _state), do: raise(error)
  defp resolve_node(node, statements, state), do: {node, statements, state}

  defp local_name_unescape(string),
    do: Macro.unescape_string(string, &local_name_unescape_map(&1))

  @reserved_characters ~c[~.-!$&'()*+,;=/?#@%_]

  defp local_name_unescape_map(e) when e in @reserved_characters, do: e
  defp local_name_unescape_map(_), do: false
end
