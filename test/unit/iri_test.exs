defmodule RDF.IRITest do
  use RDF.Test.Case

  use RDF.Vocabulary.Namespace

  defvocab EX,
    base_iri: "http://example.com/#",
    terms: [], strict: false

  doctest RDF.IRI

  alias RDF.IRI

  @absolute_iris [
      "http://www.example.com/foo/",
      %IRI{value: "http://www.example.com/foo/"},
      URI.parse("http://www.example.com/foo/"),
      "http://www.example.com/foo#",
      %IRI{value: "http://www.example.com/foo#"},
      URI.parse("http://www.example.com/foo#") |> IRI.empty_fragment_shim("#"),
      "https://en.wiktionary.org/wiki/Ῥόδος",
      %IRI{value: "https://en.wiktionary.org/wiki/Ῥόδος"},
      URI.parse("https://en.wiktionary.org/wiki/Ῥόδος"),
    ]
  @relative_iris [
      "/relative/",
      %IRI{value: "/relative/"},
      URI.parse("/relative/"),
      "/Ῥόδος/",
      %IRI{value: "/Ῥόδος/"},
      URI.parse("/Ῥόδος/"),
    ]

  def absolute_iris, do: @absolute_iris
  def relative_iris, do: @relative_iris
  def valid_iris,    do: @absolute_iris
  def invalid_iris,  do: nil  # TODO:


  describe "new/1" do
    test "with a string" do
      assert IRI.new("http://example.com/") == %IRI{value: "http://example.com/"}
    end

    test "with a RDF.IRI" do
      assert IRI.new(IRI.new("http://example.com/")) == %IRI{value: "http://example.com/"}
    end

    test "with a URI" do
      assert IRI.new(URI.parse("http://example.com/")) == %IRI{value: "http://example.com/"}
    end

    test "with a resolvable atom" do
      assert IRI.new(EX.Foo) == %IRI{value: "http://example.com/#Foo"}
    end

    test "with a non-resolvable atom" do
      assert_raise RDF.Namespace.UndefinedTermError, fn -> IRI.new(Foo.Bar) end
    end

    test "with Elixirs special atoms" do
      assert_raise FunctionClauseError, fn -> IRI.new(true) end
      assert_raise FunctionClauseError, fn -> IRI.new(false) end
      assert_raise FunctionClauseError, fn -> IRI.new(nil) end
    end
  end


  describe "new!/1" do
    test "with valid iris" do
      Enum.each(valid_iris(), fn valid_iri ->
        assert IRI.new!(valid_iri) == IRI.new(valid_iri)
      end)
    end

    test "with a resolvable atom" do
      assert IRI.new!(EX.Foo) == %IRI{value: "http://example.com/#Foo"}
    end

    test "with relative iris" do
      Enum.each(relative_iris(), fn relative_iri ->
        assert_raise RDF.IRI.InvalidError, fn ->
          IRI.new!(relative_iri)
        end
      end)
    end

    @tag skip: "TODO: proper validation"
    test "with invalid iris" do
      Enum.each(invalid_iris(), fn invalid_iri ->
        assert_raise RDF.IRI.InvalidError, fn ->
          IRI.new!(invalid_iri)
        end
      end)
    end

    test "with a non-resolvable atom" do
      assert_raise RDF.Namespace.UndefinedTermError, fn -> IRI.new!(Foo.Bar) end
    end

    test "with Elixirs special atoms" do
      assert_raise FunctionClauseError, fn -> IRI.new!(true) end
      assert_raise FunctionClauseError, fn -> IRI.new!(false) end
      assert_raise FunctionClauseError, fn -> IRI.new!(nil) end
    end
  end


  describe "valid!/1" do
    test "with valid iris" do
      Enum.each(valid_iris(), fn valid_iri ->
        assert IRI.valid!(valid_iri) == valid_iri
      end)
    end

    test "with a resolvable atom" do
      assert IRI.valid!(EX.Foo) == EX.Foo
    end

    test "with a non-resolvable atom" do
      assert_raise RDF.IRI.InvalidError, fn -> IRI.valid!(true) == false end
      assert_raise RDF.IRI.InvalidError, fn -> IRI.valid!(false) == false end
      assert_raise RDF.IRI.InvalidError, fn -> IRI.valid!(nil) == false end
      assert_raise RDF.IRI.InvalidError, fn -> IRI.valid!(Foo.Bar) == false end
    end

    test "with relative iris" do
      Enum.each(relative_iris(), fn relative_iri ->
        assert_raise RDF.IRI.InvalidError, fn ->
          IRI.valid!(relative_iri)
        end
      end)
    end

    @tag skip: "TODO: proper validation"
    test "with invalid iris" do
      Enum.each(invalid_iris(), fn invalid_iri ->
        assert_raise RDF.IRI.InvalidError, fn ->
          IRI.valid!(invalid_iri)
        end
      end)
    end
  end


  describe "valid?/1" do
    test "with valid iris" do
      Enum.each(valid_iris(), fn valid_iri ->
        assert IRI.valid?(valid_iri) == true
      end)
    end

    test "with a resolvable atom" do
      assert IRI.valid?(EX.Foo) == true
    end

    test "with a non-resolvable atom" do
      assert IRI.valid?(true) == false
      assert IRI.valid?(false) == false
      assert IRI.valid?(nil) == false
      assert IRI.valid?(Foo.Bar) == false
    end

    test "with relative iris" do
      Enum.each(relative_iris(), fn relative_iri ->
        assert IRI.valid?(relative_iri) == false
      end)
    end

    @tag skip: "TODO: proper validation"
    test "with invalid iris" do
      Enum.each(relative_iris(), fn relative_iri ->
        assert IRI.valid?(relative_iri) == false
      end)
    end
  end


  describe "absolute?/1" do
    test "with absolute iris" do
      Enum.each(absolute_iris(), fn absolute_iri ->
        assert IRI.absolute?(absolute_iri) == true
      end)
    end

    test "with a resolvable atom" do
      assert IRI.absolute?(EX.Foo) == true
    end

    test "with a non-resolvable atom" do
      assert IRI.absolute?(true) == false
      assert IRI.absolute?(false) == false
      assert IRI.absolute?(nil) == false
      assert IRI.absolute?(Foo.Bar) == false
    end

    test "with relative iris" do
      Enum.each(relative_iris(), fn relative_iri ->
        assert IRI.absolute?(relative_iri) == false
      end)
    end

    @tag skip: "TODO: proper validation"
    test "with invalid iris" do
      Enum.each(invalid_iris(), fn relative_iri ->
        assert IRI.absolute?(relative_iri) == false
      end)
    end
  end


  describe "absolute/2" do
    test "with an already absolute iri" do
      for absolute_iri <- absolute_iris(),
          base_iri <- absolute_iris() ++ relative_iris() do
        assert IRI.absolute(absolute_iri, base_iri) == IRI.new(absolute_iri)
      end
    end

    test "with a relative iri" do
      for relative_iri <- relative_iris(), base_iri <- absolute_iris() do
        assert IRI.absolute(relative_iri, base_iri) ==
                IRI.merge(base_iri, relative_iri)
      end
    end

    test "with a relative iri without an absolute base iri" do
      for relative_iri <- relative_iris(), base_iri <- [nil, "foo"] do
        assert IRI.absolute(relative_iri, base_iri) == nil
      end
    end
  end


  describe "merge/2" do
    test "with a valid absolute base iri and a valid relative iri" do
      for base_iri <- absolute_iris(), relative_iri <- relative_iris() do
        assert IRI.merge(base_iri, relative_iri) == (
            base_iri
            |> to_string
            |> URI.merge(to_string(relative_iri))
            |> IRI.empty_fragment_shim(relative_iri)
            |> IRI.new
          )
        end
    end

    test "with a valid absolute base iri and a valid absolute iri" do
      for base_iri <- absolute_iris(), absolute_iri <- absolute_iris() do
        assert IRI.merge(base_iri, absolute_iri) == (
            base_iri
            |> to_string
            |> URI.merge(to_string(absolute_iri))
            |> IRI.empty_fragment_shim(absolute_iri)
            |> IRI.new
          )
        end
    end

    test "with a relative base iri" do
      for base_iri <- relative_iris(), iri <- absolute_iris() ++ relative_iris() do
        assert_raise ArgumentError, fn ->
          IRI.merge(base_iri, iri)
        end
      end
    end

    test "with empty fragments" do
      assert IRI.merge("http://example.com/","foo#") == IRI.new("http://example.com/foo#")
    end

    @tag skip: "TODO: proper validation"
    test "with invalid iris" do
      Enum.each(invalid_iris(), fn invalid_iri ->
        refute IRI.merge(invalid_iri, "foo")
      end)
    end
  end


  describe "parse/1" do
    test "with absolute and relative iris" do
      Enum.each(absolute_iris() ++ relative_iris(), fn iri ->
        assert IRI.parse(iri) == (
            iri
            |> IRI.new
            |> to_string()
            |> URI.parse
            |> IRI.empty_fragment_shim(iri)
          )
      end)
    end

    test "with a resolvable atom" do
      assert IRI.parse(EX.Foo) == (EX.Foo |> IRI.new |> IRI.parse)
    end

    test "with empty fragments" do
      assert IRI.parse("http://example.com/foo#") |> to_string == "http://example.com/foo#"
    end

    @tag skip: "TODO: proper validation"
    test "with invalid iris" do
      Enum.each(invalid_iris(), fn invalid_iri ->
        refute IRI.parse(invalid_iri)
      end)
    end

    test "with Elixirs special atoms" do
      assert_raise FunctionClauseError, fn -> IRI.parse(true) end
      assert_raise FunctionClauseError, fn -> IRI.parse(false) end
      assert_raise FunctionClauseError, fn -> IRI.parse(nil) end
    end
  end

  describe "to_string/1" do
    test "with IRIs" do
      assert IRI.to_string(IRI.new("http://example.com/")) == "http://example.com/"
    end

    test "with IRI resolvable namespace terms" do
      assert IRI.to_string(EX.Foo) == "http://example.com/#Foo"
      assert IRI.to_string(EX.foo) == "http://example.com/#foo"
    end

    test "with non-resolvable atoms" do
      assert_raise RDF.Namespace.UndefinedTermError, fn -> IRI.to_string(Foo.Bar) end
    end
  end

  test "String.Chars protocol implementation" do
    assert to_string(IRI.new("http://example.com/")) == "http://example.com/"
  end

  test "Inspect protocol implementation" do
    assert inspect(IRI.new("http://example.com/")) == "~I<http://example.com/>"
  end

end
