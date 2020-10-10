defmodule RDF.PropertyMap do
  defstruct iris: %{},
            terms: %{}

  alias RDF.IRI

  @type t :: %__MODULE__{
          iris: %{atom => IRI.t()},
          terms: %{IRI.t() => atom}
        }

  @behaviour Access

  def new(), do: %__MODULE__{}

  def new(%__MODULE__{} = initial), do: initial

  def new(initial) do
    {:ok, property_map} = new() |> add(initial)

    property_map
  end

  def iri(%__MODULE__{} = property_map, term) do
    Map.get(property_map.iris, coerce_term(term))
  end

  def term(%__MODULE__{} = property_map, iri) do
    Map.get(property_map.terms, IRI.new(iri))
  end

  def iri_defined?(%__MODULE__{} = property_map, term) do
    Map.has_key?(property_map.iris, coerce_term(term))
  end

  def term_defined?(%__MODULE__{} = property_map, iri) do
    Map.has_key?(property_map.terms, IRI.new(iri))
  end

  @impl Access
  def fetch(%__MODULE__{} = property_map, term) do
    Access.fetch(property_map.iris, coerce_term(term))
  end

  def add(%__MODULE__{} = property_map, term, iri) do
    do_set(property_map, :add, coerce_term(term), IRI.new(iri))
  end

  def add(%__MODULE__{} = property_map, mappings) do
    Enum.reduce_while(mappings, {:ok, property_map}, fn {term, iri}, {:ok, property_map} ->
      with {:ok, property_map} <- add(property_map, term, iri) do
        {:cont, {:ok, property_map}}
      else
        error -> {:halt, error}
      end
    end)
  end

  def put(%__MODULE__{} = property_map, term, iri) do
    {:ok, added} = do_set(property_map, :put, coerce_term(term), IRI.new(iri))
    added
  end

  def put(%__MODULE__{} = property_map, mappings) do
    Enum.reduce(mappings, property_map, fn {term, iri}, property_map ->
      put(property_map, term, iri)
    end)
  end

  defp do_set(property_map, op, term, iri) do
    do_set(property_map, op, term, iri, Map.get(property_map.iris, term))
  end

  defp do_set(property_map, _, _, iri, iri), do: {:ok, property_map}

  defp do_set(property_map, _, term, iri, nil) do
    {:ok,
     %__MODULE__{
       property_map
       | iris: Map.put(property_map.iris, term, iri),
         terms: Map.put(property_map.terms, iri, term)
     }}
  end

  defp do_set(_context, :add, term, new_iri, old_iri) do
    {:error, "conflicting mapping for #{term}: #{new_iri}; already mapped to #{old_iri}"}
  end

  defp do_set(property_map, :put, term, new_iri, old_iri) do
    %__MODULE__{property_map | terms: Map.delete(property_map.terms, old_iri)}
    |> do_set(:put, term, new_iri, nil)
  end

  def delete(%__MODULE__{} = property_map, term) do
    term = coerce_term(term)

    if iri = Map.get(property_map.iris, term) do
      %__MODULE__{
        property_map
        | iris: Map.delete(property_map.iris, term),
          terms: Map.delete(property_map.terms, iri)
      }
    else
      property_map
    end
  end

  def drop(%__MODULE__{} = property_map, terms) when is_list(terms) do
    Enum.reduce(terms, property_map, fn term, property_map ->
      delete(property_map, term)
    end)
  end

  defp coerce_term(term) when is_atom(term), do: term
  defp coerce_term(term) when is_binary(term), do: String.to_atom(term)

  @impl Access
  def pop(%__MODULE__{} = property_map, term) do
    case Access.pop(property_map.iris, coerce_term(term)) do
      {nil, _} ->
        {nil, property_map}

      {iri, new_context_map} ->
        {iri, %__MODULE__{iris: new_context_map}}
    end
  end

  @impl Access
  def get_and_update(property_map, term, fun) do
    term = coerce_term(term)
    current = iri(property_map, term)

    case fun.(current) do
      {old_iri, new_iri} ->
        {:ok, property_map} = do_set(property_map, :put, term, IRI.new(new_iri), IRI.new(old_iri))
        {old_iri, property_map}

      :pop ->
        {current, delete(property_map, term)}

      other ->
        raise "the given function must return a two-element tuple or :pop, got: #{inspect(other)}"
    end
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(property_map, opts) do
      map = Map.to_list(property_map.iris)
      open = color("%RDF.PropertyMap{", :map, opts)
      sep = color(",", :map, opts)
      close = color("}", :map, opts)

      container_doc(open, map, close, opts, &to_map(&1, &2, color(" <=> ", :map, opts)),
        separator: sep,
        break: :strict
      )
    end

    defp to_map({key, value}, opts, sep) do
      concat(concat(to_doc(key, opts), sep), to_doc(value, opts))
    end
  end
end
