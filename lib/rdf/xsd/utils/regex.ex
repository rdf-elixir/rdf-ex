defmodule RDF.XSD.Utils.Regex do
  @moduledoc !"""
             XSD-flavoured regex matching.

             This is not intended to be used directly.
             Use `c:RDF.XSD.Datatype.matches?/3` implementations on the datatypes or
             `RDF.Literal.matches?/3` instead.
             """

  @doc """
  Matches the string representation of the given value against a XPath and XQuery regular expression pattern.

  The regular expression language is defined in _XQuery 1.0 and XPath 2.0 Functions and Operators_.

  see <https://www.w3.org/TR/xpath-functions/#func-matches>
  """
  @spec matches?(String.t(), String.t(), String.t()) :: boolean
  def matches?(value, pattern, flags \\ "") do
    string = to_string(value)

    case xpath_pattern(pattern, flags) do
      {:regex, regex} ->
        RDF.Utils.Regex.match?(regex, string)

      {:q, pattern} ->
        String.contains?(string, pattern)

      {:qi, pattern} ->
        string
        |> String.downcase()
        |> String.contains?(String.downcase(pattern))

      {:error, error} ->
        raise "Invalid XQuery regex pattern or flags: #{inspect(error)}"
    end
  end

  @spec xpath_pattern(String.t(), String.t()) ::
          {:q | :qi, String.t()} | {:regex, Regex.t()} | {:error, any}
  def xpath_pattern(pattern, flags)

  def xpath_pattern(pattern, flags) when is_binary(pattern) and is_binary(flags) do
    q_pattern(pattern, flags) || xpath_regex_pattern(pattern, flags)
  end

  defp q_pattern(pattern, flags) do
    if String.contains?(flags, "q") and String.replace(flags, ~r/[qi]/, "") == "" do
      {if(String.contains?(flags, "i"), do: :qi, else: :q), pattern}
    end
  end

  defp xpath_regex_pattern(pattern, flags) do
    with {:ok, regex} <-
           pattern
           |> convert_utf_escaping()
           |> Regex.compile(xpath_regex_flags(flags)) do
      {:regex, regex}
    end
  end

  @spec convert_utf_escaping(String.t()) :: String.t()
  def convert_utf_escaping(string) do
    require Integer

    xpath_unicode_regex = ~r/(\\*)\\U([0-9]|[A-F]|[a-f]){2}(([0-9]|[A-F]|[a-f]){6})/
    [first | possible_matches] = Regex.split(xpath_unicode_regex, string, include_captures: true)

    [
      first
      | Enum.map_every(possible_matches, 2, fn possible_xpath_unicode ->
          [_, escapes, _, codepoint, _] =
            RDF.Utils.Regex.run(xpath_unicode_regex, possible_xpath_unicode)

          if escapes |> String.length() |> Integer.is_odd() do
            "#{escapes}\\u{#{codepoint}}"
          else
            "\\" <> possible_xpath_unicode
          end
        end)
    ]
    |> Enum.join()
  end

  defp xpath_regex_flags(flags) do
    String.replace(flags, "q", "") <> "u"
  end
end
