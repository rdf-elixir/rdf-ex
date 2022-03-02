defmodule RDF.IRI.UUID.GeneratorTest do
  use RDF.Test.Case

  doctest RDF.IRI.UUID.Generator

  alias RDF.Resource.Generator

  test "without arguments, a URN is generated" do
    assert %IRI{value: "urn:uuid:" <> _} =
             IRI.UUID.Generator.generator_config()
             |> Generator.generate(nil)
  end

  test "setting the prefix function arguments" do
    assert %IRI{value: "http://example.com/ns/" <> _} =
             IRI.UUID.Generator.generator_config(prefix: "http://example.com/ns/")
             |> Generator.generate(nil)

    assert %IRI{} =
             iri1 =
             IRI.UUID.Generator.generator_config(prefix: EX)
             |> Generator.generate(nil)

    assert String.starts_with?(iri1.value, EX.__base_iri__())

    assert %IRI{} =
             iri2 =
             IRI.UUID.Generator.generator_config(prefix: EX)
             |> Generator.generate(nil)

    assert iri1 != iri2
  end

  test "setting UUID params via defaults" do
    for version <- [1, 4], format <- [:default, :hex] do
      assert %IRI{value: "http://example.com/ns/" <> uuid} =
               IRI.UUID.Generator.generator_config(
                 prefix: "http://example.com/ns/",
                 version: version,
                 format: format
               )
               |> Generator.generate(nil)

      uuid_info = UUID.info!(uuid)
      assert Keyword.get(uuid_info, :version) == version
      assert Keyword.get(uuid_info, :type) == format
    end

    for version <- [3, 5],
        format <- [:default, :hex],
        namespace <- [:dns, :url, UUID.uuid4()] do
      assert %IRI{value: "http://example.com/ns/" <> uuid} =
               IRI.UUID.Generator.generator_config(
                 prefix: "http://example.com/ns/",
                 version: version,
                 format: format,
                 namespace: namespace,
                 name: "test"
               )
               |> Generator.generate(nil)

      uuid_info = UUID.info!(uuid)
      assert Keyword.get(uuid_info, :version) == version
      assert Keyword.get(uuid_info, :type) == format
    end
  end

  test "setting UUID params on generate/2" do
    for version <- [1, 4], format <- [:default, :hex] do
      assert %IRI{value: "http://example.com/ns/" <> uuid} =
               IRI.UUID.Generator.generator_config()
               |> Generator.generate(
                 prefix: "http://example.com/ns/",
                 version: version,
                 format: format
               )

      uuid_info = UUID.info!(uuid)
      assert Keyword.get(uuid_info, :version) == version
      assert Keyword.get(uuid_info, :type) == format
    end

    for version <- [3, 5],
        format <- [:default, :hex],
        namespace <- [:dns, :url, UUID.uuid4()] do
      assert %IRI{value: "http://example.com/ns/" <> uuid} =
               IRI.UUID.Generator.generator_config()
               |> Generator.generate(
                 prefix: "http://example.com/ns/",
                 version: version,
                 format: format,
                 namespace: namespace,
                 name: "test"
               )

      uuid_info = UUID.info!(uuid)
      assert Keyword.get(uuid_info, :version) == version
      assert Keyword.get(uuid_info, :type) == format
    end
  end

  test "overwriting default UUID params on generate/2" do
    assert %IRI{value: "http://example.com/ns/" <> uuid} =
             IRI.UUID.Generator.generator_config(
               prefix: "http://example.com/ns/",
               version: 4,
               format: :default
             )
             |> Generator.generate(
               version: 1,
               format: :hex
             )

    uuid_info = UUID.info!(uuid)
    assert Keyword.get(uuid_info, :version) == 1
    assert Keyword.get(uuid_info, :type) == :hex

    assert %IRI{value: "http://example.com/ns/" <> uuid} =
             IRI.UUID.Generator.generator_config(
               prefix: "http://example.com/ns/",
               version: 3,
               format: :hex,
               namespace: :url
             )
             |> Generator.generate(
               version: 5,
               namespace: :dns,
               name: "example.com"
             )

    uuid_info = UUID.info!(uuid)
    assert Keyword.get(uuid_info, :version) == 5
    assert Keyword.get(uuid_info, :type) == :hex
  end
end
