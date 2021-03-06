defmodule RDF.PropertyMapTest do
  use RDF.Test.Case

  doctest RDF.PropertyMap

  alias RDF.PropertyMap

  defmodule TestNS do
    use RDF.Vocabulary.Namespace

    defvocab ExampleWithConflict,
      base_iri: "http://example.com/",
      terms: ~w[term],
      alias: [alias_term: "term"]
  end

  @example_property_map %PropertyMap{
    iris: %{
      foo: ~I<http://example.com/test/foo>,
      bar: ~I<http://example.com/test/bar>,
      Baz: RDF.iri(EX.Baz)
    },
    terms: %{
      ~I<http://example.com/test/foo> => :foo,
      ~I<http://example.com/test/bar> => :bar,
      RDF.iri(EX.Baz) => :Baz
    }
  }

  test "new/1" do
    assert PropertyMap.new(
             foo: ~I<http://example.com/test/foo>,
             bar: "http://example.com/test/bar",
             Baz: EX.Baz
           ) == @example_property_map
  end

  describe "iri/2" do
    test "when the given term exists" do
      assert PropertyMap.iri(@example_property_map, "foo") ==
               ~I<http://example.com/test/foo>

      assert PropertyMap.iri(@example_property_map, :foo) ==
               ~I<http://example.com/test/foo>
    end

    test "when the given term not exists" do
      assert PropertyMap.iri(PropertyMap.new(), "foo") == nil
      assert PropertyMap.iri(PropertyMap.new(), :foo) == nil
    end
  end

  describe "term/2" do
    test "when the given IRI exists" do
      assert PropertyMap.term(@example_property_map, ~I<http://example.com/test/foo>) ==
               :foo

      assert PropertyMap.term(@example_property_map, "http://example.com/test/foo") ==
               :foo
    end

    test "when the given IRI not exists" do
      assert PropertyMap.term(PropertyMap.new(), "http://example.com/test/foo") ==
               nil

      assert PropertyMap.term(PropertyMap.new(), ~I<http://example.com/test/foo>) ==
               nil
    end
  end

  describe "iri_defined?/2" do
    test "when the given term exists" do
      assert PropertyMap.iri_defined?(@example_property_map, "foo") == true
      assert PropertyMap.iri_defined?(@example_property_map, :foo) == true
    end

    test "when the given term not exists" do
      assert PropertyMap.iri_defined?(PropertyMap.new(), "foo") == false
      assert PropertyMap.iri_defined?(PropertyMap.new(), :foo) == false
    end
  end

  describe "term_defined?/2" do
    test "when the given IRI exists" do
      assert PropertyMap.term_defined?(@example_property_map, ~I<http://example.com/test/foo>) ==
               true

      assert PropertyMap.term_defined?(@example_property_map, "http://example.com/test/foo") ==
               true
    end

    test "when the given IRI not exists" do
      assert PropertyMap.term_defined?(PropertyMap.new(), "http://example.com/test/foo") == false

      assert PropertyMap.term_defined?(PropertyMap.new(), ~I<http://example.com/test/foo>) ==
               false
    end
  end

  describe "add/2" do
    test "with valid mappings as keyword options" do
      assert PropertyMap.add(PropertyMap.new(),
               foo: ~I<http://example.com/test/foo>,
               bar: "http://example.com/test/bar",
               Baz: EX.Baz
             ) == {:ok, @example_property_map}
    end

    test "with valid mappings as a map" do
      assert PropertyMap.add(PropertyMap.new(), %{
               :foo => ~I<http://example.com/test/foo>,
               "bar" => "http://example.com/test/bar",
               "Baz" => EX.Baz
             }) == {:ok, @example_property_map}
    end

    test "with a disjunctive PropertyMap" do
      assert {:ok, property_map} =
               PropertyMap.new()
               |> PropertyMap.add(PropertyMap.new(foo: ~I<http://example.com/test/foo>))

      assert PropertyMap.add(
               property_map,
               PropertyMap.new(%{
                 bar: "http://example.com/test/bar",
                 Baz: EX.Baz
               })
             ) == {:ok, @example_property_map}
    end

    test "with a conflicting PropertyMap" do
      assert {:error, _} =
               PropertyMap.add(@example_property_map, PropertyMap.new(foo: EX.other()))

      assert {:error, _} =
               PropertyMap.add(
                 @example_property_map,
                 PropertyMap.new(other: ~I<http://example.com/test/foo>)
               )
    end

    test "with a strict vocabulary namespace" do
      assert PropertyMap.add(PropertyMap.new(), RDF.NS.RDF) ==
               {:ok,
                PropertyMap.new(
                  type: RDF.type(),
                  first: RDF.first(),
                  langString: RDF.langString(),
                  nil: RDF.nil(),
                  object: RDF.object(),
                  predicate: RDF.predicate(),
                  rest: RDF.rest(),
                  subject: RDF.subject(),
                  value: RDF.value()
                )}
    end

    test "with a vocabulary namespace with multiple terms for the same IRI" do
      assert PropertyMap.add(PropertyMap.new(), TestNS.ExampleWithConflict) ==
               {:ok, PropertyMap.new(alias_term: "http://example.com/term")}
    end

    test "with a non-strict vocabulary namespace" do
      assert_raise ArgumentError, ~r/non-strict/, fn ->
        PropertyMap.add(PropertyMap.new(), EX)
      end
    end

    test "when a mapping to the same IRI exists" do
      assert PropertyMap.add(@example_property_map,
               foo: ~I<http://example.com/test/foo>,
               bar: "http://example.com/test/bar",
               Baz: EX.Baz
             ) == {:ok, @example_property_map}
    end

    test "when a mapping to another IRI exists" do
      assert PropertyMap.add(@example_property_map, foo: ~I<http://example.com/test/other>) ==
               {:error,
                "conflicting mapping for foo: http://example.com/test/other; already mapped to http://example.com/test/foo"}
    end

    test "when another term mapping to the IRI exists" do
      assert PropertyMap.add(@example_property_map, other: ~I<http://example.com/test/foo>) ==
               {:error,
                "conflicting mapping for other: http://example.com/test/foo; IRI already mapped to :foo"}
    end
  end

  describe "put/2" do
    test "with valid mappings as keyword options" do
      assert PropertyMap.put(PropertyMap.new(),
               foo: ~I<http://example.com/test/foo>,
               bar: "http://example.com/test/bar",
               Baz: EX.Baz
             ) == @example_property_map
    end

    test "with valid mappings as a map" do
      assert PropertyMap.put(PropertyMap.new(), %{
               :foo => ~I<http://example.com/test/foo>,
               "bar" => "http://example.com/test/bar",
               "Baz" => EX.Baz
             }) == @example_property_map
    end

    test "with a disjunctive PropertyMap" do
      assert PropertyMap.new()
             |> PropertyMap.put(PropertyMap.new(foo: ~I<http://example.com/test/foo>))
             |> PropertyMap.put(
               PropertyMap.new(%{
                 bar: "http://example.com/test/bar",
                 Baz: EX.Baz
               })
             ) == @example_property_map
    end

    test "with a conflicting PropertyMap" do
      assert @example_property_map
             |> PropertyMap.put(PropertyMap.new(foo: EX.other()))
             |> PropertyMap.put(PropertyMap.new(other: ~I<http://example.com/test/bar>)) ==
               PropertyMap.new(
                 foo: EX.other(),
                 other: ~I<http://example.com/test/bar>,
                 Baz: RDF.iri(EX.Baz)
               )
    end

    test "when mapping exists" do
      assert PropertyMap.put(@example_property_map,
               bar: "http://example.com/test/bar",
               Baz: EX.qux(),
               quux: EX.quux()
             ) ==
               PropertyMap.new(
                 foo: ~I<http://example.com/test/foo>,
                 bar: ~I<http://example.com/test/bar>,
                 Baz: EX.qux(),
                 quux: EX.quux()
               )
    end

    test "when another term mapping to the IRI exists" do
      {:ok, expected_result} =
        @example_property_map
        |> PropertyMap.delete(:foo)
        |> PropertyMap.add(other: ~I<http://example.com/test/foo>)

      assert PropertyMap.put(@example_property_map, other: ~I<http://example.com/test/foo>) ==
               expected_result
    end
  end

  describe "delete/2" do
    test "when a mapping for the given term exists" do
      assert @example_property_map
             |> PropertyMap.delete("foo")
             |> PropertyMap.delete(:bar) == PropertyMap.new(Baz: EX.Baz)
    end

    test "when a mapping for the given term not exists" do
      assert @example_property_map
             |> PropertyMap.delete("foobar")
             |> PropertyMap.delete(:barfoo) == @example_property_map
    end
  end

  test "drop/2" do
    assert PropertyMap.drop(@example_property_map, ["foo", :bar, :other]) ==
             PropertyMap.new(Baz: EX.Baz)
  end

  describe "Access behaviour" do
    test "fetch/2" do
      assert @example_property_map[:foo] == ~I<http://example.com/test/foo>
      assert @example_property_map["foo"] == ~I<http://example.com/test/foo>
      assert @example_property_map[:missing] == nil
      assert @example_property_map["missing"] == nil
    end

    test "get_and_update/2" do
      update = fn current_value -> {current_value, to_string(current_value) <> "bar"} end

      assert Access.get_and_update(@example_property_map, :foo, &{&1, IRI.append(&1, "bar")}) ==
               {~I<http://example.com/test/foo>,
                PropertyMap.put(@example_property_map, foo: ~I<http://example.com/test/foobar>)}

      assert Access.get_and_update(@example_property_map, :foo, update) ==
               {~I<http://example.com/test/foo>,
                PropertyMap.put(@example_property_map, :foo, ~I<http://example.com/test/foobar>)}

      assert Access.get_and_update(@example_property_map, :foo, fn _ -> :pop end) ==
               {~I<http://example.com/test/foo>, PropertyMap.delete(@example_property_map, :foo)}
    end
  end

  describe "Enumerable protocol" do
    test "Enum.count" do
      assert Enum.count(PropertyMap.new()) == 0
      assert Enum.count(@example_property_map) == 3
    end

    test "Enum.member?" do
      assert Enum.member?(@example_property_map, {:foo, ~I<http://example.com/test/foo>})
      assert Enum.member?(@example_property_map, {:bar, ~I<http://example.com/test/bar>})
      assert Enum.member?(@example_property_map, {:Baz, RDF.iri(EX.Baz)})
      refute Enum.member?(@example_property_map, {:bar, ~I<http://example.com/test/foo>})
    end

    test "Enum.reduce" do
      assert Enum.reduce(@example_property_map, [], fn mapping, acc -> [mapping | acc] end) ==
               [
                 {:foo, ~I<http://example.com/test/foo>},
                 {:bar, ~I<http://example.com/test/bar>},
                 {:Baz, RDF.iri(EX.Baz)}
               ]
    end

    test "Enum.at (for Enumerable.slice/1)" do
      assert Enum.at(@example_property_map, 0) == {:Baz, RDF.iri(EX.Baz)}
    end
  end
end
