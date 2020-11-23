defmodule RDF.Serialization.ParseHelperTest do
  use ExUnit.Case, async: false

  alias RDF.Serialization.ParseHelper

  @unicode_seq_4digit %{
    ~S"\u0020" => " ",
    ~S"<ab\u00E9xy>" => "<ab\xC3\xA9xy>",
    ~S"\u03B1:a" => "\xCE\xB1:a",
    ~S"a\u003Ab" => "a\x3Ab"
  }

  @unicode_seq_8digit %{
    ~S"\U00000020" => " ",
    ~S"\U00010000" => "\xF0\x90\x80\x80",
    ~S"\U000EFFFF" => "\xF3\xAF\xBF\xBF"
  }

  describe "string escaping" do
    test "unescaping of \\uXXXX codepoint escape sequences" do
      Enum.each(@unicode_seq_4digit, fn {input, output} ->
        assert ParseHelper.string_unescape(input) == output
      end)
    end

    test "unescaping of \\UXXXXXXXX codepoint escape sequences" do
      Enum.each(@unicode_seq_8digit, fn {input, output} ->
        assert ParseHelper.string_unescape(input) == output
      end)
    end
  end

  describe "IRI escaping" do
    test "unescaping of \\uXXXX codepoint escape sequences" do
      Enum.each(@unicode_seq_4digit, fn {input, output} ->
        assert ParseHelper.iri_unescape(input) == output
      end)
    end

    test "unescaping of \\UXXXXXXXX codepoint escape sequences" do
      Enum.each(@unicode_seq_8digit, fn {input, output} ->
        assert ParseHelper.iri_unescape(input) == output
      end)
    end
  end
end
