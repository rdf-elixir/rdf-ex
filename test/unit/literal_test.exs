defmodule RDF.LiteralTest do
  use ExUnit.Case

  import RDF.Sigils
  import RDF.TestLiterals

  alias RDF.Literal
  alias RDF.NS.XSD

  doctest RDF.Literal


  describe "construction by type inference" do
    test "string" do
      assert Literal.new("foo") == RDF.String.new("foo")
    end

    test "integer" do
      assert Literal.new(42) == RDF.Integer.new(42)
    end

    test "double" do
      assert Literal.new(3.14) == RDF.Double.new(3.14)
    end

    test "boolean" do
      assert Literal.new(true)  == RDF.Boolean.new(true)
      assert Literal.new(false) == RDF.Boolean.new(false)
    end

    @tag skip: "TODO"
    test "when options without datatype given"
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



    test "unknown datatype" do
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

    test "construction of a rdf:langString typed literal without language fails" do
      assert_raise ArgumentError, fn ->
        Literal.new("Eule", datatype: RDF.langString)
      end
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
      test "#{inspect literal} has no language", %{literal: literal} do
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
         test "#{inspect literal} has datatype xsd:#{type}",
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
      test "#{inspect literal} has a datatype", %{literal: literal} do
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
      test "#{inspect literal} is not plain", %{literal: literal} do
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
      test "#{inspect literal} is not simple", %{literal: literal} do
        refute Literal.simple?(literal)
      end
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
        literal(:int)      => "123",
        literal(:true)     => "true",
        literal(:false)    => "false",
        literal(:long)     => "9223372036854775807",
        literal(:double)   => "3.1415",
        literal(:date)     => "2017-04-13",
        literal(:datetime) => "2017-04-14 15:32:07",
        literal(:time)     => "01:02:03"
    }
    |> Enum.each(fn {literal, rep} ->
         @tag data: %{literal: literal, rep: rep}
         test "returns String representation of #{inspect literal} value",
              %{data: %{literal: literal, rep: rep}} do
           assert to_string(literal) == rep
         end
       end)

  end

end
