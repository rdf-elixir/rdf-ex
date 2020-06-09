defmodule RDF.Query.BGP do
  @enforce_keys [:triple_patterns]
  defstruct [:triple_patterns]

  alias RDF.{IRI, BlankNode, Literal, Namespace}
  import RDF.Utils.Guards

  @type variable :: String.t
  @type triple_pattern :: {
                            subject :: variable | RDF.Term.t,
                            predicate :: variable | RDF.Term.t,
                            object :: variable | RDF.Term.t
                          }
  @type triple_patterns :: list(triple_pattern)

  @type t :: %__MODULE__{triple_patterns: triple_patterns}


  def new(query) do
    case new!(query) do
      {:ok, bgp} -> bgp
      {:error, error} -> raise error
    end
  end

  def new!(query) do
    with {:ok, triple_patterns} <- triple_patterns(query) do
      {:ok, %__MODULE__{triple_patterns: triple_patterns}}
    end
  end

  defp triple_patterns(query) when is_list(query) do
    Enum.reduce_while(query, {:ok, []}, fn
      triple, {:ok, triple_patterns} ->
        case triple_pattern(triple) do
          {:ok, triple_pattern} ->
            {:cont, {:ok, triple_patterns ++ List.wrap(triple_pattern)}}

          {:error, error} ->
            {:halt, {:error, error}}
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

  defp triple_pattern(combined_objects_triple_pattern) when is_tuple(combined_objects_triple_pattern) do
    [subject | rest] = Tuple.to_list(combined_objects_triple_pattern)

    case rest do
      [predicate | objects] when not is_list(predicate) ->
        if Enum.all?(objects, &(not is_list(&1))) do
          objects
          |> Enum.map(fn object -> {subject, predicate, object} end)
          |> triple_patterns()
        else
          {:error, %RDF.Query.InvalidError{
            message: "Invalid use of predicate-object pair brackets"}
          }
        end

      predicate_object_pairs ->
        if Enum.all?(predicate_object_pairs, &(is_list(&1) and length(&1) > 1)) do
          predicate_object_pairs
          |> Enum.flat_map(fn [predicate | objects] ->
            Enum.map(objects, fn object -> {subject, predicate, object} end)
          end)
          |> triple_patterns()
        else
          {:error, %RDF.Query.InvalidError{
            message: "Invalid use of predicate-object pair brackets"}
          }
        end
    end
  end

  defp subject_pattern(subject) do
    value = variable(subject) || resource(subject)

    if value do
      {:ok, value}
    else
      {:error, %RDF.Query.InvalidError{
        message: "Invalid subject term in BGP triple pattern: #{inspect subject}"}
      }
    end
  end

  defp predicate_pattern(predicate) do
    value = variable(predicate) || resource(predicate) || property(predicate)

    if value do
      {:ok, value}
    else
      {:error, %RDF.Query.InvalidError{
        message: "Invalid predicate term in BGP triple pattern: #{inspect predicate}"}
      }
    end
  end

  defp object_pattern(object) do
    value = variable(object) || resource(object) || literal(object)

    if value do
      {:ok, value}
    else
      {:error, %RDF.Query.InvalidError{
        message: "Invalid object term in BGP triple pattern: #{inspect object}"}
      }
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


  @doc """
  Return a list of all variables in a BGP.
  """
  def variables(%__MODULE__{triple_patterns: triple_patterns}), do: variables(triple_patterns)

  def variables(triple_patterns) when is_list(triple_patterns) do
    triple_patterns
    |> Enum.reduce([], fn triple_pattern, vars -> variables(triple_pattern) ++ vars end)
    |> Enum.uniq()
  end

  def variables({s, p, o}) when is_atom(s) and is_atom(p) and is_atom(o), do: [s, p, o]
  def variables({s, p, _}) when is_atom(s) and is_atom(p), do: [s, p]
  def variables({s, _, o}) when is_atom(s) and is_atom(o), do: [s, o]
  def variables({_, p, o}) when is_atom(p) and is_atom(o), do: [p, o]
  def variables({s, _, _}) when is_atom(s), do: [s]
  def variables({_, p, _}) when is_atom(p), do: [p]
  def variables({_, _, o}) when is_atom(o), do: [o]

  def variables(_), do: []
end
