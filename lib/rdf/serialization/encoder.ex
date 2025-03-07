defmodule RDF.Serialization.Encoder do
  @moduledoc """
  A behaviour for encoders of RDF data structures in a specific `RDF.Serialization` format.
  """

  @doc """
  Serializes an RDF data structure into a string.

  It should return an `{:ok, string}` tuple, with `string` being the serialized
  RDF data structure, or `{:error, reason}` if an error occurs.
  """
  @callback encode(RDF.Data.t()) :: {:ok, String.t()} | {:error, any}

  @doc """
  Serializes an RDF data structure into a string.

  It should return an `{:ok, string}` tuple, with `string` being the serialized
  RDF data structure, or `{:error, reason}` if an error occurs.
  """
  @callback encode(RDF.Data.t(), keyword) :: {:ok, String.t()} | {:error, any}

  @doc """
  Serializes an RDF data structure into a string.

  As opposed to `encode`, it raises an exception if an error occurs.

  Note: The `__using__` macro automatically provides an overridable default
  implementation based on the non-bang `encode` function.
  """
  @callback encode!(RDF.Data.t()) :: String.t()

  @doc """
  Serializes an RDF data structure into a string.

  As opposed to `encode`, it raises an exception if an error occurs.

  Note: The `__using__` macro automatically provides an overridable default
  implementation based on the non-bang `encode` function.
  """
  @callback encode!(RDF.Data.t(), keyword) :: String.t()

  @doc """
  Serializes an RDF data structure into a stream.

  It should return a stream emitting either strings or iodata of the
  serialized RDF data structure. If both forms are supported the form
  should be configurable via the `:mode` option and its values `:string`
  respective `:iodata`.
  """
  @callback stream(RDF.Data.t(), keyword) :: Enumerable.t()

  @optional_callbacks stream: 2

  defmacro __using__(_) do
    quote bind_quoted: [], unquote: true, generated: true do
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

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      @stream_support __MODULE__ |> Module.definitions_in() |> Keyword.has_key?(:stream)
      @doc false
      def stream_support?, do: @stream_support
    end
  end
end
