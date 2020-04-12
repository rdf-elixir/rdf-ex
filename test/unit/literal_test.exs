defmodule RDF.LiteralTest do
  use ExUnit.Case

  import RDF.Sigils
  import RDF.TestLiterals

  alias RDF.{Literal, LangString}
  alias RDF.Literal.{Generic, Datatype}

  doctest RDF.Literal

  alias RDF.NS

  @examples %{
    RDF.XSD.String  => ["foo"],
    RDF.XSD.Integer => [42],
    RDF.XSD.Double  => [3.14],
    RDF.XSD.Decimal => [Decimal.from_float(3.14)],
    RDF.XSD.Boolean => [true, false],
  }

  describe "new/1" do
    Enum.each @examples, fn {datatype, example_values} ->
      @tag example: %{datatype: datatype, values: example_values}
      test "coercion from #{datatype |> Module.split |> List.last |> to_string}", %{example: example} do
        Enum.each example.values, fn example_value ->
          assert Literal.new(example_value) == example.datatype.new(example_value)
          assert Literal.new!(example_value) == example.datatype.new!(example_value)
        end
      end
    end

    test "with typed literals" do
      Enum.each Datatype.Registry.datatypes() -- [RDF.LangString], fn datatype ->
        literal_type = datatype.literal_type()
        assert %Literal{literal: typed_literal} = Literal.new(literal_type.new("foo"))
        assert typed_literal.__struct__ == literal_type
      end
    end

    test "when options without datatype given" do
      assert Literal.new(true, []) == RDF.XSD.Boolean.new(true)
      assert Literal.new(42, [])   == RDF.XSD.Integer.new(42)
      assert Literal.new!(true, []) == RDF.XSD.Boolean.new!(true)
      assert Literal.new!(42, [])   == RDF.XSD.Integer.new!(42)
    end
  end

  describe "typed construction" do
    test "boolean" do
      assert Literal.new(true,    datatype: NS.XSD.boolean) == RDF.XSD.Boolean.new(true)
      assert Literal.new(false,   datatype: NS.XSD.boolean) == RDF.XSD.Boolean.new(false)
      assert Literal.new("true",  datatype: NS.XSD.boolean) == RDF.XSD.Boolean.new("true")
      assert Literal.new("false", datatype: NS.XSD.boolean) == RDF.XSD.Boolean.new("false")
    end

    test "integer" do
      assert Literal.new(42,   datatype: NS.XSD.integer) == RDF.XSD.Integer.new(42)
      assert Literal.new("42", datatype: NS.XSD.integer) == RDF.XSD.Integer.new("42")
    end

    test "double" do
      assert Literal.new(3.14,   datatype: NS.XSD.double) == RDF.XSD.Double.new(3.14)
      assert Literal.new("3.14", datatype: NS.XSD.double) == RDF.XSD.Double.new("3.14")
    end

    test "decimal" do
      assert Literal.new(3.14,   datatype: NS.XSD.decimal) == RDF.XSD.Decimal.new(3.14)
      assert Literal.new("3.14", datatype: NS.XSD.decimal) == RDF.XSD.Decimal.new("3.14")
      assert Literal.new(Decimal.from_float(3.14), datatype: NS.XSD.decimal) ==
               RDF.XSD.Decimal.new(Decimal.from_float(3.14))
    end

    test "unsignedInt" do
      assert Literal.new(42,   datatype: NS.XSD.unsignedInt) == RDF.XSD.UnsignedInt.new(42)
      assert Literal.new("42", datatype: NS.XSD.unsignedInt) == RDF.XSD.UnsignedInt.new("42")
    end

    test "string" do
      assert Literal.new("foo", datatype: NS.XSD.string) == RDF.XSD.String.new("foo")
    end

    test "unmapped/unknown datatype" do
      assert Literal.new("custom typed value", datatype: "http://example/dt") ==
               Generic.new("custom typed value", datatype: "http://example/dt")
    end
  end

  describe "language tagged construction" do
    test "string literal with a language tag" do
      assert Literal.new("Eule", language: "de") == LangString.new("Eule", language: "de")
      assert Literal.new!("Eule", language: "de") == LangString.new!("Eule", language: "de")
    end

    test "non-string literals with a language tag" do
      assert Literal.new(1, language: "de") == LangString.new(1, language: "de")
      assert Literal.new!(1, language: "de") == LangString.new!(1, language: "de")
    end

    test "construction of an other than rdf:langString typed and language-tagged literal fails" do
      assert Literal.new("Eule", datatype: RDF.langString, language: "de") ==
               LangString.new("Eule", language: "de")
      assert_raise ArgumentError, fn ->
        Literal.new("Eule", datatype: NS.XSD.string, language: "de")
      end
    end

    test "construction of a rdf:langString works, but results in an invalid literal" do
      assert Literal.new("Eule", datatype: RDF.langString) == LangString.new("Eule", [])
      assert_raise RDF.Literal.InvalidError, fn ->
        Literal.new!("Eule", datatype: RDF.langString)
      end
    end
  end

  describe "has_datatype?" do
    Enum.each literals(~W[all_simple all_plain_lang]a), fn literal ->
      @tag literal: literal
      test "#{inspect literal} has no datatype", %{literal: literal} do
        refute Literal.has_datatype?(literal)
      end
    end

    Enum.each literals(:all) -- literals(~W[all_simple all_plain_lang]a), fn literal ->
      @tag literal: literal
      test "Literal for #{inspect literal} has a datatype", %{literal: literal} do
        assert Literal.has_datatype?(literal)
      end
    end
  end

  describe "plain?" do
    Enum.each literals(:all_plain), fn literal ->
      @tag literal: literal
      test "#{inspect literal} is plain", %{literal: literal} do
        assert Literal.plain?(literal)
      end
    end
    Enum.each literals(:all) -- literals(:all_plain), fn literal ->
      @tag literal: literal
      test "Literal for #{inspect literal} is not plain", %{literal: literal} do
        refute Literal.plain?(literal)
      end
    end
  end

  describe "simple?" do
    Enum.each literals(:all_simple), fn literal ->
      @tag literal: literal
      test "#{inspect literal} is simple", %{literal: literal} do
        assert Literal.simple?(literal)
      end
    end
    Enum.each literals(:all) -- literals(:all_simple), fn literal ->
      @tag literal: literal
      test "Literal for #{inspect literal} is not simple", %{literal: literal} do
        refute Literal.simple?(literal)
      end
    end
  end

  describe "datatype/1" do
    Enum.each literals(:all_simple), fn literal ->
      @tag literal: literal
      test "simple literal #{inspect literal} has datatype xsd:string", %{literal: literal} do
        assert Literal.datatype(literal) == NS.XSD.string
      end
    end

    %{
        123 => "integer",
        true => "boolean",
        false => "boolean",
        9223372036854775807 => "integer",
        3.1415 => "double",
        ~D[2017-04-13] => "date",
        ~N[2017-04-14 15:32:07] => "dateTime",
        ~T[01:02:03] => "time"
    }
    |> Enum.each(fn {value, type} ->
         @tag data: %{literal: literal = Literal.new(value), type: type}
         test "Literal for #{inspect literal} has datatype xsd:#{type}",
              %{data: %{literal: literal, type: type}} do
           assert Literal.datatype(literal) == apply(NS.XSD, String.to_atom(type), [])
         end
       end)
  end

  describe "language" do
    Enum.each literals(:all_plain_lang), fn literal ->
      @tag literal: literal
      test "#{inspect literal} has correct language", %{literal: literal} do
        assert Literal.language(literal) == "en"
      end
    end
    Enum.each literals(:all) -- literals(:all_plain_lang), fn literal ->
      @tag literal: literal
      test "Literal for #{inspect literal} has no language", %{literal: literal} do
        assert is_nil(Literal.language(literal))
      end
    end

    test "with RDF.LangString literal" do
      assert Literal.new("Upper", language: "en") |> Literal.language() == "en"
      assert Literal.new("Upper", language: "EN") |> Literal.language() == "en"
      assert Literal.new("Upper", language: "") |> Literal.language() == nil
      assert Literal.new("Upper", language: nil) |> Literal.language() == nil
    end
  end

  describe "value/1" do
    test "with XSD.Datatype literal" do
      assert Literal.new("foo") |> Literal.value() == "foo"
      assert Literal.new(42) |> Literal.value() == 42
    end

    test "with RDF.LangString literal" do
      assert Literal.new("foo", language: "en") |> Literal.value() == "foo"
    end

    test "with generic literal" do
      assert Literal.new("foo", datatype: "http://example.com/dt") |> Literal.value() == "foo"
    end
  end

  describe "lexical/1" do
    test "with XSD.Datatype literal" do
      assert Literal.new("foo") |> Literal.lexical() == "foo"
      assert Literal.new(42) |> Literal.lexical() == "42"
    end

    test "with RDF.LangString literal" do
      assert Literal.new("foo", language: "en") |> Literal.lexical() == "foo"
    end

    test "with generic literal" do
      assert Literal.new("foo", datatype: "http://example.com/dt") |> Literal.lexical() == "foo"
    end
  end

  describe "canonical/1" do
    test "with XSD.Datatype literal" do
      [
        RDF.XSD.String.new("foo"),
        RDF.XSD.Byte.new(42),

      ]
      |> Enum.each(fn
        canonical_literal ->
          assert Literal.canonical(canonical_literal) == canonical_literal
      end)
      assert RDF.XSD.Integer.new("042") |> Literal.canonical() == Literal.new(42)
      assert Literal.new(3.14) |> Literal.canonical() == Literal.new(3.14) |> RDF.XSD.Double.canonical()
    end

    test "with RDF.LangString literal" do
      assert Literal.new("foo", language: "en") |> Literal.canonical() ==
               Literal.new("foo", language: "en")
    end

    test "with generic literal" do
      assert Literal.new("foo", datatype: "http://example.com/dt") |> Literal.canonical() ==
               Literal.new("foo", datatype: "http://example.com/dt")
    end
  end

  describe "canonical?/1" do
    test "with XSD.Datatype literal" do
      assert Literal.new("foo") |> Literal.canonical?() == true
      assert Literal.new(42) |> Literal.canonical?() == true
      assert Literal.new(3.14) |> Literal.canonical?() == false
    end

    test "with RDF.LangString literal" do
      assert Literal.new("foo", language: "en") |> Literal.canonical?() == true
    end

    test "with generic literal" do
      assert Literal.new("foo", datatype: "http://example.com/dt") |> Literal.canonical?() == true
    end
  end

  describe "validation" do
    test "with XSD.Datatype literal" do
      assert Literal.new("foo") |> Literal.valid?() == true
      assert Literal.new(42) |> Literal.valid?() == true
      assert RDF.XSD.Integer.new("foo") |> Literal.valid?() == false
    end

    test "with RDF.LangString literal" do
      assert Literal.new("foo", language: "en") |> Literal.valid?() == true
    end

    test "with generic literal" do
      assert Literal.new("foo", datatype: "http://example.com/dt") |> Literal.valid?() == true
      assert Literal.new("foo", datatype: "") |> Literal.valid?() == false
    end
  end

  describe "equal_value?/2" do
    test "with XSD.Datatype literal" do
      assert Literal.equal_value?(Literal.new("foo"), Literal.new("foo")) == true
      assert Literal.equal_value?(Literal.new(42), RDF.XSD.Byte.new(42)) == true
      assert Literal.equal_value?(Literal.new("foo"), "foo") == true
      assert Literal.equal_value?(Literal.new(42), 42) == true
      assert Literal.equal_value?(Literal.new(42), 42.0) == true
      assert Literal.equal_value?(Literal.new(false), false) == true
      assert Literal.equal_value?(Literal.new(false), true) == false
    end

    test "with RDF.LangString literal" do
      assert Literal.equal_value?(Literal.new("foo", language: "en"),
                                  Literal.new("foo", language: "en")) == true
      assert Literal.equal_value?(Literal.new("foo", language: "en"), Literal.new("foo")) == false
    end

    test "with generic literal" do
      assert Literal.equal_value?(Literal.new("foo", datatype: "http://example.com/dt"),
                                  Literal.new("foo", datatype: "http://example.com/dt")) == true
      assert Literal.equal_value?(Literal.new("foo", datatype: "http://example.com/dt"),
                                  Literal.new("foo")) == false
    end
  end

  describe "compare/2" do
    test "with XSD.Datatype literal" do
      assert Literal.compare(Literal.new("foo"), Literal.new("bar")) == :gt
      assert Literal.compare(Literal.new(42), RDF.XSD.Byte.new(43)) == :lt
    end

    test "with RDF.LangString literal" do
      assert Literal.compare(Literal.new("foo", language: "en"),
                             Literal.new("bar", language: "en")) == :gt
    end

    test "with generic literal" do
      assert Literal.compare(Literal.new("foo", datatype: "http://example.com/dt"),
               Literal.new("bar", datatype: "http://example.com/dt")) == :gt
    end
  end

  @poem RDF.XSD.String.new """
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
        {~L"abracadabra", ~L"bra",    true},
        {~L"abracadabra", ~L"^a.*a$", true},
        {~L"abracadabra", ~L"^bra",   false},
        {@poem, ~L"Kaum.*krähen",     false},
        {@poem, ~L"^Kaum.*gesehen,$", false},
        {~L"foobar", ~L"foo$",        false},

        {~L"noe\u0308l", ~L"noe\\u0308l", true},
        {~L"noe\\u0308l", ~L"noe\\\\u0308l", true},
        {~L"\u{01D4B8}", ~L"\\U0001D4B8", true},
        {~L"\\U0001D4B8", ~L"\\\U0001D4B8", true},

        {~L"abracadabra"en, ~L"bra", true},
        {"abracadabra", "bra",       true},
        {RDF.XSD.Integer.new("42"), ~L"4",   true},
        {RDF.XSD.Integer.new("42"), ~L"en",  false},
      ]
      |> Enum.each(fn {literal, pattern, expected_result} ->
        result = Literal.matches?(literal, pattern)
        assert result == expected_result,
               "expected RDF.Literal.matches?(#{inspect literal}, #{inspect pattern}) to return #{inspect expected_result}, but got #{result}"
      end)
    end

    test "with flags" do
      [
        {@poem, ~L"Kaum.*krähen",     ~L"s", true},
        {@poem, ~L"^Kaum.*gesehen,$", ~L"m", true},
        {@poem, ~L"kiki",             ~L"i", true},
      ]
      |> Enum.each(fn {literal, pattern, flags, result} ->
        assert Literal.matches?(literal, pattern, flags) == result
      end)
    end

    test "with q flag" do
      [
        {~L"abcd",         ~L".*",       ~L"q",  false},
        {~L"Mr. B. Obama", ~L"B. OBAMA", ~L"iq", true},

        # If the q flag is used together with the m, s, or x flag, that flag has no effect.
        {~L"abcd",         ~L".*",       ~L"mq",   true},
        {~L"abcd",         ~L".*",       ~L"qim",  true},
        {~L"abcd",         ~L".*",       ~L"xqm",  true},
      ]
      |> Enum.each(fn {literal, pattern, flags, result} ->
        assert Literal.matches?(literal, pattern, flags) == result
      end)
    end
  end

  describe "String.Chars protocol implementation" do
    test "with XSD.Datatype literal" do
      assert Literal.new("foo") |> to_string() == "foo"
      assert Literal.new(42) |> to_string() == "42"
      assert RDF.XSD.Integer.new("foo") |> to_string() == "foo"
    end

    test "with RDF.LangString literal" do
      assert Literal.new("foo", language: "en") |> to_string() == "foo"
    end

    test "with generic literal" do
      assert Literal.new("foo", datatype: "http://example.com/dt") |> to_string() == "foo"
      assert Literal.new("foo", datatype: "") |> to_string() == "foo"
    end
  end
end
