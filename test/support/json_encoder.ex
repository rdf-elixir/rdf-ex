# credo:disable-for-this-file Credo.Check.Readability.ModuleDoc
defmodule CustomJSON do
  defstruct [:value]

  defimpl Jason.Encoder do
    def encode(%{value: value}, opts) do
      Jason.Encode.map(%{custom: value}, opts)
    end
  end
end
