defprotocol RDF.Term do
  @moduledoc """
  Shared behaviour for all RDF terms.

  A `RDF.Term` is anything which can be an element of RDF statements of a RDF graph:

  - `RDF.IRI`s
  - `RDF.BlankNode`s
  - `RDF.Literal`s

  see <https://www.w3.org/TR/sparql11-query/#defn_RDFTerm>
  """


  @type t :: RDF.IRI.t | RDF.BlankNode.t | RDF.Literal.t


  @doc """
  Tests for term equality.

  see <http://www.w3.org/TR/rdf-sparql-query/#func-sameTerm>
  """
  @fallback_to_any true
  def equal?(term1, term2)


  @doc """
  Tests for equality of values.

  Returns `nil` if the given terms are not comparable.

  see <http://www.w3.org/TR/rdf-sparql-query/#func-RDFterm-equal>
  and the value equality semantics of the different literal datatypes here:
   <https://www.w3.org/TR/sparql11-query/#OperatorMapping>
  """
  @fallback_to_any true
  def equal_value?(term1, term2)

end

defimpl RDF.Term, for: RDF.IRI do
  def equal?(term1, term2),       do: term1 == term2
  def equal_value?(term1, term2), do: RDF.IRI.equal_value?(term1, term2)
end

defimpl RDF.Term, for: RDF.BlankNode do
  def equal?(term1, term2),       do: term1 == term2
  def equal_value?(term1, term2), do: RDF.BlankNode.equal_value?(term1, term2)
end

defimpl RDF.Term, for: RDF.Literal do
  def equal?(term1, term2),       do: term1 == term2
  def equal_value?(term1, term2), do: RDF.Literal.equal_value?(term1, term2)
end

defimpl RDF.Term, for: Any do
  def equal?(term1, term2), do: term1 == term2
  def equal_value?(_, _),   do: nil
end
