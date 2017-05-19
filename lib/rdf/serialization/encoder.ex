defmodule RDF.Serialization.Encoder do
  @moduledoc false

  @callback encode(RDF.Dataset, keyword) :: keyword(String.t)
  @callback encode!(RDF.Dataset, keyword) :: String.t


  defmacro __using__(_) do
    quote bind_quoted: [], unquote: true do
      @behaviour unquote(__MODULE__)

      def encode!(data, opts \\ []) do
        case encode(data, opts) do
          {:ok,    data}   -> data
          {:error, reason} -> raise reason
        end
      end

      defoverridable [encode!: 2]
    end
  end

end
