defmodule RDF.Query.Builder do
  @moduledoc !"""
             Functions for building `RDF.Query`s.

             This functions are not intended to be used directly,
             but through the `RDF.Query` API instead.
             """

  alias RDF.Query.BGP
  alias RDF.{IRI, BlankNode, Literal, Namespace, PropertyMap}
  import RDF.Utils.Guards
  import RDF.Utils

  def bgp(query, opts \\ []) do
    property_map = if context = Keyword.get(opts, :context), do: PropertyMap.new(context)

    with {:ok, triple_patterns} <- triple_patterns(query, property_map) do
      {:ok, %BGP{triple_patterns: triple_patterns}}
    end
  end

  def bgp!(query, opts \\ []) do
    case bgp(query, opts) do
      {:ok, bgp} -> bgp
      {:error, error} -> raise error
    end
  end

  defp triple_patterns(query, property_map) when is_list(query) or is_map(query) do
    flat_map_while_ok(query, fn triple ->
      with {:ok, triple_pattern} <- triple_patterns(triple, property_map) do
        {:ok, List.wrap(triple_pattern)}
      end
    end)
  end

  defp triple_patterns({subject, predicate, objects}, property_map) do
    with {:ok, subject_pattern} <- subject_pattern(subject, property_map) do
      do_triple_patterns(subject_pattern, {predicate, objects}, property_map)
    end
  end

  defp triple_patterns({subject, predications}, property_map) when is_map(predications) do
    triple_patterns({subject, Map.to_list(predications)}, property_map)
  end

  defp triple_patterns({subject, predications}, property_map) do
    with {:ok, subject_pattern} <- subject_pattern(subject, property_map) do
      predications
      |> List.wrap()
      |> flat_map_while_ok(&do_triple_patterns(subject_pattern, &1, property_map))
    end
  end

  defp do_triple_patterns(subject_pattern, {predicate, objects}, property_map) do
    with {:ok, predicate_pattern} <- predicate_pattern(predicate, property_map) do
      objects
      |> List.wrap()
      |> map_while_ok(fn object ->
        with {:ok, object_pattern} <- object_pattern(object, property_map) do
          {:ok, {subject_pattern, predicate_pattern, object_pattern}}
        end
      end)
    end
  end

  defp subject_pattern(subject, property_map) do
    value = variable(subject) || resource(subject) || quoted_triple(subject, property_map)

    if value do
      {:ok, value}
    else
      {:error,
       %RDF.Query.InvalidError{
         message: "Invalid subject term in BGP triple pattern: #{inspect(subject)}"
       }}
    end
  end

  defp predicate_pattern(predicate, property_map) do
    value = variable(predicate) || resource(predicate) || property(predicate, property_map)

    if value do
      {:ok, value}
    else
      {:error,
       %RDF.Query.InvalidError{
         message: "Invalid predicate term in BGP triple pattern: #{inspect(predicate)}"
       }}
    end
  end

  defp object_pattern(object, property_map) do
    value =
      variable(object) || resource(object) || literal(object) ||
        quoted_triple(object, property_map)

    if value do
      {:ok, value}
    else
      {:error,
       %RDF.Query.InvalidError{
         message: "Invalid object term in BGP triple pattern: #{inspect(object)}"
       }}
    end
  end

  defp variable(var) when is_atom(var) do
    var_string = to_string(var)

    if String.ends_with?(var_string, "?") do
      var_string
      |> String.slice(0..-2//1)
      |> String.to_atom()
    end
  end

  defp variable(_), do: nil

  defp resource(%IRI{} = iri), do: iri
  defp resource(%URI{} = uri), do: IRI.new(uri)
  defp resource(%BlankNode{} = bnode), do: bnode

  defp resource(var) when is_ordinary_atom(var) do
    case to_string(var) do
      "_" <> bnode ->
        BlankNode.new(bnode)

      _ ->
        case Namespace.resolve_term(var) do
          {:ok, iri} -> iri
          _ -> nil
        end
    end
  end

  defp resource(_), do: nil

  defp property(:a, _), do: RDF.type()

  defp property(term, property_map) when is_atom(term) and not is_nil(property_map) do
    PropertyMap.iri(property_map, term)
  end

  defp property(_, _), do: nil

  defp literal(%Literal{} = literal), do: literal
  defp literal(value), do: Literal.coerce(value)

  defp quoted_triple({s, p, o}, property_map) do
    with {:ok, subject} <- subject_pattern(s, property_map),
         {:ok, predicate} <- predicate_pattern(p, property_map),
         {:ok, object} <- object_pattern(o, property_map) do
      {subject, predicate, object}
    else
      _ -> nil
    end
  end

  defp quoted_triple(_, _), do: nil

  def path(query, opts \\ [])

  def path(query, _) when is_list(query) and length(query) < 3 do
    {:error,
     %RDF.Query.InvalidError{
       message: "Invalid path expression: must have at least three elements"
     }}
  end

  def path([subject | rest], opts) do
    path_pattern(subject, rest, [], 0, Keyword.get(opts, :with_elements, false))
    |> bgp(opts)
  end

  def path!(query, opts \\ []) do
    case path(query, opts) do
      {:ok, bgp} -> bgp
      {:error, error} -> raise error
    end
  end

  defp path_pattern(subject, [predicate, object], triple_patterns, _, _) do
    [{subject, predicate, object} | triple_patterns]
    |> Enum.reverse()
  end

  defp path_pattern(subject, [predicate | rest], triple_patterns, count, with_elements) do
    object = if with_elements, do: :"el#{count}?", else: BlankNode.new(count)

    path_pattern(
      object,
      rest,
      [{subject, predicate, object} | triple_patterns],
      count + 1,
      with_elements
    )
  end
end
