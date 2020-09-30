defmodule RDF.Query.Builder do
  @moduledoc false

  alias RDF.Query.BGP
  alias RDF.{IRI, BlankNode, Literal, Namespace}
  import RDF.Utils.Guards
  import RDF.Utils

  def bgp(query) do
    with {:ok, triple_patterns} <- triple_patterns(query) do
      {:ok, %BGP{triple_patterns: triple_patterns}}
    end
  end

  def bgp!(query) do
    case bgp(query) do
      {:ok, bgp} -> bgp
      {:error, error} -> raise error
    end
  end

  defp triple_patterns(query) when is_list(query) do
    flat_map_while_ok(query, fn triple ->
      with {:ok, triple_pattern} <- triple_pattern(triple) do
        {:ok, List.wrap(triple_pattern)}
      end
    end)
  end

  defp triple_patterns(triple_pattern) when is_tuple(triple_pattern),
    do: triple_patterns([triple_pattern])

  defp triple_pattern({subject, predicate, object})
       when not is_list(predicate) and not is_list(object) do
    with {:ok, subject_pattern} <- subject_pattern(subject),
         {:ok, predicate_pattern} <- predicate_pattern(predicate),
         {:ok, object_pattern} <- object_pattern(object) do
      {:ok, {subject_pattern, predicate_pattern, object_pattern}}
    end
  end

  defp triple_pattern(combined_objects_triple_pattern)
       when is_tuple(combined_objects_triple_pattern) do
    [subject | rest] = Tuple.to_list(combined_objects_triple_pattern)

    case rest do
      [predicate | objects] when not is_list(predicate) ->
        if Enum.all?(objects, &(not is_list(&1))) do
          objects
          |> Enum.map(fn object -> {subject, predicate, object} end)
          |> triple_patterns()
        else
          {:error,
           %RDF.Query.InvalidError{
             message: "Invalid use of predicate-object pair brackets"
           }}
        end

      predicate_object_pairs ->
        if Enum.all?(predicate_object_pairs, &(is_list(&1) and length(&1) > 1)) do
          predicate_object_pairs
          |> Enum.flat_map(fn [predicate | objects] ->
            Enum.map(objects, fn object -> {subject, predicate, object} end)
          end)
          |> triple_patterns()
        else
          {:error,
           %RDF.Query.InvalidError{
             message: "Invalid use of predicate-object pair brackets"
           }}
        end
    end
  end

  defp subject_pattern(subject) do
    value = variable(subject) || resource(subject)

    if value do
      {:ok, value}
    else
      {:error,
       %RDF.Query.InvalidError{
         message: "Invalid subject term in BGP triple pattern: #{inspect(subject)}"
       }}
    end
  end

  defp predicate_pattern(predicate) do
    value = variable(predicate) || resource(predicate) || property(predicate)

    if value do
      {:ok, value}
    else
      {:error,
       %RDF.Query.InvalidError{
         message: "Invalid predicate term in BGP triple pattern: #{inspect(predicate)}"
       }}
    end
  end

  defp object_pattern(object) do
    value = variable(object) || resource(object) || literal(object)

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
      |> String.slice(0..-2)
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

  defp property(:a), do: RDF.type()
  defp property(_), do: nil

  defp literal(%Literal{} = literal), do: literal
  defp literal(value), do: Literal.coerce(value)

  def path(query, opts \\ [])

  def path(query, _) when is_list(query) and length(query) < 3 do
    {:error,
     %RDF.Query.InvalidError{
       message: "Invalid path expression: must have at least three elements"
     }}
  end

  def path([subject | rest], opts) do
    path_pattern(subject, rest, [], 0, Keyword.get(opts, :with_elements, false))
    |> bgp()
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
    object = if with_elements, do: :"el#{count}?", else: RDF.bnode(count)

    path_pattern(
      object,
      rest,
      [{subject, predicate, object} | triple_patterns],
      count + 1,
      with_elements
    )
  end
end
