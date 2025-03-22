defmodule RDF.IRI.ValidationTest do
  use RDF.Test.Case

  import RDF.IRI.Validation

  describe "valid?/1" do
    @refs [
      "a",
      "d",
      "z",
      "A",
      "D",
      "Z",
      "0",
      "5",
      "99",
      "-",
      ".",
      "_",
      "~",
      "S",
      "Ö",
      "foo",
      "%20",
      "S",
      "Dürst",
      "AZazÀÖØöø˿Ͱͽ΄῾‌‍⁰↉Ⰰ⿕、ퟻ﨎ﷇﷰ￯𐀀𪘀"
    ]

    test "validates IRIs with authority and path" do
      # empty path
      for ref <- @refs do
        assert valid?("scheme://auth/")
        assert valid?("scheme://auth/?#{ref}")
        assert valid?("scheme://auth/##{ref}")
        assert valid?("scheme://auth/?#{ref}##{ref}")
      end

      # reference in path
      for ref <- @refs do
        assert valid?("scheme://auth/#{ref}")
        assert valid?("scheme://auth/#{ref}?#{ref}")
        assert valid?("scheme://auth/#{ref}##{ref}")
        assert valid?("scheme://auth/#{ref}?#{ref}##{ref}")
      end

      # reference in nested path
      for ref <- @refs do
        assert valid?("scheme://auth/#{ref}/#{ref}")
        assert valid?("scheme://auth/#{ref}/#{ref}?#{ref}")
        assert valid?("scheme://auth/#{ref}/#{ref}##{ref}")
        assert valid?("scheme://auth/#{ref}/#{ref}?#{ref}##{ref}")
      end
    end

    test "validates IRIs with path-absolute" do
      # empty path after scheme
      for ref <- @refs do
        assert valid?("scheme:/")
        assert valid?("scheme:/?#{ref}")
        assert valid?("scheme:/##{ref}")
        assert valid?("scheme:/?#{ref}##{ref}")
      end

      # reference in path
      for ref <- @refs do
        assert valid?("scheme:/#{ref}")
        assert valid?("scheme:/#{ref}?#{ref}")
        assert valid?("scheme:/#{ref}##{ref}")
        assert valid?("scheme:/#{ref}?#{ref}##{ref}")
      end

      # reference in nested path
      for ref <- @refs do
        assert valid?("scheme:/#{ref}/#{ref}")
        assert valid?("scheme:/#{ref}/#{ref}?#{ref}")
        assert valid?("scheme:/#{ref}/#{ref}##{ref}")
        assert valid?("scheme:/#{ref}/#{ref}?#{ref}##{ref}")
      end
    end

    test "validates IRIs with ipath-rootless" do
      # reference after scheme
      for ref <- @refs do
        assert valid?("scheme:#{ref}")
        assert valid?("scheme:#{ref}?#{ref}")
        assert valid?("scheme:#{ref}##{ref}")
        assert valid?("scheme:#{ref}?#{ref}##{ref}")
      end

      # reference in nested path
      for ref <- @refs do
        assert valid?("scheme:#{ref}/#{ref}")
        assert valid?("scheme:#{ref}/#{ref}?#{ref}")
        assert valid?("scheme:#{ref}/#{ref}##{ref}")
        assert valid?("scheme:#{ref}/#{ref}?#{ref}##{ref}")
      end
    end

    test "validates IRIs with ipath-empty" do
      # empty path after scheme
      for ref <- @refs do
        assert valid?("scheme:")
        assert valid?("scheme:?#{ref}")
        assert valid?("scheme:##{ref}")
        assert valid?("scheme:?#{ref}##{ref}")
      end
    end

    test "valid IRIs" do
      for iri <-
            [
              "a:b",
              "http://example.org/path'with'apostrophes",
              "http://example.org/path%20with%20spaces",
              "http://example.org/path%2Fwith%2Fencoded%2Fslashes",
              "scheme:!$%25&'()*+,-./0123456789:/@ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz~?#",
              "scheme:" <> String.duplicate("a", 8000)
            ] do
        assert valid?(iri)
      end
    end

    test "invalidates relative references with authority" do
      for ref <- @refs do
        refute valid?("//auth/#{ref}")
        refute valid?("//auth/#{ref}?#{ref}")
        refute valid?("//auth/#{ref}##{ref}")
        refute valid?("//auth/#{ref}?#{ref}##{ref}")
      end
    end

    test "invalidates relative references with authority and port" do
      for ref <- @refs do
        refute valid?("//auth:123/#{ref}")
        refute valid?("//auth:123/#{ref}?#{ref}")
        refute valid?("//auth:123/#{ref}##{ref}")
        refute valid?("//auth:123/#{ref}?#{ref}##{ref}")
      end
    end

    test "invalidates relative references with path-absolute" do
      for ref <- @refs do
        refute valid?("/#{ref}")
        refute valid?("/#{ref}?#{ref}")
        refute valid?("/#{ref}##{ref}")
        refute valid?("/#{ref}?#{ref}##{ref}")

        refute valid?("/#{ref}/")
        refute valid?("/#{ref}/?#{ref}")
        refute valid?("/#{ref}/##{ref}")
        refute valid?("/#{ref}/?#{ref}##{ref}")

        refute valid?("/#{ref}/#{ref}")
        refute valid?("/#{ref}/#{ref}?#{ref}")
        refute valid?("/#{ref}/#{ref}##{ref}")
        refute valid?("/#{ref}/#{ref}?#{ref}##{ref}")
      end
    end

    test "invalidates relative references with path-noscheme" do
      for ref <- @refs do
        refute valid?("#{ref}")
        refute valid?("#{ref}?#{ref}")
        refute valid?("#{ref}##{ref}")
        refute valid?("#{ref}?#{ref}##{ref}")

        refute valid?("#{ref}/")
        refute valid?("#{ref}/?#{ref}")
        refute valid?("#{ref}/##{ref}")
        refute valid?("#{ref}/?#{ref}##{ref}")

        refute valid?("#{ref}/#{ref}")
        refute valid?("#{ref}/#{ref}?#{ref}")
        refute valid?("#{ref}/#{ref}##{ref}")
        refute valid?("#{ref}/#{ref}?#{ref}##{ref}")
      end
    end

    test "invalidates relative references with empty path" do
      for ref <- @refs do
        refute valid?("")
        refute valid?("?#{ref}")
        refute valid?("##{ref}")
        refute valid?("?#{ref}##{ref}")
      end
    end

    test "invalidates URIs with invalid characters" do
      invalid_chars = [
        "`",
        "^",
        "\\",
        "\u0000",
        "\u0001",
        "\u0002",
        "\u0003",
        "\u0004",
        "\u0005",
        "\u0006",
        "\u0010",
        "\u0020",
        "\u003c",
        "\u003e",
        "\u0022",
        "\u007b",
        "\u007d",
        " ",
        "<",
        ">",
        "\""
      ]

      for char <- invalid_chars do
        refute valid?("http://example/#{char}")
      end
    end

    test "specific invalid URIs" do
      invalid_uris = [
        "file:///path/to/file with spaces.txt",
        "http://www.w3.org/2013/TurtleTests/\u0020",
        "scheme://auth/\u0000",
        "scheme://auth/\u005C",
        "scheme://auth/\u005E",
        "scheme://auth/\u0060",
        "scheme://auth/\\u0000",
        "scheme://auth/\\u005C",
        "scheme://auth/\\u005E",
        "scheme://auth/\\u0060",
        "scheme://auth/^",
        "scheme://auth/`",
        "scheme://auth/\\",
        "://example.org"
      ]

      for uri <- invalid_uris do
        refute valid?(uri)
      end
    end
  end
end
