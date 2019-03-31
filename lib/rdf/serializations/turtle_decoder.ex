defmodule RDF.Turtle.Decoder do
  @moduledoc false

  use RDF.Serialization.Decoder
  
  alias RDF.IRI

  defmodule State do
    defstruct base_iri: nil, namespaces: %{}, bnode_counter: 0

    def add_namespace(%State{namespaces: namespaces} = state, ns, iri) do
      %State{state | namespaces: Map.put(namespaces, ns, iri)}
    end

    def ns(%State{namespaces: namespaces}, prefix) do
      namespaces[prefix]
    end

    def next_bnode(%State{bnode_counter: bnode_counter} = state) do
      {RDF.bnode("b#{bnode_counter}"),
        %State{state | bnode_counter: bnode_counter + 1}}
    end
  end

  @impl RDF.Serialization.Decoder
  def decode(content, opts \\ %{})

  def decode(content, opts) when is_list(opts),
    do: decode(content, Map.new(opts))

  def decode(content, opts) do
    with {:ok, tokens, _} <- tokenize(content),
         {:ok, ast}       <- parse(tokens),
         base = Map.get(opts, :base) do
      build_graph(ast, base && RDF.iri(base))
    else
      {:error, {error_line, :turtle_lexer, error_descriptor}, _error_line_again} ->
        {:error, "Turtle scanner error on line #{error_line}: #{inspect error_descriptor}"}
      {:error, {error_line, :turtle_parser, error_descriptor}} ->
        {:error, "Turtle parser error on line #{error_line}: #{inspect error_descriptor}"}
    end
  end

  def tokenize(content), do: content |> to_charlist |> :turtle_lexer.string

  def parse([]),     do: {:ok, []}
  def parse(tokens), do: tokens |> :turtle_parser.parse

  defp build_graph(ast, base) do
    {graph, %State{namespaces: namespaces}} =
      Enum.reduce ast, {RDF.Graph.new, %State{base_iri: base}}, fn
        {:triples, triples_ast}, {graph, state} ->
          with {statements, state} = triples(triples_ast, state) do
            {RDF.Graph.add(graph, statements), state}
          end

        {:directive, directive_ast}, {graph, state} ->
          {graph, directive(directive_ast, state)}
      end

    {:ok,
      if Enum.empty?(namespaces) do
        graph
      else
        RDF.Graph.add_prefixes(graph, namespaces)
      end
    }
  rescue
    error -> {:error, Exception.message(error)}
  end

  defp directive({:prefix, {:prefix_ns, _, ns}, iri}, state) do
    if IRI.absolute?(iri) do
      State.add_namespace(state, ns, iri)
    else
      with absolute_iri = IRI.absolute(iri, state.base_iri) do
        State.add_namespace(state, ns, to_string(absolute_iri))
      end
    end
  end

  defp directive({:base, iri}, %State{base_iri: base_iri} = state) do
    cond do
      IRI.absolute?(iri) ->
        %State{state | base_iri: RDF.iri(iri)}
      base_iri != nil ->
        with absolute_iri = IRI.absolute(iri, base_iri) do
          %State{state | base_iri: absolute_iri}
        end
      true ->
        raise "Could not resolve relative IRI '#{iri}', no base iri provided"
    end
  end


  defp triples({:blankNodePropertyList, _} = ast, state) do
    with {_, statements, state} = resolve_node(ast, [], state) do
      {statements, state}
    end
  end

  defp triples({subject, predications}, state) do
    with {subject, statements, state} = resolve_node(subject, [], state) do
      Enum.reduce predications, {statements, state}, fn {predicate, objects}, {statements, state} ->
        with {predicate, statements, state} = resolve_node(predicate, statements, state) do
          Enum.reduce objects, {statements, state}, fn object, {statements, state} ->
            with {object, statements, state} = resolve_node(object, statements, state) do
              {[{subject, predicate, object} | statements], state}
            end
          end
        end
      end
    end
  end

  defp resolve_node({:prefix_ln, line_number, {prefix, name}}, statements, state) do
    if ns = State.ns(state, prefix) do
      {RDF.iri(ns <> local_name_unescape(name)), statements, state}
    else
      raise "line #{line_number}: undefined prefix #{inspect prefix}"
    end
  end

  defp resolve_node({:prefix_ns, line_number, prefix}, statements, state) do
    if ns = State.ns(state, prefix) do
      {RDF.iri(ns), statements, state}
    else
      raise "line #{line_number}: undefined prefix #{inspect prefix}"
    end
  end

  defp resolve_node({:relative_iri, relative_iri}, _, %State{base_iri: nil}) do
    raise "Could not resolve relative IRI '#{relative_iri}', no base iri provided"
  end

  defp resolve_node({:relative_iri, relative_iri}, statements, state) do
    {IRI.absolute(relative_iri, state.base_iri), statements, state}
  end

  defp resolve_node({:anon}, statements, state) do
    with {node, state} = State.next_bnode(state) do
      {node, statements, state}
    end
  end

  defp resolve_node({:blankNodePropertyList, property_list}, statements, state) do
    with {subject, state} = State.next_bnode(state),
         {new_statements, state} = triples({subject, property_list}, state) do
      {subject, statements ++ new_statements, state}
    end
  end

  defp resolve_node({{:string_literal_quote, _line, value}, {:datatype, datatype}}, statements, state) do
    with {datatype, statements, state} = resolve_node(datatype, statements, state) do
      {RDF.literal(value, datatype: datatype), statements, state}
    end
  end

  defp resolve_node({:collection, []}, statements, state) do
    {RDF.nil, statements, state}
  end

  defp resolve_node({:collection, elements}, statements, state) do
    with {first_list_node, state} = State.next_bnode(state),
         [first_element | rest_elements] = elements,
         {first_element_node, statements, state} =
           resolve_node(first_element, statements, state),
         first_statement = [{first_list_node, RDF.first, first_element_node}] do
      {last_list_node, statements, state} =
        Enum.reduce rest_elements, {first_list_node, statements ++ first_statement, state},
          fn element, {list_node, statements, state} ->
            with {element_node, statements, state} =
                   resolve_node(element, statements, state),
                 {next_list_node, state} = State.next_bnode(state) do
              {next_list_node, statements ++ [
                  {list_node,      RDF.rest,  next_list_node},
                  {next_list_node, RDF.first, element_node},
                ], state}
            end
          end
      {first_list_node, statements ++ [{last_list_node, RDF.rest, RDF.nil}], state}
    end
  end

  defp resolve_node(node, statements, state), do: {node, statements, state}

  defp local_name_unescape(string),
    do: Macro.unescape_string(string, &local_name_unescape_map(&1))

  @reserved_characters ~c[~.-!$&'()*+,;=/?#@%_]

  defp local_name_unescape_map(e) when e in @reserved_characters, do: e
  defp local_name_unescape_map(_), do: false

end
