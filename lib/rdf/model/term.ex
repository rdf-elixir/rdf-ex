defprotocol RDF.Term do
  @moduledoc """
  Shared behaviour for all RDF terms.

  A `RDF.Term` is anything which can be an element of RDF statements of an RDF graph:

  - `RDF.IRI`s
  - `RDF.BlankNode`s
  - `RDF.Literal`s

  see <https://www.w3.org/TR/sparql11-query/#defn_RDFTerm>
  """

  @type t :: RDF.Resource.t() | RDF.Literal.t()

  @doc """
  Checks if the given value is an RDF term.

  Note: As opposed to `RDF.term?` this function returns `false` on atoms and does
  not try to resolve them to IRIs.

  ## Examples

      iex> RDF.Term.term?(RDF.iri("http://example.com/resource"))
      true
      iex> RDF.Term.term?(EX.Resource)
      false
      iex> RDF.Term.term?(RDF.bnode)
      true
      iex> RDF.Term.term?(RDF.XSD.integer(42))
      true
      iex> RDF.Term.term?(42)
      false
  """
  def term?(value)

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
  Converts a given value into an RDF term.

  Returns `nil` if the given value is not convertible into any valid RDF.Term.

  ## Examples

      iex> RDF.Term.coerce("foo")
      ~L"foo"
      iex> RDF.Term.coerce(42)
      RDF.XSD.integer(42)

  """
  def coerce(value)

  @doc """
  Returns the native Elixir value of an RDF term.

  Returns `nil` if the given value is not a valid RDF term or a value convertible to an RDF term.

  ## Examples

      iex> RDF.Term.value(~I<http://example.com/>)
      "http://example.com/"
      iex> RDF.Term.value(~L"foo")
      "foo"
      iex> RDF.XSD.integer(42) |> RDF.Term.value()
      42

  """
  def value(term)
end

defimpl RDF.Term, for: RDF.IRI do
  def equal?(term1, term2), do: term1 == term2
  def equal_value?(term1, term2), do: RDF.IRI.equal_value?(term1, term2)
  def coerce(term), do: term
  def value(term), do: term.value
  def term?(_), do: true
end

defimpl RDF.Term, for: RDF.BlankNode do
  def equal?(term1, term2), do: term1 == term2
  def equal_value?(term1, term2), do: RDF.BlankNode.equal_value?(term1, term2)
  def coerce(term), do: term
  def value(term), do: to_string(term)
  def term?(_), do: true
end

defimpl RDF.Term, for: Reference do
  @dialyzer {:nowarn_function, equal_value?: 2}
  @dialyzer {:nowarn_function, coerce: 1}
  def equal?(term1, term2), do: term1 == term2
  def equal_value?(term1, term2), do: RDF.Term.equal_value?(coerce(term1), term2)
  def coerce(term), do: RDF.BlankNode.new(term)
  def value(term), do: term
  def term?(_), do: false
end

defimpl RDF.Term, for: RDF.Literal do
  def equal?(term1, term2), do: RDF.Literal.equal?(term1, term2)
  def equal_value?(term1, term2), do: RDF.Literal.equal_value?(term1, term2)
  def coerce(term), do: term
  def value(term), do: RDF.Literal.value(term) || RDF.Literal.lexical(term)
  def term?(_), do: true
end

defimpl RDF.Term, for: Atom do
  def equal?(term1, term2), do: term1 == term2

  def equal_value?(nil, _), do: nil
  def equal_value?(term1, term2), do: RDF.Term.equal_value?(coerce(term1), term2)

  def coerce(true), do: RDF.XSD.true()
  def coerce(false), do: RDF.XSD.false()
  def coerce(nil), do: nil

  def coerce(term) do
    case RDF.Namespace.resolve_term(term) do
      {:ok, iri} -> iri
      _ -> nil
    end
  end

  def value(true), do: true
  def value(false), do: false
  def value(nil), do: nil
  def value(term), do: RDF.Term.value(coerce(term))

  def term?(_), do: false
end

defimpl RDF.Term, for: BitString do
  def equal?(term1, term2), do: term1 == term2
  def equal_value?(term1, term2), do: RDF.Term.equal_value?(coerce(term1), term2)
  def coerce(term), do: RDF.XSD.String.new(term)
  def value(term), do: term
  def term?(_), do: false
end

defimpl RDF.Term, for: Integer do
  def equal?(term1, term2), do: term1 == term2
  def equal_value?(term1, term2), do: RDF.Term.equal_value?(coerce(term1), term2)
  def coerce(term), do: RDF.XSD.Integer.new(term)
  def value(term), do: term
  def term?(_), do: false
end

defimpl RDF.Term, for: Float do
  def equal?(term1, term2), do: term1 == term2
  def equal_value?(term1, term2), do: RDF.Term.equal_value?(coerce(term1), term2)
  def coerce(term), do: RDF.XSD.Double.new(term)
  def value(term), do: term
  def term?(_), do: false
end

defimpl RDF.Term, for: Decimal do
  def equal?(term1, term2), do: term1 == term2
  def equal_value?(term1, term2), do: RDF.Term.equal_value?(coerce(term1), term2)
  def coerce(term), do: RDF.XSD.Decimal.new(term)
  def value(term), do: term
  def term?(_), do: false
end

defimpl RDF.Term, for: DateTime do
  def equal?(term1, term2), do: term1 == term2
  def equal_value?(term1, term2), do: RDF.Term.equal_value?(coerce(term1), term2)
  def coerce(term), do: RDF.XSD.DateTime.new(term)
  def value(term), do: term
  def term?(_), do: false
end

defimpl RDF.Term, for: NaiveDateTime do
  def equal?(term1, term2), do: term1 == term2
  def equal_value?(term1, term2), do: RDF.Term.equal_value?(coerce(term1), term2)
  def coerce(term), do: RDF.XSD.DateTime.new(term)
  def value(term), do: term
  def term?(_), do: false
end

defimpl RDF.Term, for: Date do
  def equal?(term1, term2), do: term1 == term2
  def equal_value?(term1, term2), do: RDF.Term.equal_value?(coerce(term1), term2)
  def coerce(term), do: RDF.XSD.Date.new(term)
  def value(term), do: term
  def term?(_), do: false
end

defimpl RDF.Term, for: Time do
  def equal?(term1, term2), do: term1 == term2
  def equal_value?(term1, term2), do: RDF.Term.equal_value?(coerce(term1), term2)
  def coerce(term), do: RDF.XSD.Time.new(term)
  def value(term), do: term
  def term?(_), do: false
end

defimpl RDF.Term, for: URI do
  def equal?(term1, term2), do: term1 == term2
  def equal_value?(term1, term2), do: RDF.Term.equal_value?(coerce(term1), term2)
  def coerce(term), do: RDF.XSD.AnyURI.new(term)
  def value(term), do: term
  def term?(_), do: false
end

defimpl RDF.Term, for: Any do
  def equal?(term1, term2), do: term1 == term2
  def equal_value?(_, _), do: nil
  def coerce(_), do: nil
  def value(_), do: nil
  def term?(_), do: false
end
