defmodule RDF.TestData do

  @dir Path.join(File.cwd!, "test/data/")
  def dir, do: @dir

  def file(name) do
    if (path = Path.join(@dir, name)) |> File.exists? do
      path
    else
      raise "Test data file '#{name}' not found"
    end
  end

end
