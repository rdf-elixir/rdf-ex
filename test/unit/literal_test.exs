defmodule RDF.LiteralTest do
  use ExUnit.Case

  import RDF.Sigils
  import RDF.TestLiterals

  alias RDF.Literal
  alias RDF.NS.XSD

  doctest RDF.Literal

  @examples %{
    RDF.String  => ["foo"],
    RDF.Integer => [42],
    RDF.Double  => [3.14],
    RDF.Decimal => [Decimal.from_float(3.14)],
    RDF.Boolean => [true, false],
  }


  describe "construction by type inference" do
    Enum.each @examples, fn {datatype, example_values} ->
      @tag example: %{datatype: datatype, values: example_values}
      test (datatype |> Module.split |> List.last |> to_string), %{example: example} do
        Enum.each example.values, fn example_value ->
          assert Literal.new(example_value) == example.datatype.new(example_value)
        end
      end
    end

    test "when options without datatype given" do
      assert Literal.new(true, %{}) == RDF.Boolean.new(true)
      assert Literal.new(42, %{})   == RDF.Integer.new(42)
    end
  end


  describe "typed construction" do
    test "boolean" do
      assert Literal.new(true,    datatype: XSD.boolean) == RDF.Boolean.new(true)
      assert Literal.new(false,   datatype: XSD.boolean) == RDF.Boolean.new(false)
      assert Literal.new("true",  datatype: XSD.boolean) == RDF.Boolean.new("true")
      assert Literal.new("false", datatype: XSD.boolean) == RDF.Boolean.new("false")
    end

    test "integer" do
      assert Literal.new(42,   datatype: XSD.integer) == RDF.Integer.new(42)
      assert Literal.new("42", datatype: XSD.integer) == RDF.Integer.new("42")
    end

    test "double" do
      assert Literal.new(3.14,   datatype: XSD.double) == RDF.Double.new(3.14)
      assert Literal.new("3.14", datatype: XSD.double) == RDF.Double.new("3.14")
    end

    test "decimal" do
      assert Literal.new(3.14,   datatype: XSD.decimal) == RDF.Decimal.new(3.14)
      assert Literal.new("3.14", datatype: XSD.decimal) == RDF.Decimal.new("3.14")
      assert Literal.new(Decimal.from_float(3.14), datatype: XSD.decimal) ==
               RDF.Decimal.new(Decimal.from_float(3.14))
    end

    test "string" do
      assert Literal.new("foo", datatype: XSD.string) == RDF.String.new("foo")
    end

    test "unmapped/unknown datatype" do
      literal = Literal.new("custom typed value", datatype: "http://example/dt")
      assert literal.value == "custom typed value"
      assert literal.datatype == ~I<http://example/dt>
    end

  end


  describe "language tagged construction" do
    test "string literal with a language tag" do
      literal = Literal.new("Eule", language: "de")
      assert literal.value    == "Eule"
      assert literal.datatype == RDF.langString
      assert literal.language == "de"
    end

    test "language is ignored on non-string literals" do
      literal = Literal.new(1, language: "de")
      assert literal.value    == 1
      assert literal.datatype == XSD.integer
      refute literal.language
    end

    test "construction of an other than rdf:langString typed and language-tagged literal fails" do
      assert_raise ArgumentError, fn ->
        Literal.new("Eule", datatype: XSD.string, language: "de")
      end
    end

    test "nil as language is ignored" do
      assert Literal.new("Eule", datatype: XSD.string, language: nil) ==
             Literal.new("Eule", datatype: XSD.string)
      assert Literal.new("Eule", language: nil) ==
             Literal.new("Eule")

      assert Literal.new!("Eule", datatype: XSD.string, language: nil) ==
             Literal.new!("Eule", datatype: XSD.string)
      assert Literal.new!("Eule", language: nil) ==
             Literal.new!("Eule")
    end

    test "construction of a rdf:langString works, but results in an invalid literal" do
      assert %Literal{value: "Eule"} = literal = Literal.new("Eule", datatype: RDF.langString)
      refute Literal.valid?(literal)
    end
  end


  describe "language" do
    Enum.each literals(:all_plain_lang), fn literal ->
      @tag literal: literal
      test "#{inspect literal} has correct language", %{literal: literal} do
        assert literal.language == "en"
      end
    end
    Enum.each literals(:all) -- literals(:all_plain_lang), fn literal ->
      @tag literal: literal
      test "Literal for #{literal} has no language", %{literal: literal} do
        assert is_nil(literal.language)
      end
    end

    test "language get lower-cased" do
      assert Literal.new("Upper", language: "EN").language == "en"
      assert Literal.new("Upper", %{language: "EN"}).language == "en"
    end
  end


  describe "datatype" do
    Enum.each literals(:all_simple), fn literal ->
      @tag literal: literal
      test "simple literal #{inspect literal} has datatype xsd:string", %{literal: literal} do
        assert literal.datatype == XSD.string
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
         test "Literal for #{literal} has datatype xsd:#{type}",
              %{data: %{literal: literal, type: type}} do
           assert literal.datatype == apply(XSD, String.to_atom(type), [])
         end
       end)
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
      test "Literal for #{literal} has a datatype", %{literal: literal} do
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
      test "Literal for #{literal} is not plain", %{literal: literal} do
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
      test "Literal for #{literal} is not simple", %{literal: literal} do
        refute Literal.simple?(literal)
      end
    end
  end


  describe "canonicalization" do

    # for mapped/known datatypes the RDF.Datatype.Test.Case uses the general RDF.Literal.canonical function

    test "an unmapped/unknown datatypes is always canonical" do
      assert Literal.canonical? Literal.new("custom typed value", datatype: "http://example/dt")
    end

    test "for unmapped/unknown datatypes, canonicalize is a no-op" do
      assert Literal.new("custom typed value", datatype: "http://example/dt") ==
        Literal.canonical(Literal.new("custom typed value", datatype: "http://example/dt"))
    end
  end

  describe "validation" do

    # for mapped/known datatypes the RDF.Datatype.Test.Case uses the general RDF.Literal.valid? function

    test "a literal with an unmapped/unknown datatype is always valid" do
      assert Literal.valid? Literal.new("custom typed value", datatype: "http://example/dt")
    end
  end


  @poem RDF.string """
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
        {RDF.integer("42"), ~L"4",   true},
        {RDF.integer("42"), ~L"en",  false},
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
    Enum.each values(:all_plain), fn value ->
      @tag value: value
      test "returns String representation of #{inspect value}", %{value: value} do
        assert to_string(apply(Literal, :new, value)) == List.first(value)
      end
    end

    %{
        literal(:int)            => "123",
        literal(:true)           => "true",
        literal(:false)          => "false",
        literal(:long)           => "9223372036854775807",
        literal(:double)         => "3.1415",
        literal(:date)           => "2017-04-13",
        literal(:datetime)       => "2017-04-14T15:32:07Z",
        literal(:naive_datetime) => "2017-04-14T15:32:07",
        literal(:time)           => "01:02:03"
    }
    |> Enum.each(fn {literal, rep} ->
         @tag data: %{literal: literal, rep: rep}
         test "returns String representation of Literal value #{literal}",
              %{data: %{literal: literal, rep: rep}} do
           assert to_string(literal) == rep
         end
       end)
  end

end
