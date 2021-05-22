defimpl Inspect, for: RDF.IRI do
  def inspect(%RDF.IRI{value: value}, _opts) do
    "~I<#{value}>"
  end
end

defimpl Inspect, for: RDF.BlankNode do
  def inspect(%RDF.BlankNode{value: value}, _opts) do
    "~B<#{value}>"
  end
end

defimpl Inspect, for: RDF.Literal do
  def inspect(literal, _opts) do
    "%RDF.Literal{literal: #{inspect(literal.literal)}, valid: #{RDF.Literal.valid?(literal)}}"
  end
end

defimpl Inspect, for: RDF.Description do
  def inspect(description, opts) do
    if opts.structs do
      try do
        limit = opts.limit < RDF.Description.statement_count(description)

        description =
          if limit do
            description.subject
            |> RDF.Description.new(init: Enum.take(description, opts.limit))
          else
            description
          end

        body =
          description
          |> RDF.Turtle.write_string!(only: :triples, indent: 2)
          |> String.trim_trailing()

        "#RDF.Description<\n#{body}#{if limit, do: "..\n..."}\n>"
      rescue
        caught_exception ->
          message =
            "got #{inspect(caught_exception.__struct__)} with message " <>
              "#{inspect(Exception.message(caught_exception))} while inspecting RDF.Description #{description.subject}"

          exception = Inspect.Error.exception(message: message)

          if opts.safe do
            Inspect.inspect(exception, opts)
          else
            reraise(exception, __STACKTRACE__)
          end
      end
    else
      Inspect.Map.inspect(description, opts)
    end
  end
end

defimpl Inspect, for: RDF.Graph do
  def inspect(graph, opts) do
    if opts.structs do
      try do
        no_metadata = Keyword.get(opts.custom_options, :no_metadata, false)

        limit = opts.limit < RDF.Graph.statement_count(graph)

        graph =
          if limit do
            graph
            |> RDF.Graph.clear()
            |> RDF.Graph.add(Enum.take(graph, opts.limit))
          else
            graph
          end

        header = "#RDF.Graph<name: #{inspect(graph.name)}"

        body =
          graph
          |> RDF.Turtle.write_string!(only: if(no_metadata, do: :triples), indent: 2)
          |> String.trim_trailing()

        "#{header}\n#{body}#{if limit, do: "..\n..."}\n>"
      rescue
        caught_exception ->
          message =
            "got #{inspect(caught_exception.__struct__)} with message " <>
              "#{inspect(Exception.message(caught_exception))} while inspecting RDF.Graph #{graph.name}"

          exception = Inspect.Error.exception(message: message)

          if opts.safe do
            Inspect.inspect(exception, opts)
          else
            reraise(exception, __STACKTRACE__)
          end
      end
    else
      Inspect.Map.inspect(graph, opts)
    end
  end
end

defimpl Inspect, for: RDF.Dataset do
  import Inspect.Algebra

  def inspect(dataset, opts) do
    map = [name: dataset.name, graph_names: Map.keys(dataset.graphs)]
    open = color("%RDF.Dataset{", :map, opts)
    sep = color(",", :map, opts)
    close = color("}", :map, opts)
    container_doc(open, map, close, opts, &Inspect.List.keyword/2, separator: sep, break: :strict)
  end
end

defimpl Inspect, for: RDF.Diff do
  def inspect(diff, opts) do
    if opts.structs do
      try do
        {additions, deletions} = unify_metadata(diff.additions, diff.deletions)

        """
        #RDF.Diff<
        #{changes(additions, "  + ", opts.limit)}
        #{changes(deletions, "  - ", opts.limit)}
        >
        """
      rescue
        caught_exception ->
          message =
            "got #{inspect(caught_exception.__struct__)} with message " <>
              "#{inspect(Exception.message(caught_exception))} while inspecting RDF.Diff"

          exception = Inspect.Error.exception(message: message)

          if opts.safe do
            Inspect.inspect(exception, opts)
          else
            reraise(exception, __STACKTRACE__)
          end
      end
    else
      Inspect.Map.inspect(diff, opts)
    end
  end

  defp unify_metadata(additions, deletions) do
    unified_base = unified_base(additions.base_iri, deletions.base_iri)
    unified_prefixes = unified_prefixes(additions.prefixes, deletions.prefixes)

    {
      additions
      |> RDF.Graph.set_base_iri(unified_base)
      |> RDF.Graph.clear_prefixes()
      |> RDF.Graph.add_prefixes(unified_prefixes),
      deletions
      |> RDF.Graph.set_base_iri(unified_base)
      |> RDF.Graph.clear_prefixes()
      |> RDF.Graph.add_prefixes(unified_prefixes)
    }
  end

  defp unified_base(nil, nil), do: nil
  defp unified_base(nil, deletions_base), do: deletions_base
  defp unified_base(additions_base, _), do: additions_base

  defp unified_prefixes(nil, nil), do: nil
  defp unified_prefixes(additions_prefixes, nil), do: additions_prefixes
  defp unified_prefixes(nil, deletions_prefixes), do: deletions_prefixes

  defp unified_prefixes(additions_prefixes, deletions_prefixes) do
    case RDF.PrefixMap.merge(additions_prefixes, deletions_prefixes, :ignore) do
      {:ok, prefix_map} -> prefix_map
      {:error, error} -> raise error
    end
  end

  defp changes(graph, prefix, limit) do
    [_header | triples] =
      graph
      |> Kernel.inspect(limit: limit, custom_options: [no_metadata: true])
      |> String.split("\n")
      # remove the trailing ">"
      |> List.delete_at(-1)

    triples
    |> Enum.map(&[prefix, &1])
    |> Enum.intersperse("\n")
  end
end
