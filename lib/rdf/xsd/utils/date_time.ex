defmodule RDF.XSD.Utils.DateTime do
  @moduledoc false

  @spec tz(String.t()) :: String.t()
  def tz(string) do
    case RDF.Utils.Regex.run(~r/([+-])(\d\d:\d\d)/, string) do
      [_, sign, zone] ->
        sign <> zone

      _ ->
        if String.ends_with?(string, "Z") do
          "Z"
        else
          ""
        end
    end
  end
end
