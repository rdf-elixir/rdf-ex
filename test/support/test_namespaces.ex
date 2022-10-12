defmodule RDF.TestNamespaces do
  @moduledoc false

  import RDF.Sigils
  import RDF.Namespace

  alias RDF.PropertyMap

  defnamespace SimpleNS,
               [
                 foo: ~I<http://example.com/foo>,
                 bar: "http://example.com/bar",
                 Baz: ~I<http://example.com/Baz>,
                 Baaz: "http://example.com/Baaz"
               ],
               moduledoc: "Example doc"

  defnamespace NSfromPropertyMap,
               PropertyMap.new(
                 foo: ~I<http://example.com/foo>,
                 bar: "http://example.com/bar"
               )
end
