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
          |> RDF.Turtle.write_string!(only: :triples)
          |> String.trim_trailing()

        "#RDF.Description\n#{body}#{if limit, do: "..\n..."}"
      rescue
        caught_exception ->
          message =
            "got #{inspect(caught_exception.__struct__)} with message " <>
              "#{inspect(Exception.message(caught_exception))} while inspecting RDF.Description #{
                description.subject
              }"

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
        limit = opts.limit < RDF.Graph.statement_count(graph)

        graph =
          if limit do
            graph
            |> RDF.Graph.clear()
            |> RDF.Graph.add(Enum.take(graph, opts.limit))
          else
            graph
          end

        header = "#RDF.Graph name: #{inspect(graph.name)}"

        body =
          graph
          |> RDF.Turtle.write_string!()
          |> String.trim_trailing()

        "#{header}\n#{body}#{if limit, do: "..\n..."}"
      rescue
        caught_exception ->
          message =
            "got #{inspect(caught_exception.__struct__)} with message " <>
              "#{inspect(Exception.message(caught_exception))} while inspecting RDF.Graph #{
                graph.name
              }"

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
