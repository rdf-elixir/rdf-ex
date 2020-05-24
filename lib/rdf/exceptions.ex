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

defmodule RDF.XSD.Datatype.Mismatch do
  defexception [:value, :expected_type]

  def message(%{value: value, expected_type: expected_type}) do
    "'#{inspect(value)}' is not a #{expected_type}"
  end
end

defmodule RDF.Quad.InvalidGraphContextError do
  defexception [:graph_context]

  def message(%{graph_context: graph_context}) do
    "'#{inspect(graph_context)}' is not a valid graph context of a RDF.Quad"
  end
end


defmodule RDF.Namespace.InvalidVocabBaseIRIError do
  defexception [:message]
end

defmodule RDF.Namespace.InvalidTermError do
  defexception [:message]
end

defmodule RDF.Namespace.InvalidAliasError do
  defexception [:message]
end

defmodule RDF.Namespace.UndefinedTermError do
  defexception [:message]
end
