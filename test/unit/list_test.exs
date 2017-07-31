defmodule RDF.ListTest do
  use RDF.Test.Case

  doctest RDF.List

  import RDF.Sigils

  alias RDF.{BlankNode, Literal, Graph}

  use RDF.Vocabulary.Namespace

  defvocab EX,
    base_uri: "http://example.org/#",
    terms: [], strict: false

  setup do
    {:ok,
      empty:  RDF.List.new(RDF.nil, Graph.new),
      one:    RDF.List.from([EX.element],           head: ~B<one>),
      abc:    RDF.List.from(~w[a b c],              head: ~B<abc>),
      ten:    RDF.List.from(Enum.to_list(1..10),    head: ~B<ten>),
      nested: RDF.List.from(["foo", [1, 2], "bar"], head: ~B<nested>),
    }
  end


  describe "new/2" do

    #######################################################################
    # success cases

    test "valid head list node" do
      graph = Graph.new(
                   ~B<Foo>
                   |> RDF.first(1)
                   |> RDF.rest(~B<Bar>))
               |> Graph.add(
                   ~B<Bar>
                   |> RDF.first(2)
                   |> RDF.rest(RDF.nil))
      assert %RDF.List{} = list = RDF.List.new(~B<Foo>, graph)
      assert list.head == ~B<Foo>
      assert list.graph == graph
    end

    test "with non-blank list nodes" do
      graph = Graph.new(
                   EX.Foo
                   |> RDF.first(1)
                   |> RDF.rest(RDF.nil))
      assert %RDF.List{} = list = RDF.List.new(EX.Foo, graph)
      assert list.head == RDF.uri(EX.Foo)
    end

    test "with other properties on its nodes" do
      assert RDF.List.new(~B<Foo>,
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
             )
             |> RDF.List.valid? == true
    end

    #######################################################################
    # failure cases

    test "when given list node doesn't exist in the given graph" do
      assert RDF.List.new(RDF.bnode, RDF.Graph.new) == nil
    end

    test "When the given head node is not a list" do
      assert RDF.List.new(42, RDF.Graph.new) == nil
      assert RDF.List.new(EX.Foo, RDF.Graph.new({EX.Foo, EX.bar, EX.Baz})) == nil
      assert RDF.List.new(EX.Foo, RDF.Graph.new({EX.Foo, RDF.first, EX.Baz})) == nil
    end


    test "when list nodes are incomplete" do
      assert RDF.List.new(EX.Foo, RDF.Graph.new({EX.Foo, RDF.first, EX.Baz})) == nil
      assert RDF.List.new(EX.Foo, RDF.Graph.new({EX.Foo, RDF.rest, RDF.nil})) == nil
    end

    test "when head node has multiple rdf:first objects" do
      assert RDF.List.new(~B<Foo>,
               Graph.new(
                   ~B<Foo>
                   |> RDF.first(1, 2)
                   |> RDF.rest(RDF.nil))
             ) == nil
    end

    test "when later list nodes have multiple rdf:first objects" do
      assert RDF.List.new(~B<Foo>,
               Graph.new(
                   ~B<Foo>
                   |> RDF.first(1)
                   |> RDF.rest(~B<Bar>))
               |> Graph.add(
                   ~B<Bar>
                   |> RDF.first(2, 3)
                   |> RDF.rest(RDF.nil))
             ) == nil
    end

    test "when list nodes have multiple rdf:rest objects" do
      assert RDF.List.new(~B<Foo>,
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
             ) == nil
      assert RDF.List.new(~B<Foo>,
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
             ) == nil
    end

    test "when the list is cyclic" do
      assert RDF.List.new(~B<Foo>,
               Graph.new(
                   ~B<Foo>
                   |> RDF.first(1)
                   |> RDF.rest(~B<Bar>))
               |> Graph.add(
                   ~B<Bar>
                   |> RDF.first(2)
                   |> RDF.rest(~B<Foo>))
             ) == nil
    end
  end


  describe "from/1" do
    test "an empty list", %{empty: empty} do
      assert RDF.List.from([]) == empty
    end

    test "an empty list with named head node", %{empty: empty} do
      assert RDF.List.from([], name: ~B<foo>) == empty
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
            assert RDF.List.from([element], head: bnode) ==
                    RDF.List.new(bnode, graph_with_list)
          end
        end
       end)

    test "nested list" do
      assert %RDF.List{head: bnode, graph: graph_with_list} =
              RDF.List.from([[1]])
      assert [nested] = get_in(graph_with_list, [bnode, RDF.first])
      assert get_in(graph_with_list, [bnode, RDF.rest]) == [RDF.nil]
      assert get_in(graph_with_list, [nested, RDF.first]) == [RDF.Integer.new(1)]
      assert get_in(graph_with_list, [nested, RDF.rest]) == [RDF.nil]

      assert %RDF.List{head: bnode, graph: graph_with_list} =
              RDF.List.from(["foo", [1, 2], "bar"])
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
          assert %RDF.List{head: bnode, graph: graph_with_list} =
                  RDF.List.from(list)
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

    test "an enumerable" do
      assert RDF.List.from(MapSet.new([42]), head: ~B<foo>) ==
              RDF.List.from([42], head: ~B<foo>)
    end

    test "head option with unresolved namespace-qualified name" do
      assert RDF.List.from([42], head: EX.Foo).head == RDF.uri(EX.Foo)
    end
  end


  describe "values/1" do
    test "the empty list", %{empty: empty} do
      assert RDF.List.values(empty) == []
    end

    test "list with one element", %{one: one} do
      assert RDF.List.values(one) == [EX.element]
    end

    test "list with multiple elements", %{abc: abc, ten: ten} do
      assert RDF.List.values(abc) == ~w[a b c] |> Enum.map(&Literal.new/1)
      assert RDF.List.values(ten) == 1..10 |> Enum.to_list |> Enum.map(&Literal.new/1)
    end

    test "list with non-blank list nodes" do
      assert RDF.List.from([EX.element], head: EX.Foo)
             |> RDF.List.values == [EX.element]
    end

    test "nested list", %{nested: nested} do
      assert RDF.List.values(nested) ==
                [~L"foo", [RDF.Integer.new(1), RDF.Integer.new(2)], ~L"bar"]

      assert RDF.list(["foo", [1, 2]]) |> RDF.List.values ==
                [~L"foo", [RDF.Integer.new(1), RDF.Integer.new(2)]]

      assert RDF.list([[1, 2], "foo"]) |> RDF.List.values ==
                [[RDF.Integer.new(1), RDF.Integer.new(2)], ~L"foo"]

      inner_list = RDF.list([1, 2], head: ~B<inner>)
      assert RDF.list(["foo", ~B<inner>], graph: inner_list.graph)
             |> RDF.List.values == [~L"foo", [RDF.Integer.new(1), RDF.Integer.new(2)]]
    end
  end


  describe "nodes/1" do
    test "the empty list", %{empty: empty} do
      assert RDF.List.nodes(empty) == []
    end

    test "non-empty list", %{one: one} do
      assert RDF.List.nodes(one) == [~B<one>]
    end

    test "nested list", %{nested: nested} do
      assert RDF.list([[1, 2, 3]], head: ~B<outer>)
             |> RDF.List.nodes == [~B<outer>]
      assert [~B<nested>, _, _] = RDF.List.nodes(nested)
    end
  end


  describe "valid?/2" do
    test "the empty list", %{empty: empty} do
      assert RDF.List.valid?(empty)
    end

    test "valid list with one element", %{one: one} do
      assert RDF.List.valid?(one) == true
    end

    test "valid list with multiple elements", %{abc: abc, ten: ten} do
      assert RDF.List.valid?(abc) == true
      assert RDF.List.valid?(ten) == true
    end

    test "valid nested list", %{nested: nested} do
      assert RDF.List.valid?(nested) == true
    end

    test "a non-blank list node is not valid" do
      assert RDF.list([EX.element], head: EX.Foo) |> RDF.List.valid? == false
    end

    test "a non-blank list node on later nodes makes the whole list invalid" do
      assert RDF.List.new(~B<Foo>,
               Graph.new(
                   ~B<Foo>
                   |> RDF.first(1)
                   |> RDF.rest(EX.Foo))
               |> Graph.add(
                   EX.Foo
                   |> RDF.first(2)
                   |> RDF.rest(RDF.nil))
             )
             |> RDF.List.valid? == false
    end
  end


  describe "node?" do
    test "the empty list", %{empty: empty} do
      assert RDF.List.node?(empty.head, empty.graph) == true
    end

    test "list with one element", %{one: one} do
      assert RDF.List.node?(one.head, one.graph) == true
    end

    test "list with multiple elements", %{abc: abc, ten: ten} do
      assert RDF.List.node?(abc.head, abc.graph) == true
      assert RDF.List.node?(ten.head, ten.graph) == true
    end

    test "nested list", %{nested: nested} do
      assert RDF.List.node?(nested.head, nested.graph) == true
    end

    test "unresolved namespace-qualified name" do
      assert RDF.List.node?(EX.Foo,
              RDF.List.from([EX.element], head: EX.Foo).graph) == true
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


  describe "Enumerable.reduce" do
    test "the empty list", %{empty: empty} do
      assert Enum.reduce(empty, [], fn description, acc -> [description | acc] end) == []
    end

    test "a valid list", %{one: one} do
      assert [one.graph[one.head]] ==
        Enum.reduce(one, [], fn description, acc -> [description | acc] end)
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
