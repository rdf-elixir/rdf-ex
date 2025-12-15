defmodule RDF.Data do
  @moduledoc """
  Functions for working with RDF data structures.

  This module provides a rich API for RDF data structures built on top of
  the minimal `RDF.Data.Source` protocol, similar to how Elixir's `Enum`
  module builds on the `Enumerable` protocol.
  """

  import RDF.Guards

  alias RDF.Data.Source

  @doc """
  Reduces the RDF data structure using the given function.

  Similar to `Enum.reduce/3`, applies `fun` to each statement in the data structure
  to produce a single result. This is the user-facing function that hides the
  complexity of the protocol's tagged tuple system.

  ## Examples

      iex> graph = RDF.graph([{EX.S1, EX.p, EX.O1}, {EX.S2, EX.p, EX.O2}])
      iex> RDF.Data.reduce(graph, 0, fn {_s, _p, _o}, acc -> acc + 1 end)
      2
  """
  @spec reduce(Source.t(), acc, (RDF.Statement.t(), acc -> acc)) :: acc when acc: term()
  def reduce(data, acc, fun) when is_function(fun, 2) do
    case Source.reduce(data, {:cont, acc}, &{:cont, fun.(&1, &2)}) do
      {:done, result} -> result
      {:halted, result} -> result
    end
  end

  @doc """
  Reduces the RDF data structure using the given function without an initial accumulator.

  The first statement becomes the initial accumulator.

  Raises `Enum.EmptyError` if the data structure is empty.
  """
  @spec reduce(Source.t(), (RDF.Statement.t(), acc -> acc)) :: acc when acc: term()
  def reduce(data, fun) when is_function(fun, 2) do
    case Source.reduce(data, {:cont, :first}, fn
           stmt, :first -> {:cont, stmt}
           stmt, acc -> {:cont, fun.(stmt, acc)}
         end) do
      {:done, :first} -> raise Enum.EmptyError
      {:done, result} -> result
      {:halted, result} -> result
    end
  end

  @doc """
  Reduces the RDF data structure using the given function with early termination support.

  Similar to `Enum.reduce_while/3`, applies `fun` to each statement in the data structure
  with the ability to halt iteration early. The function must return:

  - `{:cont, acc}` to continue iteration with the new accumulator
  - `{:halt, acc}` to stop iteration and return the accumulator

  ## Examples

      iex> graph = RDF.graph([{EX.S1, EX.p, EX.O1}, {EX.S2, EX.p, EX.O2}, {EX.S3, EX.p, EX.O3}])
      iex> RDF.Data.reduce_while(graph, 0, fn _stmt, acc -> {:cont, acc + 1} end)
      3

      iex> graph = RDF.graph([{EX.S1, EX.p, EX.O1}, {EX.target, EX.p, EX.O2}])
      iex> RDF.Data.reduce_while(graph, nil, fn {s, _p, _o}, _acc ->
      ...>   if s == ~I<http://example.com/target> do
      ...>     {:halt, s}
      ...>   else
      ...>     {:cont, nil}
      ...>   end
      ...> end)
      ~I<http://example.com/target>
  """
  @spec reduce_while(
          Source.t(),
          acc,
          (RDF.Statement.t(), acc -> {:cont, acc} | {:halt, acc})
        ) :: acc
        when acc: term()
  def reduce_while(data, acc, fun) when is_function(fun, 2) do
    case Source.reduce(data, {:cont, acc}, fun) do
      {:done, result} -> result
      {:halted, result} -> result
    end
  end

  @doc """
  Invokes the given function for each statement in the data structure.

  The function is invoked with each statement as its only argument and
   always returns `:ok`. It is useful for executing side effects on the data.

  ## Examples

      RDF.Data.each(graph, &IO.inspect/1)
      # prints each statement
      # => :ok
  """
  @spec each(Source.t(), (RDF.Statement.t() -> any())) :: :ok
  def each(data, fun) when is_function(fun, 1) do
    reduce(data, nil, fn stmt, _ ->
      fun.(stmt)
      nil
    end)

    :ok
  end

  @doc """
  Maps a transformation function over all statements in the data structure.

  The given `fun` function can return:
    
  - a statement tuple (triple or quad) - included in the result
  - a list of statements - flattened and included in the result
  - `nil` - excluded from the result

  ## Structural promotion

  The result structure type depends on the mapped statements:

  - stays the same type when all mapped statements fit the original structure
  - promotes to a graph structure when statements have different subjects
  - promotes to a dataset structure when statements have different graph names

  ## Examples

      iex> RDF.Data.map(EX.S |> EX.p(EX.O), fn {s, p, _o} -> {s, p, EX.New} end)
      EX.S |> EX.p(EX.New)

      iex> RDF.Data.map(RDF.graph({EX.S, EX.p, EX.O}), fn {s, p, _o} -> {s, p, EX.New} end)
      RDF.graph({EX.S, EX.p, EX.New})

  Description upgrades to graph when mapped statements have different subjects:

      iex> desc = EX.S |> EX.p(EX.O1) |> EX.p(EX.O2)
      iex> RDF.Data.map(desc, fn {_s, p, o} -> {o, p, EX.S} end)
      RDF.graph([{EX.O1, EX.p, EX.S}, {EX.O2, EX.p, EX.S}])

  Graph upgrades to dataset when mapped statements have different graph names:

      iex> graph = RDF.graph([{EX.S, EX.p, EX.O1}, {EX.S, EX.p, EX.O2}])
      iex> RDF.Data.map(graph, fn {s, p, o} -> {s, p, o, o} end)
      RDF.dataset([{EX.S, EX.p, EX.O1, EX.O1}, {EX.S, EX.p, EX.O2, EX.O2}])
  """
  @spec map(Source.t(), (RDF.Statement.t() -> RDF.Statement.t() | [RDF.Statement.t()] | nil)) ::
          Source.t()
  @unset_graph_name :__unset__
  def map(data, fun) when is_function(fun, 1) do
    structure_type = Source.structure_type(data)

    {new_structure_type, result, graph_name, subject} =
      reduce(data, {structure_type, [], @unset_graph_name, nil}, &map_acc(&2, fun.(&1)))

    build_mapped_structure(new_structure_type, structure_type, data, result, graph_name, subject)
  end

  @doc """
  Transforms statements and accumulates a value in a single pass.

  Combines the functionality of `map/2` with an accumulator, similar to
  `Enum.map_reduce/3`. For each statement, the function receives the statement
  and the current accumulator, and returns a tuple with the mapped result and
  the new accumulator.

  The mapped result can be:

  - a statement (triple or quad) - replaces the original statement
  - `nil` - filters out the statement
  - a list of statements - expands to multiple statements

  Like `map/2`, structural promotion occurs based on the mapped results.

  ## Examples

      iex> graph = RDF.graph([{EX.S1, EX.p1, EX.O1}, {EX.S2, EX.p2, EX.O2}])
      iex> RDF.Data.map_reduce(graph, 0, fn {s, p, _o}, count ->
      ...>   {{s, p, EX.New}, count + 1}
      ...> end)
      {RDF.graph([{EX.S1, EX.p1, EX.New}, {EX.S2, EX.p2, EX.New}]), 2}
  """
  @spec map_reduce(Source.t(), acc, (RDF.Statement.t(), acc -> {mapped, acc})) ::
          {Source.t(), acc}
        when acc: term(), mapped: RDF.Statement.t() | [RDF.Statement.t()] | nil
  def map_reduce(data, acc, fun) when is_function(fun, 2) do
    type = Source.structure_type(data)

    {{new_type, result, graph_name, subject}, final_acc} =
      reduce(data, {{type, [], @unset_graph_name, nil}, acc}, fn
        stmt, {internal_acc, user_acc} ->
          {mapped, new_user_acc} = fun.(stmt, user_acc)
          {map_acc(internal_acc, mapped), new_user_acc}
      end)

    {build_mapped_structure(new_type, type, data, result, graph_name, subject), final_acc}
  end

  defp map_acc(acc, nil), do: acc

  defp map_acc(acc, result) when is_list(result), do: Enum.reduce(result, acc, &map_acc(&2, &1))

  defp map_acc({:dataset, stmts, _, _}, mapped), do: {:dataset, [mapped | stmts], nil, nil}

  defp map_acc({:graph, stmts, @unset_graph_name, _}, {_, _, _} = mapped),
    do: {:graph, [mapped | stmts], @unset_graph_name, nil}

  defp map_acc({:graph, stmts, @unset_graph_name, _}, {_, _, _, g} = mapped),
    do: {:graph, [mapped | stmts], g, nil}

  defp map_acc({:graph, stmts, nil, _}, {_, _, _} = mapped),
    do: {:graph, [mapped | stmts], nil, nil}

  defp map_acc({:graph, stmts, g, _}, {_, _, _, g} = mapped),
    do: {:graph, [mapped | stmts], g, nil}

  defp map_acc({:graph, stmts, _, _}, mapped), do: {:dataset, [mapped | stmts], nil, nil}

  defp map_acc({:description, stmts, @unset_graph_name, nil}, {s, _, _} = mapped),
    do: {:description, [mapped | stmts], @unset_graph_name, s}

  defp map_acc({:description, stmts, @unset_graph_name, s}, {s, _, _} = mapped),
    do: {:description, [mapped | stmts], @unset_graph_name, s}

  defp map_acc({:description, stmts, @unset_graph_name, _}, {_, _, _} = mapped),
    do: {:graph, [mapped | stmts], @unset_graph_name, nil}

  defp map_acc({:description, stmts, nil, nil}, {s, _, _} = mapped),
    do: {:description, [mapped | stmts], nil, s}

  defp map_acc({:description, stmts, nil, s}, {s, _, _} = mapped),
    do: {:description, [mapped | stmts], nil, s}

  defp map_acc({:description, stmts, nil, _}, {_, _, _} = mapped),
    do: {:graph, [mapped | stmts], nil, nil}

  defp map_acc({:description, stmts, _, _}, {_, _, _} = mapped),
    do: {:dataset, [mapped | stmts], nil, nil}

  defp map_acc({:description, stmts, @unset_graph_name, nil}, {s, _, _, g} = mapped),
    do: {:description, [mapped | stmts], g, s}

  defp map_acc({:description, stmts, @unset_graph_name, s}, {s, _, _, g} = mapped),
    do: {:description, [mapped | stmts], g, s}

  defp map_acc({:description, stmts, @unset_graph_name, _}, {_, _, _, g} = mapped),
    do: {:graph, [mapped | stmts], g, nil}

  defp map_acc({:description, stmts, g, nil}, {s, _, _, g} = mapped),
    do: {:description, [mapped | stmts], g, s}

  defp map_acc({:description, stmts, g, s}, {s, _, _, g} = mapped),
    do: {:description, [mapped | stmts], g, s}

  defp map_acc({:description, stmts, g, _}, {_, _, _, g} = mapped),
    do: {:graph, [mapped | stmts], g, nil}

  defp map_acc({:description, stmts, _, _}, {_, _, _, _} = mapped),
    do: {:dataset, [mapped | stmts], nil, nil}

  defp build_mapped_structure(:description, _, data, result, _, subject) do
    derive(data, :description, subject || Source.subject(data), result)
  end

  defp build_mapped_structure(:graph, _, data, result, @unset_graph_name, _) do
    derive(data, :graph, Source.graph_name(data), result)
  end

  defp build_mapped_structure(:graph, _, data, result, graph_name, _) do
    derive(data, :graph, graph_name, result)
  end

  defp build_mapped_structure(:dataset, :dataset, data, result, _, _) do
    derive(data, :dataset, dataset_name(data), result)
  end

  defp build_mapped_structure(:dataset, _, data, result, _, _) do
    derive(data, :dataset, nil, result)
  end

  @doc """
  Filters statements in the data structure based on a predicate function.

  Returns a new data structure of the same type containing only the statements
  for which the predicate function returns a truthy value.

  ## Examples

      iex> graph = RDF.graph([{EX.S1, EX.p1, EX.O1}, {EX.S2, EX.p2, EX.O2}])
      iex> RDF.Data.filter(graph, fn {_s, p, _o} -> p == EX.p1 end)
      RDF.graph([{EX.S1, EX.p1, EX.O1}])

      iex> dataset = RDF.dataset([{EX.S, EX.p1, EX.O, EX.G}, {EX.S, EX.p2, EX.O, nil}])
      iex> RDF.Data.filter(dataset, fn {_s, p, _o, _g} -> p == EX.p1 end)
      RDF.dataset([{EX.S, EX.p1, EX.O, EX.G}])
  """
  @spec filter(Source.t(), (RDF.Statement.t() -> boolean)) :: Source.t()
  def filter(data, fun) when is_function(fun, 1) do
    filtered_statements =
      reduce(data, [], fn stmt, acc ->
        if fun.(stmt) do
          [stmt | acc]
        else
          acc
        end
      end)

    rebuild_structure(data, filtered_statements)
  end

  @doc """
  Rejects statements in the data structure based on a predicate function.

  Returns a new data structure of the same type containing only the statements
  for which the predicate function returns a falsy value.

  This is the complement of `filter/2`.

  ## Examples

      iex> graph = RDF.graph([{EX.S1, EX.p1, EX.O1}, {EX.S2, EX.p2, EX.O2}])
      iex> RDF.Data.reject(graph, fn {_s, p, _o} -> p == EX.p1 end)
      RDF.graph([{EX.S2, EX.p2, EX.O2}])

      iex> dataset = RDF.dataset([{EX.S, EX.p1, EX.O, EX.G}, {EX.S, EX.p2, EX.O, nil}])
      iex> RDF.Data.reject(dataset, fn {_s, p, _o, _g} -> p == EX.p1 end)
      RDF.dataset([{EX.S, EX.p2, EX.O}])
  """
  @spec reject(Source.t(), (RDF.Statement.t() -> boolean)) :: Source.t()
  def reject(data, fun) when is_function(fun, 1) do
    filtered_statements =
      reduce(data, [], fn stmt, acc ->
        if fun.(stmt) do
          acc
        else
          [stmt | acc]
        end
      end)

    rebuild_structure(data, filtered_statements)
  end

  @doc """
  Takes the first `amount` statements from the RDF data structure.

  Returns a new data structure of the same type containing at most `amount` statements.
  The order of statements is implementation-dependent and should not be relied upon.

  For negative amounts, returns an empty data structure.

  ## Examples

      iex> graph = RDF.graph([{EX.S1, EX.p, EX.O1}, {EX.S2, EX.p, EX.O2}, {EX.S3, EX.p, EX.O3}])
      iex> RDF.Data.statement_count(RDF.Data.take(graph, 2))
      2

      iex> RDF.Data.take(RDF.graph(), 5)
      RDF.graph()
  """
  @spec take(Source.t(), integer()) :: Source.t()
  def take(data, amount) when amount <= 0 do
    rebuild_structure(data, [])
  end

  def take(data, amount) when is_integer(amount) do
    {taken_statements, _} =
      reduce_while(data, {[], 0}, fn stmt, {acc, count} ->
        if count < amount do
          {:cont, {[stmt | acc], count + 1}}
        else
          {:halt, {acc, count}}
        end
      end)

    rebuild_structure(data, taken_statements)
  end

  @doc """
  Deletes matching statements from the data structure.

  Returns a new data structure with the specified statements removed.
  The resulting structure maintains the same type and metadata (like graph names)
  as the original.

  ## Examples

      iex> graph = RDF.graph([{EX.S1, EX.p, EX.O1}, {EX.S2, EX.p, EX.O2}])
      iex> RDF.Data.delete(graph, {EX.S1, EX.p, EX.O1})
      RDF.graph({EX.S2, EX.p, EX.O2})

      iex> graph = RDF.graph([{EX.S1, EX.p, EX.O1}, {EX.S2, EX.p, EX.O2}])
      iex> RDF.Data.delete(graph, [{EX.S1, EX.p, EX.O1}, {EX.S2, EX.p, EX.O2}])
      RDF.graph()

      iex> graph = RDF.graph([{EX.S1, EX.p, EX.O1}, {EX.S2, EX.p, EX.O2}])
      iex> RDF.Data.delete(graph, EX.S1 |> EX.p(EX.O1))
      RDF.graph({EX.S2, EX.p, EX.O2})
  """
  @spec delete(Source.t(), RDF.Statement.t() | [RDF.Statement.t()] | Source.t()) :: Source.t()
  def delete(data, statements_to_delete) do
    coerced = coerce_delete_statements(statements_to_delete)

    case Source.delete(data, coerced) do
      {:ok, result} -> result
      {:error, _} -> delete_fallback(data, coerced)
    end
  end

  defp coerce_delete_statements(statement) when is_tuple(statement), do: RDF.statement(statement)
  defp coerce_delete_statements(list) when is_list(list), do: Enum.map(list, &RDF.statement/1)
  defp coerce_delete_statements(other), do: statements(other)

  defp delete_fallback(data, coerced_statements) do
    delete_set = coerced_statements |> List.wrap() |> MapSet.new()

    remaining =
      data
      |> statements()
      |> Enum.reject(&MapSet.member?(delete_set, &1))

    rebuild_structure(data, remaining)
  end

  @doc """
  Removes and returns one statement from the RDF data structure.

  Returns a tuple `{statement, remaining_data}` where `statement` is a triple or quad,
  and `remaining_data` is the data structure without that `statement`. For empty data
  structures, returns `{nil, data}`.

  The specific statement returned is implementation-dependent and should not be
  relied upon for ordering.

  ## Examples

      iex> graph = RDF.graph([{EX.S, EX.p, EX.O}])
      iex> {triple, remaining} = RDF.Data.pop(graph)
      iex> triple
      {~I<http://example.com/S>, EX.p(), ~I<http://example.com/O>}
      iex> RDF.Graph.empty?(remaining)
      true

      iex> RDF.Data.pop(RDF.graph())
      {nil, RDF.graph()}
  """
  @spec pop(Source.t()) :: {RDF.Statement.t() | nil, Source.t()}
  def pop(data) do
    case Source.reduce(data, {:cont, nil}, fn stmt, _ -> {:halt, stmt} end) do
      {:halted, statement} -> {statement, delete(data, statement)}
      {:done, nil} -> {nil, data}
    end
  end

  @doc """
  Merges a list of data structures and/or statements into a single structure.

  ## Examples

      iex> graph = RDF.graph({EX.S1, EX.p1, EX.O1})
      iex> RDF.Data.merge([graph, {EX.S2, EX.p2, EX.O2}, EX.S3 |> EX.p3(EX.O3)])
      RDF.graph([{EX.S1, EX.p1, EX.O1}, {EX.S2, EX.p2, EX.O2}, {EX.S3, EX.p3, EX.O3}])

      iex> RDF.Data.merge([])
      RDF.graph()
  """
  @spec merge([Source.t() | RDF.Statement.t()]) :: Source.t()
  def merge([]), do: RDF.graph()
  def merge([single]) when is_tuple(single), do: to_data(single)
  def merge([first | rest]) when is_struct(first), do: Enum.reduce(rest, first, &merge(&2, &1))

  def merge(list) when is_list(list) do
    case extract_data(list, []) do
      {nil, _} -> Enum.reduce(tl(list), to_data(hd(list)), &merge(&2, &1))
      {data, rest} -> Enum.reduce(rest, data, &merge(&2, &1))
    end
  end

  defp extract_data([], acc), do: {nil, acc}

  defp extract_data([statement | rest], acc) when is_tuple(statement),
    do: extract_data(rest, [statement | acc])

  defp extract_data([struct | rest], acc), do: {struct, acc ++ rest}

  defp to_data({s, p, o}), do: RDF.description(s, init: {p, o})
  defp to_data({s, p, o, g}), do: RDF.graph({s, p, o}, name: g)

  @doc """
  Merges two data structures with automatic structural promotion.

  Rules:

  - Description + Description with same subject → Description
  - Description + Description with different subjects → Graph
  - Graph + Graph with same name → Graph
  - Graph + Graph with different names → Dataset
  - Otherwise, promotes to the most complex structure required

  ## Examples

      iex> desc1 = EX.S |> EX.p1(EX.O1)
      iex> desc2 = EX.S |> EX.p2(EX.O2)
      iex> RDF.Data.merge(desc1, desc2)
      EX.S |> EX.p1(EX.O1) |> EX.p2(EX.O2)

      iex> graph1 = RDF.graph([{EX.S1, EX.p, EX.O}], name: EX.G1)
      iex> graph2 = RDF.graph([{EX.S2, EX.p, EX.O}], name: EX.G2)
      iex> RDF.Data.merge(graph1, graph2)
      RDF.dataset([{EX.S1, EX.p, EX.O, EX.G1}, {EX.S2, EX.p, EX.O, EX.G2}])
  """
  @spec merge(Source.t(), Source.t() | RDF.Statement.t() | [Source.t() | RDF.Statement.t()]) ::
          Source.t()
  def merge(data1, data2)

  def merge(data, statement) when is_tuple(statement), do: merge(data, to_data(statement))

  def merge(data, list) when is_list(list), do: Enum.reduce(list, data, &merge(&2, &1))

  def merge(data1, data2) do
    target_type = merged_structure_type(data1, data2)

    case select_base(target_type, data1, data2) do
      {base, other} ->
        add(base, if(target_type == :dataset, do: to_quads(other), else: statements(other)))

      nil ->
        build_promoted_structure(target_type, data1, data2)
    end
  end

  defp merged_structure_type(data1, data2) do
    case {Source.structure_type(data1), Source.structure_type(data2)} do
      {:dataset, _} ->
        :dataset

      {_, :dataset} ->
        :dataset

      {:description, :description} ->
        if Source.subject(data1) == Source.subject(data2), do: :description, else: :graph

      {:graph, :graph} ->
        if Source.graph_name(data1) == Source.graph_name(data2), do: :graph, else: :dataset

      {:graph, :description} ->
        if Source.graph_name(data1) == nil, do: :graph, else: :dataset

      {:description, :graph} ->
        if Source.graph_name(data2) == nil, do: :graph, else: :dataset
    end
  end

  defp select_base(target_type, data1, data2) do
    cond do
      Source.structure_type(data1) == target_type -> {data1, data2}
      Source.structure_type(data2) == target_type -> {data2, data1}
      true -> nil
    end
  end

  defp build_promoted_structure(:graph, data1, data2) do
    derive(data1, :graph, nil, statements(data1) ++ statements(data2))
  end

  defp build_promoted_structure(:dataset, data1, data2) do
    derive(data1, :dataset, nil, to_quads(data1) ++ to_quads(data2))
  end

  @doc """
  Returns all statements in the data structure.

  Extracts all statements as a list. The format depends on the structure type:

  - `:description` and `:graph`: Returns triples `{subject, predicate, object}`
  - `:dataset`: Returns quads `{subject, predicate, object, graph_name}`

  ## Examples

      iex> graph = RDF.graph([{EX.S, EX.p, EX.O}])
      iex> RDF.Data.statements(graph)
      [{~I<http://example.com/S>, EX.p(), ~I<http://example.com/O>}]

      iex> dataset = RDF.dataset([{EX.S, EX.p, EX.O, EX.G}])
      iex> RDF.Data.statements(dataset)
      [{~I<http://example.com/S>, EX.p(), ~I<http://example.com/O>, ~I<http://example.com/G>}]
  """
  @spec statements(Source.t()) :: [RDF.Statement.t()]
  def statements(data) do
    data |> reduce([], &[&1 | &2]) |> :lists.reverse()
  end

  @doc """
  Returns all statements as triples.

  Converts all statements to triple format `{subject, predicate, object}`.
  For Datasets, this drops the graph component from quads.

  ## Examples

      iex> graph = RDF.graph([{EX.S, EX.p, EX.O}])
      iex> RDF.Data.triples(graph)
      [{~I<http://example.com/S>, EX.p(), ~I<http://example.com/O>}]

      iex> dataset = RDF.dataset([{EX.S, EX.p, EX.O, EX.G}])
      iex> RDF.Data.triples(dataset)
      [{~I<http://example.com/S>, EX.p(), ~I<http://example.com/O>}]
  """
  @spec triples(Source.t()) :: [RDF.Triple.t()]
  def triples(data) do
    if Source.structure_type(data) == :dataset do
      data
      |> reduce([], fn {s, p, o, _g}, acc -> [{s, p, o} | acc] end)
      |> :lists.reverse()
    else
      statements(data)
    end
  end

  @doc """
  Returns all statements as quads.

  Converts all statements to quad format `{subject, predicate, object, graph_name}`.
  For descriptions and graphs, adds the graph name (or `nil` for default graph).

  ## Examples

      iex> graph = RDF.graph([{EX.S, EX.p, EX.O}])
      iex> RDF.Data.quads(graph)
      [{~I<http://example.com/S>, EX.p(), ~I<http://example.com/O>, nil}]

      iex> named_graph = RDF.graph([{EX.S, EX.p, EX.O}], name: EX.G)
      iex> RDF.Data.quads(named_graph)
      [{~I<http://example.com/S>, EX.p(), ~I<http://example.com/O>, ~I<http://example.com/G>}]
  """
  @spec quads(Source.t()) :: [RDF.Quad.t()]
  def quads(data) do
    case Source.structure_type(data) do
      :dataset -> statements(data)
      :graph -> data |> to_quads() |> :lists.reverse()
      :description -> data |> to_quads(nil) |> :lists.reverse()
    end
  end

  defp to_quads(data), do: to_quads(data, Source.graph_name(data))

  defp to_quads(data, graph_name) do
    reduce(data, [], fn
      {s, p, o}, acc -> [{s, p, o, graph_name} | acc]
      quad, acc -> [quad | acc]
    end)
  end

  @doc """
  Returns the default graph from the RDF data structure.

  ## Examples

      iex> desc = EX.S |> EX.p(EX.O)
      iex> RDF.Data.default_graph(desc)
      RDF.graph({EX.S, EX.p, EX.O})

      iex> dataset = RDF.dataset([{EX.S, EX.p, EX.O, nil}])
      iex> RDF.Data.default_graph(dataset)
      RDF.graph({EX.S, EX.p, EX.O})

      iex> dataset = RDF.dataset([{EX.S, EX.p, EX.O, EX.Graph1}])
      iex> RDF.Data.default_graph(dataset)
      RDF.graph()
  """
  @spec default_graph(Source.t()) :: Source.t()
  def default_graph(data) do
    graph(data, nil)
  end

  @doc """
  Returns a specific graph from the RDF data structure.

  If the graph doesn't exist, an empty graph is returned.
  Use `graph/3` to provide a custom default value.

  ## Examples

      iex> dataset = RDF.dataset([{EX.S, EX.p, EX.O, EX.Graph1}])
      iex> RDF.Data.graph(dataset, EX.Graph1)
      RDF.graph({EX.S, EX.p, EX.O}, name: EX.Graph1)

      iex> dataset = RDF.dataset([{EX.S, EX.p, EX.O, EX.Graph1}])
      iex> RDF.Data.graph(dataset, EX.NonExistent)
      RDF.graph(name: EX.NonExistent)
  """
  @spec graph(Source.t(), RDF.Resource.coercible() | nil) :: Source.t()
  def graph(data, graph_name) do
    case Source.graph(data, graph_name) do
      {:ok, graph} -> graph
      :error -> derive(data, :graph, graph_name)
    end
  end

  @doc """
  Returns a specific graph from the RDF data structure, or a default value if not found.

  ## Examples

      iex> dataset = RDF.dataset([{EX.S, EX.p, EX.O, EX.Graph1}])
      iex> RDF.Data.graph(dataset, EX.Graph1, nil)
      RDF.graph({EX.S, EX.p, EX.O}, name: EX.Graph1)

      iex> dataset = RDF.dataset([{EX.S, EX.p, EX.O, EX.Graph1}])
      iex> RDF.Data.graph(dataset, EX.NonExistent, nil)
      nil

      iex> dataset = RDF.dataset([{EX.S, EX.p, EX.O, EX.Graph1}])
      iex> RDF.Data.graph(dataset, EX.NonExistent, :not_found)
      :not_found
  """
  @spec graph(Source.t(), RDF.Resource.coercible() | nil, default) :: Source.t() | default
        when default: term()
  def graph(data, graph_name, default) do
    case Source.graph(data, graph_name) do
      {:ok, graph} -> graph
      :error -> default
    end
  end

  @doc """
  Returns all graphs in the data structure.

  Behavior by structure type:

  - `:description`: returns a single graph containing the description
  - `:graph`: returns a list containing the graph itself
  - `:dataset`: returns all graphs (including the default graph if present)

  ## Examples

      iex> description = EX.S |> EX.p(EX.O)
      iex> RDF.Data.graphs(description)
      [RDF.graph(description)]

      iex> graph = RDF.graph([{EX.S, EX.p, EX.O}])
      iex> RDF.Data.graphs(graph)
      [graph]

      iex> dataset = RDF.dataset([{EX.S1, EX.p, EX.O1, nil}, {EX.S2, EX.p, EX.O2, EX.graph1}])
      iex> RDF.Data.graphs(dataset)
      [RDF.graph([{EX.S1, EX.p, EX.O1}]), RDF.graph([{EX.S2, EX.p, EX.O2}], name: EX.graph1)]
  """
  @spec graphs(Source.t()) :: [Source.t()]
  def graphs(data) do
    case Source.structure_type(data) do
      :description ->
        [derive(data, :graph, nil, statements(data))]

      :graph ->
        [data]

      :dataset ->
        data
        |> graph_names()
        |> Enum.map(&graph(data, &1, nil))
        |> Enum.reject(&is_nil/1)
    end
  end

  @doc """
  Returns all graph names in the data structure.

  Behavior by structure type:

  - `:description`: Always returns `[nil]` (implicit unnamed graph)
  - `:graph`: Returns `[name]` where name is the graph's name (could be `nil`)
  - `:dataset`: Returns all graph names

  ## Examples

      iex> desc = EX.S |> EX.p(EX.O)
      iex> RDF.Data.graph_names(desc)
      [nil]

      iex> graph = RDF.Graph.new([{EX.S, EX.p, EX.O}], name: EX.Graph1)
      iex> RDF.Data.graph_names(graph)
      [~I<http://example.com/Graph1>]

      iex> dataset = RDF.Dataset.new([{EX.S, EX.p, EX.O, EX.G1}, {EX.S2, EX.p, EX.O2, nil}])
      iex> RDF.Data.graph_names(dataset)
      [nil, ~I<http://example.com/G1>]
  """
  @spec graph_names(Source.t()) :: [RDF.IRI.t() | nil]
  def graph_names(data) do
    case Source.graph_names(data) do
      {:ok, graph_names} ->
        graph_names

      {:error, _} ->
        case Source.structure_type(data) do
          :description ->
            [nil]

          :graph ->
            [Source.graph_name(data)]

          :dataset ->
            data
            |> reduce(MapSet.new(), fn
              {_, _, _, g}, acc -> MapSet.put(acc, g)
              _, acc -> MapSet.put(acc, nil)
            end)
            |> MapSet.to_list()
        end
    end
  end

  @doc """
  Returns all descriptions in the data structure.

  ## Examples

      iex> graph = RDF.graph([{EX.S1, EX.p(), EX.O1}, {EX.S2, EX.p(), EX.O2}])
      iex> RDF.Data.descriptions(graph)
      [EX.p(EX.S1, EX.O1), EX.p(EX.S2, EX.O2)]

      iex> dataset = RDF.dataset([{EX.S1, EX.p(), EX.O1, nil}, {EX.S2, EX.p(), EX.O2, EX.G}, {EX.S3, EX.p(), EX.O3, EX.G}])
      iex> RDF.Data.descriptions(dataset)
      [EX.p(EX.S1, EX.O1), EX.p(EX.S2, EX.O2), EX.p(EX.S3, EX.O3)]
  """
  @spec descriptions(Source.t()) :: [Source.t()]
  def descriptions(data) do
    data
    |> subjects()
    |> Enum.map(fn subject -> description(data, subject) end)
    |> Enum.reject(&is_nil/1)
  end

  @doc """
  Returns the description of a specific subject in the RDF data structure.

  If the subject doesn't exist, an empty description for that subject is returned.
  Use `description/3` to provide a custom default value.

  ## Examples

      iex> graph = RDF.graph([{EX.Alice, EX.knows, EX.Bob}])
      iex> RDF.Data.description(graph, EX.Alice)
      EX.Alice |> EX.knows(EX.Bob)

      iex> graph = RDF.graph([{EX.Alice, EX.knows, EX.Bob}])
      iex> RDF.Data.description(graph, EX.Charlie)
      RDF.description(EX.Charlie)

  """
  @spec description(Source.t(), RDF.Resource.coercible()) :: Source.t()
  def description(data, subject) do
    case Source.description(data, subject) do
      {:ok, desc} -> desc
      :error -> derive(data, :description, subject)
    end
  end

  @doc """
  Returns the description of a specific subject, or a default value if not found.

  ## Examples

      iex> graph = RDF.graph([{EX.Alice, EX.knows, EX.Bob}])
      iex> RDF.Data.description(graph, EX.Alice, nil)
      EX.Alice |> EX.knows(EX.Bob)

      iex> graph = RDF.graph([{EX.Alice, EX.knows, EX.Bob}])
      iex> RDF.Data.description(graph, EX.Charlie, nil)
      nil

      iex> graph = RDF.graph([{EX.Alice, EX.knows, EX.Bob}])
      iex> RDF.Data.description(graph, EX.Charlie, :not_found)
      :not_found

  """
  @spec description(Source.t(), RDF.Resource.coercible(), default) :: Source.t() | default
        when default: term()
  def description(data, subject, default) do
    case Source.description(data, subject) do
      {:ok, desc} -> desc
      :error -> default
    end
  end

  @doc """
  Returns all unique subjects in the data structure.

  ## Examples

      iex> graph = RDF.Graph.new([{EX.S1, EX.p, EX.O}, {EX.S2, EX.p, EX.O}])
      iex> RDF.Data.subjects(graph)
      [~I<http://example.com/S1>, ~I<http://example.com/S2>]
  """
  @spec subjects(Source.t()) :: [RDF.Resource.t()]
  def subjects(data) do
    case Source.subjects(data) do
      {:ok, subjects} ->
        subjects

      {:error, _} ->
        data |> reduce(MapSet.new(), &MapSet.put(&2, elem(&1, 0))) |> MapSet.to_list()
    end
  end

  @doc """
  Returns all unique predicates in the data structure.

  ## Examples

      iex> graph = RDF.Graph.new([{EX.S, EX.p1, EX.O}, {EX.S, EX.p2, EX.O}])
      iex> RDF.Data.predicates(graph)
      [~I<http://example.com/p1>, ~I<http://example.com/p2>]
  """
  @spec predicates(Source.t()) :: [RDF.IRI.t()]
  def predicates(data) do
    case Source.predicates(data) do
      {:ok, predicates} ->
        predicates

      {:error, _} ->
        data |> reduce(MapSet.new(), &MapSet.put(&2, elem(&1, 1))) |> MapSet.to_list()
    end
  end

  @doc """
  Returns all unique resource objects in the data structure.

  Resource objects are IRIs and blank nodes, excluding literals. 
  For all object terms including literals, use `object_terms/1`.

  ## Examples

      iex> graph = RDF.Graph.new([{EX.S, EX.p, EX.O1}, {EX.S, EX.p2, "literal"}])
      iex> RDF.Data.object_resources(graph)
      [~I<http://example.com/O1>]
  """
  @spec object_resources(Source.t()) :: [RDF.Resource.t()]
  def object_resources(data) do
    case Source.objects(data) do
      {:ok, objects} ->
        objects

      {:error, _} ->
        data
        |> reduce(MapSet.new(), fn
          {_, _, object}, acc when is_rdf_resource(object) -> MapSet.put(acc, object)
          {_, _, object, _}, acc when is_rdf_resource(object) -> MapSet.put(acc, object)
          _, acc -> acc
        end)
        |> MapSet.to_list()
    end
  end

  @doc """
  Returns all unique object terms in the data structure.

  Object terms include all RDF terms: IRIs, blank nodes, and literals.

  ## Examples

      iex> graph = RDF.Graph.new([{EX.S, EX.p, EX.O1}, {EX.S, EX.p2, "literal"}])
      iex> RDF.Data.object_terms(graph)
      [~L"literal", ~I<http://example.com/O1>]
  """
  @spec object_terms(Source.t()) :: [RDF.Term.t()]
  def object_terms(data) do
    data |> reduce(MapSet.new(), &MapSet.put(&2, elem(&1, 2))) |> MapSet.to_list()
  end

  @doc """
  Returns all unique resources (non-literal terms) in the data structure.

  Resources are IRIs and blank nodes that appear as subjects or objects.

  ## Examples

      iex> graph = RDF.Graph.new([{EX.S, EX.p, EX.O}, {EX.S, EX.p2, "literal"}])
      iex> RDF.Data.resources(graph)
      [~I<http://example.com/O>, ~I<http://example.com/S>]
  """
  @spec resources(Source.t()) :: [RDF.Resource.t()]
  def resources(data) do
    case Source.resources(data) do
      {:ok, resources} ->
        resources

      {:error, _} ->
        data
        |> subjects()
        |> MapSet.new()
        |> MapSet.union(MapSet.new(object_resources(data)))
        |> MapSet.to_list()
    end
  end

  @doc """
  Returns the count of primary elements relative to the structure type.

  This provides a consistent "size" metric that is meaningful for each structure level.

  - `:description`: counts predicates (with non-empty object sets)
  - `:graph`: counts subjects (descriptions)
  - `:dataset`: counts graphs

  ## Examples

      iex> desc = EX.S |> EX.p(EX.O1) |> EX.q(EX.O2)
      iex> RDF.Data.count(desc)
      2  # 2 predicates

      iex> graph = RDF.Graph.new([{EX.S1, EX.p, EX.O}, {EX.S2, EX.p, EX.O}])
      iex> RDF.Data.count(graph)
      2  # 2 subjects

      iex> dataset = RDF.Dataset.new([{EX.S, EX.p, EX.O, EX.G1}, {EX.S, EX.p, EX.O, EX.G2}])
      iex> RDF.Data.count(dataset)
      2  # 2 graphs
  """
  @spec count(Source.t()) :: non_neg_integer()
  def count(data) do
    case Source.structure_type(data) do
      :description -> predicate_count(data)
      :graph -> subject_count(data)
      :dataset -> graph_count(data)
    end
  end

  @doc """
  Returns the count of graphs in the RDF data structure.

  Depending on the structure type, the count represents:

  - `:description`: Always 1 (implicit unnamed graph)
  - `:graph`: Always 1
  - `:dataset`: Number of graphs (including default if present)

  ## Examples

      iex> desc = EX.S |> EX.p(EX.O)
      iex> RDF.Data.graph_count(desc)
      1

      iex> graph = RDF.graph([{EX.S1, EX.p, EX.O1}])
      iex> RDF.Data.graph_count(graph)
      1

      iex> dataset = RDF.dataset([
      ...>   {EX.S1, EX.p, EX.O1, nil},
      ...>   {EX.S2, EX.p, EX.O2, EX.Graph}
      ...> ])
      iex> RDF.Data.graph_count(dataset)
      2

      iex> RDF.Data.graph_count(RDF.dataset())
      0
  """
  @spec graph_count(Source.t()) :: non_neg_integer()
  def graph_count(data) do
    case Source.graph_count(data) do
      {:ok, count} -> count
      {:error, _} -> data |> graph_names() |> length()
    end
  end

  @doc """
  Returns the count of statements in the RDF data structure.

  ## Examples

      iex> graph = RDF.graph([{EX.S1, EX.p, EX.O1}, {EX.S2, EX.p, EX.O2}])
      iex> RDF.Data.statement_count(graph)
      2

      iex> RDF.Data.statement_count(RDF.dataset())
      0
  """
  @spec statement_count(Source.t()) :: non_neg_integer()
  def statement_count(data) do
    case Source.statement_count(data) do
      {:ok, count} -> count
      {:error, _} -> reduce(data, 0, fn _stmt, acc -> acc + 1 end)
    end
  end

  @doc """
  Returns the count of unique subjects in the RDF data structure.

  ## Examples

      iex> graph = RDF.graph([{EX.S1, EX.p, EX.O1}, {EX.S2, EX.p, EX.O2}])
      iex> RDF.Data.subject_count(graph)
      2

      iex> RDF.Data.subject_count(EX.S |> EX.p(EX.O))
      1

      iex> RDF.Data.subject_count(RDF.graph())
      0
  """
  @spec subject_count(Source.t()) :: non_neg_integer()
  def subject_count(data) do
    case Source.description_count(data) do
      {:ok, count} -> count
      {:error, _} -> fallback_subject_count(data)
    end
  end

  defp fallback_subject_count(data) do
    data
    |> reduce(MapSet.new(), &MapSet.put(&2, elem(&1, 0)))
    |> MapSet.size()
  end

  @doc """
  Returns the count of unique predicates in the data structure.

  ## Examples

      iex> desc = EX.S |> EX.p(EX.O1) |> EX.q(EX.O2)
      iex> RDF.Data.predicate_count(desc)
      2

      iex> graph = RDF.Graph.new([{EX.S1, EX.p, EX.O1}, {EX.S2, EX.p, EX.O2}, {EX.S3, EX.q, EX.O3}])
      iex> RDF.Data.predicate_count(graph)
      2
  """
  @spec predicate_count(Source.t()) :: non_neg_integer()
  def predicate_count(%RDF.Description{} = data), do: map_size(data.predications)

  def predicate_count(data) do
    data
    |> reduce(MapSet.new(), &MapSet.put(&2, elem(&1, 1)))
    |> MapSet.size()
  end

  @doc """
  Returns true if the given RDF data structure is empty.

  ## Examples

      iex> RDF.Data.empty?(RDF.graph())
      true

      iex> RDF.Data.empty?(RDF.graph([{EX.S, EX.p, EX.O}]))
      false
  """
  @spec empty?(Source.t()) :: boolean()
  def empty?(data) do
    case Source.statement_count(data) do
      {:ok, 0} -> true
      {:ok, _} -> false
      {:error, _} -> fallback_empty?(data)
    end
  end

  defp fallback_empty?(data) do
    case Source.reduce(data, {:cont, true}, fn _, _ -> {:halt, false} end) do
      {:done, result} -> result
      {:halted, result} -> result
    end
  end

  @doc """
  Checks equality of two data structures.

  Supports cross-structure comparisons with special rules:

  - description equals graph if graph contains only that description
  - graph equals dataset if dataset contains only that graph
  - otherwise compares statement sets

  ## Examples

      iex> desc1 = EX.S |> EX.p(EX.O)
      iex> desc2 = EX.S |> EX.p(EX.O)
      iex> RDF.Data.equal?(desc1, desc2)
      true

      iex> desc = EX.S |> EX.p(EX.O)
      iex> graph = RDF.graph([{EX.S, EX.p(), EX.O}])
      iex> RDF.Data.equal?(desc, graph)
      true

      iex> graph = RDF.graph([{EX.S, EX.p(), EX.O}])
      iex> dataset = RDF.dataset([{EX.S, EX.p(), EX.O, nil}])
      iex> RDF.Data.equal?(graph, dataset)
      true
  """
  @spec equal?(Source.t(), Source.t()) :: boolean
  def equal?(data1, data2) do
    empty1 = empty?(data1)
    empty2 = empty?(data2)

    cond do
      empty1 and empty2 ->
        true

      empty1 != empty2 ->
        false

      true ->
        case {Source.structure_type(data1), Source.structure_type(data2)} do
          {same, same} ->
            compare_statement_sets(data1, data2)

          {:description, :graph} ->
            Source.graph_name(data1) == Source.graph_name(data2) and
              case descriptions(data2) do
                [single_desc] -> compare_statement_sets(data1, single_desc)
                _ -> false
              end

          {:graph, :description} ->
            equal?(data2, data1)

          {:graph, :dataset} ->
            case graphs(data2) do
              [single_graph] ->
                Source.graph_name(data1) == Source.graph_name(single_graph) and
                  compare_statement_sets(data1, single_graph)

              _ ->
                false
            end

          {:dataset, :graph} ->
            equal?(data2, data1)

          {:description, :dataset} ->
            case graphs(data2) do
              [single_graph] ->
                if Source.graph_name(single_graph) == nil do
                  case descriptions(single_graph) do
                    [single_desc] ->
                      Source.subject(data1) == Source.subject(single_desc) and
                        compare_statement_sets(data1, single_desc)

                    _ ->
                      false
                  end
                else
                  false
                end

              _ ->
                false
            end

          {:dataset, :description} ->
            equal?(data2, data1)

          _ ->
            compare_statement_sets(data1, data2)
        end
    end
  end

  defp compare_statement_sets(data1, data2) do
    MapSet.equal?(to_statement_set(data1), to_statement_set(data2))
  end

  defp to_statement_set(data) do
    reduce(data, MapSet.new(), &MapSet.put(&2, &1))
  end

  @doc """
  Checks if data includes the given statements.

  Returns `true` if all given statements are present in the data structure.

  The `statements` parameter can be:

  - A single triple `{s, p, o}` or quad `{s, p, o, g}`
  - A list of triples or quads
  - Another structure implementing `RDF.Data.Source`

  For datasets, triple patterns (without graph) are matched against **all**
  graphs. Use a quad `{s, p, o, graph_name}` to check a specific graph (including
  `nil` for the default graph).

  ## Examples

      iex> graph = RDF.Graph.new([{EX.S, EX.p, EX.O}])
      iex> RDF.Data.include?(graph, {EX.S, EX.p, EX.O})
      true

      iex> graph = RDF.Graph.new([{EX.S, EX.p, EX.O}])
      iex> RDF.Data.include?(graph, [{EX.S, EX.p, EX.O}])
      true

      iex> graph = RDF.Graph.new([{EX.S, EX.p, EX.O}])
      iex> desc = EX.S |> EX.p(EX.O)
      iex> RDF.Data.include?(graph, desc)
      true

      iex> dataset = RDF.Dataset.new([
      ...>   {EX.S1, EX.p, EX.O1, nil},
      ...>   {EX.S2, EX.p, EX.O2, EX.Graph}
      ...> ])
      iex> RDF.Data.include?(dataset, {EX.S1, EX.p, EX.O1})
      true
      iex> RDF.Data.include?(dataset, {EX.S2, EX.p, EX.O2})
      true
      iex> RDF.Data.include?(dataset, {EX.S2, EX.p, EX.O2, nil})
      false
      iex> RDF.Data.include?(dataset, {EX.S2, EX.p, EX.O2, EX.Graph})
      true
  """
  @spec include?(
          data :: Source.t(),
          statements :: RDF.Statement.t() | [RDF.Statement.t()] | Source.t()
        ) :: boolean
  def include?(data, statements) when is_list(statements) do
    Enum.all?(statements, &include?(data, &1))
  end

  def include?(data, {s, p, o, g}) do
    coerced_graph_name = RDF.coerce_graph_name(g)

    case graph(data, coerced_graph_name, nil) do
      nil -> false
      graph -> include?(graph, {s, p, o})
    end
  end

  def include?(data, {s, p, o}) do
    case Source.structure_type(data) do
      :dataset ->
        data |> graphs() |> Enum.any?(&include?(&1, {s, p, o}))

      _ ->
        coerced_predicate = RDF.coerce_predicate(p)
        coerced_object = RDF.coerce_object(o)

        data
        |> description(s)
        |> reduce_while(false, fn
          {_, ^coerced_predicate, ^coerced_object}, _acc -> {:halt, true}
          _, acc -> {:cont, acc}
        end)
    end
  end

  def include?(data, %_{} = included_data) do
    include?(data, statements(included_data))
  end

  @doc """
  Returns `true` if the data describes the given subject.

  Checks if any statements with the given subject exist in the data structure.

  ## Examples

      iex> graph = RDF.graph([{EX.Alice, EX.knows, EX.Bob}])
      iex> RDF.Data.describes?(graph, EX.Alice)
      true

      iex> graph = RDF.graph([{EX.Alice, EX.knows, EX.Bob}])
      iex> RDF.Data.describes?(graph, EX.Unknown)
      false
  """
  @spec describes?(Source.t(), RDF.Resource.coercible()) :: boolean()
  def describes?(data, subject) do
    match?({:ok, _}, Source.description(data, subject))
  end

  @doc """
  Converts the RDF data structure to a graph.

  If the data is already a graph and no options are provided, returns it unchanged.
  For datasets, all graphs are merged into a single graph (graph names are lost).

  ## Options

  - `:native` - Forces conversion to native `RDF.Graph` (default: `false`)

  ## Examples

      iex> desc = EX.S |> EX.p(EX.O)
      iex> RDF.Data.to_graph(desc)
      RDF.graph({EX.S, EX.p(), EX.O})

      iex> graph = RDF.graph([{EX.S, EX.p, EX.O}], name: EX.G)
      iex> RDF.Data.to_graph(graph)
      graph

      iex> dataset = RDF.dataset([{EX.S1, EX.p, EX.O1, EX.G1}, {EX.S2, EX.p, EX.O2, EX.G2}])
      iex> RDF.Data.to_graph(dataset)
      RDF.graph([{EX.S1, EX.p, EX.O1}, {EX.S2, EX.p, EX.O2}])
  """
  @spec to_graph(Source.t(), keyword()) :: RDF.Graph.t() | Source.t()
  def to_graph(data, opts \\ []) do
    native = Keyword.get(opts, :native, false)

    if Source.structure_type(data) == :graph and not native do
      data
    else
      triples = triples(data)
      graph_name = Source.graph_name(data)

      if native do
        RDF.Graph.new(triples, name: graph_name)
      else
        derive(data, :graph, graph_name, triples)
      end
    end
  end

  @doc """
  Converts the RDF data structure to a dataset.

  If the data is already a dataset and no options are provided, returns it unchanged.
  For graphs, the graph is embedded preserving its name (named or default graph).

  ## Options

  - `:native` - Forces conversion to native `RDF.Dataset` (default: `false`)

  ## Examples

      iex> desc = EX.S |> EX.p(EX.O)
      iex> RDF.Data.to_dataset(desc)
      RDF.dataset({EX.S, EX.p(), EX.O})

      iex> graph = RDF.graph([{EX.S, EX.p, EX.O}], name: EX.G)
      iex> RDF.Data.to_dataset(graph)
      RDF.dataset({EX.S, EX.p(), EX.O, EX.G})

      iex> dataset = RDF.dataset([{EX.S, EX.p, EX.O, EX.G}])
      iex> RDF.Data.to_dataset(dataset)
      dataset
  """
  @spec to_dataset(Source.t(), keyword()) :: RDF.Dataset.t() | Source.t()
  def to_dataset(data, opts \\ []) do
    native = Keyword.get(opts, :native, false)

    if Source.structure_type(data) == :dataset and not native do
      data
    else
      quads = quads(data)

      if native do
        RDF.Dataset.new(quads, name: dataset_name(data))
      else
        derive(data, :dataset, nil, quads)
      end
    end
  end

  defp rebuild_structure(template_data, statements) do
    template_data |> Source.structure_type() |> rebuild_structure(template_data, statements)
  end

  defp rebuild_structure(:description, data, statements) do
    # Note: This assumes that the subject in statements matches the template
    derive(data, :description, Source.subject(data), statements)
  end

  defp rebuild_structure(:graph, data, statements) do
    derive(data, :graph, Source.graph_name(data), statements)
  end

  defp rebuild_structure(:dataset, data, statements) do
    derive(data, :dataset, dataset_name(data), statements)
  end

  defp dataset_name(%RDF.Dataset{name: name}), do: name
  defp dataset_name(_), do: nil

  defp derive(data, :description, subject) do
    case Source.derive(data, :description, subject: subject) do
      {:ok, desc} -> desc
      {:error, _} -> RDF.Description.new(subject)
    end
  end

  defp derive(data, :graph, graph_name) do
    case Source.derive(data, :graph, name: graph_name) do
      {:ok, graph} -> graph
      {:error, _} -> RDF.Graph.new(name: graph_name)
    end
  end

  defp derive(data, :dataset, dataset_name) do
    case Source.derive(data, :dataset, name: dataset_name) do
      {:ok, dataset} -> dataset
      {:error, _} -> RDF.Dataset.new(name: dataset_name)
    end
  end

  defp derive(data, structure_type, arg, statements) do
    data
    |> derive(structure_type, arg)
    |> add(statements)
  end

  defp add(%type{} = data, statements) do
    case Source.add(data, statements) do
      {:ok, result} -> result
      {:error, _} -> type.add(data, statements)
    end
  end
end
