defmodule RDF.Reader do
  @moduledoc false

  @callback read_file(String.t, keyword) :: keyword(RDF.Graph)
  @callback read_file!(String.t, keyword) :: RDF.Graph
  @callback read_string(String.t, keyword) :: keyword(RDF.Graph)
  @callback read_string!(String.t, keyword) :: RDF.Graph

  defmacro __using__(_) do
    quote bind_quoted: [], unquote: true do
      @behaviour unquote(__MODULE__)

      def read(file_or_content, opts \\ []) do
        if File.exists?(file_or_content) do
          read_file(file_or_content, opts)
        else
          read_string(file_or_content, opts)
        end
      end

      def read!(file_or_content, opts \\ []) do
        case read(file_or_content, opts) do
          {:ok,   graph}   -> graph
          {:error, reason} -> raise reason
        end
      end

      def read_file(file, opts \\ []) do
        case File.read(file) do
          {:ok,   content} -> read_string(content, opts)
          {:error, reason} -> {:error, reason}
        end
      end

      def read_file!(file, opts \\ []) do
        case read_file(file, opts) do
          {:ok,   graph}   -> graph
          {:error, reason} -> raise File.Error, path: file, action: "read", reason: reason
        end
      end

      def read_string!(content, opts \\ []) do
        case read_string(content, opts) do
          {:ok,   graph}   -> graph
          {:error, reason} -> raise reason
        end
      end

      defoverridable [read: 2, read!: 2, read_file: 2, read_file!: 2, read_string!: 2]
    end
  end

end
