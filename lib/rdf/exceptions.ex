defmodule RDF.IRI.InvalidError do
  defexception [:message]
end

defmodule RDF.Literal.InvalidError do
  defexception [:message]
end

defmodule RDF.Triple.InvalidSubjectError do
  defexception [:subject]

  def message(%{subject: subject}) do
    "'#{inspect(subject)}' is not a valid subject of a RDF.Triple"
  end
end

defmodule RDF.Triple.InvalidPredicateError do
  defexception [:predicate]

  def message(%{predicate: predicate}) do
    "'#{inspect(predicate)}' is not a valid predicate of a RDF.Triple"
  end
end

defmodule RDF.Quad.InvalidGraphContextError do
  defexception [:graph_context]

  def message(%{graph_context: graph_context}) do
    "'#{inspect(graph_context)}' is not a valid graph context of a RDF.Quad"
  end
end

defmodule RDF.Graph.EmptyDescriptionError do
  defexception [:subject]

  def message(%{subject: subject}) do
    """
    RDF.Graph with empty description about '#{inspect(subject)}' detected.
    Empty descriptions in a graph lead to inconsistent behaviour. The RDF.Graph API
    should ensure that this never happens. So this probably happened by changing the
    contents of the RDF.Graph struct directly, which is strongly discouraged.
    You should always use the RDF.Graph API to change the content of a graph.
    If this happened while using the RDF.Graph API, this is a bug.
    Please report this at https://github.com/rdf-elixir/rdf-ex/issues and describe the
    circumstances how this happened.
    """
  end
end

defmodule RDF.XSD.Datatype.MismatchError do
  defexception [:value, :expected_type]

  def message(%{value: value, expected_type: expected_type}) do
    "'#{inspect(value)}' is not a #{expected_type}"
  end
end

defmodule RDF.Vocabulary.Namespace.CompileError do
  defexception [:message]
end

defmodule RDF.Namespace.InvalidTermError do
  defexception [:message]
end

defmodule RDF.Namespace.UndefinedTermError do
  defexception [:message]
end

defmodule RDF.Query.InvalidError do
  defexception [:message]
end

defmodule RDF.Resource.Generator.ConfigError do
  defexception [:message]
end
