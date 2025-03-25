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

  alias RDF.Namespace
  alias RDF.IRI.Validation
  import RDF.Guards

  @type t :: %__MODULE__{value: String.t()}

  @type coercible :: String.t() | URI.t() | module | t

  @enforce_keys [:value]
  defstruct [:value]

  # see https://tools.ietf.org/html/rfc3986#appendix-B
  @scheme_regex Regex.recompile!(~r/^([a-z][a-z0-9\+\-\.]*):/i)

  @doc """
  The default base IRI to be used when reading a serialization and no `base_iri` option is provided.

  The value can be set via the `default_base_iri` configuration. For example:

      config :rdf,
        default_base_iri: "http://my_app.example/"

  You can also set `:default_base_iri` to a module-function tuple `{mod, fun}`
  with a function which should be called to determine the default base IRI.

  See [section 5.1.4 of RFC 3987](https://tools.ietf.org/html/rfc3986#page-29)
  """
  case Application.compile_env(:rdf, :default_base_iri) do
    {mod, fun} ->
      def default_base(), do: apply(unquote(mod), unquote(fun), [])

    default_base ->
      @default_base default_base
      def default_base, do: @default_base
  end

  @doc """
  Creates a `RDF.IRI`.
  """
  @spec new(coercible) :: t
  def new(iri)
  def new(iri) when is_binary(iri), do: %__MODULE__{value: iri}
  def new(term) when maybe_ns_term(term), do: Namespace.resolve_term!(term)
  def new(%URI{} = uri), do: uri |> URI.to_string() |> new()
  def new(%__MODULE__{} = iri), do: iri

  @doc """
  Creates a `RDF.IRI`, but checks if the given IRI is valid.

  If the given IRI is not valid a `RDF.IRI.InvalidError` is raised.

  see `valid?/1`
  """
  @spec new!(coercible) :: t
  def new!(iri)
  def new!(iri) when is_binary(iri), do: iri |> valid_binary!() |> new()
  # since terms of a namespace are already validated
  def new!(term) when maybe_ns_term(term), do: new(term)
  def new!(%URI{} = uri), do: uri |> valid!() |> new()
  def new!(%__MODULE__{} = iri), do: valid!(iri)

  @doc """
  Appends a String to a `RDF.IRI`.

  ## Example

      iex> ~I<http://example.com/> |> RDF.IRI.append("foo")
      ~I<http://example.com/foo>

      iex> EX.foo |> RDF.IRI.append("bar")
      EX.foobar

      iex> EX.Foo |> RDF.IRI.append("bar")
      RDF.iri(EX.Foobar)
  """
  @spec append(t | module, String.t()) :: t
  def append(iri, string)

  def append(%__MODULE__{} = iri, string) do
    %__MODULE__{iri | value: iri.value <> string}
  end

  def append(term, string) when maybe_ns_term(term) do
    term |> Namespace.resolve_term!() |> append(string)
  end

  @doc """
  Coerces an IRI serving as a base IRI.

  As opposed to `new/1` this also accepts bare `RDF.Vocabulary.Namespace` modules
  and uses the base IRI from their definition.
  """
  @spec coerce_base(coercible) :: t
  def coerce_base(base_iri)

  def coerce_base(module) when maybe_ns_term(module) do
    if RDF.Vocabulary.Namespace.vocabulary_namespace?(module) do
      apply(module, :__base_iri__, [])
      |> new()
    else
      new(module)
    end
  end

  def coerce_base(base_iri), do: new(base_iri)

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
  @spec valid!(coercible) :: coercible
  def valid!(iri) do
    if not valid?(iri), do: raise(RDF.IRI.InvalidError, "Invalid IRI: #{inspect(iri)}")
    iri
  end

  defp valid_binary!(iri) do
    if not valid_binary?(iri), do: raise(RDF.IRI.InvalidError, "Invalid IRI: #{inspect(iri)}")
    iri
  end

  @doc """
  Checks if the given IRI is valid according to RFC 3987.

  ## Examples

      iex> RDF.IRI.valid?("http://www.example.com/foo")
      true

      iex> RDF.IRI.valid?("urn:isbn:0451450523")
      true

      iex> RDF.IRI.valid?("http://example.com/path with spaces")
      false

      iex> RDF.IRI.valid?("example.com")
      false
  """
  @spec valid?(coercible) :: boolean
  def valid?(iri) when is_binary(iri), do: valid_binary?(iri)
  def valid?(%__MODULE__{value: value}), do: valid?(value)
  def valid?(%URI{scheme: nil}), do: false
  def valid?(%URI{} = uri), do: uri |> URI.to_string() |> valid?()

  def valid?(term) when maybe_ns_term(term) do
    case Namespace.resolve_term(term) do
      {:ok, iri} -> valid?(iri)
      _ -> false
    end
  end

  def valid?(_), do: false

  @spec valid_binary?(binary()) :: boolean
  defp valid_binary?(iri), do: Validation.valid?(iri)

  @doc """
  Checks if the given value is an absolute IRI.

  An absolute IRI is defined in [RFC3987](http://www.ietf.org/rfc/rfc3987.txt)
  containing a scheme along with a path and optional query and fragment segments.
  """
  @spec absolute?(any) :: boolean
  def absolute?(iri)

  def absolute?(value) when is_binary(value), do: not is_nil(scheme_from_binary(value))
  def absolute?(%__MODULE__{value: value}), do: absolute?(value)
  def absolute?(%URI{scheme: nil}), do: false
  def absolute?(%URI{scheme: _}), do: true

  def absolute?(term) when maybe_ns_term(term) do
    case Namespace.resolve_term(term) do
      {:ok, iri} -> absolute?(iri)
      _ -> false
    end
  end

  def absolute?(_), do: false

  @doc """
  Resolves a relative IRI against a base IRI.

  as specified in [section 5.1 Establishing a Base URI of RFC3986](http://tools.ietf.org/html/rfc3986#section-5.1).
  Only the basic algorithm in [section 5.2 of RFC3986](http://tools.ietf.org/html/rfc3986#section-5.2)
  is used; neither Syntax-Based Normalization nor Scheme-Based Normalization are performed.

  Characters additionally allowed in IRI references are treated in the same way that unreserved
  characters are treated in URI references, per [section 6.5 of RFC3987](http://tools.ietf.org/html/rfc3987#section-6.5)

  If the given `base` is not an absolute IRI `nil` is returned.
  """
  @spec absolute(coercible, coercible) :: t | nil
  def absolute(iri, base) do
    cond do
      absolute?(iri) -> new(iri)
      not absolute?(base) -> nil
      true -> merge(base, iri)
    end
  end

  @doc """
  Merges two IRIs.

  This function merges two IRIs as per
  [RFC 3986, section 5.2](https://tools.ietf.org/html/rfc3986#section-5.2).
  """
  @spec merge(coercible, coercible) :: t
  def merge(base, rel) do
    base
    |> parse()
    |> URI.merge(parse(rel))
    |> new()
  end

  @doc """
  Merges two IRIs and fails when the given base or the result of the merge is not a valid IRI.

  This function merges two IRIs as per
  [RFC 3986, section 5.2](https://tools.ietf.org/html/rfc3986#section-5.2).
  """
  @spec merge!(coercible, coercible) :: t
  def merge!(base, rel), do: base |> valid!() |> merge(rel) |> valid!()

  @doc """
  Returns the scheme of the given IRI

  If the given string is not a valid absolute IRI, `nil` is returned.

  ## Examples

      iex> RDF.IRI.scheme("http://www.example.com/foo")
      "http"
      iex> RDF.IRI.scheme("not an iri")
      nil
  """
  @spec scheme(coercible) :: String.t() | nil
  def scheme(iri)
  def scheme(%__MODULE__{value: value}), do: scheme(value)
  def scheme(%URI{scheme: scheme}), do: scheme
  def scheme(term) when maybe_ns_term(term), do: Namespace.resolve_term!(term) |> scheme()

  def scheme(iri) when is_binary(iri), do: scheme_from_binary(iri)

  defp scheme_from_binary(iri) do
    with [_, scheme] <- RDF.Utils.Regex.run(@scheme_regex, iri) do
      scheme
    end
  end

  @doc """
  Parses an IRI into its components and returns them as an `URI` struct.
  """
  @spec parse(coercible) :: URI.t()
  def parse(iri)
  def parse(iri) when is_binary(iri), do: URI.parse(iri)
  def parse(term) when maybe_ns_term(term), do: Namespace.resolve_term!(term) |> parse()
  def parse(%__MODULE__{value: value}), do: URI.parse(value)
  def parse(%URI{} = uri), do: uri

  @doc """
  Checks whether `iri` lies in `namespace`.

  ## Examples

      iex> RDF.IRI.in_namespace?(~I<http://example.com/foo>, ~I<http://example.com/>)
      true
      iex> RDF.IRI.in_namespace?(EX.Foo, ~I<http://example.com/>)
      true
      iex> RDF.IRI.in_namespace?(~I<http://example.com/foo/bar>, "http://example.com/")
      true
      iex> RDF.IRI.in_namespace?(~I<http://example.com/#foo>, EX)
      true
  """
  @spec in_namespace?(t | module, String.t() | t | module) :: boolean
  def in_namespace?(iri, namespace)

  def in_namespace?(iri, namespace) when is_binary(namespace),
    do: starts_with?(iri, namespace)

  def in_namespace?(iri, namespace) when maybe_ns_term(namespace),
    do: in_namespace?(iri, coerce_base(namespace))

  def in_namespace?(iri, %__MODULE__{} = namespace),
    do: in_namespace?(iri, __MODULE__.to_string(namespace))

  @doc """
  Checks whether `iri` starts with any of the given prefixes.

  ## Examples

      iex> RDF.IRI.starts_with?(~I<http://example.com/foo>, "http://example.com/")
      true
      iex> RDF.IRI.starts_with?(EX.Foo, "http://example.com/")
      true
      iex> RDF.IRI.starts_with?(~I<http://example.com/foo/bar>, ["http://example.com/", "http://example.org/"])
      true
      iex> RDF.IRI.starts_with?(~I<http://example.com/#foo>, "http://example.org/")
      false
  """
  @spec starts_with?(t | module, String.pattern()) :: boolean
  def starts_with?(%__MODULE__{} = iri, prefix) do
    String.starts_with?(iri.value, prefix)
  end

  def starts_with?(term, prefix) when maybe_ns_term(term),
    do: term |> Namespace.resolve_term!() |> starts_with?(prefix)

  @doc """
  Checks whether `iri` end with any of the given suffixes.

  ## Examples

      iex> RDF.IRI.ends_with?(~I<http://example.com/foo>, "foo")
      true
      iex> RDF.IRI.ends_with?(EX.Foo, "Foo")
      true
      iex> RDF.IRI.ends_with?(~I<http://example.com/foo>, ["foo", "bar"])
      true
      iex> RDF.IRI.ends_with?(~I<http://example.com/foo>, "bar")
      false
  """
  @spec ends_with?(t | module, String.t() | [String.t()]) :: boolean
  def ends_with?(%__MODULE__{} = iri, suffix) do
    String.ends_with?(iri.value, suffix)
  end

  def ends_with?(term, suffix) when maybe_ns_term(term),
    do: term |> Namespace.resolve_term!() |> ends_with?(suffix)

  @doc """
  Tests for value equality of IRIs.

  Returns `nil` when the given arguments are not comparable as IRIs.

  see <https://www.w3.org/TR/rdf-concepts/#section-Graph-URIref>
  """
  @spec equal_value?(t | RDF.Literal.t() | atom, t | RDF.Literal.t() | URI.t() | atom) ::
          boolean | nil
  def equal_value?(left, right)

  def equal_value?(%__MODULE__{value: left}, %__MODULE__{value: right}),
    do: left == right

  def equal_value?(%__MODULE__{} = left, %RDF.Literal{} = right),
    do: RDF.Literal.equal_value?(right, left)

  def equal_value?(%__MODULE__{value: left}, %URI{} = right),
    do: left == URI.to_string(right)

  def equal_value?(left, %__MODULE__{} = right) when maybe_ns_term(left),
    do: equal_value?(right, left)

  def equal_value?(%__MODULE__{} = left, right) when maybe_ns_term(right) do
    case Namespace.resolve_term(right) do
      {:ok, iri} -> equal_value?(left, iri)
      _ -> nil
    end
  end

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
  @spec to_string(t | module) :: String.t()
  def to_string(iri)
  def to_string(%__MODULE__{value: value}), do: value
  def to_string(term) when maybe_ns_term(term), do: term |> new() |> __MODULE__.to_string()

  defimpl String.Chars do
    def to_string(iri), do: RDF.IRI.to_string(iri)
  end
end
