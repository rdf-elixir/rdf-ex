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
end
