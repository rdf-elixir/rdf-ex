defmodule RDF do
  @moduledoc """
  The top-level module of RDF.ex.

  RDF.ex consists of:

  - modules for the nodes of an RDF graph
    - `RDF.Term`
    - `RDF.IRI`
    - `RDF.BlankNode`
    - `RDF.Literal`
  - the `RDF.Literal.Datatype` system
  - a facility for the mapping of URIs of a vocabulary to Elixir modules and
    functions: `RDF.Vocabulary.Namespace`
  - a facility for the automatic generation of resource identifiers: `RDF.Resource.Generator`
  - modules for the construction of statements
    - `RDF.Triple`
    - `RDF.Quad`
    - `RDF.Statement`
  - modules for collections of statements
    - `RDF.Description`
    - `RDF.Graph`
    - `RDF.Dataset`
    - `RDF.Data`
    - `RDF.List`
    - `RDF.Diff`
  - functions to construct and execute basic graph pattern queries: `RDF.Query`
  - functions for working with RDF serializations: `RDF.Serialization`
  - behaviours for the definition of RDF serialization formats
    - `RDF.Serialization.Format`
    - `RDF.Serialization.Decoder`
    - `RDF.Serialization.Encoder`
  - and the implementation of various RDF serialization formats
    - `RDF.NTriples`
    - `RDF.NQuads`
    - `RDF.Turtle`

  This top-level module provides shortcut functions for the construction of the
  basic elements and structures of RDF and some general helper functions.

  For a general introduction you may refer to the guides on the [homepage](https://rdf-elixir.dev).
  """

  alias RDF.{
    IRI,
    BlankNode,
    Literal,
    Namespace,
    Description,
    Graph,
    Dataset,
    Serialization,
    PrefixMap
  }

  import RDF.Guards
  import RDF.Utils.Bootstrapping

  @star? Application.get_env(:rdf, :star, true)
  @doc """
  Returns whether RDF-star support is enabled.
  """
  def star?(), do: @star?

  defdelegate default_base_iri(), to: IRI, as: :default_base

  @standard_prefixes PrefixMap.new(
                       xsd: xsd_iri_base(),
                       rdf: rdf_iri_base(),
                       rdfs: rdfs_iri_base()
                     )

  @doc """
  A fixed set prefixes that will always be part of the `default_prefixes/0`.

  ```elixir
  #{inspect(@standard_prefixes, pretty: true)}
  ```

  See `default_prefixes/0`, if you don't want these standard prefixes to be part
  of the default prefixes.
  """
  def standard_prefixes(), do: @standard_prefixes

  @doc """
  A user-defined `RDF.PrefixMap` of prefixes to IRI namespaces.

  This prefix map will be used implicitly wherever a prefix map is expected, but
  not provided. For example, when you don't pass a prefix map to the Turtle serializer,
  this prefix map will be used.

  By default the `standard_prefixes/0` are part of this prefix map, but you can
  define additional default prefixes via the `default_prefixes` compile-time
  configuration.

  For example:

      config :rdf,
        default_prefixes: %{
          ex: "http://example.com/"
        }

  You can also set `:default_prefixes` to a module-function tuple `{mod, fun}`
  with a function which should be called to determine the default prefixes.

  If you don't want the `standard_prefixes/0` to be part of the default prefixes,
  or you want to map the standard prefixes to different namespaces (strongly discouraged!),
  you can set the `use_standard_prefixes` compile-time configuration flag to `false`.

      config :rdf,
        use_standard_prefixes: false

  """
  case Application.get_env(:rdf, :default_prefixes, %{}) do
    {mod, fun} ->
      if Application.get_env(:rdf, :use_standard_prefixes, true) do
        def default_prefixes() do
          PrefixMap.merge!(@standard_prefixes, apply(unquote(mod), unquote(fun), []))
        end
      else
        def default_prefixes(), do: apply(unquote(mod), unquote(fun), [])
      end

    default_prefixes ->
      @default_prefixes PrefixMap.new(default_prefixes)
      if Application.get_env(:rdf, :use_standard_prefixes, true) do
        def default_prefixes() do
          PrefixMap.merge!(@standard_prefixes, @default_prefixes)
        end
      else
        def default_prefixes(), do: @default_prefixes
      end
  end

  @doc """
  Returns the `default_prefixes/0` with additional prefix mappings.

  The `prefix_mappings` can be given in any format accepted by `RDF.PrefixMap.new/1`.
  """
  def default_prefixes(prefix_mappings) do
    default_prefixes() |> PrefixMap.merge!(prefix_mappings)
  end

  defdelegate read_string(string, opts), to: Serialization
  defdelegate read_string!(string, opts), to: Serialization
  defdelegate read_stream(stream, opts \\ []), to: Serialization
  defdelegate read_stream!(stream, opts \\ []), to: Serialization
  defdelegate read_file(filename, opts \\ []), to: Serialization
  defdelegate read_file!(filename, opts \\ []), to: Serialization
  defdelegate write_string(data, opts), to: Serialization
  defdelegate write_string!(data, opts), to: Serialization
  defdelegate write_stream(data, opts), to: Serialization
  defdelegate write_file(data, filename, opts \\ []), to: Serialization
  defdelegate write_file!(data, filename, opts \\ []), to: Serialization

  @doc """
  Checks if the given value is a RDF resource.

  ## Examples

  Supposed `EX` is a `RDF.Vocabulary.Namespace` and `Foo` is not.

      iex> RDF.resource?(RDF.iri("http://example.com/resource"))
      true
      iex> RDF.resource?(EX.resource)
      true
      iex> RDF.resource?(EX.Resource)
      true
      iex> RDF.resource?(Foo.Resource)
      false
      iex> RDF.resource?(RDF.bnode)
      true
      iex> RDF.resource?(RDF.XSD.integer(42))
      false
      iex> RDF.resource?(42)
      false
  """
  def resource?(value)
  def resource?(%IRI{}), do: true
  def resource?(%BlankNode{}), do: true

  def resource?(qname) when maybe_ns_term(qname) do
    case Namespace.resolve_term(qname) do
      {:ok, iri} -> resource?(iri)
      _ -> false
    end
  end

  if @star? do
    def resource?({_, _, _} = triple), do: RDF.Triple.valid?(triple)
  end

  def resource?(_), do: false

  @doc """
  Checks if the given value is a RDF term.

  ## Examples

  Supposed `EX` is a `RDF.Vocabulary.Namespace` and `Foo` is not.

      iex> RDF.term?(RDF.iri("http://example.com/resource"))
      true
      iex> RDF.term?(EX.resource)
      true
      iex> RDF.term?(EX.Resource)
      true
      iex> RDF.term?(Foo.Resource)
      false
      iex> RDF.term?(RDF.bnode)
      true
      iex> RDF.term?(RDF.XSD.integer(42))
      true
      iex> RDF.term?(42)
      false
  """
  def term?(value)
  def term?(%Literal{}), do: true
  def term?(value), do: resource?(value)

  defdelegate uri?(value), to: IRI, as: :valid?
  defdelegate iri?(value), to: IRI, as: :valid?
  defdelegate uri(value), to: IRI, as: :new
  defdelegate iri(value), to: IRI, as: :new
  defdelegate uri!(value), to: IRI, as: :new!
  defdelegate iri!(value), to: IRI, as: :new!

  @doc """
  Checks if the given value is a blank node.

  ## Examples

      iex> RDF.bnode?(RDF.bnode)
      true
      iex> RDF.bnode?(RDF.iri("http://example.com/resource"))
      false
      iex> RDF.bnode?(42)
      false
  """
  def bnode?(%BlankNode{}), do: true
  def bnode?(_), do: false

  defdelegate bnode(), to: BlankNode, as: :new
  defdelegate bnode(id), to: BlankNode, as: :new

  @doc """
  Checks if the given value is a RDF literal.
  """
  def literal?(%Literal{}), do: true
  def literal?(_), do: false

  defdelegate literal(value), to: Literal, as: :new
  defdelegate literal(value, opts), to: Literal, as: :new

  if @star? do
    alias RDF.Star.{Triple, Quad, Statement}

    defdelegate triple(s, p, o, property_map \\ nil), to: Triple, as: :new
    defdelegate triple(tuple, property_map \\ nil), to: Triple, as: :new

    defdelegate quad(s, p, o, g, property_map \\ nil), to: Quad, as: :new
    defdelegate quad(tuple, property_map \\ nil), to: Quad, as: :new

    defdelegate statement(s, p, o), to: Statement, as: :new
    defdelegate statement(s, p, o, g), to: Statement, as: :new
    defdelegate statement(tuple, property_map \\ nil), to: Statement, as: :new

    defdelegate coerce_subject(subject, property_map \\ nil), to: Statement
    defdelegate coerce_predicate(predicate), to: Statement
    defdelegate coerce_predicate(predicate, property_map), to: Statement
    defdelegate coerce_object(object, property_map \\ nil), to: Statement
    defdelegate coerce_graph_name(graph_name), to: Statement
  else
    alias RDF.{Triple, Quad, Statement}

    defdelegate triple(s, p, o, property_map \\ nil), to: Triple, as: :new
    defdelegate triple(tuple, property_map \\ nil), to: Triple, as: :new

    defdelegate quad(s, p, o, g, property_map \\ nil), to: Quad, as: :new
    defdelegate quad(tuple, property_map \\ nil), to: Quad, as: :new

    defdelegate statement(s, p, o), to: Statement, as: :new
    defdelegate statement(s, p, o, g), to: Statement, as: :new
    defdelegate statement(tuple, property_map \\ nil), to: Statement, as: :new

    defdelegate coerce_subject(subject), to: Statement
    defdelegate coerce_predicate(predicate), to: Statement
    defdelegate coerce_predicate(predicate, property_map), to: Statement
    defdelegate coerce_object(object), to: Statement
    defdelegate coerce_graph_name(graph_name), to: Statement
  end

  defdelegate description(subject, opts \\ []), to: Description, as: :new

  defdelegate graph(), to: Graph, as: :new
  defdelegate graph(arg), to: Graph, as: :new
  defdelegate graph(arg1, arg2), to: Graph, as: :new

  defdelegate dataset(), to: Dataset, as: :new
  defdelegate dataset(arg), to: Dataset, as: :new
  defdelegate dataset(arg1, arg2), to: Dataset, as: :new

  defdelegate diff(arg1, arg2), to: RDF.Diff

  defdelegate list?(resource, graph), to: RDF.List, as: :node?
  defdelegate list?(description), to: RDF.List, as: :node?

  def list(native_list), do: RDF.List.from(native_list)
  def list(head, %Graph{} = graph), do: RDF.List.new(head, graph)
  def list(native_list, opts), do: RDF.List.from(native_list, opts)

  defdelegate prefix_map(prefixes), to: RDF.PrefixMap, as: :new
  defdelegate property_map(property_map), to: RDF.PropertyMap, as: :new

  ############################################################################
  # These alias functions for the RDF.NS.RDF namespace are mandatory.
  # Without them the property functions are inaccessible, since the namespace
  # can't be aliased, because it gets in conflict with the root namespace
  # of the project.

  defdelegate langString(value, opts), to: RDF.LangString, as: :new
  defdelegate lang_string(value, opts), to: RDF.LangString, as: :new

  for term <- ~w[type subject predicate object first rest value]a do
    defdelegate unquote(term)(), to: RDF.NS.RDF
    @doc false
    defdelegate unquote(term)(s, o), to: RDF.NS.RDF
    @doc false
    defdelegate unquote(term)(s, o1, o2), to: RDF.NS.RDF
    @doc false
    defdelegate unquote(term)(s, o1, o2, o3), to: RDF.NS.RDF
    @doc false
    defdelegate unquote(term)(s, o1, o2, o3, o4), to: RDF.NS.RDF
    @doc false
    defdelegate unquote(term)(s, o1, o2, o3, o4, o5), to: RDF.NS.RDF
  end

  defdelegate langString(), to: RDF.NS.RDF
  defdelegate lang_string(), to: RDF.NS.RDF, as: :langString
  defdelegate unquote(nil)(), to: RDF.NS.RDF

  defdelegate __base_iri__(), to: RDF.NS.RDF
end
