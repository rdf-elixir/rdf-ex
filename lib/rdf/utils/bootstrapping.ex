defmodule RDF.Utils.Bootstrapping do
  @moduledoc !"""
             This module holds functions to circumvent circular dependency problems.
             """

  @xsd_base_iri "http://www.w3.org/2001/XMLSchema#"
  @rdf_base_iri "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  @rdfs_base_iri "http://www.w3.org/2000/01/rdf-schema#"
  @owl_base_iri "http://www.w3.org/2002/07/owl#"

  def xsd_iri_base(), do: RDF.IRI.new(@xsd_base_iri)
  def rdf_iri_base(), do: RDF.IRI.new(@rdf_base_iri)
  def rdfs_iri_base(), do: RDF.IRI.new(@rdfs_base_iri)
  def owl_iri_base(), do: RDF.IRI.new(@owl_base_iri)

  def xsd_iri(term), do: RDF.IRI.new(@xsd_base_iri <> term)
  def rdf_iri(term), do: RDF.IRI.new(@rdf_base_iri <> term)
  def rdfs_iri(term), do: RDF.IRI.new(@rdfs_base_iri <> term)
  def owl_iri(term), do: RDF.IRI.new(@owl_base_iri <> term)
end
