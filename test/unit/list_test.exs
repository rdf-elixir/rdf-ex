defmodule RDF.ListTest do
  use RDF.Test.Case

  doctest RDF.List

  import RDF.Sigils

  alias RDF.{BlankNode, Literal, Graph}

#  alias RDF.NS.{XSD}

  use RDF.Vocabulary.Namespace

  defvocab EX,
    base_uri: "http://example.org/#",
    terms: [], strict: false

  setup do
    {:ok,
      one: RDF.list!([EX.element], head: ~B<one>),
      abc: RDF.list!(~w[a b c], head: ~B<abc>),
      ten: RDF.list!(Enum.to_list(1..10), head: ~B<ten>),
      nested: RDF.list!(["foo", [1, 2], "bar"], head: ~B<nested>),
    }
  end

  describe "new/1" do
    test "an empty anonymous list" do
      assert RDF.List.new([]) == {RDF.nil, Graph.new}
    end

    test "an empty named list" do
      assert RDF.List.new([], name: ~B<foo>) == {RDF.nil, Graph.new}
    end

    %{
      "URI"        => RDF.uri(EX.Foo),
      "blank node" => ~B<Foo>,
      "literal"    => ~L<Foo>,
      "string"     => "Foo",
      "integer"    => 42,
      "float"      => 3.14,
      "true"       => true,
      "false"      => false,
      "unresolved namespace-qualified name" => EX.Foo,
    }
    |> Enum.each(fn {type, element} ->
        @tag element: element
        test "list with #{type} element", %{element: element} do
          with {bnode, graph_with_list} = one_element_list(element) do
            assert {bnode, graph_with_list} == RDF.List.new([element], head: bnode)
          end
        end
       end)

    test "nested list" do
      assert {bnode, graph_with_list} = RDF.List.new([[1]])
      assert [nested] = get_in(graph_with_list, [bnode, RDF.first])
      assert get_in(graph_with_list, [bnode, RDF.rest]) == [RDF.nil]
      assert get_in(graph_with_list, [nested, RDF.first]) == [RDF.Integer.new(1)]
      assert get_in(graph_with_list, [nested, RDF.rest]) == [RDF.nil]

      assert {bnode, graph_with_list} = RDF.List.new(["foo", [1, 2], "bar"])
      assert get_in(graph_with_list, [bnode, RDF.first]) == [~L"foo"]
      assert [second] = get_in(graph_with_list, [bnode, RDF.rest])
      assert [nested] = get_in(graph_with_list, [second, RDF.first])
      assert get_in(graph_with_list, [nested, RDF.first]) == [RDF.Integer.new(1)]
      assert [nested_second] = get_in(graph_with_list, [nested, RDF.rest])
      assert get_in(graph_with_list, [nested_second, RDF.first]) == [RDF.Integer.new(2)]
      assert get_in(graph_with_list, [nested_second, RDF.rest])  == [RDF.nil]
      assert [third] = get_in(graph_with_list, [second, RDF.rest])
      assert get_in(graph_with_list, [third, RDF.first]) == [~L"bar"]
      assert get_in(graph_with_list, [third, RDF.rest])  == [RDF.nil]
    end

    %{
      "preserve order"  => [3, 2, 1],
      "different types" => [1, "foo", true, false, 3.14, EX.foo, EX.Foo, ~B<Foo>],
    }
    |> Enum.each(fn {desc, list} ->
        @tag list: list
        test "list with multiple elements: #{desc}", %{list: list} do
          assert {bnode, graph_with_list} = RDF.List.new(list)
          assert RDF.nil ==
            Enum.reduce list, bnode, fn element, list_node ->
              case element do
                %URI{} ->
                  assert get_in(graph_with_list, [list_node, RDF.first]) == [element]
                %BlankNode{} ->
                  assert get_in(graph_with_list, [list_node, RDF.first]) == [element]
                %Literal{} ->
                  assert get_in(graph_with_list, [list_node, RDF.first]) == [element]
                element when is_boolean(element) ->
                  assert get_in(graph_with_list, [list_node, RDF.first]) == [RDF.Literal.new(element)]
                element when is_atom(element) ->
                  assert get_in(graph_with_list, [list_node, RDF.first]) == [RDF.uri(element)]
                _ ->
                  assert get_in(graph_with_list, [list_node, RDF.first]) == [RDF.Literal.new(element)]
              end
              [next] = get_in(graph_with_list, [list_node, RDF.rest])
              unless next == RDF.nil do
                assert %BlankNode{} = next
              end
              next
            end
        end
       end)

    test "head option with unresolved namespace-qualified name" do
      assert {uri, _} = RDF.List.new([42], head: EX.Foo)
      assert uri == RDF.uri(EX.Foo)
    end
  end

  describe "to_native/1" do
    test "the empty list" do
      assert RDF.List.to_native(RDF.nil, RDF.Graph.new) == []
    end

    test "list with one element", %{one: one} do
      assert RDF.List.to_native(~B<one>, one) == [EX.element]
    end

    test "list with multiple elements", %{abc: abc, ten: ten} do
      assert RDF.List.to_native(~B<abc>, abc) == ~w[a b c] |> Enum.map(&Literal.new/1)
      assert RDF.List.to_native(~B<ten>, ten) == 1..10 |> Enum.to_list |> Enum.map(&Literal.new/1)
    end

    test "nested list", %{nested: nested} do
      assert RDF.List.to_native(~B<nested>, nested) ==
                [~L"foo", [RDF.Integer.new(1), RDF.Integer.new(2)], ~L"bar"]

      {head, graph} = RDF.list(["foo", [1, 2]])
      assert RDF.List.to_native(head, graph) ==
                [~L"foo", [RDF.Integer.new(1), RDF.Integer.new(2)]]

      {head, graph} = RDF.list([[1, 2], "foo"])
      assert RDF.List.to_native(head, graph) ==
                [[RDF.Integer.new(1), RDF.Integer.new(2)], ~L"foo"]
    end

    test "when given list node doesn't exist in the given graph it returns nil" do
      assert RDF.List.to_native(RDF.bnode, RDF.Graph.new) == nil
    end

    test "When the given list node is not a list it returns nil" do
      assert RDF.List.to_native(42, RDF.Graph.new) == nil
      assert RDF.List.to_native(EX.Foo, RDF.Graph.new({EX.Foo, EX.bar, EX.Baz})) == nil
      assert RDF.List.to_native(EX.Foo, RDF.Graph.new({EX.Foo, RDF.first, EX.Baz})) == nil
    end

    test "When the given list node is not a valid list it returns nil" do
      assert RDF.List.to_native(~B<Foo>,
               Graph.new(
                   ~B<Foo>
                   |> RDF.first(1, 2)
                   |> RDF.rest(RDF.nil))
             ) == nil
      assert RDF.List.to_native(RDF.uri(EX.Foo), RDF.list!([EX.element], head: EX.Foo)) == nil
    end
  end

  describe "node?" do
    test "the empty list" do
      assert RDF.List.node?(RDF.nil, Graph.new) == true
    end

    test "list with one element", %{one: one} do
      assert RDF.List.node?(~B<one>, one) == true
    end

    test "list with multiple elements", %{abc: abc, ten: ten} do
      assert RDF.List.node?(~B<abc>, abc) == true
      assert RDF.List.node?(~B<ten>, ten) == true
    end

    test "nested list", %{nested: nested} do
      assert RDF.List.node?(~B<nested>, nested) == true
    end

    test "unresolved namespace-qualified name" do
      assert RDF.List.node?(EX.Foo, RDF.list!([EX.element], head: EX.Foo)) == true
    end

    test "when given list node doesn't exist in the given graph" do
      assert RDF.List.node?(RDF.bnode, RDF.Graph.new) == false
    end

    test "literal" do
      assert RDF.List.node?(~L"Foo", RDF.Graph.new) == false
      assert RDF.List.node?(42, RDF.Graph.new) == false
      assert RDF.List.node?(true, RDF.Graph.new) == false
      assert RDF.List.node?(false, RDF.Graph.new) == false
      assert RDF.List.node?(nil, RDF.Graph.new) == false
    end

    test "non-list node" do
      assert RDF.List.node?(EX.Foo, RDF.Graph.new({EX.Foo, EX.bar, EX.Baz})) == false
    end

    test "incomplete list nodes" do
      assert RDF.List.node?(EX.Foo, RDF.Graph.new({EX.Foo, RDF.first, EX.Baz})) == false
      assert RDF.List.node?(EX.Foo, RDF.Graph.new({EX.Foo, RDF.rest, RDF.nil})) == false
    end
  end


  describe "valid?/2" do
    test "the empty list" do
      assert RDF.List.valid?(RDF.nil, Graph.new)
    end

    test "valid list with one element", %{one: one} do
      assert RDF.List.valid?(~B<one>, one) == true
    end

    test "valid list with multiple elements", %{abc: abc, ten: ten} do
      assert RDF.List.valid?(~B<abc>, abc) == true
      assert RDF.List.valid?(~B<ten>, ten) == true
    end

    test "valid nested list", %{nested: nested} do
      assert RDF.List.valid?(~B<nested>, nested) == true
    end

    test "a list with other properties on its nodes is valid" do
      assert RDF.List.valid?(~B<Foo>,
               Graph.new(
                   ~B<Foo>
                   |> EX.other(EX.Property)
                   |> RDF.first(1)
                   |> RDF.rest(~B<Bar>))
               |> Graph.add(
                   ~B<Bar>
                   |> EX.other(EX.Property2)
                   |> RDF.first(2)
                   |> RDF.rest(RDF.nil))
             ) == true
    end

    test "incomplete list nodes are invalid" do
      assert RDF.List.valid?(EX.Foo, RDF.Graph.new({EX.Foo, RDF.first, EX.Baz})) == false
      assert RDF.List.valid?(EX.Foo, RDF.Graph.new({EX.Foo, RDF.rest, RDF.nil})) == false
    end

    test "a list with multiple rdf:first object is not valid" do
      assert RDF.List.valid?(~B<Foo>,
               Graph.new(
                   ~B<Foo>
                   |> RDF.first(1, 2)
                   |> RDF.rest(RDF.nil))
             ) == false
    end

    test "a list with multiple rdf:first object on later nodes is not valid" do
      assert RDF.List.valid?(~B<Foo>,
               Graph.new(
                   ~B<Foo>
                   |> RDF.first(1)
                   |> RDF.rest(~B<Bar>))
               |> Graph.add(
                   ~B<Bar>
                   |> RDF.first(2, 3)
                   |> RDF.rest(RDF.nil))
             ) == false
    end

    test "a list with multiple rdf:rest object is not valid" do
      assert RDF.List.valid?(~B<Foo>,
               Graph.new(
                   ~B<Foo>
                   |> RDF.first(1)
                   |> RDF.rest(~B<Bar>, ~B<Baz>))
               |> Graph.add(
                   ~B<Bar>
                   |> RDF.first(2)
                   |> RDF.rest(RDF.nil))
               |> Graph.add(
                   ~B<Baz>
                   |> RDF.first(3)
                   |> RDF.rest(RDF.nil))
             ) == false
      assert RDF.List.valid?(~B<Foo>,
               Graph.new(
                   ~B<Foo>
                   |> RDF.first(1)
                   |> RDF.rest(~B<Bar>))
               |> Graph.add(
                   ~B<Bar>
                   |> RDF.first(2)
                   |> RDF.rest(RDF.nil, ~B<Baz>))
               |> Graph.add(
                   ~B<Baz>
                   |> RDF.first(3)
                   |> RDF.rest(RDF.nil))
             ) == false
    end

    test "a list with circles is not valid" do
      assert RDF.List.valid?(~B<Foo>,
               Graph.new(
                   ~B<Foo>
                   |> RDF.first(1)
                   |> RDF.rest(~B<Bar>))
               |> Graph.add(
                   ~B<Bar>
                   |> RDF.first(2)
                   |> RDF.rest(~B<Foo>))
             ) == false
    end

    test "a non-blank list node is not valid" do
      assert RDF.List.valid?(RDF.uri(EX.Foo), RDF.list!([EX.element], head: EX.Foo)) == false
    end

    test "a non-blank list node on later nodes makes the whole list invalid" do
      assert RDF.List.valid?(~B<Foo>,
               Graph.new(
                   ~B<Foo>
                   |> RDF.first(1)
                   |> RDF.rest(EX.Foo))
               |> Graph.add(
                   EX.Foo
                   |> RDF.first(2)
                   |> RDF.rest(RDF.nil))
             ) == false
    end

    test "when the given list node doesn't exsist in the given graph" do
      assert RDF.List.valid?(RDF.bnode, RDF.Graph.new) == false
      assert RDF.List.valid?(RDF.bnode, RDF.Graph.new) == false
    end
  end


  defp one_element_list(element),
    do: one_element_list(element, RDF.bnode)

  defp one_element_list(element, bnode) do
    {bnode,
      Graph.new(
        bnode
        |> RDF.first(element)
        |> RDF.rest(RDF.nil)
      )
    }
  end

end
