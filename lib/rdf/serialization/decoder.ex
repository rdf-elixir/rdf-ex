defmodule RDF.Serialization.Decoder do
  @moduledoc false

  @callback decode(String.t, keyword) :: keyword(RDF.Graph)
  @callback decode!(String.t, keyword) :: RDF.Graph


  defmacro __using__(_) do
    quote bind_quoted: [], unquote: true do
      @behaviour unquote(__MODULE__)

      def decode!(content, opts \\ []) do
        case decode(content, opts) do
          {:ok,    data}   -> data
          {:error, reason} -> raise reason
        end
      end

      defoverridable [decode!: 2]
    end
  end

end
