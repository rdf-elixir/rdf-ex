defmodule RDF.Reader do



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
