defmodule RDF.NQuads.Encoder do
  @moduledoc """
  An encoder for N-Quads serializations of RDF.ex data structures.

  As for all encoders of `RDF.Serialization.Format`s, you normally won't use these
  functions directly, but via one of the `write_` functions on the `RDF.NQuads`
  format module or the generic `RDF.Serialization` module.

  ## Options

  - `:default_graph_name`: The graph name to be used as the default for triples
    from a `RDF.Graph` or `RDF.Description`. When the input to be encoded is a
   `RDF.Description` the default is `nil` for the default graph. In case of a
   `RDF.Graph` the default is the `RDF.Graph.name/1`. The option doesn't
    have any effect at all when the input to be encoded is a `RDF.Dataset`.
  """

  use RDF.Serialization.Encoder

  alias RDF.{Statement, Graph}

  @impl RDF.Serialization.Encoder
  @callback encode(RDF.Data.t(), keyword) :: {:ok, String.t()} | {:error, any}
  def encode(data, opts \\ []) do
    default_graph_name = default_graph_name(data, Keyword.get(opts, :default_graph_name, false))
    {:ok, Enum.map_join(data, &statement(&1, default_graph_name))}
  end

  @impl RDF.Serialization.Encoder
  @spec stream(RDF.Data.t(), keyword) :: Enumerable.t()
  def stream(data, opts \\ []) do
    default_graph_name = default_graph_name(data, Keyword.get(opts, :default_graph_name, false))

    case Keyword.get(opts, :mode, :string) do
      :string -> Stream.map(data, &statement(&1, default_graph_name))
      :iodata -> Stream.map(data, &iolist_statement(&1, default_graph_name))
      invalid -> raise "Invalid stream mode: #{invalid}"
    end
  end

  defp default_graph_name(%Graph{} = graph, false), do: graph.name
  defp default_graph_name(_, none) when none in [false, nil], do: nil

  defp default_graph_name(_, default_graph_name),
    do: Statement.coerce_graph_name(default_graph_name)

  @spec statement(Statement.t(), Statement.graph_name()) :: String.t()
  def statement(statement, default_graph_name)

  def statement({subject, predicate, object, nil}, _) do
    "#{term(subject)} #{term(predicate)} #{term(object)} .\n"
  end

  def statement({subject, predicate, object, graph}, _) do
    "#{term(subject)} #{term(predicate)} #{term(object)} #{term(graph)} .\n"
  end

  def statement({subject, predicate, object}, default_graph_name) do
    statement({subject, predicate, object, default_graph_name}, default_graph_name)
  end

  defdelegate term(value), to: RDF.NTriples.Encoder

  @spec iolist_statement(Statement.t(), Statement.graph_name()) :: iolist
  def iolist_statement(statement, default_graph_name)

  def iolist_statement({subject, predicate, object, nil}, _) do
    [iolist_term(subject), " ", iolist_term(predicate), " ", iolist_term(object), " .\n"]
  end

  def iolist_statement({subject, predicate, object, graph}, _) do
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

  def iolist_statement({subject, predicate, object}, default_graph_name) do
    iolist_statement({subject, predicate, object, default_graph_name}, default_graph_name)
  end

  defdelegate iolist_term(value), to: RDF.NTriples.Encoder
end
