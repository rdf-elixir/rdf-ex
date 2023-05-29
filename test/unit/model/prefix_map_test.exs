defmodule RDF.PrefixMapTest do
  use RDF.Test.Case

  doctest RDF.PrefixMap

  alias RDF.PrefixMap

  @ex_ns1 ~I<http://example.com/foo/>
  @ex_ns2 ~I<http://example.com/bar#>
  @ex_ns3 ~I<http://example.com/baz#>
  @ex_ns4 ~I<http://other.com/foo>

  @example1 %PrefixMap{map: %{ex1: @ex_ns1}}

  @example2 %PrefixMap{
    map: %{
      ex1: @ex_ns1,
      ex2: @ex_ns2
    }
  }

  @example3 %PrefixMap{
    map: %{
      ex1: @ex_ns1,
      ex2: @ex_ns2,
      ex3: @ex_ns3
    }
  }

  @example4 %PrefixMap{
    map: %{
      ex1: @ex_ns1,
      ex: RDF.iri(EX.__base_iri__())
    }
  }

  test "new/0" do
    assert PrefixMap.new() == %PrefixMap{}
  end

  describe "new/1" do
    test "with a map" do
      assert PrefixMap.new(%{
               "ex1" => "http://example.com/foo/",
               "ex2" => "http://example.com/bar#"
             }) == @example2
    end

    test "with a keyword map" do
      assert PrefixMap.new(
               ex1: "http://example.com/foo/",
               ex2: "http://example.com/bar#"
             ) == @example2
    end

    test "with another prefix map" do
      assert PrefixMap.new(@example2) == @example2
    end

    test "when the IRI namespace is given as a RDF.Vocabulary.Namespace" do
      assert PrefixMap.new(
               ex1: "http://example.com/foo/",
               ex: EX
             ) == @example4
    end
  end

  describe "add/3" do
    test "when no mapping of the given prefix exists" do
      assert PrefixMap.add(@example1, :ex2, @ex_ns2) == {:ok, @example2}
    end

    test "when the prefix is given as a string" do
      assert PrefixMap.add(@example1, "ex2", @ex_ns2) == {:ok, @example2}
    end

    test "when the empty prefix is given" do
      assert PrefixMap.add(PrefixMap.new(), "", @ex_ns1) ==
               {:ok, %PrefixMap{map: %{"": @ex_ns1}}}
    end

    test "when the IRI namespace is given as a string" do
      assert PrefixMap.add(@example1, :ex2, "http://example.com/bar#") == {:ok, @example2}
    end

    test "when the IRI namespace is given as a RDF.Vocabulary.Namespace" do
      assert PrefixMap.add(@example1, :ex, EX) == {:ok, @example4}
    end

    test "when the IRI namespace is given as a RDF.Vocabulary.Namespace which is not loaded yet" do
      assert {:ok, prefix_map} = PrefixMap.new() |> PrefixMap.add(:rdfs, RDF.NS.RDFS)
      assert PrefixMap.has_prefix?(prefix_map, :rdfs)
    end

    test "when the IRI namespace is given as an atom" do
      assert_raise RDF.Namespace.UndefinedTermError, "foo is not a term on a RDF.Namespace", fn ->
        PrefixMap.add(@example1, :ex, :foo)
      end
    end

    test "when a mapping of the given prefix to the same namespace already exists" do
      assert PrefixMap.add(@example2, :ex2, "http://example.com/bar#") == {:ok, @example2}
    end

    test "when a mapping of the given prefix to a different namespace already exists" do
      assert PrefixMap.add(@example2, :ex2, @ex_ns3) ==
               {:error, "prefix :ex2 is already mapped to another namespace"}
    end
  end

  describe "add!/3" do
    test "when no mapping of the given prefix exists" do
      assert PrefixMap.add!(@example1, :ex2, @ex_ns2) == @example2
    end

    test "when a mapping of the given prefix to a different namespace already exists" do
      assert_raise RuntimeError, "prefix :ex2 is already mapped to another namespace", fn ->
        PrefixMap.add!(@example2, :ex2, @ex_ns3)
      end
    end
  end

  describe "put/3" do
    test "when no mapping of the given prefix exists" do
      assert PrefixMap.put(@example1, :ex2, @ex_ns2) == @example2
    end

    test "when the prefix is given as a string" do
      assert PrefixMap.put(@example1, "ex2", @ex_ns2) == @example2
    end

    test "when the IRI namespace is given as a string" do
      assert PrefixMap.put(@example1, :ex2, "http://example.com/bar#") == @example2
    end

    test "when the IRI namespace is given as a RDF.Vocabulary.Namespace" do
      assert PrefixMap.put(@example1, :ex, EX) == @example4
    end

    test "when the IRI namespace is given as a RDF.Vocabulary.Namespace which is not loaded yet" do
      assert prefix_map = PrefixMap.new() |> PrefixMap.put(:rdfs, RDF.NS.RDFS)
      assert PrefixMap.has_prefix?(prefix_map, :rdfs)
    end

    test "when the IRI namespace is given as an atom" do
      assert_raise RDF.Namespace.UndefinedTermError, "foo is not a term on a RDF.Namespace", fn ->
        PrefixMap.put(@example1, :ex, :foo)
      end
    end

    test "when a mapping of the given prefix to a different namespace already exists" do
      assert PrefixMap.put(@example1, :ex1, "http://example.com/bar#") ==
               PrefixMap.new(ex1: "http://example.com/bar#")
    end
  end

  describe "merge/2" do
    test "when the prefix maps are disjunctive" do
      other_prefix_map = PrefixMap.new(ex3: @ex_ns3)
      assert PrefixMap.merge(@example2, other_prefix_map) == {:ok, @example3}
    end

    test "when the prefix maps share some prefixes, but both map to the same namespace" do
      other_prefix_map = PrefixMap.new(ex3: @ex_ns3)
      assert PrefixMap.merge(@example3, other_prefix_map) == {:ok, @example3}
    end

    test "when the prefix maps share some prefixes and both map to different namespaces" do
      other_prefix_map = PrefixMap.new(ex3: @ex_ns4)

      assert PrefixMap.merge(@example3, other_prefix_map) ==
               {:error, [:ex3]}
    end

    test "when the second prefix map is given as a structure convertible to a prefix map" do
      assert PrefixMap.merge(@example2, %{ex3: @ex_ns3}) == {:ok, @example3}
      assert PrefixMap.merge(@example2, ex3: @ex_ns3) == {:ok, @example3}
    end

    test "when two PrefixMaps are given" do
      prefix_map = PrefixMap.new(ex3: @ex_ns3)
      assert PrefixMap.merge(prefix_map, prefix_map) == {:ok, prefix_map}
    end

    test "when the second argument is not convertible to a prefix map" do
      assert_raise ArgumentError,
                   ~S["not convertible" is not convertible to a RDF.PrefixMap],
                   fn ->
                     PrefixMap.merge(@example2, "not convertible")
                   end
    end
  end

  describe "merge/3" do
    test "with a function resolving conflicts by choosing one of the inputs" do
      other_prefix_map = PrefixMap.new(ex3: @ex_ns4)

      assert PrefixMap.merge(@example3, other_prefix_map, fn _prefix, ns1, _ns2 -> ns1 end) ==
               {:ok, @example3}

      assert PrefixMap.merge(@example1, %{ex1: EX}, fn _prefix, _ns1, ns2 -> ns2 end) ==
               {:ok, PrefixMap.new(ex1: EX)}
    end

    test "with a function which does not resolve by returning nil" do
      other_prefix_map = PrefixMap.new(ex3: @ex_ns4)

      assert PrefixMap.merge(@example3, other_prefix_map, fn _, _, _ -> nil end) ==
               PrefixMap.merge(@example3, other_prefix_map)
    end

    test "with a function just partially resolving handling conflicts" do
      assert PrefixMap.merge(@example3, @example3, fn prefix, ns1, _ ->
               if prefix == :ex2, do: ns1
             end) ==
               {:error, [:ex3, :ex1]}
    end

    test "when the function returns a non-IRI value which is convertible" do
      assert PrefixMap.merge(@example1, @example1, fn _, _, _ -> "http://example.com/" end) ==
               {:ok, PrefixMap.new(ex1: "http://example.com/")}
    end

    test "with :ignore as the conflict resolver" do
      assert PrefixMap.merge(@example3, [ex3: @ex_ns4], :ignore) == {:ok, @example3}
    end

    test "with :overwrite as the conflict resolver" do
      assert PrefixMap.merge(@example3, [ex3: @ex_ns4], :overwrite) ==
               @example3
               |> PrefixMap.delete(:ex3)
               |> PrefixMap.add(:ex3, @ex_ns4)
    end
  end

  describe "merge!/2" do
    test "when the prefix maps can be merged" do
      other_prefix_map = PrefixMap.new(ex3: @ex_ns3)
      assert PrefixMap.merge!(@example2, other_prefix_map) == @example3
    end

    test "when the prefix maps can not be merged" do
      assert_raise RuntimeError, "conflicting prefix mappings: :ex2", fn ->
        PrefixMap.merge!(@example2, ex2: @ex_ns3)
      end
    end
  end

  describe "merge!/3" do
    test "when all conflicts can be resolved" do
      other_prefix_map = PrefixMap.new(ex3: @ex_ns4)

      assert PrefixMap.merge!(@example3, other_prefix_map, fn _prefix, ns1, _ns2 -> ns1 end) ==
               @example3
    end

    test "when not all conflicts can be resolved" do
      assert_raise RuntimeError, "conflicting prefix mappings: :ex1", fn ->
        PrefixMap.merge!(@example2, @example2, fn prefix, ns1, _ -> if prefix == :ex2, do: ns1 end)
      end
    end
  end

  describe "delete/2" do
    test "when a mapping of the given prefix exists" do
      assert PrefixMap.delete(@example2, :ex2) == @example1
    end

    test "when no mapping of the given prefix exists" do
      assert PrefixMap.delete(@example1, :ex2) == @example1
    end

    test "with the prefix is given as a string" do
      assert PrefixMap.delete(@example2, "ex2") == @example1
    end
  end

  describe "drop/2" do
    test "when a mapping of the given prefix exists" do
      assert PrefixMap.drop(@example3, [:ex3, :ex2, :ex]) == @example1
    end

    test "when no mapping of the given prefix exists" do
      assert PrefixMap.drop(@example1, [:ex2]) == @example1
    end

    test "with the prefixes are given as strings" do
      assert PrefixMap.drop(@example3, ["ex3", :ex2]) == @example1
    end
  end

  describe "namespace/2" do
    test "when a mapping of the given prefix exists" do
      assert PrefixMap.namespace(@example2, :ex2) == @ex_ns2
    end

    test "when no mapping of the given prefix exists" do
      assert PrefixMap.namespace(@example1, :ex2) == nil
    end

    test "with the prefix is given as a string" do
      assert PrefixMap.namespace(@example2, "ex2") == @ex_ns2
    end
  end

  describe "prefix/2" do
    test "when a mapping to the given namespace exists" do
      assert PrefixMap.prefix(@example2, @ex_ns2) == :ex2
    end

    test "when no mapping to the given namespace exists" do
      assert PrefixMap.prefix(@example1, @ex_ns2) == nil
    end

    test "with the namespace is given as a string" do
      assert PrefixMap.prefix(@example2, to_string(@ex_ns2)) == :ex2
    end
  end

  describe "has_prefix?/2" do
    test "when a mapping of the given prefix exists" do
      assert PrefixMap.has_prefix?(@example2, :ex2) == true
    end

    test "when no mapping of the given prefix exists" do
      assert PrefixMap.has_prefix?(@example1, :ex2) == false
    end

    test "with the prefix is given as a string" do
      assert PrefixMap.has_prefix?(@example2, "ex2") == true
    end
  end

  test "prefixes/1" do
    assert_order_independent PrefixMap.prefixes(@example2) == ~w[ex1 ex2]a
    assert PrefixMap.prefixes(PrefixMap.new()) == ~w[]a
  end

  test "namespaces/1" do
    assert_order_independent PrefixMap.namespaces(@example2) == [@ex_ns1, @ex_ns2]
    assert PrefixMap.namespaces(PrefixMap.new()) == ~w[]a
  end

  describe "prefixed_name/2" do
    test "when given an RDF.IRI and the used prefix is defined" do
      assert PrefixMap.prefixed_name(@example2, ~I<http://example.com/foo/Test>) ==
               "ex1:Test"

      assert PrefixMap.prefixed_name(@example2, ~I<http://example.com/bar#Test>) ==
               "ex2:Test"
    end

    test "when given a string and the used prefix is defined" do
      assert PrefixMap.prefixed_name(@example2, "http://example.com/foo/Test") ==
               "ex1:Test"

      assert PrefixMap.prefixed_name(@example2, "http://example.com/bar#Test") ==
               "ex2:Test"
    end

    test "when the used prefix is not defined" do
      assert PrefixMap.prefixed_name(@example2, ~I<http://example.com/fo/Test>) == nil
      assert PrefixMap.prefixed_name(@example2, "http://example.com/baz#Test") == nil
    end

    test "when the given IRI is under a sub-path of a defined namespace" do
      assert PrefixMap.prefixed_name(@example2, ~I<http://example.com/foo/bar/Test>) == nil
      assert PrefixMap.prefixed_name(@example2, ~I<http://example.com/foo/bar#Test>) == nil
    end
  end

  describe "prefixed_name_to_iri/2" do
    test "when the used prefix is defined" do
      assert PrefixMap.prefixed_name_to_iri(@example2, "ex1:Test") ==
               ~I<http://example.com/foo/Test>

      assert PrefixMap.prefixed_name_to_iri(@example2, "ex2:Test") ==
               ~I<http://example.com/bar#Test>
    end

    test "when the used prefix is not defined" do
      assert PrefixMap.prefixed_name_to_iri(@example2, "ex3:Test") == nil
    end

    test "when the given string does not have a prefix" do
      assert PrefixMap.prefixed_name_to_iri(@example2, "Test") == nil
    end
  end

  describe "Enumerable protocol" do
    test "Enum.count" do
      # credo:disable-for-next-line Credo.Check.Warning.ExpensiveEmptyEnumCheck
      assert Enum.count(PrefixMap.new()) == 0
      assert Enum.count(@example1) == 1
      assert Enum.count(@example2) == 2
    end

    test "Enum.member?" do
      assert Enum.member?(@example2, {:ex1, @ex_ns1})
      assert Enum.member?(@example2, {:ex2, @ex_ns2})
      refute Enum.member?(@example2, {:ex1, @ex_ns2})
      refute Enum.member?(@example2, {:ex2, @ex_ns3})
    end

    test "Enum.reduce" do
      assert_order_independent Enum.reduce(@example2, [], fn mapping, acc -> [mapping | acc] end) ==
                                 [{:ex2, @ex_ns2}, {:ex1, @ex_ns1}]
    end

    test "Enum.at (for Enumerable.slice/1)" do
      assert Enum.at(@example2, 0) in @example2
    end
  end

  test "inspect/1" do
    assert inspect(@example2) ==
             "RDF.PrefixMap.new(%{:ex1 => ~I<http://example.com/foo/>, :ex2 => ~I<http://example.com/bar#>})"
  end
end
