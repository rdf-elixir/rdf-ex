defmodule RDF.String do
  @moduledoc """
  `RDF.Datatype` for XSD string.
  """

  use RDF.Datatype, id: RDF.Datatype.NS.XSD.string

  def new(value, opts) when is_list(opts),
    do: new(value, Map.new(opts))
  def new(value, %{language: language} = opts) when not is_nil(language),
    do: RDF.LangString.new!(value, opts)
  def new(value, opts),
    do: super(value, opts)

  def new!(value, opts) when is_list(opts),
    do: new!(value, Map.new(opts))
  def new!(value, %{language: language} = opts) when not is_nil(language),
    do: RDF.LangString.new!(value, opts)
  def new!(value, opts),
    do: super(value, opts)


  def build_literal_by_lexical(lexical, opts) do
    build_literal(lexical, nil, opts)
  end


  def convert(value, _), do: to_string(value)


end
