defmodule RDF.Utils.ResourceClassifier do

  alias RDF.Description

  @rdf_type RDF.uri("http://www.w3.org/1999/02/22-rdf-syntax-ns#type")

  @doc """
  Determines if the given resource is RDF property by
  """
  def property?(resource, data) do
    with %Description{} = description <- RDF.Data.description(data, resource) do
      property_by_domain?(description) or
       property_by_rdf_type?(Description.get(description, @rdf_type))
    end
#    || property_by_predicate_usage?(resource, data)
  end


  @property_properties ~w[
      http://www.w3.org/2000/01/rdf-schema#domain
      http://www.w3.org/2000/01/rdf-schema#range
      http://www.w3.org/2000/01/rdf-schema#subPropertyOf
      http://www.w3.org/2002/07/owl#equivalentProperty
      http://www.w3.org/2002/07/owl#inverseOf
      http://www.w3.org/2002/07/owl#propertyDisjointWith
    ]
    |> Enum.map(&RDF.uri/1)
    |> MapSet.new

  defp property_by_domain?(description) do
    Enum.any? @property_properties, fn property ->
      description[property]
    end
  end


  @property_classes ~w[
      http://www.w3.org/1999/02/22-rdf-syntax-ns#Property
      http://www.w3.org/2000/01/rdf-schema#ContainerMembershipProperty
      http://www.w3.org/2002/07/owl#ObjectProperty
      http://www.w3.org/2002/07/owl#DatatypeProperty
      http://www.w3.org/2002/07/owl#AnnotationProperty
      http://www.w3.org/2002/07/owl#FunctionalProperty
      http://www.w3.org/2002/07/owl#InverseFunctionalProperty
      http://www.w3.org/2002/07/owl#SymmetricProperty
      http://www.w3.org/2002/07/owl#AsymmetricProperty
      http://www.w3.org/2002/07/owl#ReflexiveProperty
      http://www.w3.org/2002/07/owl#IrreflexiveProperty
      http://www.w3.org/2002/07/owl#TransitiveProperty
      http://www.w3.org/2002/07/owl#DeprecatedProperty
    ]
    |> Enum.map(&RDF.uri/1)
    |> MapSet.new

  defp property_by_rdf_type?(nil), do: nil
  defp property_by_rdf_type?(types) do
     not (
       types
       |> MapSet.new
       |> MapSet.disjoint?(@property_classes)
     )
  end


#  defp property_by_predicate_usage?(resource, data) do
#    resource in Graph.predicates(data) || nil
#  end

end
