defmodule RDF.Turtle.Encoder do
  alias RDF.TurtleTriG

  @moduledoc """
  An encoder for Turtle serializations of RDF.ex data structures.

  As for all encoders of `RDF.Serialization.Format`s, you normally won't use these
  functions directly, but via one of the `write_` functions on the `RDF.Turtle`
  format module or the generic `RDF.Serialization` module.


  ## Options

  - `:content`: Allows specifying the content and structure of the Turtle document
    to be rendered and defining which parts should be generated in which order.
    This option accepts lists of the values `:base`, `:prefixes`, and `:triples`.
    You can also use `:directives` to specify `[:base, :prefixes]` as a group.
    Additionally, arbitrary strings can be included at desired positions to customize
    the document.

        RDF.Turtle.write_string(graph, content: [
          "# === HEADER ===",
          :directives,
          "\\n# === TRIPLES ===",
          :triples
        ])

  - `:prefixes`: Allows to specify the prefixes to be used as a `RDF.PrefixMap` or
    anything from which a `RDF.PrefixMap` can be created with `RDF.PrefixMap.new/1`.
    If not specified the ones from the given graph are used or if these are also not
    present the `RDF.default_prefixes/0`. If you explicitly want to omit the prefixes
    use `[]` as a value.
  - `:base`: : Allows to specify the base URI to be used for a `@base` directive.
    If not specified the one from the given graph is used or if there is also none
    specified for the graph the `RDF.default_base_iri/0`.
  #{TurtleTriG.Encoder.options_doc()}
  """

  use RDF.Serialization.Encoder

  alias RDF.{Description, Graph}

  @impl RDF.Serialization.Encoder
  @spec encode(Graph.t() | Description.t(), keyword) :: {:ok, String.t()} | {:error, any}
  def encode(%type{} = data, opts \\ []) when type in [Description, Graph] do
    TurtleTriG.Encoder.encode(data, :turtle, opts)
  end
end
