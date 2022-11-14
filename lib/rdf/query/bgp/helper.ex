defmodule RDF.Query.BGP.Helper do
  @moduledoc !"""
             Shared functions between the `RDF.Query.BGP.Simple` and `RDF.Query.BGP.Stream` engines.
             """

  import RDF.Guards

  def solvable?(term) when is_tuple(term) and tuple_size(term) == 1, do: true
  def solvable?({s, p, o}), do: solvable?(p) or solvable?(s) or solvable?(o)
  def solvable?(_), do: false

  def apply_solutions(triple_pattern, solutions) do
    if solver = solver(triple_pattern) do
      Stream.map(solutions, solver)
    else
      solutions
    end
  end

  defp solver(triple_pattern) do
    if solver = solver_fun(triple_pattern) do
      &{&1, solver.(&1)}
    end
  end

  defp solver_fun({{s}, {p}, {o}}), do: &{&1[s], &1[p], &1[o]}
  defp solver_fun({{s}, p, {o}}), do: &{&1[s], p, &1[o]}

  defp solver_fun({{s}, {p}, o}) do
    if o_solver = solver_fun(o) do
      &{&1[s], &1[p], o_solver.(&1)}
    else
      &{&1[s], &1[p], o}
    end
  end

  defp solver_fun({{s}, p, o}) do
    if o_solver = solver_fun(o) do
      &{&1[s], p, o_solver.(&1)}
    else
      &{&1[s], p, o}
    end
  end

  defp solver_fun({s, {p}, {o}}) do
    if s_solver = solver_fun(s) do
      &{s_solver.(&1), &1[p], &1[o]}
    else
      &{s, &1[p], &1[o]}
    end
  end

  defp solver_fun({s, p, {o}}) do
    if s_solver = solver_fun(s) do
      &{s_solver.(&1), p, &1[o]}
    else
      &{s, p, &1[o]}
    end
  end

  defp solver_fun({s, {p}, o}) do
    s_solver = solver_fun(s)
    o_solver = solver_fun(o)

    cond do
      s_solver && o_solver -> &{s_solver.(&1), &1[p], o_solver.(&1)}
      s_solver -> &{s_solver.(&1), &1[p], o}
      o_solver -> &{s, &1[p], o_solver.(&1)}
      true -> &{s, &1[p], o}
    end
  end

  defp solver_fun({s, p, o}) do
    s_solver = solver_fun(s)
    o_solver = solver_fun(o)

    cond do
      s_solver && o_solver -> &{s_solver.(&1), p, o_solver.(&1)}
      s_solver -> &{s_solver.(&1), p, o}
      o_solver -> &{s, p, o_solver.(&1)}
      true -> fn _ -> {s, p, o} end
    end
  end

  defp solver_fun(_), do: nil

  def solve_variables(var, val, {s, p, o}),
    do: {solve_variables(var, val, s), solve_variables(var, val, p), solve_variables(var, val, o)}

  def solve_variables(var, val, var), do: val
  def solve_variables(_, _, term), do: term

  def solve_variables(bindings, pattern) do
    Enum.reduce(bindings, pattern, fn {var, val}, pattern ->
      solve_variables(var, val, pattern)
    end)
  end

  def quoted_triple_with_variables?({s, p, o}) do
    is_atom(s) or is_atom(p) or is_atom(o) or
      quoted_triple_with_variables?(s) or
      quoted_triple_with_variables?(p) or
      quoted_triple_with_variables?(o)
  end

  def quoted_triple_with_variables?(_), do: false

  def match_triple(triple, triple), do: %{}
  def match_triple({s, p, o}, {var, p, o}) when is_atom(var), do: %{var => s}
  def match_triple({s, p, o}, {s, var, o}) when is_atom(var), do: %{var => p}
  def match_triple({s, p, o}, {s, p, var}) when is_atom(var), do: %{var => o}

  def match_triple({s, p1, o1}, {triple_pattern, p2, o2}) when is_triple(triple_pattern) do
    if bindings = match_triple({"solved", p1, o1}, {"solved", p2, o2}) do
      if nested_bindings = match_triple(s, triple_pattern) do
        Map.merge(bindings, nested_bindings)
      end
    end
  end

  def match_triple({s1, p1, o}, {s2, p2, triple_pattern}) when is_triple(triple_pattern) do
    if bindings = match_triple({s1, p1, "solved"}, {s2, p2, "solved"}) do
      if nested_bindings = match_triple(o, triple_pattern) do
        Map.merge(bindings, nested_bindings)
      end
    end
  end

  def match_triple({s, p, o}, {var1, var2, o}) when is_atom(var1) and is_atom(var2),
    do: %{var1 => s, var2 => p}

  def match_triple({s, p, o}, {var1, p, var2}) when is_atom(var1) and is_atom(var2),
    do: %{var1 => s, var2 => o}

  def match_triple({s, p, o}, {s, var1, var2}) when is_atom(var1) and is_atom(var2),
    do: %{var1 => p, var2 => o}

  def match_triple({s, p, o}, {var1, var2, var3})
      when is_atom(var1) and is_atom(var2) and is_atom(var3),
      do: %{var1 => s, var2 => p, var3 => o}

  def match_triple(_, _), do: nil
end
