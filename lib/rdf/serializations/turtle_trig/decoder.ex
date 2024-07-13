defmodule RDF.TurtleTriG.Decoder do
  @moduledoc false

  @shared_doc """
  ## Blank Node Generation

  When interpreting blank node descriptions, the decoder generates blank node
  identifiers. By default, it uses `RDF.BlankNode.Generator.UUID` to create
  random identifiers, ensuring uniqueness across multiple parsing operations.
  This behavior prevents unintended merging of unrelated blank nodes,
  which could occur with deterministic identifiers, e.g. from
  `RDF.BlankNode.Generator.Increment`.

  You can customize blank node generation using the `bnode_gen` option and
  providing either a module implementing `RDF.BlankNode.Generator.Algorithm`
  or an instantiated `RDF.BlankNode.Generator.Algorithm` struct in case you
  want to customize the generator. See the respective
  `RDF.BlankNode.Generator.Algorithm` implementation on what fields can be set.
  You can also use `:uuid`, `:random` or `:increment` as short values for the
  respective `RDF.BlankNode.Generator.Algorithm` implementations.

  Example usage:

      RDF.Turtle.Decoder.decode!(turtle_string,
        bnode_gen: RDF.BlankNode.Generator.Increment.new(prefix: "x", counter: 42))

  To set a global or environment-specific default, use the `turtle_trig_decoder_bnode_gen`
  application config (e.g. the `RDF.BlankNode.Generator.Increment` implementation,
  generating deterministic blank nodes, can make testing easier):

      config :rdf,
        turtle_trig_decoder_bnode_gen: :increment

  ## Other options

  - `:base`: allows to specify the base URI to be used against relative URIs
    when no base URI is defined with a `@base` directive within the document

  """

  def shared_doc, do: @shared_doc
end
