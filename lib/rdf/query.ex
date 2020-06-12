defmodule RDF.Query do
  @moduledoc """
  The RDF Graph query API.
  """

  alias RDF.Graph
  alias RDF.Query.{BGP, Builder}

  @default_matcher RDF.Query.BGP.Stream


  def execute(query, graph, opts \\ [])

  def execute(%BGP{} = query, %Graph{} = graph, opts) do
    matcher = Keyword.get(opts, :matcher, @default_matcher)
    matcher.execute(query, graph, opts)
  end

  def execute(query, graph, opts) when is_list(query) or is_tuple(query) do
    with {:ok, bgp} <- Builder.bgp(query) do
       execute(bgp, graph, opts)
    end
  end

  def execute!(query, graph, opts)  do
    case execute(query, graph, opts) do
      {:ok, results} -> results
      {:error, error} -> raise error
    end
  end


  def stream(query, graph, opts \\ [])

  def stream(%BGP{} = query, %Graph{} = graph, opts) do
    matcher = Keyword.get(opts, :matcher, @default_matcher)
    matcher.stream(query, graph, opts)
  end

  def stream(query, graph, opts) when is_list(query) or is_tuple(query) do
    with {:ok, bgp} <- Builder.bgp(query) do
      stream(bgp, graph, opts)
    end
  end

  def stream!(query, graph, opts)  do
    case execute(query, graph, opts) do
      {:ok, results} -> results
      {:error, error} -> raise error
    end
  end

  defdelegate bgp(query), to: Builder, as: :bgp!
  defdelegate path(query, opts \\ []), to: Builder, as: :path!
end
