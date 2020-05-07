defmodule RDF.XSD.Float do
  @moduledoc """
  `RDF.XSD.Datatype` for XSD floats.

  Although the XSD spec defines floats as a primitive we derive it here from `XSD.Double`
  with any further constraints, since Erlang doesn't support 32-bit floats.
  """

  use RDF.XSD.Datatype.Restriction,
    name: "float",
    id: RDF.Utils.Bootstrapping.xsd_iri("float"),
    base: RDF.XSD.Double,
    register: false # core datatypes don't need to be registered
end
