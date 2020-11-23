defmodule RDF.NTriples.Encoder do
  @moduledoc """
  An encoder for N-Triples serializations of RDF.ex data structures.

  As for all encoders of `RDF.Serialization.Format`s, you normally won't use these
  functions directly, but via one of the `write_` functions on the `RDF.NTriples`
  format module or the generic `RDF.Serialization` module.
  """

  use RDF.Serialization.Encoder

  alias RDF.{Triple, Term, IRI, BlankNode, Literal, LangString, XSD}

  @impl RDF.Serialization.Encoder
  @callback encode(RDF.Data.t(), keyword) :: {:ok, String.t()} | {:error, any}
  def encode(data, _opts \\ []) do
    {:ok,
     data
     |> Enum.reduce([], &[statement(&1) | &2])
     |> Enum.reverse()
     |> Enum.join()}
  end

  @impl RDF.Serialization.Encoder
  @spec stream(RDF.Data.t(), keyword) :: Enumerable.t()
  def stream(data, opts \\ []) do
    case Keyword.get(opts, :mode, :string) do
      :string -> Stream.map(data, &statement(&1))
      :iodata -> Stream.map(data, &iolist_statement(&1))
      invalid -> raise "Invalid stream mode: #{invalid}"
    end
  end

  @spec statement(Triple.t()) :: String.t()
  def statement({subject, predicate, object}) do
    "#{term(subject)} #{term(predicate)} #{term(object)} .\n"
  end

  @spec term(Term.t()) :: String.t()
  def term(%IRI{} = iri) do
    "<#{to_string(iri)}>"
  end

  def term(%Literal{literal: %LangString{} = lang_string}) do
    ~s["#{lang_string.value}"@#{lang_string.language}]
  end

  def term(%Literal{literal: %XSD.String{} = xsd_string}) do
    ~s["#{xsd_string.value}"]
  end

  def term(%Literal{} = literal) do
    ~s["#{Literal.lexical(literal)}"^^<#{to_string(Literal.datatype_id(literal))}>]
  end

  def term(%BlankNode{} = bnode) do
    to_string(bnode)
  end

  @spec iolist_statement(Triple.t()) :: iolist
  def iolist_statement({subject, predicate, object}) do
    [iolist_term(subject), " ", iolist_term(predicate), " ", iolist_term(object), " .\n"]
  end

  @spec iolist_term(Term.t()) :: String.t()
  def iolist_term(%IRI{} = iri) do
    ["<", iri.value, ">"]
  end

  def iolist_term(%Literal{literal: %LangString{} = lang_string}) do
    [~s["], lang_string.value, ~s["@], lang_string.language]
  end

  def iolist_term(%Literal{literal: %XSD.String{} = xsd_string}) do
    [~s["], xsd_string.value, ~s["]]
  end

  def iolist_term(%Literal{} = literal) do
    [~s["], Literal.lexical(literal), ~s["^^<], to_string(Literal.datatype_id(literal)), ">"]
  end

  def iolist_term(%BlankNode{} = bnode) do
    to_string(bnode)
  end
end
