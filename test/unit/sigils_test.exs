defmodule RDF.SigilsTest do
  use ExUnit.Case, async: true

  import RDF.Sigils

  doctest RDF.Sigils

  describe "IRI sigil without interpolation" do

    test "it can create a URI struct from a sigil" do
      assert ~I<http://example.com> == RDF.uri("http://example.com")
    end

  end

end
