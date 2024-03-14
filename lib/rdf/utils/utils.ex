defmodule RDF.Utils do
  @moduledoc false

  def downcase?(term) when is_atom(term), do: term |> Atom.to_string() |> downcase?()
  def downcase?(term), do: term =~ ~r/^(_|\p{Ll})/u

  def lazy_map_update(map, key, fun) do
    lazy_map_update(map, key, fn -> fun.(nil) end, fun)
  end

  def lazy_map_update(map, key, init_fun, fun) do
    case map do
      %{^key => value} ->
        Map.put(map, key, fun.(value))

      %{} ->
        Map.put(map, key, init_fun.())

      other ->
        :erlang.error({:badmap, other}, [map, key, init_fun, fun])
    end
  end

  def map_while_ok(enum, fun) do
    with {:ok, mapped} <-
           Enum.reduce_while(enum, {:ok, []}, fn e, {:ok, acc} ->
             case fun.(e) do
               {:ok, value} -> {:cont, {:ok, [value | acc]}}
               error -> {:halt, error}
             end
           end) do
      {:ok, Enum.reverse(mapped)}
    end
  end

  def flat_map_while_ok(enum, fun) do
    with {:ok, mapped} <- map_while_ok(enum, fun) do
      {:ok, Enum.concat(mapped)}
    end
  end

  def map_join_while_ok(enum, joiner \\ "", fun) do
    with {:ok, mapped} <- map_while_ok(enum, fun) do
      {:ok, Enum.join(mapped, joiner)}
    end
  end

  def reject_empty_map_values(map) do
    Map.filter(map, fn
      {_, nil} -> false
      {_, _} -> true
    end)
  end

  def permutations([]), do: [[]]

  def permutations(list) do
    for x <- list, y <- permutations(list -- [x]), do: [x | y]
  end
end
