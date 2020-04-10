defmodule RDF.Literal.Helper.Macros do
  @moduledoc false

  defmacro defdelegate_to_rdf_datatype(fun_name) do
    quote do
      def unquote(fun_name)(%__MODULE__{literal: %datatype{}} = literal) do
        apply(RDF.Literal.Datatype.Registry.rdf_datatype(datatype), unquote(fun_name), [literal])
      end
    end
  end
end
