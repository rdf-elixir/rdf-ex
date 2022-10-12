defmodule RDF.QueryPlannerHelper do
  @moduledoc false

  import RDF.Guards

  def better?(left, right) do
    left = simplify_triple(left)
    right = simplify_triple(right)

    less_variables?(left, right) or
      (same_count_of_variables?(left, right) and better_positioning?(left, right)) or
      false
  end

  defp simplify_triple({s, p, o}), do: {simplify_term(s), simplify_term(p), simplify_term(o)}

  defp simplify_term(triple) when is_triple(triple) do
    case variable_count(triple) do
      0 -> 0
      variable_count -> {variable_count}
    end
  end

  defp simplify_term(variable) when is_atom(variable), do: 1
  defp simplify_term(_), do: 0

  defp variable_count({count}), do: count
  defp variable_count(variable) when is_atom(variable), do: 1

  defp variable_count(triple) when is_tuple(triple) do
    triple
    |> Tuple.to_list()
    |> Enum.count(&variable?/1)
  end

  defp variable_count(_), do: 0

  defp variable?(variable) when is_atom(variable), do: true
  defp variable?(%type{}) when type in [RDF.IRI, RDF.Literal, RDF.BlankNode], do: false
  defp variable?(count) when is_integer(count), do: count > 0

  defp less_variables?(left, right) do
    valued_variable_count(left) < valued_variable_count(right)
  end

  defp same_count_of_variables?(left, right) do
    valued_variable_count(left) == valued_variable_count(right)
  end

  defp valued_variable_count(triple) when is_triple(triple) do
    triple
    |> Tuple.to_list()
    |> Enum.map(&valued_variable_count/1)
    |> Enum.sum()
  end

  defp valued_variable_count({3}), do: 1
  defp valued_variable_count({_}), do: 0
  defp valued_variable_count(count), do: count

  defp better_positioning?(left, right) do
    Enum.reduce_while(0..2, nil, fn i, _ ->
      case better_term?(elem(left, i), elem(right, i)) do
        nil -> {:cont, true}
        result -> {:halt, result}
      end
    end)
  end

  defp better_term?(term, term), do: nil
  defp better_term?(1, 0), do: false
  defp better_term?(0, 1), do: true
  defp better_term?({_}, 0), do: false
  defp better_term?({_}, 1), do: true
  defp better_term?(0, {_}), do: true
  defp better_term?(1, {_}), do: false
  defp better_term?({left_count}, {right_count}), do: left_count < right_count

  #############################################################################
  # functions for generating all possible combinations of triple patterns
  # with quoted triples (but NOT nested quoted triples)

  def all_combinations do
    all_tps = all_tps()
    for left <- all_tps, right <- all_tps, do: {left, right}
  end

  defp all_tps do
    elements = [:var, :term, :quoted_triple]

    for s <- elements, p <- elements, o <- elements do
      {s, p, o}
    end
    |> Enum.reject(&match?({_, :quoted_triple, _}, &1))
    |> Enum.map(fn {s, p, o} ->
      {tp_term(s, :subject), tp_term(p, :predicate), tp_term(o, :object)}
    end)
    |> Enum.flat_map(&expand_quoted_triples/1)
  end

  defp expand_quoted_triples({{}, p, o}) do
    quoted_triples("s")
    |> Enum.map(&{&1, p, o})
    |> Enum.flat_map(&expand_quoted_triples(&1))
  end

  defp expand_quoted_triples({s, p, {}}) do
    quoted_triples("o")
    |> Enum.map(&{s, p, &1})
    |> Enum.flat_map(&expand_quoted_triples(&1))
  end

  defp expand_quoted_triples(triple), do: [triple]

  defp quoted_triples(pos) do
    [
      {RDF.iri("urn:QS#{pos}"), RDF.iri("urn:QP#{pos}"), RDF.iri("urn:QO#{pos}")},
      {:"qs_#{pos}?", RDF.iri("urn:QP#{pos}"), RDF.iri("urn:QO#{pos}")},
      {:"qs_#{pos}?", :"qp_#{pos}?", RDF.iri("urn:QO#{pos}")},
      {:"qs_#{pos}?", :"qp_#{pos}?", :"qo_#{pos}?"}
    ]
  end

  defp tp_term(:var, :subject), do: :s?
  defp tp_term(:var, :predicate), do: :p?
  defp tp_term(:var, :object), do: :o?
  defp tp_term(:term, :subject), do: RDF.iri("urn:S")
  defp tp_term(:term, :predicate), do: RDF.iri("urn:P")
  defp tp_term(:term, :object), do: RDF.iri("urn:O")
  defp tp_term(:quoted_triple, _), do: {}
end
