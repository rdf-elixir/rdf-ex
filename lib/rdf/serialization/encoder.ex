defmodule RDF.Serialization.Encoder do
  @moduledoc """
  A behaviour for encoders of `RDF.Graph`s or `RDF.Dataset`s in a specific
  `RDF.Serialization` format.
  """

  alias RDF.{Dataset, Graph, Description}

  @doc """
  Encodes a `RDF.Graph` or `RDF.Dataset`.

  It returns an `{:ok, string}` tuple, with `string` being the serialized
  `RDF.Graph` or `RDF.Dataset`, or `{:error, reason}` if an error occurs.
  """
  @callback encode(Description.t() | Graph.t() | Dataset.t(), keyword | map) ::
              {:ok, String.t()} | {:error, any}

  @doc """
  Encodes a `RDF.Graph` or `RDF.Dataset`.

  As opposed to `encode`, it raises an exception if an error occurs.

  Note: The `__using__` macro automatically provides an overridable default
  implementation based on the non-bang `encode` function.
  """
  @callback encode!(Description.t() | Graph.t() | Dataset.t(), keyword | map) :: String.t()

  defmacro __using__(_) do
    quote bind_quoted: [], unquote: true do
      @behaviour unquote(__MODULE__)

      @impl unquote(__MODULE__)
      @dialyzer {:nowarn_function, encode!: 2}
      @spec encode!(RDF.Data.t(), keyword) :: String.t()
      def encode!(data, opts \\ []) do
        case encode(data, opts) do
          {:ok, data} -> data
          {:error, reason} -> raise reason
        end
      end

      defoverridable encode!: 1
      defoverridable encode!: 2
    end
  end
end
