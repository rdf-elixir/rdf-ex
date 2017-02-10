ExUnit.start()

with {:ok, files} = File.ls("./test/support") do
  Enum.each files, fn(file) ->
    Code.require_file "support/#{file}", __DIR__
  end
end
