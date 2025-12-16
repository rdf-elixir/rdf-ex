defmodule External do
  @moduledoc """
  A dummy struct to test external `RDF.Data.Source` protocol implementations.
  """

  defstruct [:data]

  import RDF.Sigils

  def new(data \\ nil) do
    %__MODULE__{
      data:
        data ||
          RDF.graph([
            {~I<http://example.com/S>, ~I<http://example.com/p>, 42},
            {~I<http://example.com/S>, ~I<http://example.com/q>, ~I<http://example.com/O>}
          ])
    }
  end

  defimpl RDF.Data.Source do
    def structure_type(_), do: :graph

    def reduce(%External{data: graph}, acc, fun) do
      RDF.Data.Source.reduce(graph, acc, fun)
    end

    def description(%External{data: graph}, subject) do
      RDF.Data.Source.description(graph, subject)
    end

    def graph(%External{data: graph}, graph_name) do
      RDF.Data.Source.graph(graph, graph_name)
    end

    def statement_count(%External{data: graph}) do
      RDF.Data.Source.statement_count(graph)
    end

    def description_count(%External{data: graph}) do
      RDF.Data.Source.description_count(graph)
    end

    def graph_count(_external), do: {:ok, 1}

    def subjects(%External{data: graph}) do
      RDF.Data.Source.subjects(graph)
    end

    def graph_names(_external) do
      {:ok, [nil]}
    end

    def graph_name(%External{data: graph}) do
      RDF.Data.Source.graph_name(graph)
    end

    def subject(%External{}), do: nil

    def add(%External{data: graph} = external, statements) do
      with {:ok, updated_graph} <- RDF.Data.Source.add(graph, statements) do
        {:ok, %External{external | data: updated_graph}}
      end
    end

    def delete(%External{data: graph} = external, statements) do
      with {:ok, updated_graph} <- RDF.Data.Source.delete(graph, statements) do
        {:ok, %External{external | data: updated_graph}}
      end
    end

    def derive(%External{data: graph}, :graph, opts) do
      with {:ok, new_graph} <- RDF.Data.Source.derive(graph, :graph, opts) do
        {:ok, %External{data: new_graph}}
      end
    end

    def derive(%External{}, :description, opts) do
      case Keyword.fetch(opts, :subject) do
        {:ok, subject} -> {:ok, RDF.Description.new(subject)}
        :error -> {:error, :no_subject}
      end
    end

    def derive(%External{}, :dataset, _opts) do
      {:ok, RDF.Dataset.new()}
    end
  end
end

defmodule MinimalDescription do
  @moduledoc """
  A minimal `RDF.Data.Source` implementation for testing fallback logic.

  Only implements the required functions.
  """

  defstruct [:subject, :data]

  def new(subject, data \\ nil) do
    %__MODULE__{
      subject: RDF.coerce_subject(subject),
      data: data || RDF.Description.new(subject)
    }
  end

  def add(%__MODULE__{data: data} = minimal_description, statements) do
    %{minimal_description | data: RDF.Description.add(data, statements)}
  end

  defimpl RDF.Data.Source do
    def structure_type(_), do: :description

    def reduce(%MinimalDescription{data: desc}, acc, fun) do
      RDF.Data.Source.reduce(desc, acc, fun)
    end

    def derive(%MinimalDescription{subject: s}, :description, opts) do
      {:ok, MinimalDescription.new(Keyword.get(opts, :subject, s))}
    end

    def derive(%MinimalDescription{}, :graph, opts) do
      {:ok, MinimalGraph.new(nil, name: opts[:name])}
    end

    def derive(%MinimalDescription{}, :dataset, opts) do
      {:ok, MinimalDataset.new(nil, name: opts[:name])}
    end

    def description(%MinimalDescription{subject: s} = minimal, subject) do
      if s == RDF.coerce_subject(subject), do: {:ok, minimal}, else: :error
    end

    def graph(%MinimalDescription{data: desc}, nil),
      do: {:ok, MinimalGraph.new(RDF.Graph.new(desc))}

    def graph(%MinimalDescription{}, _), do: :error

    def subject(%MinimalDescription{subject: s}), do: s
    def graph_name(_), do: nil

    def graph_names(_), do: {:error, __MODULE__}
    def subjects(_), do: {:error, __MODULE__}
    def statement_count(_), do: {:error, __MODULE__}
    def description_count(_), do: {:error, __MODULE__}
    def graph_count(_), do: {:error, __MODULE__}
    def add(_, _), do: {:error, __MODULE__}
    def delete(_, _), do: {:error, __MODULE__}
  end
end

defmodule MinimalGraph do
  @moduledoc """
  A minimal `RDF.Data.Source` implementation for testing fallback logic.

  Only implements the required functions.
  """

  defstruct [:name, :data]

  def new(data \\ nil, opts \\ []) do
    %__MODULE__{
      name: Keyword.get(opts, :name),
      data: data || RDF.Graph.new()
    }
  end

  def add(%__MODULE__{data: graph} = minimal_graph, statements) do
    %{minimal_graph | data: RDF.Graph.add(graph, statements)}
  end

  defimpl RDF.Data.Source do
    def structure_type(_), do: :graph

    def reduce(%MinimalGraph{data: graph}, acc, fun) do
      RDF.Data.Source.reduce(graph, acc, fun)
    end

    def derive(%MinimalGraph{}, :description, opts) do
      case Keyword.fetch(opts, :subject) do
        {:ok, subject} -> {:ok, MinimalDescription.new(subject)}
        :error -> {:error, :no_subject}
      end
    end

    def derive(%MinimalGraph{name: n}, :graph, opts) do
      {:ok, MinimalGraph.new(nil, name: opts[:name] || n)}
    end

    def derive(%MinimalGraph{}, :dataset, opts) do
      {:ok, MinimalDataset.new(nil, name: opts[:name])}
    end

    def description(%MinimalGraph{data: graph}, subject) do
      with {:ok, desc} <- RDF.Data.Source.description(graph, subject) do
        {:ok, MinimalDescription.new(desc.subject, desc)}
      end
    end

    def graph(%MinimalGraph{name: n} = minimal, graph_name) do
      if n == RDF.coerce_graph_name(graph_name), do: {:ok, minimal}, else: :error
    end

    def subject(_), do: nil
    def graph_name(%MinimalGraph{name: n}), do: n

    def graph_names(_), do: {:error, __MODULE__}
    def subjects(_), do: {:error, __MODULE__}
    def statement_count(_), do: {:error, __MODULE__}
    def description_count(_), do: {:error, __MODULE__}
    def graph_count(_), do: {:error, __MODULE__}
    def add(_, _), do: {:error, __MODULE__}
    def delete(_, _), do: {:error, __MODULE__}
  end
end

defmodule MinimalDataset do
  @moduledoc """
  A minimal `RDF.Data.Source` implementation for testing fallback logic.

  Only implements the required functions.
  """

  defstruct [:name, :data]

  def new(data \\ nil, opts \\ []) do
    %__MODULE__{
      name: Keyword.get(opts, :name),
      data: data || RDF.Dataset.new()
    }
  end

  def add(%__MODULE__{data: dataset} = minimal_dataset, statements) do
    %{minimal_dataset | data: RDF.Dataset.add(dataset, statements)}
  end

  defimpl RDF.Data.Source do
    def structure_type(_), do: :dataset

    def reduce(%MinimalDataset{data: dataset}, acc, fun) do
      RDF.Data.Source.reduce(dataset, acc, fun)
    end

    def derive(%MinimalDataset{}, :description, opts) do
      case Keyword.fetch(opts, :subject) do
        {:ok, subject} -> {:ok, MinimalDescription.new(subject)}
        :error -> {:error, :no_subject}
      end
    end

    def derive(%MinimalDataset{}, :graph, opts) do
      {:ok, MinimalGraph.new(nil, name: opts[:name])}
    end

    def derive(%MinimalDataset{name: n}, :dataset, opts) do
      {:ok, MinimalDataset.new(nil, name: opts[:name] || n)}
    end

    def description(%MinimalDataset{data: dataset}, subject) do
      with {:ok, desc} <- RDF.Data.Source.description(dataset, subject) do
        {:ok, MinimalDescription.new(desc.subject, desc)}
      end
    end

    def graph(%MinimalDataset{data: dataset}, graph_name) do
      with {:ok, graph} <- RDF.Data.Source.graph(dataset, graph_name) do
        {:ok, MinimalGraph.new(graph, name: graph.name)}
      end
    end

    def subject(_), do: nil
    def graph_name(_), do: nil

    def graph_names(_), do: {:error, __MODULE__}
    def subjects(_), do: {:error, __MODULE__}
    def statement_count(_), do: {:error, __MODULE__}
    def description_count(_), do: {:error, __MODULE__}
    def graph_count(_), do: {:error, __MODULE__}

    def add(_, _), do: {:error, __MODULE__}
    def delete(_, _), do: {:error, __MODULE__}
  end
end
