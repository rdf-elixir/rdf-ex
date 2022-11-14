defmodule RDF.LiteralTest do
  use RDF.Test.Case

  import RDF.TestLiterals

  alias RDF.{Literal, XSD, LangString}
  alias RDF.Literal.{Generic, Datatype}
  alias Decimal, as: D

  # Elixir 1.14 changed the order of inspect strings of structs, so,
  # the literals in error strings
  if Version.match?(System.version(), ">= 1.14.0") do
    doctest RDF.Literal
  end

  alias RDF.NS

  @examples %{
    XSD.String => ["foo"],
    XSD.Integer => [42],
    XSD.Double => [3.14],
    XSD.Decimal => [Decimal.from_float(3.14)],
    XSD.Boolean => [true, false]
  }

  describe "new/1" do
    Enum.each(@examples, fn {datatype, example_values} ->
      @tag example: %{datatype: datatype, values: example_values}
      test "coercion from #{datatype |> Module.split() |> List.last() |> to_string}", %{
        example: example
      } do
        Enum.each(example.values, fn example_value ->
          assert Literal.new(example_value) == example.datatype.new(example_value)
          assert Literal.new!(example_value) == example.datatype.new!(example_value)
        end)
      end
    end)

    test "with builtin datatype literals" do
      Enum.each(Datatype.Registry.builtin_datatypes(), fn datatype ->
        datatype_literal = datatype.new("foo").literal
        assert %Literal{literal: ^datatype_literal} = Literal.new(datatype_literal)
      end)
    end

    test "with custom datatype literals" do
      datatype_literal = RDF.TestDatatypes.Age.new(42).literal
      assert %Literal{literal: ^datatype_literal} = Literal.new(datatype_literal)
    end

    test "when options without datatype given" do
      assert Literal.new(true, []) == XSD.Boolean.new(true)
      assert Literal.new(42, []) == XSD.Integer.new(42)
      assert Literal.new!(true, []) == XSD.Boolean.new!(true)
      assert Literal.new!(42, []) == XSD.Integer.new!(42)
    end
  end

  describe "typed construction" do
    test "boolean" do
      assert Literal.new(true, datatype: NS.XSD.boolean()) == XSD.Boolean.new(true)
      assert Literal.new(false, datatype: NS.XSD.boolean()) == XSD.Boolean.new(false)
      assert Literal.new("true", datatype: NS.XSD.boolean()) == XSD.Boolean.new("true")
      assert Literal.new("false", datatype: NS.XSD.boolean()) == XSD.Boolean.new("false")
    end

    test "integer" do
      assert Literal.new(42, datatype: NS.XSD.integer()) == XSD.Integer.new(42)
      assert Literal.new("42", datatype: NS.XSD.integer()) == XSD.Integer.new("42")
    end

    test "double" do
      assert Literal.new(3.14, datatype: NS.XSD.double()) == XSD.Double.new(3.14)
      assert Literal.new("3.14", datatype: NS.XSD.double()) == XSD.Double.new("3.14")
    end

    test "decimal" do
      assert Literal.new(3.14, datatype: NS.XSD.decimal()) == XSD.Decimal.new(3.14)
      assert Literal.new("3.14", datatype: NS.XSD.decimal()) == XSD.Decimal.new("3.14")

      assert Literal.new(Decimal.from_float(3.14), datatype: NS.XSD.decimal()) ==
               XSD.Decimal.new(Decimal.from_float(3.14))
    end

    test "unsignedInt" do
      assert Literal.new(42, datatype: NS.XSD.unsignedInt()) == XSD.UnsignedInt.new(42)
      assert Literal.new("42", datatype: NS.XSD.unsignedInt()) == XSD.UnsignedInt.new("42")
    end

    test "string" do
      assert Literal.new("foo", datatype: NS.XSD.string()) == XSD.String.new("foo")
    end

    test "registered custom datatype" do
      assert Literal.new(42, datatype: EX.Age) == RDF.TestDatatypes.Age.new(42)
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
      assert Literal.new("Eule", datatype: RDF.langString(), language: "de") ==
               LangString.new("Eule", language: "de")

      assert_raise ArgumentError, fn ->
        Literal.new("Eule", datatype: NS.XSD.string(), language: "de")
      end
    end

    test "construction of a rdf:langString works, but results in an invalid literal" do
      assert Literal.new("Eule", datatype: RDF.langString()) == LangString.new("Eule", [])

      assert_raise RDF.Literal.InvalidError, fn ->
        Literal.new!("Eule", datatype: RDF.langString())
      end
    end
  end

  describe "coerce/1" do
    test "with boolean" do
      assert Literal.coerce(true) == XSD.true()
      assert Literal.coerce(false) == XSD.false()
    end

    test "with string" do
      assert Literal.coerce("foo") == XSD.string("foo")
    end

    test "with integer" do
      assert Literal.coerce(42) == XSD.integer(42)
    end

    test "with float" do
      assert Literal.coerce(3.14) == XSD.double(3.14)
    end

    test "with decimal" do
      assert D.from_float(3.14) |> Literal.coerce() == XSD.decimal(3.14)
    end

    test "with datetime" do
      assert DateTime.from_iso8601("2002-04-02T12:00:00+00:00") |> elem(1) |> Literal.coerce() ==
               DateTime.from_iso8601("2002-04-02T12:00:00+00:00") |> elem(1) |> XSD.datetime()
    end

    test "with naive datetime" do
      assert ~N"2002-04-02T12:00:00" |> Literal.coerce() ==
               ~N"2002-04-02T12:00:00" |> XSD.datetime()
    end

    test "with date" do
      assert ~D"2002-04-02" |> Literal.coerce() ==
               ~D"2002-04-02" |> XSD.date()
    end

    test "with time" do
      assert ~T"12:00:00" |> Literal.coerce() ==
               ~T"12:00:00" |> XSD.time()
    end

    test "with URI" do
      assert URI.parse("http://example.com") |> Literal.coerce() ==
               XSD.any_uri("http://example.com")
    end

    test "with a resolvable vocabulary namespace term atom" do
      assert Literal.coerce(EX.Foo) == EX.Foo |> RDF.iri() |> IRI.parse() |> XSD.any_uri()
    end

    test "with a non-resolvable atom" do
      refute Literal.coerce(Foo)
      refute Literal.coerce(:foo)
    end

    test "with RDF.Literals" do
      assert XSD.integer(42) |> Literal.coerce() == XSD.integer(42)
    end

    test "with RDF datatype Literals" do
      assert %XSD.Integer{value: 42} |> Literal.coerce() == XSD.integer(42)
    end

    test "with inconvertible values" do
      refute Literal.coerce(nil)
      refute Literal.coerce(self())
    end
  end

  describe "is_a?/2" do
    test "with RDF.Literal.Datatype module" do
      assert ~L"foo" |> Literal.is_a?(XSD.String)
      assert ~L"foo"en |> Literal.is_a?(RDF.LangString)
      assert XSD.integer(42) |> Literal.is_a?(XSD.Integer)
      assert XSD.byte(42) |> Literal.is_a?(XSD.Integer)

      assert RDF.literal("foo", datatype: "http://example.com/dt")
             |> RDF.Literal.is_a?(RDF.Literal.Generic)

      refute XSD.float(3.14) |> Literal.is_a?(XSD.Integer)
    end

    test "with XSD.Numeric" do
      assert XSD.integer(42) |> Literal.is_a?(XSD.Numeric)
      assert XSD.byte(42) |> Literal.is_a?(XSD.Numeric)
      assert XSD.decimal(3.14) |> Literal.is_a?(XSD.Numeric)
      refute ~L"foo" |> Literal.is_a?(XSD.Numeric)
      refute ~L"foo"en |> Literal.is_a?(XSD.Numeric)
    end

    test "with XSD.Datatype" do
      assert XSD.integer(42) |> Literal.is_a?(XSD.Datatype)
      assert XSD.byte(42) |> Literal.is_a?(XSD.Datatype)
      assert XSD.decimal(3.14) |> Literal.is_a?(XSD.Datatype)
      assert ~L"foo" |> Literal.is_a?(XSD.Datatype)
      refute ~L"foo"en |> Literal.is_a?(XSD.Datatype)
    end

    test "with non-datatype modules" do
      refute ~L"foo" |> Literal.is_a?(String)
      refute ~L"foo" |> Literal.is_a?(Regex)
      refute XSD.integer(42) |> Literal.is_a?(Integer)
    end

    test "with non-literal" do
      refute "foo" |> Literal.is_a?(XSD.String)
      refute 42 |> Literal.is_a?(XSD.Numeric)
    end
  end

  describe "has_datatype?" do
    Enum.each(literals(~W[all_simple all_plain_lang]a), fn literal ->
      @tag literal: literal
      test "#{inspect(literal)} has no datatype", %{literal: literal} do
        refute Literal.has_datatype?(literal)
      end
    end)

    Enum.each(literals(:all) -- literals(~W[all_simple all_plain_lang]a), fn literal ->
      @tag literal: literal
      test "Literal for #{inspect(literal)} has a datatype", %{literal: literal} do
        assert Literal.has_datatype?(literal)
      end
    end)
  end

  describe "plain?" do
    Enum.each(literals(:all_plain), fn literal ->
      @tag literal: literal
      test "#{inspect(literal)} is plain", %{literal: literal} do
        assert Literal.plain?(literal)
      end
    end)

    Enum.each(literals(:all) -- literals(:all_plain), fn literal ->
      @tag literal: literal
      test "Literal for #{inspect(literal)} is not plain", %{literal: literal} do
        refute Literal.plain?(literal)
      end
    end)
  end

  describe "simple?" do
    Enum.each(literals(:all_simple), fn literal ->
      @tag literal: literal
      test "#{inspect(literal)} is simple", %{literal: literal} do
        assert Literal.simple?(literal)
      end
    end)

    Enum.each(literals(:all) -- literals(:all_simple), fn literal ->
      @tag literal: literal
      test "Literal for #{inspect(literal)} is not simple", %{literal: literal} do
        refute Literal.simple?(literal)
      end
    end)
  end

  describe "datatype_id/1" do
    Enum.each(literals(:all_simple), fn literal ->
      @tag literal: literal
      test "simple literal #{inspect(literal)} has datatype xsd:string", %{literal: literal} do
        assert Literal.datatype_id(literal) == NS.XSD.string()
      end
    end)

    %{
      123 => "integer",
      true => "boolean",
      false => "boolean",
      9_223_372_036_854_775_807 => "integer",
      3.1415 => "double",
      ~D[2017-04-13] => "date",
      ~N[2017-04-14 15:32:07] => "dateTime",
      ~T[01:02:03] => "time"
    }
    |> Enum.each(fn {value, type} ->
      @tag data: %{literal: literal = Literal.new(value), type: type}
      test "Literal for #{inspect(literal)} has datatype xsd:#{type}",
           %{data: %{literal: literal, type: type}} do
        assert Literal.datatype_id(literal) == apply(NS.XSD, String.to_atom(type), [])
      end
    end)
  end

  describe "language" do
    Enum.each(literals(:all_plain_lang), fn literal ->
      @tag literal: literal
      test "#{inspect(literal)} has correct language", %{literal: literal} do
        assert Literal.language(literal) == "en"
      end
    end)

    Enum.each(literals(:all) -- literals(:all_plain_lang), fn literal ->
      @tag literal: literal
      test "Literal for #{inspect(literal)} has no language", %{literal: literal} do
        assert is_nil(Literal.language(literal))
      end
    end)

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
        XSD.String.new("foo"),
        XSD.Byte.new(42)
      ]
      |> Enum.each(fn
        canonical_literal ->
          assert Literal.canonical(canonical_literal) == canonical_literal
      end)

      assert XSD.Integer.new("042") |> Literal.canonical() == Literal.new(42)

      assert Literal.new(3.14) |> Literal.canonical() ==
               Literal.new(3.14) |> XSD.Double.canonical()
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
      assert XSD.Integer.new("foo") |> Literal.valid?() == false
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
      assert Literal.equal_value?(Literal.new(42), XSD.Byte.new(42)) == true
      assert Literal.equal_value?(Literal.new("foo"), "foo") == true
      assert Literal.equal_value?(Literal.new(42), 42) == true
      assert Literal.equal_value?(Literal.new(42), 42.0) == true
      assert Literal.equal_value?(Literal.new(false), false) == true
      assert Literal.equal_value?(Literal.new(false), true) == false
    end

    test "with RDF.LangString literal" do
      assert Literal.equal_value?(
               Literal.new("foo", language: "en"),
               Literal.new("foo", language: "en")
             ) == true

      assert Literal.equal_value?(Literal.new("foo", language: "en"), Literal.new("foo")) == nil
    end

    test "with generic literal" do
      assert Literal.equal_value?(
               Literal.new("foo", datatype: "http://example.com/dt"),
               Literal.new("foo", datatype: "http://example.com/dt")
             ) == true

      assert Literal.equal_value?(
               Literal.new("foo", datatype: "http://example.com/dt"),
               Literal.new("foo")
             ) == nil
    end
  end

  describe "compare/2" do
    test "with XSD.Datatype literal" do
      assert Literal.compare(Literal.new("foo"), Literal.new("bar")) == :gt
      assert Literal.compare(Literal.new(42), XSD.Byte.new(43)) == :lt
    end

    test "with RDF.LangString literal" do
      assert Literal.compare(
               Literal.new("foo", language: "en"),
               Literal.new("bar", language: "en")
             ) == :gt
    end

    test "with generic literal" do
      assert Literal.compare(
               Literal.new("foo", datatype: "http://example.com/dt"),
               Literal.new("bar", datatype: "http://example.com/dt")
             ) == :gt
    end
  end

  @poem XSD.String.new("""
        <poem author="Wilhelm Busch">
        Kaum hat dies der Hahn gesehen,
        Fängt er auch schon an zu krähen:
        Kikeriki! Kikikerikih!!
        Tak, tak, tak! - da kommen sie.
        </poem>
        """)

  describe "matches?" do
    test "without flags" do
      [
        {~L"abracadabra", ~L"bra", true},
        {~L"abracadabra", ~L"^a.*a$", true},
        {~L"abracadabra", ~L"^bra", false},
        {@poem, ~L"Kaum.*krähen", false},
        {@poem, ~L"^Kaum.*gesehen,$", false},
        {~L"foobar", ~L"foo$", false},
        {~L"noe\u0308l", ~L"noe\\u0308l", true},
        {~L"noe\\u0308l", ~L"noe\\\\u0308l", true},
        {~L"\u{01D4B8}", ~L"\\U0001D4B8", true},
        {~L"\\U0001D4B8", ~L"\\\U0001D4B8", true},
        {~L"abracadabra"en, ~L"bra", true},
        {"abracadabra", "bra", true},
        {XSD.Integer.new("42"), ~L"4", true},
        {XSD.Integer.new("42"), ~L"en", false}
      ]
      |> Enum.each(fn {literal, pattern, expected_result} ->
        result = Literal.matches?(literal, pattern)

        assert result == expected_result,
               "expected RDF.Literal.matches?(#{inspect(literal)}, #{inspect(pattern)}) to return #{inspect(expected_result)}, but got #{result}"
      end)
    end

    test "with flags" do
      [
        {@poem, ~L"Kaum.*krähen", ~L"s", true},
        {@poem, ~L"^Kaum.*gesehen,$", ~L"m", true},
        {@poem, ~L"kiki", ~L"i", true}
      ]
      |> Enum.each(fn {literal, pattern, flags, result} ->
        assert Literal.matches?(literal, pattern, flags) == result
      end)
    end

    test "with q flag" do
      [
        {~L"abcd", ~L".*", ~L"q", false},
        {~L"Mr. B. Obama", ~L"B. OBAMA", ~L"iq", true},

        # If the q flag is used together with the m, s, or x flag, that flag has no effect.
        {~L"abcd", ~L".*", ~L"mq", true},
        {~L"abcd", ~L".*", ~L"qim", true},
        {~L"abcd", ~L".*", ~L"xqm", true}
      ]
      |> Enum.each(fn {literal, pattern, flags, result} ->
        assert Literal.matches?(literal, pattern, flags) == result
      end)
    end
  end

  describe "update/2" do
    test "it updates value and lexical form" do
      assert XSD.string("foo")
             |> Literal.update(fn s when is_binary(s) -> s <> "bar" end) ==
               XSD.string("foobar")

      assert XSD.integer(1) |> Literal.update(fn i when is_integer(i) -> i + 1 end) ==
               XSD.integer(2)

      assert XSD.byte(42) |> Literal.update(fn i when is_integer(i) -> i + 1 end) ==
               XSD.byte(43)

      assert XSD.integer(1)
             |> Literal.update(fn i when is_integer(i) -> "0" <> to_string(i) end) ==
               XSD.integer("01")
    end

    test "it does not change the datatype of generic literals" do
      assert RDF.literal("foo", datatype: "http://example.com/dt")
             |> Literal.update(fn s when is_binary(s) -> s <> "bar" end) ==
               RDF.literal("foobar", datatype: "http://example.com/dt")
    end

    test "it does not change the language of language literals" do
      assert RDF.langString("foo", language: "en")
             |> Literal.update(fn s when is_binary(s) -> s <> "bar" end) ==
               RDF.langString("foobar", language: "en")
    end

    test "with as: :lexical opt it passes the lexical form" do
      assert XSD.integer(1)
             |> Literal.update(fn i when is_binary(i) -> "0" <> i end, as: :lexical) ==
               XSD.integer("01")
    end
  end

  describe "String.Chars protocol implementation" do
    test "with XSD.Datatype literal" do
      assert Literal.new("foo") |> to_string() == "foo"
      assert Literal.new(42) |> to_string() == "42"
      assert XSD.Integer.new("foo") |> to_string() == "foo"
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
