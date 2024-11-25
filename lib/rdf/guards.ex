defmodule RDF.Guards do
  @moduledoc """
  A collection of guards.
  """

  import RDF.Utils.Guards

  alias RDF.{IRI, BlankNode, Literal, XSD}

  @elixir_issue_10485_warning """
  > #### Warning {: .warning}
  >
  > Due to [this bug in Elixir](https://github.com/elixir-lang/elixir/issues/10485)
  > a false warning is currently raised when the given `term` is not a `RDF.Literal`,
  > although the implementation works as expected. If you want to get rid of the warning
  > you'll have to catch non-`RDF.Literal` values in a separate clause before the one
  > calling this guard.
  """

  @doc """
  Returns if the given term is a `RDF.IRI`.

  Note: This guard does not recognize `RDF.IRI`s given as upper-cased
  `RDF.Namespace` terms. You'll have to use the `RDF.iri?/1` function in a
  function body for this, or the `RDF.Namespace.IRI.term_to_iri/1` macro
  if you want to resolve `RDF.Namespace` terms in pattern matches.

  ## Examples

      iex> is_rdf_iri(~I<http://example.com/>)
      true

      iex> is_rdf_iri("http://example.com/")
      false

      iex> is_rdf_iri(RDF.type())
      true

      iex> is_rdf_iri(RDF.NS.RDFS.Class)
      false

      iex> RDF.iri?(RDF.NS.RDFS.Class)
      true
  """
  defguard is_rdf_iri(term) when is_struct(term, IRI)

  @doc """
  Returns if the given term is a `RDF.BlankNode`.

  ## Examples

      iex> is_rdf_bnode(~B<b1>)
      true

      iex> is_rdf_bnode(~L"b1")
      false
  """
  defguard is_rdf_bnode(term) when is_struct(term, BlankNode)

  @doc """
  Returns if the given term is a `RDF.Literal`.

  ## Examples

      iex> is_rdf_literal(~L"foo")
      true

      iex> is_rdf_literal(~L"foo"en)
      true

      iex> is_rdf_literal(XSD.integer(42))
      true

      iex> is_rdf_literal(42)
      false
  """
  defguard is_rdf_literal(term) when is_struct(term, Literal)

  @doc """
  Returns if the given term is a `RDF.Literal` with the given `RDF.Literal.Datatype`.

  #{@elixir_issue_10485_warning}

  ## Examples

      iex> is_rdf_literal(~L"foo", XSD.String)
      true

      iex> is_rdf_literal(XSD.Integer.new(42), XSD.String)
      false
  """
  defguard is_rdf_literal(term, datatype)
           when is_rdf_literal(term) and is_struct(term.literal, datatype)

  @doc """
  Returns if the given term is a plain `RDF.Literal`, i.e. has either datatype `xsd:string` or `rdf:langString`.

  #{@elixir_issue_10485_warning}

  ## Examples

      iex> is_plain_rdf_literal(~L"foo")
      true

      iex> is_plain_rdf_literal(~L"foo"en)
      true

      iex> is_plain_rdf_literal(XSD.Integer.new(42))
      false
  """
  defguard is_plain_rdf_literal(term)
           when is_rdf_literal(term, XSD.String) or is_rdf_literal(term, RDF.LangString)

  @doc """
  Returns if the given term is a typed `RDF.Literal`, i.e. has , i.e. has another datatype than `xsd:string` or `rdf:langString`.

  #{@elixir_issue_10485_warning}

  ## Examples

      iex> is_typed_rdf_literal(XSD.Integer.new(42))
      true

      iex> is_typed_rdf_literal(~L"foo")
      false

      iex> is_typed_rdf_literal(~L"foo"en)
      false
  """
  defguard is_typed_rdf_literal(term) when is_rdf_literal(term) and not is_plain_rdf_literal(term)

  @doc """
  Returns if the given term is a `RDF.Resource`, i.e. a `RDF.IRI` or `RDF.BlankNode`.

  Note: This function does not recognize `RDF.IRI`s given as upper-cased
  `RDF.Namespace` terms. You'll have to use the `RDF.resource?/1` function for this.

  ## Examples

      iex> is_rdf_resource(~I<http://example.com/foo>)
      true

      iex> is_rdf_resource(~B<foo>)
      true

      iex> is_rdf_resource(~L"foo")
      false

      iex> is_rdf_resource(RDF.type())
      true

      iex> is_rdf_resource(RDF.NS.RDFS.Class)
      false

      iex> RDF.resource?(RDF.NS.RDFS.Class)
      true
  """
  defguard is_rdf_resource(term) when is_rdf_iri(term) or is_rdf_bnode(term)

  @doc """
  Returns if the given term is a `RDF.Term`, i.e. a `RDF.IRI`, `RDF.BlankNode` or `RDF.Literal`.

  Note: This function does not recognize `RDF.IRI`s given as upper-cased
  `RDF.Namespace` terms. You'll have to use the `RDF.term?/1` function for this.

  ## Examples

      iex> is_rdf_term(~I<http://example.com/foo>)
      true

      iex> is_rdf_term(~B<foo>)
      true

      iex> is_rdf_term(~L"foo")
      true

      iex> is_rdf_term(RDF.type())
      true

      iex> is_rdf_term(RDF.NS.RDFS.Class)
      false

      iex> RDF.term?(RDF.NS.RDFS.Class)
      true
  """
  defguard is_rdf_term(term) when is_rdf_resource(term) or is_rdf_literal(term)

  @doc """
  Returns if the given term is a triple, i.e. a tuple with three elements.

  Note: This

  ## Examples

      iex> is_triple({~I<http://example.com/S>, EX.foo(), 42})
      true

      iex> is_triple({~I<http://example.com/S>, EX.foo()})
      false

      iex> is_triple({~I<http://example.com/S>, EX.foo(), 42, EX.Graph})
      false
  """
  defguard is_triple(term) when is_tuple(term) and tuple_size(term) == 3

  @doc """
  Returns if the given term is a quad, i.e. a tuple with four elements.

  ## Examples

      iex> is_quad({~I<http://example.com/S>, EX.foo(), 42, EX.Graph})
      true

      iex> is_quad({~I<http://example.com/S>, EX.foo(), 42})
      false

      iex> is_quad({~I<http://example.com/S>, EX.foo()})
      false
  """
  defguard is_quad(term) when is_tuple(term) and tuple_size(term) == 4

  @doc """
  Returns if the given term is a triple or a quad in terms of `is_triple/1` or `is_quad/1`.

  ## Examples

      iex> is_statement({~I<http://example.com/S>, EX.foo(), 42, EX.Graph})
      true

      iex> is_statement({~I<http://example.com/S>, EX.foo(), 42})
      true

      iex> is_statement({~I<http://example.com/S>, EX.foo()})
      false
  """
  defguard is_statement(term) when is_triple(term) or is_quad(term)

  @doc """
  Returns if the given term is a `RDF.Triple`, i.e. a tuple with three elements where each element is a `RDF.Term`.

  ## Examples

      iex> is_rdf_triple({~I<http://example.com/S>, EX.foo(), XSD.integer(42)})
      true

      iex> is_rdf_triple({~I<http://example.com/S>, EX.foo(), 42})
      false

      iex> is_rdf_triple({~L"the subject can not be a literal", EX.foo(), XSD.integer(42)})
      false

      iex> is_rdf_triple({~I<http://example.com/S>, ~L"the predicate can not be a literal", XSD.integer(42)})
      false

      iex> is_rdf_triple({~I<http://example.com/S>, EX.foo()})
      false

      iex> is_rdf_triple({~I<http://example.com/S>, EX.foo(), XSD.integer(42), RDF.iri(EX.Graph)})
      false
  """
  defguard is_rdf_triple(term)
           when is_triple(term) and
                  is_rdf_resource(elem(term, 0)) and
                  is_rdf_resource(elem(term, 1)) and
                  is_rdf_term(elem(term, 2))

  @doc """
  Returns if the given term is a `RDF.Quad`, i.e. a tuple with four elements where each element is a `RDF.Term`.

  ## Examples

      iex> is_rdf_quad({~I<http://example.com/S>, EX.foo(), XSD.integer(42), RDF.iri(EX.Graph)})
      true

      iex> is_rdf_quad({~I<http://example.com/S>, EX.foo(), 42, RDF.iri(EX.Graph)})
      false

      iex> is_rdf_quad({~L"the subject can not be a literal", EX.foo(), XSD.integer(42), RDF.iri(EX.Graph)})
      false

      iex> is_rdf_quad({~I<http://example.com/S>, ~L"the predicate can not be a literal", XSD.integer(42), RDF.iri(EX.Graph)})
      false

      iex> is_rdf_quad({~I<http://example.com/S>, EX.foo(), XSD.integer(42), ~L"the graph context can not be a literal"})
      false

      iex> is_rdf_quad({~I<http://example.com/S>, EX.foo(), XSD.integer(42)})
      false

      iex> is_rdf_quad({~I<http://example.com/S>, EX.foo()})
      false
  """
  defguard is_rdf_quad(term)
           when is_quad(term) and
                  is_rdf_resource(elem(term, 0)) and
                  is_rdf_resource(elem(term, 1)) and
                  is_rdf_term(elem(term, 2)) and
                  is_rdf_resource(elem(term, 3))

  @doc """
  Returns if the given term is a `RDF.Statement` in terms of `is_rdf_triple/1` or `is_rdf_quad/1`.

  ## Examples

      iex> is_rdf_statement({~I<http://example.com/S>, EX.foo(), XSD.integer(42)})
      true

      iex> is_rdf_statement({~I<http://example.com/S>, EX.foo(), XSD.integer(42), RDF.iri(EX.Graph)})
      true

      iex> is_rdf_statement({~I<http://example.com/S>, EX.foo()})
      false

      iex> is_rdf_statement({~L"the subject can not be a literal", EX.foo(), XSD.integer(42)})
      false

  """
  defguard is_rdf_statement(term) when is_rdf_triple(term) or is_rdf_quad(term)

  @doc """
  Returns if the given term is an atom which could potentially be an `RDF.Vocabulary.Namespace` term.

  ## Examples

      iex> maybe_ns_term(EX.Foo)
      true

      iex> maybe_ns_term(true)
      false

      iex> maybe_ns_term(false)
      false

      iex> maybe_ns_term(nil)
      false
  """
  defguard maybe_ns_term(term) when maybe_module(term)
end
