defmodule RDF.TurtleTriG.Encoder.Sequencer do
  @moduledoc false

  alias RDF.{IRI, BlankNode, Description, Graph}

  @rdf_type RDF.Utils.Bootstrapping.rdf_iri("type")

  # Defines rdf:type of subjects to be serialized at the beginning of the encoded graph
  @top_classes [RDF.Utils.Bootstrapping.rdfs_iri("Class")]

  # Defines order of predicates at the beginning of a resource description
  @predicate_order [
    @rdf_type,
    RDF.Utils.Bootstrapping.rdfs_iri("label"),
    IRI.new("http://purl.org/dc/terms/title")
  ]
  @ordered_properties MapSet.new(@predicate_order)

  def descriptions(%Graph{} = graph, base_iri) do
    graph
    |> Graph.descriptions()
    |> descriptions(base_iri)
  end

  def descriptions(descriptions, base_iri) do
    group = Enum.group_by(descriptions, &description_group(&1, base_iri))

    ordered_descriptions =
      (@top_classes
       |> Stream.map(&group[&1])
       |> Stream.reject(&is_nil/1)
       |> Enum.flat_map(&sort_descriptions/1)) ++
        (group |> Map.get(:other, []) |> sort_descriptions())

    case group[:base] do
      [base] -> [base | ordered_descriptions]
      _ -> ordered_descriptions
    end
  end

  defp description_group(%{subject: base_iri}, base_iri), do: :base

  defp description_group(description, _) do
    if types = description.predications[@rdf_type] do
      Enum.find(@top_classes, :other, &Map.has_key?(types, &1))
    else
      :other
    end
  end

  defp sort_descriptions(descriptions), do: Enum.sort(descriptions, &description_order/2)

  defp description_order(%{subject: %IRI{}}, %{subject: %BlankNode{}}), do: true
  defp description_order(%{subject: %BlankNode{}}, %{subject: %IRI{}}), do: false

  defp description_order(%{subject: {s, p, o1}}, %{subject: {s, p, o2}}),
    do: to_string(o1) < to_string(o2)

  defp description_order(%{subject: {s, p1, _}}, %{subject: {s, p2, _}}),
    do: to_string(p1) < to_string(p2)

  defp description_order(%{subject: {s1, _, _}}, %{subject: {s2, _, _}}),
    do: to_string(s1) < to_string(s2)

  defp description_order(%{subject: {_, _, _}}, %{subject: _}), do: false
  defp description_order(%{subject: _}, %{subject: {_, _, _}}), do: true
  defp description_order(%{subject: s1}, %{subject: s2}), do: to_string(s1) < to_string(s2)

  def predications(%Description{predications: predications}) do
    sorted_predications =
      @predicate_order
      |> Enum.map(fn predicate -> {predicate, predications[predicate]} end)
      |> Enum.reject(fn {_, objects} -> is_nil(objects) end)

    unsorted_predications =
      Enum.reject(predications, fn {predicate, _} ->
        MapSet.member?(@ordered_properties, predicate)
      end)

    sorted_predications ++ unsorted_predications
  end
end
