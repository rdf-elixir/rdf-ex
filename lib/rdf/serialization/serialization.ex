defmodule RDF.Serialization do
  @moduledoc """
  General functions for working with RDF serializations.
  """

  @formats [
    RDF.Turtle,
    JSON.LD,
    RDF.NTriples,
    RDF.NQuads,
  ]

  @doc """
  The list of all known `RDF.Serialization.Format`s in the RDF.ex eco-system.

  Note: Not all known formats might be available to an application, see `available_formats/0`.

  ## Examples

      iex> RDF.Serialization.formats
      [RDF.Turtle, JSON.LD, RDF.NTriples, RDF.NQuads]

  """
  def formats, do: @formats

  @doc """
  The list of all available `RDF.Serialization.Format`s in an application.

  A known format might not be available in an application, when the format is
  implemented in an external library and this not specified as a Mix dependency
  of this application.

  ## Examples

      iex> RDF.Serialization.available_formats
      [RDF.Turtle, RDF.NTriples, RDF.NQuads]

  """
  def available_formats do
    Enum.filter @formats, &Code.ensure_loaded?/1
  end

  @doc """
  Returns the `RDF.Serialization.Format` with the given name, if available.

  ## Examples

      iex> RDF.Serialization.format(:turtle)
      RDF.Turtle
      iex> RDF.Serialization.format("turtle")
      RDF.Turtle
      iex> RDF.Serialization.format(:jsonld)
      nil  # unless json_ld is defined as a dependency of the application
  """
  def format(name)

  def format(name) when is_binary(name) do
    try do
      name
      |> String.to_existing_atom
      |> format()
    rescue
      ArgumentError -> nil
    end
  end

  def format(name) do
    format_where(fn format -> format.name == name end)
  end


  @doc """
  Returns the `RDF.Serialization.Format` with the given media type, if available.

  ## Examples

      iex> RDF.Serialization.format_by_media_type("text/turtle")
      RDF.Turtle
      iex> RDF.Serialization.format_by_media_type("application/ld+json")
      nil  # unless json_ld is defined as a dependency of the application
  """
  def format_by_media_type(media_type) do
    format_where(fn format -> format.media_type == media_type end)
  end

  @doc """
  Returns the proper `RDF.Serialization.Format` for the given file extension, if available.

  ## Examples

      iex> RDF.Serialization.format_by_extension("ttl")
      RDF.Turtle
      iex> RDF.Serialization.format_by_extension("jsonld")
      nil  # unless json_ld is defined as a dependency of the application
  """
  def format_by_extension(extension) do
    format_where(fn format -> format.extension == extension end)
  end

  defp format_where(fun) do
    @formats
    |> Stream.filter(&Code.ensure_loaded?/1)
    |> Enum.find(fun)
  end
end
