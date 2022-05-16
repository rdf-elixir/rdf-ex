defmodule External do
  defstruct []

  import RDF.Sigils
  def data, do: RDF.triple(~I<http://example.com/S>, ~I<http://example.com/p>, 42)

  defimpl RDF.Data do
    def merge(%External{}, data, opts) do
      RDF.Data.merge(data, External.data(), opts)
    end

    def delete(_external, _, _opts), do: nil
    def pop(_external), do: nil
    def empty?(_external), do: false
    def include?(_external, _, _opts \\ []), do: false
    def describes?(_external, _), do: false
    def description(_external, _), do: nil
    def descriptions(_external), do: []
    def statements(_external), do: []
    def subjects(_external), do: []
    def predicates(_external), do: []
    def objects(_external), do: []
    def resources(_external), do: []
    def subject_count(_external), do: 0
    def statement_count(_external), do: 0

    def values(_external, _opts \\ []), do: nil
    def map(_external, _fun), do: nil

    def equal?(%External{}, data) do
      RDF.Data.equal?(data, RDF.graph(External.data()))
    end
  end
end
