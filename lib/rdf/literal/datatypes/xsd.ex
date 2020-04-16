defmodule RDF.Literal.XSD do
  @moduledoc false

  alias RDF.Literal

  @after_compile __MODULE__

  def __after_compile__(_env, _bytecode) do
    Enum.each XSD.datatypes(), &def_xsd_datatype/1
  end

  defp def_xsd_datatype(xsd_datatype) do
    xsd_datatype
    |> datatype_module_name()
    |> Module.create(datatype_module_body(xsd_datatype), Macro.Env.location(__ENV__))
  end

  def datatype_module_name(xsd_datatype) do
    Module.concat(RDF, xsd_datatype)
  end

  defp datatype_module_body(xsd_datatype) do
    [
      quote do
        @behaviour RDF.Literal.Datatype

        def new(value, opts \\ []) do
          %Literal{literal: unquote(xsd_datatype).new(value, opts)}
        end

        def new!(value, opts \\ []) do
          %Literal{literal: unquote(xsd_datatype).new!(value, opts)}
        end

        @impl RDF.Literal.Datatype
        def literal_type, do: unquote(xsd_datatype)

        @impl RDF.Literal.Datatype
        defdelegate name, to: unquote(xsd_datatype)

        @impl RDF.Literal.Datatype
        defdelegate id, to: unquote(xsd_datatype)

        @iri RDF.IRI.new(unquote(xsd_datatype).id())
        @impl RDF.Literal.Datatype
        def datatype(%Literal{literal: literal}), do: datatype(literal)
        def datatype(%unquote(xsd_datatype){}), do: @iri

        @impl RDF.Literal.Datatype
        def language(%Literal{literal: literal}), do: language(literal)
        def language(%unquote(xsd_datatype){}), do: nil

        @impl RDF.Literal.Datatype
        def value(%Literal{literal: literal}), do: value(literal)
        def value(%unquote(xsd_datatype){} = literal), do: unquote(xsd_datatype).value(literal)

        @impl RDF.Literal.Datatype
        def lexical(%Literal{literal: literal}), do: lexical(literal)
        def lexical(%unquote(xsd_datatype){} = literal), do: unquote(xsd_datatype).lexical(literal)

        @impl RDF.Literal.Datatype
        def canonical(%Literal{literal: %unquote(xsd_datatype){} = typed_literal} = literal),
          do: %Literal{literal | literal: unquote(xsd_datatype).canonical(typed_literal)}
        def canonical(%unquote(xsd_datatype){} = literal), do: canonical(%Literal{literal: literal})

        @impl RDF.Literal.Datatype
        def canonical?(%Literal{literal: literal}), do: canonical?(literal)
        def canonical?(%unquote(xsd_datatype){} = literal), do: unquote(xsd_datatype).canonical?(literal)

        @impl RDF.Literal.Datatype
        def valid?(%Literal{literal: literal}), do: valid?(literal)
        def valid?(%unquote(xsd_datatype){} = literal), do: unquote(xsd_datatype).valid?(literal)
        def valid?(_), do: false

        @impl RDF.Literal.Datatype
        def cast(%Literal{literal: %unquote(xsd_datatype){}} = literal), do: literal
        def cast(%Literal{literal: literal}) do
          if casted_literal = unquote(xsd_datatype).cast(literal) do
            %Literal{literal: casted_literal}
          end
        end
        def cast(nil), do: nil
        def cast(value), do: value |> Literal.new() |> cast()

        @impl RDF.Literal.Datatype
        def equal_value?(left, %Literal{literal: right}), do: equal_value?(left, right)
        def equal_value?(%Literal{literal: left}, right), do: equal_value?(left, right)
        def equal_value?(%unquote(xsd_datatype){} = left, right) do
          unquote(xsd_datatype).equal_value?(left, right)
        end
        def equal_value?(_, _), do: false

        @impl RDF.Literal.Datatype
        @dialyzer {:nowarn_function, compare: 2} # TODO: Why is this warning raised
        def compare(left, %Literal{literal: right}), do: compare(left, right)
        def compare(%Literal{literal: left}, right), do: compare(left, right)
        def compare(%unquote(xsd_datatype){} = left, right) do
          unquote(xsd_datatype).compare(left, right)
        end
      end
    | datatype_specific_module_body(xsd_datatype)]
  end

  defp datatype_specific_module_body(XSD.Boolean) do
    [
      quote do
        def ebv(%Literal{literal: literal}), do: ebv(literal)
        def ebv(literal) do
          if ebv = XSD.Boolean.ebv(literal), do: %Literal{literal: ebv}
        end

        def effective(value), do: ebv(value)

        def fn_not(%Literal{literal: literal}), do: fn_not(literal)
        def fn_not(literal) do
          if result = XSD.Boolean.fn_not(literal), do: %Literal{literal: result}
        end

        def logical_and(%Literal{literal: left}, right), do: logical_and(left, right)
        def logical_and(left, %Literal{literal: right}), do: logical_and(left, right)
        def logical_and(left, right) do
          if result = XSD.Boolean.logical_and(left, right), do: %Literal{literal: result}
        end

        def logical_or(%Literal{literal: left}, right), do: logical_or(left, right)
        def logical_or(left, %Literal{literal: right}), do: logical_or(left, right)
        def logical_or(left, right) do
          if result = XSD.Boolean.logical_or(left, right), do: %Literal{literal: result}
        end
      end
    ]
  end

  defp datatype_specific_module_body(XSD.DateTime) do
    [
      quote do
        def now(), do: XSD.DateTime.now() |> new()
      end
    ]
  end

  defp datatype_specific_module_body(_), do: []
end
