defmodule RDF.NTriples.Encoder do
  @moduledoc """
  An encoder for N-Triples serializations of RDF.ex data structures.

  As for all encoders of `RDF.Serialization.Format`s, you normally won't use these
  functions directly, but via one of the `write_` functions on the `RDF.NTriples`
  format module or the generic `RDF.Serialization` module.
  """

  use RDF.Serialization.Encoder

  alias RDF.{Triple, Term, IRI, BlankNode, Literal, LangString, XSD}

  @doc """
  Encodes the given RDF data in N-Triples format.

  ## Options

  - `:sort`: Boolean flag which specifies if the encoded triples should
    be sorted into Unicode code point order (Default: `false`)
  """
  @impl RDF.Serialization.Encoder
  @spec encode(RDF.Data.t(), keyword) :: {:ok, String.t()} | {:error, any}
  def encode(data, opts \\ []) do
    if Keyword.get(opts, :sort, false) do
      {:ok,
       data
       |> Enum.map(&statement/1)
       |> Enum.sort()
       |> Enum.join()}
    else
      {:ok,
       data
       |> Enum.map(&iolist_statement/1)
       |> IO.iodata_to_binary()}
    end
  end

  @doc """
  Encodes the given RDF data into a stream of N-Triples.

  ## Options

  - `:mode`: Allows to specify if the encoded statements should be emitted as
    strings or IO lists using the value `:string` or `:iodata` respectively
    (Default: `:string`)
  """
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
    ~s["#{escape_string(lang_string.value)}"@#{lang_string.language}]
  end

  def term(%Literal{literal: %XSD.String{} = xsd_string}) do
    ~s["#{escape_string(xsd_string.value)}"]
  end

  def term(%Literal{} = literal) do
    ~s["#{escape_string(Literal.lexical(literal))}"^^<#{to_string(Literal.datatype_id(literal))}>]
  end

  def term(%BlankNode{} = bnode) do
    to_string(bnode)
  end

  def term({s, p, o}) do
    "<< #{term(s)} #{term(p)} #{term(o)} >>"
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
    [~S["], escape_string(lang_string.value), ~S["@], lang_string.language]
  end

  def iolist_term(%Literal{literal: %XSD.String{} = xsd_string}) do
    [~S["], escape_string(xsd_string.value), ~S["]]
  end

  def iolist_term(%Literal{} = literal) do
    [
      ~S["],
      escape_string(Literal.lexical(literal)),
      ~S["^^<],
      to_string(Literal.datatype_id(literal)),
      ">"
    ]
  end

  def iolist_term(%BlankNode{} = bnode) do
    to_string(bnode)
  end

  def iolist_term({s, p, o}) do
    ["<< ", iolist_term(s), " ", iolist_term(p), " ", iolist_term(o), " >>"]
  end

  @doc false
  def escape_string(string) do
    string
    |> String.replace("\\", "\\\\")
    |> String.replace("\t", "\\t")
    |> String.replace("\b", "\\b")
    |> String.replace("\n", "\\n")
    |> String.replace("\r", "\\r")
    |> String.replace("\f", "\\f")
    |> String.replace("\"", ~S[\"])
  end
end
