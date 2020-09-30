defmodule RDF.Utils do
  @moduledoc false

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
             with {:ok, value} <- fun.(e) do
               {:cont, {:ok, [value | acc]}}
             else
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
end
