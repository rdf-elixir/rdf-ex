defmodule RDF.Reader do

  def read(decoder, file_or_content, opts \\ []) do
    if File.exists?(file_or_content) do
      read_file(decoder, file_or_content, opts)
    else
      read_string(decoder, file_or_content, opts)
    end
  end

  def read!(decoder, file_or_content, opts \\ []) do
    case read(decoder, file_or_content, opts) do
      {:ok,   graph}   -> graph
      {:error, reason} -> raise reason
    end
  end

  def read_string(decoder, content, opts \\ []) do
    decoder.decode(content, opts)
  end

  def read_string!(decoder, content, opts \\ []) do
    decoder.decode!(content, opts)
  end

  def read_file(decoder, file, opts \\ []) do
    case File.read(file) do
      {:ok,   content} -> read_string(decoder, content, opts)
      {:error, reason} -> {:error, reason}
    end
  end

  def read_file!(decoder, file, opts \\ []) do
    with content = File.read!(file) do
      read_string!(decoder, content, opts)
    end
  end

end
