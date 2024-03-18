defmodule RDF.Utils.Regex do
  @moduledoc """
  Drop-in replacements for Elixir `Regex` functions.

  In Elixir, each execution of a compiled regex includes a verification step to
  ensure the PCRE version of the regex is compatible with the version compiled
  with the local OTP. While this verification introduces a slight overhead, the
  cumulative effect can be significant, particularly since evaluating regular
  expressions is crucial for performance in RDF.ex. This is especially notable
  during deserialization, where regular expression are evaluated in quite tight
  loops.

  All regular expressions are evaluated in RDF.ex through the functions in this
  module which can be configured with the `optimize_regexes` key in the
  compile-time application environment to circumvent Elixir and call through to
  Erlang `re` directly:

      config :rdf,
        optimize_regexes: true

  By default this optimization is disabled and should be enabled only if your
  application is running in a controlled environment.
  """

  if Application.compile_env(:rdf, :optimize_regexes, false) do
    @doc """
    Drop-in replacement for `Regex.run/2` using Erlang `re` directly.
    """
    @spec run(Regex.t(), String.t()) :: nil | [binary]
    def run(%Regex{re_pattern: pattern}, string) do
      case :re.run(string, pattern, [{:capture, :all, :binary}]) do
        {:match, matches} -> matches
        :nomatch -> nil
        :match -> []
      end
    end

    @doc """
    Drop-in replacement for `Regex.match?/2` using Erlang `re` directly.
    """
    @spec match?(Regex.t(), String.t()) :: boolean
    def match?(%Regex{re_pattern: pattern}, string) do
      :re.run(string, pattern, [{:capture, :none}]) == :match
    end
  else
    defdelegate run(regex, string), to: Regex
    defdelegate match?(regex, string), to: Regex
  end
end
