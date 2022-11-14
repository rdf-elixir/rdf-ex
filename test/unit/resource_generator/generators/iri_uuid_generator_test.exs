defmodule RDF.IRI.UUID.GeneratorTest do
  use RDF.Test.Case

  doctest RDF.IRI.UUID.Generator

  alias RDF.Resource.Generator
  alias RDF.Resource.Generator.ConfigError

  describe "generate/0" do
    test "valid general config" do
      for version <- [1, 4], format <- [:default, :hex] do
        assert %IRI{value: "http://example.com/ns/" <> uuid} =
                 generator_config(
                   prefix: "http://example.com/ns/",
                   uuid_version: version,
                   uuid_format: format
                 )
                 |> Generator.generate()

        uuid_info = UUID.info!(uuid)
        assert Keyword.get(uuid_info, :version) == version
        assert Keyword.get(uuid_info, :type) == format
      end
    end

    test "valid random_based-specific config" do
      assert %IRI{value: uuid} =
               generator_config(
                 uuid_version: 1,
                 random_based: [uuid_version: 4]
               )
               |> Generator.generate()

      assert uuid |> UUID.info!() |> Keyword.get(:version) == 4
      assert uuid |> UUID.info!() |> Keyword.get(:type) == :urn

      assert %IRI{value: "http://example.com/ns/" <> uuid} =
               generator_config(
                 prefix: "http://example.com/ns/",
                 random_based: [
                   uuid_version: 1,
                   uuid_format: :hex
                 ]
               )
               |> Generator.generate()

      assert uuid |> UUID.info!() |> Keyword.get(:version) == 1
      assert uuid |> UUID.info!() |> Keyword.get(:type) == :hex

      assert %IRI{value: "http://example.com/ns/" <> uuid} =
               generator_config(
                 uuid_version: 1,
                 random_based: [
                   prefix: "http://example.com/ns/"
                 ]
               )
               |> Generator.generate()

      assert uuid |> UUID.info!() |> Keyword.get(:version) == 1
      assert uuid |> UUID.info!() |> Keyword.get(:type) == :default
    end

    test "setting the prefix as a vocabulary namespace" do
      assert %IRI{} = iri = generator_config(prefix: EX) |> Generator.generate()
      assert String.starts_with?(iri.value, EX.__base_iri__())
      assert %IRI{} = iri = generator_config(random_based: [prefix: EX]) |> Generator.generate()
      assert String.starts_with?(iri.value, EX.__base_iri__())
    end

    test "defaults" do
      assert %IRI{value: "urn:uuid:" <> _} = generator_config() |> Generator.generate()

      assert %IRI{value: uuid} = generator_config(uuid_version: 1) |> Generator.generate()

      assert uuid |> UUID.info!() |> Keyword.get(:version) == 1
      assert uuid |> UUID.info!() |> Keyword.get(:type) == :urn

      assert %IRI{value: "http://example.com/ns/" <> uuid} =
               generator_config(prefix: "http://example.com/ns/")
               |> Generator.generate()

      assert uuid |> UUID.info!() |> Keyword.get(:version) == 4
      assert uuid |> UUID.info!() |> Keyword.get(:type) == :default
    end

    test "uuid_namespace is ignored" do
      assert %IRI{value: "http://example.com/ns/" <> uuid} =
               generator_config(
                 prefix: "http://example.com/ns/",
                 uuid_version: 1,
                 uuid_namespace: :url
               )
               |> Generator.generate()

      assert uuid |> UUID.info!() |> Keyword.get(:version) == 1
    end

    test "invalid config" do
      # improper UUID version
      assert_raise ConfigError, fn ->
        generator_config(uuid_version: 5) |> Generator.generate()
      end

      assert_raise ConfigError, fn ->
        generator_config(random_based: [uuid_version: 5]) |> Generator.generate()
      end

      # non-URN format without prefix
      assert_raise ConfigError, fn ->
        generator_config(uuid_format: :default) |> Generator.generate()
      end

      assert_raise ConfigError, fn ->
        generator_config(random_based: [uuid_format: :default]) |> Generator.generate()
      end
    end
  end

  describe "generate/1" do
    test "valid general config" do
      for version <- [3, 5],
          format <- [:default, :hex],
          namespace <- [:dns, :url, UUID.uuid4()] do
        assert %IRI{value: "http://example.com/ns/" <> uuid} =
                 generator_config(
                   prefix: "http://example.com/ns/",
                   uuid_version: version,
                   uuid_format: format,
                   uuid_namespace: namespace
                 )
                 |> Generator.generate("test")

        uuid_info = UUID.info!(uuid)
        assert Keyword.get(uuid_info, :version) == version
        assert Keyword.get(uuid_info, :type) == format
      end
    end

    test "valid value_based-specific config" do
      assert %IRI{value: uuid} =
               generator_config(
                 uuid_version: 5,
                 uuid_namespace: :dns,
                 value_based: [uuid_version: 3]
               )
               |> Generator.generate("test")

      assert uuid |> UUID.info!() |> Keyword.get(:version) == 3
      assert uuid |> UUID.info!() |> Keyword.get(:type) == :urn

      assert %IRI{value: "http://example.com/ns/" <> uuid} =
               generator_config(
                 prefix: "http://example.com/ns/",
                 uuid_namespace: :dns,
                 value_based: [
                   uuid_version: 5,
                   uuid_format: :hex
                 ]
               )
               |> Generator.generate("test")

      assert uuid |> UUID.info!() |> Keyword.get(:version) == 5
      assert uuid |> UUID.info!() |> Keyword.get(:type) == :hex

      assert %IRI{value: "http://example.com/ns/" <> uuid} =
               generator_config(
                 uuid_version: 5,
                 value_based: [
                   prefix: "http://example.com/ns/",
                   uuid_namespace: :dns
                 ]
               )
               |> Generator.generate("test")

      assert uuid |> UUID.info!() |> Keyword.get(:version) == 5
      assert uuid |> UUID.info!() |> Keyword.get(:type) == :default
    end

    test "setting the prefix as a vocabulary namespace" do
      assert %IRI{} =
               iri =
               generator_config(prefix: EX, uuid_namespace: :dns) |> Generator.generate("test")

      assert String.starts_with?(iri.value, EX.__base_iri__())
    end

    test "defaults" do
      assert %IRI{value: "urn:uuid:" <> _} =
               generator_config(uuid_namespace: :dns) |> Generator.generate("test")

      assert %IRI{value: uuid} =
               generator_config(uuid_version: 3, uuid_namespace: :dns)
               |> Generator.generate("test")

      assert uuid |> UUID.info!() |> Keyword.get(:version) == 3
      assert uuid |> UUID.info!() |> Keyword.get(:type) == :urn

      assert %IRI{value: "http://example.com/ns/" <> uuid} =
               generator_config(prefix: "http://example.com/ns/", uuid_namespace: :dns)
               |> Generator.generate("test")

      assert uuid |> UUID.info!() |> Keyword.get(:version) == 5
      assert uuid |> UUID.info!() |> Keyword.get(:type) == :default
    end

    test "invalid config" do
      # missing UUID namespace
      assert_raise ConfigError, fn ->
        generator_config(uuid_version: 5) |> Generator.generate("test")
      end

      assert_raise ConfigError, fn ->
        generator_config(value_based: [uuid_version: 5]) |> Generator.generate("test")
      end

      assert_raise ConfigError, fn ->
        generator_config() |> Generator.generate("test")
      end

      # improper UUID version
      assert_raise ConfigError, fn ->
        generator_config(uuid_version: 1) |> Generator.generate("test")
      end

      assert_raise ConfigError, fn ->
        generator_config(value_based: [uuid_version: 1]) |> Generator.generate("test")
      end

      # non-URN format without prefix
      assert_raise ConfigError, fn ->
        generator_config(uuid_format: :default) |> Generator.generate("test")
      end

      assert_raise ConfigError, fn ->
        generator_config(value_based: [uuid_format: :default]) |> Generator.generate("test")
      end
    end
  end

  defp generator_config(config \\ []) do
    Keyword.put(config, :generator, RDF.IRI.UUID.Generator)
  end
end
