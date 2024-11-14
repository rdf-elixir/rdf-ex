defmodule RDF.Vocabulary.ResourceClassifier do
  @moduledoc false

  alias RDF.{Description, Graph, Dataset}

  import RDF.Utils.Bootstrapping

  @rdf_type rdf_iri("type")

  @doc """
  Determines if the given resource is RDF property by
  """
  def property?(resource, data) do
    with %Description{} = description <- RDF.Data.description(data, resource) do
      property_by_domain?(description) or
        property_by_rdf_type?(Description.get(description, @rdf_type))
    end || property_by_predicate_usage?(resource, data)
  end

  @property_properties (Enum.map(
                          ~w[
                            domain
                            range
                            subPropertyOf
                          ],
                          &rdfs_iri/1
                        ) ++
                          Enum.map(
                            ~w[
                              equivalentProperty
                              inverseOf
                              propertyDisjointWith
                            ],
                            &owl_iri/1
                          ))
                       |> MapSet.new()

  defp property_by_domain?(description) do
    Enum.any?(@property_properties, fn property ->
      description[property]
    end)
  end

  @property_classes [
                      rdf_iri("Property"),
                      rdfs_iri("ContainerMembershipProperty")
                      | Enum.map(
                          ~w[
                            ObjectProperty
                            DatatypeProperty
                            AnnotationProperty
                            FunctionalProperty
                            InverseFunctionalProperty
                            SymmetricProperty
                            AsymmetricProperty
                            ReflexiveProperty
                            IrreflexiveProperty
                            TransitiveProperty
                            DeprecatedProperty
                          ],
                          &owl_iri/1
                        )
                    ]
                    |> MapSet.new()

  @dialyzer {:nowarn_function, property_by_rdf_type?: 1}
  defp property_by_rdf_type?(nil), do: nil

  defp property_by_rdf_type?(types) do
    not (types
         |> MapSet.new()
         |> MapSet.disjoint?(@property_classes))
  end

  defp property_by_predicate_usage?(resource, %Description{predications: predications}) do
    Map.has_key?(predications, resource)
  end

  defp property_by_predicate_usage?(resource, %Graph{descriptions: descriptions}) do
    Enum.any?(descriptions, fn {_, description} ->
      property_by_predicate_usage?(resource, description)
    end)
  end

  defp property_by_predicate_usage?(resource, %Dataset{graphs: graphs}) do
    Enum.any?(graphs, fn {_, graph} ->
      property_by_predicate_usage?(resource, graph)
    end)
  end
end
