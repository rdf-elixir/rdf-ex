defmodule RDF.Utils.Regex do
  @moduledoc """
  Drop-in replacements for Elixir `Regex` functions.

  Elixir does a check on every run of a compiled regex, to check if the PCRE
  version of the regex matches the version that the local OTP version got
  compiled against. This check seems to be unexpectedly costly (there is a call
  though to `:erlang.system_info/1`). Since regular expression evaluation is
  critical performance-wise in RDF.ex, especially during deserialization, all
  regular expressions are evaluated through the functions in this module which
  can be configured with the `optimize_regexes` key in the compile-time application
  environment to circumvent Elixir and call through to Erlang `re` directly:

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
