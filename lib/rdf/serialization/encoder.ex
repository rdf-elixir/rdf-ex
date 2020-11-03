defmodule RDF.Serialization.Encoder do
  @moduledoc !"""
             A behaviour for encoders of RDF data structures in a specific `RDF.Serialization` format.
             """

  @doc """
  Serializes a RDF data structure into a string.

  It should return an `{:ok, string}` tuple, with `string` being the serialized
  RDF data structure, or `{:error, reason}` if an error occurs.
  """
  @callback encode(RDF.Data.t(), keyword) :: {:ok, String.t()} | {:error, any}

  @doc """
  Serializes a RDF data structure into a string.

  As opposed to `encode`, it raises an exception if an error occurs.

  Note: The `__using__` macro automatically provides an overridable default
  implementation based on the non-bang `encode` function.
  """
  @callback encode!(RDF.Data.t(), keyword) :: String.t()

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

      defoverridable unquote(__MODULE__)
    end
  end
end
