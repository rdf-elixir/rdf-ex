use Mix.Config

unless Mix.env in ~w[docs bench]a do
  import_config "#{Mix.env}.exs"
end
