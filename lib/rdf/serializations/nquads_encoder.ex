defmodule RDF.NQuads.Encoder do
  @moduledoc """
  An encoder for N-Quads serializations of RDF.ex data structures.

  As for all encoders of `RDF.Serialization.Format`s, you normally won't use these
  functions directly, but via one of the `write_` functions on the `RDF.NQuads`
  format module or the generic `RDF.Serialization` module.
  """

  use RDF.Serialization.Encoder

  alias RDF.Statement

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

  @spec statement(Statement.t()) :: String.t()
  def statement(statement)

  def statement({subject, predicate, object, nil}) do
    statement({subject, predicate, object})
  end

  def statement({subject, predicate, object, graph}) do
    "#{term(subject)} #{term(predicate)} #{term(object)} #{term(graph)} .\n"
  end

  def statement({subject, predicate, object}) do
    "#{term(subject)} #{term(predicate)} #{term(object)} .\n"
  end

  defdelegate term(value), to: RDF.NTriples.Encoder

  @spec iolist_statement(Statement.t()) :: iolist
  def iolist_statement(statement)

  def iolist_statement({subject, predicate, object, nil}) do
    iolist_statement({subject, predicate, object})
  end

  def iolist_statement({subject, predicate, object, graph}) do
    [
      iolist_term(subject),
      " ",
      iolist_term(predicate),
      " ",
      iolist_term(object),
      " ",
      iolist_term(graph),
      " .\n"
    ]
  end

  def iolist_statement({subject, predicate, object}) do
    [iolist_term(subject), " ", iolist_term(predicate), " ", iolist_term(object), " .\n"]
  end

  defdelegate iolist_term(value), to: RDF.NTriples.Encoder
end
