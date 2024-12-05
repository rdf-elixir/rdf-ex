defmodule RDF.Graph.Builder do
  @moduledoc false

  alias RDF.{Description, Graph, Dataset, PrefixMap, IRI, Vocabulary}

  defmodule Error do
    defexception [:message]
  end

  defmodule Helper do
    @moduledoc !"Functions which are auto-imported in every `RDF.Graph.Builder` block"

    defdelegate a(), to: RDF.NS.RDF, as: :type
    defdelegate a(s, o), to: RDF.NS.RDF, as: :type

    def exclude(_), do: nil
  end

  def build(do_block, env, bindings, opts) do
    build(do_block, env, builder_mod(env), bindings, opts)
  end

  def build({:__block__, _, block}, env, builder_mod, bindings, opts) do
    env_aliases = env_aliases(env)
    block = expand_aliased_modules(block, env_aliases)
    {bindings_vars, bindings_pattern} = bindings_vars(bindings, builder_mod)
    block = bind_vars(block, bindings_vars, builder_mod)
    non_strict_ns = extract_non_strict_ns(block)
    {declarations, data} = Enum.split_with(block, &declaration?/1)
    {base, declarations} = extract_base(declarations)
    base_string = base_string(base)
    data = resolve_relative_iris(data, base_string)
    declarations = resolve_relative_iris(declarations, base_string)
    {prefixes, ad_hoc_ns, declarations} = extract_prefixes(declarations, builder_mod, env)
    non_strict_ns = (non_strict_ns ++ ad_hoc_ns) |> Enum.uniq()

    mod_body =
      quote do
        for mod <- unquote(non_strict_ns) do
          @compile {:no_warn_undefined, mod}
        end

        def build(unquote(bindings_pattern), opts) do
          alias RDF.XSD
          alias RDF.NS.{RDFS, OWL}

          import RDF.Sigils
          import Helper

          unquote(declarations)

          RDF.Graph.Builder.do_build(
            unquote(data),
            opts,
            unquote(prefixes),
            unquote(base_string)
          )
        end
      end

    Module.create(builder_mod, mod_body, Macro.Env.location(env))

    quote do
      apply(unquote(builder_mod), :build, [Map.new(unquote(bindings)), unquote(opts)])
    end
  end

  def build(single, env, builder_mod, bindings, opts) do
    build({:__block__, [], List.wrap(single)}, env, builder_mod, bindings, opts)
  end

  @doc false
  def do_build(data, opts, prefixes, base) do
    Graph.new(graph_opts(opts, prefixes, base))
    |> Graph.add(Enum.filter(data, &rdf?/1))
  end

  def builder_mod(env) do
    Module.concat(env.module, "GraphBuilder#{random_number()}")
  end

  defp graph_opts(opts, prefixes, base) do
    opts
    |> set_base_opt(base)
    |> set_prefix_opt(prefixes)
  end

  defp set_base_opt(opts, nil), do: opts
  defp set_base_opt(opts, base), do: Keyword.put(opts, :base_iri, base)

  defp set_prefix_opt(opts, []), do: opts

  defp set_prefix_opt(opts, prefixes) do
    Keyword.update(opts, :prefixes, RDF.default_prefixes(prefixes), fn opt_prefixes ->
      PrefixMap.new(prefixes)
      |> PrefixMap.merge!(opt_prefixes, :ignore)
    end)
  end

  defp base_string(nil), do: nil
  defp base_string(base) when is_binary(base), do: base
  defp base_string(base) when is_atom(base), do: apply(base, :__base_iri__, [])
  defp base_string({:sigil_I, _, [{_, _, [base]}, _]}), do: base

  defp base_string(_) do
    raise Error,
      message: "invalid @base expression; only literal values are allowed as @base value"
  end

  defp resolve_relative_iris(ast, base) do
    Macro.prewalk(ast, fn
      {:sigil_I, meta_outer, [{:<<>>, meta_inner, [iri]}, list]} = sigil ->
        if IRI.absolute?(iri) do
          sigil
        else
          absolute = iri |> IRI.absolute(base) |> IRI.to_string()
          {:sigil_I, meta_outer, [{:<<>>, meta_inner, [absolute]}, list]}
        end

      other ->
        other
    end)
  end

  defp extract_base(declarations) do
    {base, declarations} =
      Enum.reduce(declarations, {nil, []}, fn
        {:@, line, [{:base, _, [{:__aliases__, _, ns}] = aliases}]}, {_, declarations} ->
          {Module.concat(ns), [{:alias, line, aliases} | declarations]}

        {:@, _, [{:base, _, [base]}]}, {_, declarations} ->
          {base, declarations}

        declaration, {base, declarations} ->
          {base, [declaration | declarations]}
      end)

    {base, Enum.reverse(declarations)}
  end

  defp extract_prefixes(declarations, builder_mod, env) do
    {prefixes, ad_hoc_ns, declarations} =
      Enum.reduce(declarations, {[], [], []}, fn
        {:@, line, [{:prefix, _, [{:__aliases__, _, ns}] = aliases}]},
        {prefixes, ad_hoc_ns, declarations} ->
          {
            [prefix(ns) | prefixes],
            ad_hoc_ns,
            [{:alias, line, aliases} | declarations]
          }

        {:@, line, [{:prefix, _, [[{prefix, {:__aliases__, _, ns} = aliases}]]}]},
        {prefixes, ad_hoc_ns, declarations} ->
          {
            [prefix(prefix, ns) | prefixes],
            ad_hoc_ns,
            [{:alias, line, [aliases]} | declarations]
          }

        {:@, line, [{:prefix, _, [[{prefix, uri}]]}]}, {prefixes, ad_hoc_ns, declarations}
        when is_binary(uri) ->
          ns = ad_hoc_namespace(prefix, uri, builder_mod, env)

          {
            [prefix(prefix, ns) | prefixes],
            [Module.concat(ns) | ad_hoc_ns],
            [{:alias, line, [{:__aliases__, line, ns}]} | declarations]
          }

        {:@, _, [{:prefix, _, _}]} = expr, _ ->
          raise Error, "invalid @prefix expression:\n\t#{Macro.to_string(expr)}"

        declaration, {prefixes, ad_hoc_ns, declarations} ->
          {prefixes, ad_hoc_ns, [declaration | declarations]}
      end)

    {prefixes, ad_hoc_ns, Enum.reverse(declarations)}
  end

  defp prefix(namespace) do
    namespace
    |> determine_prefix()
    |> prefix(namespace)
  end

  defp prefix(prefix, namespace) do
    {prefix, Module.concat(namespace)}
  end

  defp determine_prefix(namespace) do
    namespace
    |> Enum.reverse()
    |> hd()
    |> to_string()
    |> Macro.underscore()
    |> String.to_atom()
  end

  defp ad_hoc_namespace(prefix, uri, builder_mod, env) do
    {:module, module, _, _} =
      builder_mod
      |> Module.concat(prefix |> Atom.to_string() |> Macro.camelize())
      |> Vocabulary.Namespace.create!(uri, [], env, strict: false)

    module |> Module.split() |> Enum.map(&String.to_atom/1)
  end

  defp declaration?({:=, _, _}), do: true
  defp declaration?({:@, _, [{:prefix, _, _}]}), do: true
  defp declaration?({:@, _, [{:base, _, _}]}), do: true
  defp declaration?({:alias, _, _}), do: true
  defp declaration?({:import, _, _}), do: true
  defp declaration?({:require, _, _}), do: true
  defp declaration?({:use, _, _}), do: true
  defp declaration?(_), do: false

  defp rdf?(nil), do: false
  defp rdf?(:ok), do: false
  defp rdf?(%Description{}), do: true
  defp rdf?(%Graph{}), do: true
  defp rdf?(%Dataset{}), do: true
  defp rdf?(statements) when is_map(statements), do: true
  defp rdf?(statements) when is_tuple(statements), do: true
  defp rdf?(list) when is_list(list), do: true

  defp rdf?(invalid) do
    raise Error, message: "invalid RDF data: #{inspect(invalid)}"
  end

  defp expand_aliased_modules(ast, env_aliases) do
    Macro.prewalk(ast, fn
      {:__aliases__, [alias: false], _} = alias ->
        alias

      {:__aliases__, _, module} ->
        {:__aliases__, [alias: false], expand_module(module, env_aliases)}

      other ->
        other
    end)
  end

  defp expand_module([first | rest] = module, env_aliases) do
    if full = env_aliases[first] do
      full ++ rest
    else
      module
    end
  end

  defp bindings_vars(bindings, mod) do
    vars = Enum.map(bindings, fn {key, _} -> key end)

    {vars, {:%{}, [], Enum.map(vars, &{&1, Macro.var(&1, mod)})}}
  end

  defp bind_vars(block, bindings_vars, mod) do
    Macro.prewalk(block, fn
      {var, line, nil} = expr -> if var in bindings_vars, do: {var, line, mod}, else: expr
      other -> other
    end)
  end

  defp env_aliases(env) do
    Map.new(env.aliases, fn {short, full} ->
      {
        module_to_atom_without_elixir_prefix(short),
        full |> Module.split() |> Enum.map(&String.to_atom/1)
      }
    end)
  end

  defp module_to_atom_without_elixir_prefix(module) do
    [short] = Module.split(module)
    String.to_atom(short)
  end

  defp extract_non_strict_ns(block) do
    modules =
      block
      |> Macro.prewalker()
      |> Enum.reduce([], fn
        {:__aliases__, _, mod}, modules -> [Module.concat(mod) | modules]
        _, modules -> modules
      end)
      |> Enum.uniq()

    for module <- modules, non_strict_vocab_namespace?(module), do: module
  end

  defp non_strict_vocab_namespace?(mod) do
    Vocabulary.Namespace.vocabulary_namespace?(mod) and not mod.__strict__()
  end

  defp random_number do
    :erlang.unique_integer([:positive])
  end
end
