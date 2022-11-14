defmodule RDF.XSD.Utils.RegexTest do
  use ExUnit.Case

  alias RDF.XSD.Utils.Regex

  @poem """
  <poem author="Wilhelm Busch">
  Kaum hat dies der Hahn gesehen,
  Fängt er auch schon an zu krähen:
  Kikeriki! Kikikerikih!!
  Tak, tak, tak! - da kommen sie.
  </poem>
  """

  describe "matches?" do
    test "without flags" do
      [
        {"abracadabra", "bra", true},
        {"abracadabra", "^a.*a$", true},
        {"abracadabra", "^bra", false},
        {@poem, "Kaum.*krähen", false},
        {@poem, "^Kaum.*gesehen,$", false},
        {"foobar", "foo$", false},
        {~S"noe\u0308l", ~S"noe\\u0308l", true},
        {~S"noe\\u0308l", ~S"noe\\\\u0308l", true},
        {~S"\u{01D4B8}", ~S"\\U0001D4B8", true},
        {~S"\\U0001D4B8", ~S"\\\U0001D4B8", true},
        {42, "4", true},
        {42, "en", false}
      ]
      |> Enum.each(fn {literal, pattern, expected_result} ->
        result = Regex.matches?(literal, pattern)

        assert result == expected_result,
               "expected XSD.Regex.matches?(#{inspect(literal)}, #{inspect(pattern)}) to return #{inspect(expected_result)}, but got #{result}"
      end)
    end

    test "with flags" do
      [
        {@poem, "Kaum.*krähen", "s", true},
        {@poem, "^Kaum.*gesehen,$", "m", true},
        {@poem, "kiki", "i", true}
      ]
      |> Enum.each(fn {literal, pattern, flags, result} ->
        assert Regex.matches?(literal, pattern, flags) == result
      end)
    end

    test "with q flag" do
      [
        {"abcd", ".*", "q", false},
        {"Mr. B. Obama", "B. OBAMA", "iq", true},

        # If the q flag is used together with the m, s, or x flag, that flag has no effect.
        {"abcd", ".*", "mq", true},
        {"abcd", ".*", "qim", true},
        {"abcd", ".*", "xqm", true}
      ]
      |> Enum.each(fn {literal, pattern, flags, result} ->
        assert Regex.matches?(literal, pattern, flags) == result
      end)
    end
  end
end
