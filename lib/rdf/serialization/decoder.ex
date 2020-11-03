defmodule RDF.Serialization.Decoder do
  @moduledoc !"""
             A behaviour for decoders of strings encoded in a specific `RDF.Serialization` format.
             """

  alias RDF.{Dataset, Graph}

  @doc """
  Decodes a serialized `RDF.Graph` or `RDF.Dataset` from the given string.

  It returns an `{:ok, data}` tuple, with `data` being the deserialized graph or
  dataset, or `{:error, reason}` if an error occurs.
  """
  @callback decode(String.t(), keyword) :: {:ok, Graph.t() | Dataset.t()} | {:error, any}

  @doc """
  Decodes a serialized `RDF.Graph` or `RDF.Dataset` from the given string.

  As opposed to `decode`, it raises an exception if an error occurs.

  Note: The `__using__` macro automatically provides an overridable default
  implementation based on the non-bang `decode` function.
  """
  @callback decode!(String.t(), keyword) :: RDF.Graph.t() | RDF.Dataset.t()

  defmacro __using__(_) do
    quote bind_quoted: [], unquote: true do
      @behaviour unquote(__MODULE__)

      @impl unquote(__MODULE__)
      @spec decode!(String.t(), keyword) :: RDF.Graph.t() | RDF.Dataset.t()
      def decode!(content, opts \\ []) do
        case decode(content, opts) do
          {:ok, data} -> data
          {:error, reason} -> raise reason
        end
      end

      defoverridable unquote(__MODULE__)
    end
  end
end
