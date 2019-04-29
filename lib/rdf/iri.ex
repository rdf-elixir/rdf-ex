defmodule RDF.IRI do
  @moduledoc """
  A structure for IRIs.

  This structure just wraps a plain IRI string and doesn't bother with the
  components of the IRI, since in the context of RDF there are usually very many
  IRIs and parsing them isn't needed in most cases. For these reasons we don't
  use Elixirs built-in `URI` structure, because it would be unnecessary
  expensive in terms of performance and memory.

  The component parts can always be retrieved with the `RDF.IRI.parse/1`
  function, which returns Elixirs built-in `URI` structure. Note, that `URI`
  doesn't escape Unicode characters by default, so it's a suitable structure for
  IRIs.

  see <https://tools.ietf.org/html/rfc3987>
  """

  @enforce_keys [:value]
  defstruct [:value]

  alias RDF.Namespace

  @type t :: module

  # see https://tools.ietf.org/html/rfc3986#appendix-B
  @scheme_regex Regex.recompile!(~r/^([a-z][a-z0-9\+\-\.]*):/i)

  @doc """
  The default base IRI to be used when reading a serialization and no `base` option is provided.

  The value can be set via the `default_base_iri` configuration. For example:

      config :rdf,
        default_base_iri: "http://my_app.example/"

  See [section 5.1.4 of RFC 3987](https://tools.ietf.org/html/rfc3986#page-29)
  """
  @default_base Application.get_env(:rdf, :default_base_iri)
  def default_base, do: @default_base


  @doc """
  Creates a `RDF.IRI`.
  """
  def new(iri)
  def new(iri) when is_binary(iri),   do: %RDF.IRI{value: iri}
  def new(qname) when is_atom(qname) and qname not in [nil, true, false],
    do: Namespace.resolve_term(qname)
  def new(%URI{} = uri),              do: uri |> URI.to_string |> new
  def new(%RDF.IRI{} = iri),          do: iri

  @doc """
  Creates a `RDF.IRI`, but checks if the given IRI is valid.

  If the given IRI is not valid a `RDF.IRI.InvalidError` is raised.

  see `valid?/1`
  """
  def new!(iri)
  def new!(iri) when is_binary(iri),   do: iri |> valid!() |> new()
  def new!(qname) when is_atom(qname) and qname not in [nil, true, false],
    do: new(qname)  # since terms of a namespace are already validated
  def new!(%URI{} = uri),              do: uri |> valid!() |> new()
  def new!(%RDF.IRI{} = iri),          do: valid!(iri)


  @doc """
  Returns the given value unchanged if it's a valid IRI, otherwise raises an exception.

  ## Examples

      iex> RDF.IRI.valid!("http://www.example.com/foo")
      "http://www.example.com/foo"
      iex> RDF.IRI.valid!(RDF.IRI.new("http://www.example.com/foo"))
      RDF.IRI.new("http://www.example.com/foo")
      iex> RDF.IRI.valid!("not an iri")
      ** (RDF.IRI.InvalidError) Invalid IRI: "not an iri"
  """
  def valid!(iri) do
    if not valid?(iri), do: raise RDF.IRI.InvalidError, "Invalid IRI: #{inspect iri}"
    iri
  end


  @doc """
  Checks if the given IRI is valid.

  Note: This currently checks only if the given IRI is absolute.

  ## Examples

      iex> RDF.IRI.valid?("http://www.example.com/foo")
      true
      iex> RDF.IRI.valid?("not an iri")
      false
  """
  def valid?(iri), do: absolute?(iri)  # TODO: Provide a more elaborate validation


  @doc """
  Checks if the given value is an absolute IRI.

  An absolute IRI is defined in [RFC3987](http://www.ietf.org/rfc/rfc3987.txt)
  containing a scheme along with a path and optional query and fragment segments.
  """
  def absolute?(iri)

  def absolute?(value) when is_binary(value), do: not is_nil(scheme(value))
  def absolute?(%RDF.IRI{value: value}),      do: absolute?(value)
  def absolute?(%URI{scheme: nil}),           do: false
  def absolute?(%URI{scheme: _}),             do: true
  def absolute?(qname) when is_atom(qname) and qname not in [nil, true, false] do
    qname |> Namespace.resolve_term |> absolute?()
  rescue
    _ -> false
  end
  def absolute?(_), do: false


  @doc """
  Resolves a relative IRI against a base IRI.

  as specified in [section 5.1 Establishing a Base URI of RFC3986](http://tools.ietf.org/html/rfc3986#section-5.1).
  Only the basic algorithm in [section 5.2 of RFC3986](http://tools.ietf.org/html/rfc3986#section-5.2)
  is used; neither Syntax-Based Normalization nor Scheme-Based Normalization are performed.

  Characters additionally allowed in IRI references are treated in the same way that unreserved
  characters are treated in URI references, per [section 6.5 of RFC3987](http://tools.ietf.org/html/rfc3987#section-6.5)

  If the given is not an absolute IRI `nil` is returned.
  """
  def absolute(iri, base) do
    cond do
      absolute?(iri)      -> new(iri)
      not absolute?(base) -> nil
      true                -> merge(base, iri)
    end
  end


  @doc """
  Merges two IRIs.

  This function merges two IRIs as per
  [RFC 3986, section 5.2](https://tools.ietf.org/html/rfc3986#section-5.2).
  """
  def merge(base, rel) do
    base
    |> parse()
    |> URI.merge(parse(rel))
    |> empty_fragment_shim(rel)
    |> new()
  end


  @doc false
  # shim for https://github.com/elixir-lang/elixir/pull/6419
  def empty_fragment_shim(_, %URI{} = uri), do: uri
  def empty_fragment_shim(uri, %RDF.IRI{value: value}),
    do: empty_fragment_shim(uri, value)
  def empty_fragment_shim(uri, original) do
    if String.ends_with?(original, "#") do
      %URI{uri | fragment: ""}
    else
      uri
    end
  end


  @doc """
  Returns the scheme of the given IRI

  If the given string is not a valid absolute IRI, `nil` is returned.

  ## Examples

      iex> RDF.IRI.scheme("http://www.example.com/foo")
      "http"
      iex> RDF.IRI.scheme("not an iri")
      nil
  """
  def scheme(iri)
  def scheme(%RDF.IRI{value: value}),    do: scheme(value)
  def scheme(%URI{scheme: scheme}),      do: scheme
  def scheme(qname) when is_atom(qname), do: Namespace.resolve_term(qname) |> scheme()
  def scheme(iri) when is_binary(iri) do
    with [_, scheme] <- Regex.run(@scheme_regex, iri) do
      scheme
    end
  end


  @doc """
  Parses an IRI into its components and returns them as an `URI` struct.
  """
  def parse(iri)
  def parse(iri) when is_binary(iri),   do: URI.parse(iri) |> empty_fragment_shim(iri)
  def parse(qname) when is_atom(qname) and qname not in [nil, true, false],
    do: Namespace.resolve_term(qname) |> parse()
  def parse(%RDF.IRI{value: value}),    do: URI.parse(value) |> empty_fragment_shim(value)
  def parse(%URI{} = uri),              do: uri


  @doc """
  Tests for value equality of IRIs.

  Returns `nil` when the given arguments are not comparable as IRIs.

  see <https://www.w3.org/TR/rdf-concepts/#section-Graph-URIref>
  """
  def equal_value?(left, right)

  def equal_value?(%RDF.IRI{value: left}, %RDF.IRI{value: right}),
    do: left == right

  @xsd_any_uri "http://www.w3.org/2001/XMLSchema#anyURI"

  def equal_value?(%RDF.Literal{datatype: %RDF.IRI{value: @xsd_any_uri}, value: left}, right),
    do: equal_value?(new(left), right)

  def equal_value?(left, %RDF.Literal{datatype: %RDF.IRI{value: @xsd_any_uri}, value: right}),
    do: equal_value?(left, new(right))

  def equal_value?(_, _),
    do: nil


  @doc """
  Returns the given IRI as a string.

  Note that this function can also handle `RDF.Vocabulary.Namespace` terms.

  ## Examples

      iex> RDF.IRI.to_string RDF.IRI.new("http://example.com/#foo")
      "http://example.com/#foo"
      iex> RDF.IRI.to_string EX.foo
      "http://example.com/#foo"
      iex> RDF.IRI.to_string EX.Foo
      "http://example.com/#Foo"

  """
  def to_string(iri)

  def to_string(%RDF.IRI{value: value}),
    do: value

  def to_string(qname) when is_atom(qname),
    do: qname |> new() |> __MODULE__.to_string()

  defimpl String.Chars do
    def to_string(iri), do: RDF.IRI.to_string(iri)
  end
end
