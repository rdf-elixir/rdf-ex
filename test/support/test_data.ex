defmodule RDF.TestData do
  @moduledoc """
  Functions for accessing test data.

  Both internal and official test data for the W3C test suites.
  """

  @dir Path.join(File.cwd!(), "test/data/")
  def dir, do: @dir

  def path(name) do
    path = Path.join(@dir, name)

    if File.exists?(path) do
      path
    else
      raise "test data file '#{path}' not found"
    end
  end
end
