defmodule RDF.TriG.Encoder do
  alias RDF.TurtleTriG

  @moduledoc """
  An encoder for TriG serializations of RDF.ex data structures.

  As for all encoders of `RDF.Serialization.Format`s, you normally won't use these
  functions directly, but via one of the `write_` functions on the `RDF.TriG`
  format module or the generic `RDF.Serialization` module.


  ## Options

  - `:content`: Allows specifying the content and structure of the Turtle document
    to be rendered and defining which parts should be generated in which order.
    This option accepts lists of the values `:base`, `:prefixes`, `:default_graph` and `:named_graphs`.
    You can also use `:directives` to specify `[:base, :prefixes]` and `:graphs`
    to specify `[:default_graph, :named_graphs]` as a group.
    Additionally, arbitrary strings can be included at desired positions to customize
    the document.

        RDF.TriG.write_string(dataset, content: [
          "# === HEADER ===\\n\\n",
          :directives,
          "\\n# === NAMED GRAPHS ===\\n\\n",
          :named_graphs
          "\\n# === DEFAULT GRAPH ===\\n\\n",
          :default_graph
        ])

  - `:prefixes`: Allows to specify the prefixes to be used as a `RDF.PrefixMap` or
    anything from which a `RDF.PrefixMap` can be created with `RDF.PrefixMap.new/1`.
    If not specified the prefixes from all the graphs of the given dataset are used
    or if these are also not present the `RDF.default_prefixes/0`.
  - `:base`: : Allows to specify the base URI to be used for a `@base` directive.
    If not specified the `RDF.default_base_iri/0` is used.
  #{TurtleTriG.Encoder.options_doc()}
  """

  use RDF.Serialization.Encoder

  alias RDF.{Description, Graph, Dataset}

  @impl RDF.Serialization.Encoder
  @spec encode(Dataset.t() | Graph.t() | Description.t(), keyword) ::
          {:ok, String.t()} | {:error, any}
  def encode(%type{} = data, opts \\ []) when type in [Description, Graph, Dataset] do
    TurtleTriG.Encoder.encode(data, :trig, opts)
  end
end
