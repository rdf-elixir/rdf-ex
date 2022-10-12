defmodule RDF.Query.Test.Case do
  @moduledoc """
  `ExUnit.CaseTemplate` for `RDF.Query` tests.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      use RDF.Test.Case

      alias RDF.Query.BGP

      import unquote(__MODULE__)
    end
  end

  alias RDF.Query.BGP

  def bgp_struct(), do: %BGP{triple_patterns: []}

  def bgp_struct(triple_patterns) when is_list(triple_patterns),
    do: %BGP{triple_patterns: triple_patterns}

  def bgp_struct({_, _, _} = triple_pattern),
    do: %BGP{triple_patterns: [triple_pattern]}

  def ok_bgp_struct(triple_patterns), do: {:ok, bgp_struct(triple_patterns)}

  def comparable(elements), do: MapSet.new(elements)
end
