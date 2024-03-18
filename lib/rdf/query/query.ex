defmodule RDF.Query do
  @moduledoc """
  The RDF Graph query API.
  """

  alias RDF.Graph
  alias RDF.Query.{BGP, Builder}

  @default_matcher RDF.Query.BGP.Stream

  @doc """
  Execute the given `query` against the given `graph`.

  The `query` can be given directly as `RDF.Query.BGP` struct created with one
  of the builder functions in this module or as basic graph pattern expression
  accepted by `bgp/1`.

  The result is a list of maps with the  solutions for the variables in the graph
  pattern query and will be returned in a `:ok` tuple. In case of an error a
  `:error` tuple is returned.

  ## Example

  Let's assume we have an `example_graph` with these triples:

  ```turtle
  @prefix foaf: <http://xmlns.com/foaf/0.1/> .
  @prefix ex:   <http://example.com/> .

  ex:Outlaw
    foaf:name   "Johnny Lee Outlaw" ;
    foaf:mbox   <mailto:jlow@example.com> .

  ex:Goodguy
    foaf:name   "Peter Goodguy" ;
    foaf:mbox   <mailto:peter@example.org> ;
    foaf:friend ex:Outlaw .
  ```

      iex> {:_, FOAF.name, :name?} |> RDF.Query.execute(example_graph())
      {:ok, [%{name: ~L"Peter Goodguy"}, %{name: ~L"Johnny Lee Outlaw"}]}

      iex> [
      ...>   {:_, FOAF.name, :name?},
      ...>   {:_, FOAF.mbox, :mbox?},
      ...> ] |> RDF.Query.execute(example_graph())
      {:ok, [
        %{name: ~L"Peter Goodguy", mbox: ~I<mailto:peter@example.org>},
        %{name: ~L"Johnny Lee Outlaw", mbox: ~I<mailto:jlow@example.com>}
      ]}

      iex> query = [
      ...>   {:_, FOAF.name, :name?},
      ...>   {:_, FOAF.mbox, :mbox?},
      ...> ] |> RDF.Query.bgp()
      ...> RDF.Query.execute(query, example_graph())
      {:ok, [
        %{name: ~L"Peter Goodguy", mbox: ~I<mailto:peter@example.org>},
        %{name: ~L"Johnny Lee Outlaw", mbox: ~I<mailto:jlow@example.com>}
      ]}

      iex> [
      ...>   EX.Goodguy, FOAF.friend, FOAF.name, :name?
      ...> ] |> RDF.Query.path() |> RDF.Query.execute(example_graph())
      {:ok, [%{name: ~L"Johnny Lee Outlaw"}]}

  """
  def execute(query, graph, opts \\ [])

  def execute(%BGP{} = query, %Graph{} = graph, opts) do
    matcher = Keyword.get(opts, :matcher, @default_matcher)
    {:ok, matcher.execute(query, graph, opts)}
  end

  def execute(query, graph, opts) do
    with {:ok, bgp} <- Builder.bgp(query, opts) do
      execute(bgp, graph, opts)
    end
  end

  @doc """
  Execute the given `query` against the given `graph`.

  As opposed to `execute/3` this function returns the results directly or fails
  with an exception.
  """
  def execute!(query, graph, opts \\ []) do
    case execute(query, graph, opts) do
      {:ok, results} -> results
      {:error, error} -> raise error
    end
  end

  @doc """
  Returns a `Stream` for the execution of the given `query` against the given `graph`.

  Just like on `execute/3` the `query` can be given directly as `RDF.Query.BGP` struct
  created with one of the builder functions in this module or as basic graph pattern
  expression accepted by `bgp/1`.

  The stream of solutions for variable bindings will be returned in a `:ok` tuple.
  In case of an error a `:error` tuple is returned.

  ## Example

  Let's assume we have an `example_graph` with these triples:

  ```turtle
  @prefix foaf: <http://xmlns.com/foaf/0.1/> .
  @prefix ex:   <http://example.com/> .

  ex:Outlaw
    foaf:name   "Johnny Lee Outlaw" ;
    foaf:mbox   <mailto:jlow@example.com> .

  ex:Goodguy
    foaf:name   "Peter Goodguy" ;
    foaf:mbox   <mailto:peter@example.org> ;
    foaf:friend ex:Outlaw .
  ```

      iex> {:ok, stream} = {:_, FOAF.name, :name?} |> RDF.Query.stream(example_graph())
      ...> Enum.to_list(stream)
      [%{name: ~L"Peter Goodguy"}, %{name: ~L"Johnny Lee Outlaw"}]

      iex> {:ok, stream} = [
      ...>   {:_, FOAF.name, :name?},
      ...>   {:_, FOAF.mbox, :mbox?},
      ...> ] |> RDF.Query.stream(example_graph())
      ...> Enum.take(stream, 1)
      [
        %{name: ~L"Peter Goodguy", mbox: ~I<mailto:peter@example.org>},
      ]

  """
  def stream(query, graph, opts \\ [])

  def stream(%BGP{} = query, %Graph{} = graph, opts) do
    matcher = Keyword.get(opts, :matcher, @default_matcher)
    {:ok, matcher.stream(query, graph, opts)}
  end

  def stream(query, graph, opts) do
    with {:ok, bgp} <- Builder.bgp(query, opts) do
      stream(bgp, graph, opts)
    end
  end

  @doc """
  Returns a `Stream` for the execution of the given `query` against the given `graph`.

  As opposed to `stream/3` this function returns the stream directly or fails
  with an exception.
  """
  def stream!(query, graph, opts \\ []) do
    case stream(query, graph, opts) do
      {:ok, results} -> results
      {:error, error} -> raise error
    end
  end

  @doc """
  Creates a `RDF.Query.BGP` struct.

  A basic graph pattern consist of single or list of triple patterns.
  A triple pattern is a tuple which consists of RDF terms or variables for
  the subject, predicate and object of an RDF triple.

  As RDF terms `RDF.IRI`s, `RDF.BlankNode`s, `RDF.Literal`s or all Elixir
  values which can be coerced to any of those are allowed, i.e.
  `RDF.Vocabulary.Namespace` atoms or Elixir values which can be coerced to RDF
  literals with `RDF.Literal.coerce/1` (only on object position). On predicate
  position the `:a` atom can be used for the `rdf:type` property.

  Variables are written as atoms ending with a question mark. Blank nodes which
  in a graph query patterns act like a variable which doesn't show up in the
  results can be written as atoms starting with an underscore.

  Here's a basic graph pattern example:

  ```elixir
  [
    {:s?, :a, EX.Foo},
    {:s?, :a, EX.Bar},
    {:s?, RDFS.label, "foo"},
    {:s?, :p?, :o?}
  ]
  ```

  Multiple triple patterns sharing the same subject and/or predicate can be grouped:

  - Multiple objects to the same subject-predicate pair can be written by just
    writing them one by one on the same triple pattern.
  - Multiple predicate-objects pair on the same subject can be written by
    grouping them with square brackets.

  With these, the previous example can be shortened to:

  ```elixir
  {
    :s?,
      [:a, EX.Foo, EX.Bar],
      [RDFS.label, "foo"],
      [:p?, :o?]
  }
  ```

  """
  defdelegate bgp(query), to: Builder, as: :bgp!

  @doc """
  Creates a `RDF.Query.BGP` struct for a path through a graph.

  The elements of the path can consist of the same RDF terms and variable
  expressions allowed in `bgp/1` expressions.

  ## Example

  The `RDF.Query.BGP` struct build with this:

      RDF.Query.path [EX.S, EX.p, RDFS.label, :name?]

  is the same as the one build by this `bgp/1` call:

      RDF.Query.bgp [
        {EX.S, EX.p, :_o},
        {:_o, RDFS.label, :name?},
      ]

  """
  defdelegate path(query, opts \\ []), to: Builder, as: :path!
end
