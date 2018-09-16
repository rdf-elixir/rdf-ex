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

  Non-RDF terms are tried to be coerced via `RDF.Term.coerce/1` before comparison.

  Returns `nil` if the given terms are not comparable.

  see <http://www.w3.org/TR/rdf-sparql-query/#func-RDFterm-equal>
  and the value equality semantics of the different literal datatypes here:
   <https://www.w3.org/TR/sparql11-query/#OperatorMapping>
  """
  @fallback_to_any true
  def equal_value?(term1, term2)

  @doc """
  Converts a given value into a RDF term.

  Returns `nil` if the given value is not convertible into any valid RDF.Term.
  """
  def coerce(value)

end

defimpl RDF.Term, for: RDF.IRI do
  def equal?(term1, term2),       do: term1 == term2
  def equal_value?(term1, term2), do: RDF.IRI.equal_value?(term1, term2)
  def coerce(term),               do: term
end

defimpl RDF.Term, for: RDF.BlankNode do
  def equal?(term1, term2),       do: term1 == term2
  def equal_value?(term1, term2), do: RDF.BlankNode.equal_value?(term1, term2)
  def coerce(term),               do: term
end

defimpl RDF.Term, for: Reference do
  def equal?(term1, term2),       do: term1 == term2
  def equal_value?(term1, term2), do: RDF.Term.equal_value?(coerce(term1), term2)
  def coerce(term),               do: RDF.BlankNode.new(term)
end

defimpl RDF.Term, for: RDF.Literal do
  def equal?(term1, term2),       do: term1 == term2
  def equal_value?(term1, term2), do: RDF.Literal.equal_value?(term1, term2)
  def coerce(term),               do: term
end

defimpl RDF.Term, for: Atom do
  def equal?(term1, term2), do: term1 == term2

  def equal_value?(nil, _),       do: nil
  def equal_value?(term1, term2), do: RDF.Term.equal_value?(coerce(term1), term2)

  def coerce(true),  do: RDF.true
  def coerce(false), do: RDF.false
  def coerce(_),     do: nil
end

defimpl RDF.Term, for: BitString do
  def equal?(term1, term2),       do: term1 == term2
  def equal_value?(term1, term2), do: RDF.Term.equal_value?(coerce(term1), term2)
  def coerce(term),               do: RDF.String.new(term)
end

defimpl RDF.Term, for: Integer do
  def equal?(term1, term2),       do: term1 == term2
  def equal_value?(term1, term2), do: RDF.Term.equal_value?(coerce(term1), term2)
  def coerce(term),               do: RDF.Integer.new(term)
end

defimpl RDF.Term, for: Float do
  def equal?(term1, term2),       do: term1 == term2
  def equal_value?(term1, term2), do: RDF.Term.equal_value?(coerce(term1), term2)
  def coerce(term),               do: RDF.Double.new(term)
end

defimpl RDF.Term, for: DateTime do
  def equal?(term1, term2),       do: term1 == term2
  def equal_value?(term1, term2), do: RDF.Term.equal_value?(coerce(term1), term2)
  def coerce(term),               do: RDF.DateTime.new(term)
end

defimpl RDF.Term, for: NaiveDateTime do
  def equal?(term1, term2),       do: term1 == term2
  def equal_value?(term1, term2), do: RDF.Term.equal_value?(coerce(term1), term2)
  def coerce(term),               do: RDF.DateTime.new(term)
end

defimpl RDF.Term, for: Date do
  def equal?(term1, term2),       do: term1 == term2
  def equal_value?(term1, term2), do: RDF.Term.equal_value?(coerce(term1), term2)
  def coerce(term),               do: RDF.Date.new(term)
end

defimpl RDF.Term, for: Time do
  def equal?(term1, term2),       do: term1 == term2
  def equal_value?(term1, term2), do: RDF.Term.equal_value?(coerce(term1), term2)
  def coerce(term),               do: RDF.Time.new(term)
end

defimpl RDF.Term, for: Any do
  def equal?(term1, term2), do: term1 == term2
  def equal_value?(_, _),   do: nil
  def coerce(_),            do: nil
end
