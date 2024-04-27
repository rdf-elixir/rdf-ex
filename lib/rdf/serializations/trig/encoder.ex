defmodule RDF.TriG.Encoder do
  alias RDF.TurtleTriG

  @moduledoc """
  An encoder for TriG serializations of RDF.ex data structures.

  As for all encoders of `RDF.Serialization.Format`s, you normally won't use these
  functions directly, but via one of the `write_` functions on the `RDF.TriG`
  format module or the generic `RDF.Serialization` module.


  ## Options

  - `:only`: Allows to specify which parts of a TriG document should be generated.
    Possible values: `:base`, `:prefixes`, `:directives` (means the same as `[:base, :prefixes]`),
    `:default_graph`, `:named_graphs`, `:graphs` (means the same as `[:default_graph, :named_graphs]`)
    or a list with any combination of these values.
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
