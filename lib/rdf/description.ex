defmodule RDF.Description do
  @moduledoc """
  A set of RDF triples about the same subject.

  `RDF.Description` implements:

  - Elixir's `Access` behaviour
  - Elixir's `Enumerable` protocol
  - Elixir's `Inspect` protocol
  - the `RDF.Data` protocol
  """

  @behaviour Access

  import RDF.Statement
  alias RDF.{Statement, Triple}

  @enforce_keys [:subject]
  defstruct subject: nil, predications: %{}

  @type t :: %__MODULE__{
          subject: Statement.subject(),
          predications: predications
        }

  @type predications :: %{Statement.predicate() => %{Statement.object() => nil}}

  @type input ::
          Triple.coercible_t()
          | {Statement.coercible_predicate(),
             Statement.coercible_object() | [Statement.coercible_object()]}
          | %{
              Statement.coercible_predicate() =>
                Statement.coercible_object() | [Statement.coercible_object()]
            }
          | [
              Triple.coercible_t()
              | {Statement.coercible_predicate(),
                 Statement.coercible_object() | [Statement.coercible_object()]}
              | t
            ]
          | t

  @doc """
  Creates an empty `RDF.Description` about the given subject.
  """
  @spec new(Statement.coercible_subject() | Triple.coercible_t() | t) :: t
  def new(subject)
  def new(%__MODULE__{} = description), do: new(description.subject)
  def new({subject, predicate, object}), do: new(subject) |> add({predicate, object})
  def new(subject), do: %__MODULE__{subject: coerce_subject(subject)}

  @doc """
  Returns the subject IRI or blank node of a description.
  """
  def subject(%__MODULE__{} = description), do: description.subject

  @doc """
  Changes the subject of a description.
  """
  def change_subject(%__MODULE__{} = description, new_subject) do
    %__MODULE__{description | subject: coerce_subject(new_subject)}
  end

  @doc """
  Add statements to a `RDF.Description`.

  Note: When the statements to be added are given as another `RDF.Description`,
  the subject must not match subject of the description to which the statements
  are added. As opposed to that `RDF.Data.merge/2` will produce a `RDF.Graph`
  containing both descriptions.

  ## Examples

      iex> RDF.Description.new({EX.S, EX.P1, EX.O1}) |> RDF.Description.add({EX.P2, EX.O2})
      RDF.Description.new(EX.S) |> RDF.Description.add([{EX.P1, EX.O1}, {EX.P2, EX.O2}])
      iex> RDF.Description.new({EX.S, EX.P, EX.O1}) |> RDF.Description.add({EX.P, [EX.O2, EX.O3]})
      RDF.Description.new(EX.S) |> RDF.Description.add([{EX.P, EX.O1}, {EX.P, EX.O2}, {EX.P, EX.O3}])

  """
  @spec add(t, input, keyword) :: t
  def add(description, input, opts \\ [])

  # This implementation is actually unnecessary as the implementation with the is_map clause
  # would work perfectly fine with RDF.Descriptions Enumerable implementation.
  # It exists only for performance reasons, since this version is roughly twice as fast.
  def add(%__MODULE__{} = description, %__MODULE__{} = input_description, _opts) do
    %__MODULE__{
      description
      | predications:
          Map.merge(
            description.predications,
            input_description.predications,
            fn _predicate, objects, new_objects ->
              Map.merge(objects, new_objects)
            end
          )
    }
  end

  def add(description, predications, opts)
      when is_map(predications) or is_list(predications) do
    Enum.reduce(predications, description, fn
      predications, description -> add(description, predications, opts)
    end)
  end

  def add(%__MODULE__{} = description, {subject, predicate, objects}, opts) do
    if coerce_subject(subject) == description.subject do
      add(description, {predicate, objects}, opts)
    else
      description
    end
  end

  def add(%__MODULE__{} = description, {predicate, objects}, _opts) do
    normalized_objects =
      objects
      |> List.wrap()
      |> Map.new(fn object -> {coerce_object(object), nil} end)

    if Enum.empty?(normalized_objects) do
      description
    else
      %__MODULE__{
        description
        | predications:
            Map.update(
              description.predications,
              coerce_predicate(predicate),
              normalized_objects,
              fn objects ->
                Map.merge(objects, normalized_objects)
              end
            )
      }
    end
  end

  @doc """
  Adds statements to a `RDF.Description` and overwrites all existing statements with already used predicates.

  Note: As it is a destructive function this function is more strict in its handling of
  `RDF.Description`s than `add/3`. The subject of a `RDF.Description` to be put must
  match. If you want to overwrite existing statements with those from the description of
  another subject, you'll have to explicitly change the subject with `change_subject/2`
  first before using `put/3`.

  ## Examples

      iex> RDF.Description.put(RDF.Description.new({EX.S, EX.P, EX.O1}), {EX.P, EX.O2})
      RDF.Description.new({EX.S, EX.P, EX.O2})

  """
  @spec put(t, input, keyword) :: t
  def put(description, input, opts \\ [])

  def put(
        %__MODULE__{subject: subject} = description,
        %__MODULE__{subject: subject} = input,
        _opts
      ) do
    %__MODULE__{
      description
      | predications:
          Enum.reduce(
            input.predications,
            description.predications,
            fn {predicate, objects}, predications ->
              Map.put(predications, predicate, objects)
            end
          )
    }
  end

  def put(%__MODULE__{} = description, %__MODULE__{}, _opts), do: description

  def put(%__MODULE__{} = description, input, opts) do
    put(description, description.subject |> new() |> add(input), opts)
  end

  @doc """
  Deletes statements from a `RDF.Description`.

  Note: When the statements to be deleted are given as another `RDF.Description`,
  the subject must not match subject of the description from which the statements
  are deleted. If you want to delete only a matching description subject, you can
  use `RDF.Data.delete/2`.
  """
  @spec delete(t, input, keyword) :: t
  def delete(description, input, opts \\ [])

  # This implementation is actually unnecessary as the implementation with the is_map clause
  # would work perfectly fine with RDF.Descriptions Enumerable implementation.
  # It exists only for performance reasons.
  def delete(%__MODULE__{} = description, %__MODULE__{} = input_description, _opts) do
    predications = description.predications

    %__MODULE__{
      description
      | predications:
          Enum.reduce(
            input_description.predications,
            predications,
            fn {predicate, objects}, predications ->
              if current_objects = Map.get(description.predications, predicate) do
                rest = Map.drop(current_objects, Map.keys(objects))

                if Enum.empty?(rest) do
                  Map.delete(predications, predicate)
                else
                  Map.put(predications, predicate, rest)
                end
              else
                predications
              end
            end
          )
    }
  end

  def delete(description, predications, opts)
      when is_map(predications) or is_list(predications) do
    Enum.reduce(predications, description, fn
      predications, description -> delete(description, predications, opts)
    end)
  end

  def delete(%__MODULE__{} = description, {subject, predicate, objects}, opts) do
    if coerce_subject(subject) == description.subject do
      delete(description, {predicate, objects}, opts)
    else
      description
    end
  end

  def delete(%__MODULE__{} = description, {predicate, objects}, _opts) do
    predicate = coerce_predicate(predicate)

    if current_objects = Map.get(description.predications, predicate) do
      normalized_objects =
        objects
        |> List.wrap()
        |> Enum.map(&coerce_object/1)

      rest = Map.drop(current_objects, normalized_objects)

      %__MODULE__{
        description
        | predications:
            if Enum.empty?(rest) do
              Map.delete(description.predications, predicate)
            else
              Map.put(description.predications, predicate, rest)
            end
      }
    else
      description
    end
  end

  @doc """
  Deletes all statements with the given properties.
  """
  @spec delete_predicates(t, Statement.coercible_predicate() | [Statement.coercible_predicate()]) ::
          t
  def delete_predicates(description, properties)

  def delete_predicates(%__MODULE__{} = description, properties) when is_list(properties) do
    Enum.reduce(properties, description, fn property, description ->
      delete_predicates(description, property)
    end)
  end

  def delete_predicates(%__MODULE__{subject: subject, predications: predications}, property) do
    %__MODULE__{
      subject: subject,
      predications: Map.delete(predications, coerce_predicate(property))
    }
  end

  @doc """
  Fetches the objects for the given predicate of a Description.

  When the predicate can not be found `:error` is returned.

  ## Examples

      iex> RDF.Description.new({EX.S, EX.p, EX.O}) |> RDF.Description.fetch(EX.p)
      {:ok, [RDF.iri(EX.O)]}
      iex> RDF.Description.new(EX.S) |> RDF.Description.add([{EX.P, EX.O1}, {EX.P, EX.O2}]) |>
      ...>   RDF.Description.fetch(EX.P)
      {:ok, [RDF.iri(EX.O1), RDF.iri(EX.O2)]}
      iex> RDF.Description.fetch(RDF.Description.new(EX.S), EX.foo)
      :error
  """
  @impl Access
  @spec fetch(t, Statement.coercible_predicate()) :: {:ok, [Statement.object()]} | :error
  def fetch(%__MODULE__{predications: predications}, predicate) do
    with {:ok, objects} <- Access.fetch(predications, coerce_predicate(predicate)) do
      {:ok, Map.keys(objects)}
    end
  end

  @doc """
  Gets the objects for the given predicate of a Description.

  When the predicate can not be found, the optionally given default value or `nil` is returned.

  ## Examples

      iex> RDF.Description.get(RDF.Description.new({EX.S, EX.P, EX.O}), EX.P)
      [RDF.iri(EX.O)]
      iex> RDF.Description.get(RDF.Description.new(EX.S), EX.foo)
      nil
      iex> RDF.Description.get(RDF.Description.new(EX.S), EX.foo, :bar)
      :bar
  """
  @spec get(t, Statement.coercible_predicate(), any) :: [Statement.object()] | any
  def get(description = %__MODULE__{}, predicate, default \\ nil) do
    case fetch(description, predicate) do
      {:ok, value} -> value
      :error -> default
    end
  end

  @doc """
  Gets a single object for the given predicate of a Description.

  When the predicate can not be found, the optionally given default value or `nil` is returned.

  ## Examples

      iex> RDF.Description.first(RDF.Description.new({EX.S, EX.P, EX.O}), EX.P)
      RDF.iri(EX.O)
      iex> RDF.Description.first(RDF.Description.new(EX.S), EX.foo)
      nil
  """
  @spec first(t, Statement.coercible_predicate()) :: Statement.object() | nil
  def first(description = %__MODULE__{}, predicate) do
    description
    |> get(predicate, [])
    |> List.first()
  end

  @doc """
  Updates the objects of the `predicate` in `description` with the given function.

  If `predicate` is present in `description` with `objects` as value,
  `fun` is invoked with argument `objects` and its result is used as the new
  list of objects of `predicate`. If `predicate` is not present in `description`,
  `initial` is inserted as the objects of `predicate`. The initial value will
  not be passed through the update function.

  The initial value and the returned objects by the update function will automatically
  coerced to proper RDF object values before added.

  ## Examples

      iex> RDF.Description.new({EX.S, EX.p, EX.O}) |>
      ...> RDF.Description.update(EX.p, fn objects -> [EX.O2 | objects] end)
      RDF.Description.new(EX.S) |> RDF.Description.add([{EX.p, EX.O}, {EX.p, EX.O2}])
      iex> RDF.Description.new(EX.S) |>
      ...> RDF.Description.update(EX.p, EX.O, fn _ -> EX.O2 end)
      RDF.Description.new({EX.S, EX.p, EX.O})

  """
  @spec update(
          t,
          Statement.coercible_predicate(),
          Statement.coercible_object() | nil,
          ([Statement.Object] -> [Statement.Object])
        ) :: t
  def update(description = %__MODULE__{}, predicate, initial \\ nil, fun) do
    predicate = coerce_predicate(predicate)

    case get(description, predicate) do
      nil ->
        if initial do
          put(description, {predicate, initial})
        else
          description
        end

      objects ->
        objects
        |> fun.()
        |> List.wrap()
        |> case do
          [] -> delete_predicates(description, predicate)
          objects -> put(description, {predicate, objects})
        end
    end
  end

  @doc """
  Gets and updates the objects of the given predicate of a Description, in a single pass.

  Invokes the passed function on the objects of the given predicate; this
  function should return either `{objects_to_return, new_object}` or `:pop`.

  If the passed function returns `{objects_to_return, new_objects}`, the return
  value of `get_and_update` is `{objects_to_return, new_description}` where
  `new_description` is the input `Description` updated with `new_objects` for
  the given predicate.

  If the passed function returns `:pop` the objects for the given predicate are
  removed and a `{removed_objects, new_description}` tuple gets returned.

  ## Examples

      iex> RDF.Description.new({EX.S, EX.P, EX.O}) |>
      ...>   RDF.Description.get_and_update(EX.P, fn current_objects ->
      ...>     {current_objects, EX.NEW}
      ...>   end)
      {[RDF.iri(EX.O)], RDF.Description.new({EX.S, EX.P, EX.NEW})}
      iex> RDF.Graph.new([{EX.S, EX.P1, EX.O1}, {EX.S, EX.P2, EX.O2}]) |>
      ...>   RDF.Graph.description(EX.S) |>
      ...>   RDF.Description.get_and_update(EX.P1, fn _ -> :pop end)
      {[RDF.iri(EX.O1)], RDF.Description.new({EX.S, EX.P2, EX.O2})}
  """
  @impl Access
  @spec get_and_update(
          t,
          Statement.coercible_predicate(),
          ([Statement.Object] -> {[Statement.Object], t} | :pop)
        ) :: {[Statement.Object], t}
  def get_and_update(description = %__MODULE__{}, predicate, fun) do
    triple_predicate = coerce_predicate(predicate)

    case fun.(get(description, triple_predicate)) do
      {objects_to_return, new_objects} ->
        {objects_to_return, put(description, {triple_predicate, new_objects})}

      :pop ->
        pop(description, triple_predicate)
    end
  end

  @doc """
  Pops an arbitrary triple from a `RDF.Description`.
  """
  @spec pop(t) :: {Triple.t() | [Statement.Object] | nil, t}
  def pop(description)

  def pop(description = %__MODULE__{predications: predications})
      when map_size(predications) == 0,
      do: {nil, description}

  def pop(%__MODULE__{subject: subject, predications: predications}) do
    [{predicate, objects}] = Enum.take(predications, 1)
    [{object, _}] = Enum.take(objects, 1)

    popped =
      if Enum.count(objects) == 1,
        do: elem(Map.pop(predications, predicate), 1),
        else: elem(pop_in(predications, [predicate, object]), 1)

    {{subject, predicate, object}, %__MODULE__{subject: subject, predications: popped}}
  end

  @doc """
  Pops the objects of the given predicate of a Description.

  When the predicate can not be found the optionally given default value or `nil` is returned.

  ## Examples

      iex> RDF.Description.pop(RDF.Description.new({EX.S, EX.P, EX.O}), EX.P)
      {[RDF.iri(EX.O)], RDF.Description.new(EX.S)}
      iex> RDF.Description.pop(RDF.Description.new({EX.S, EX.P, EX.O}), EX.Missing)
      {nil, RDF.Description.new({EX.S, EX.P, EX.O})}
  """
  @impl Access
  def pop(description = %__MODULE__{subject: subject, predications: predications}, predicate) do
    case Access.pop(predications, coerce_predicate(predicate)) do
      {nil, _} ->
        {nil, description}

      {objects, new_predications} ->
        {Map.keys(objects), %__MODULE__{subject: subject, predications: new_predications}}
    end
  end

  @doc """
  The set of all properties used in the predicates within a `RDF.Description`.

  ## Examples

      iex> RDF.Description.new(EX.S1) |> RDF.Description.add([
      ...>   {EX.p1, EX.O1},
      ...>   {EX.p2, EX.O2},
      ...>   {EX.p2, EX.O3}]) |>
      ...>   RDF.Description.predicates
      MapSet.new([EX.p1, EX.p2])
  """
  @spec predicates(t) :: MapSet.t()
  def predicates(%__MODULE__{predications: predications}),
    do: predications |> Map.keys() |> MapSet.new()

  @doc """
  The set of all resources used in the objects within a `RDF.Description`.

  Note: This function does collect only IRIs and BlankNodes, not Literals.

  ## Examples

      iex> RDF.Description.new(EX.S1) |> RDF.Description.add([
      ...>   {EX.p1, EX.O1},
      ...>   {EX.p2, EX.O2},
      ...>   {EX.p3, EX.O2},
      ...>   {EX.p4, RDF.bnode(:bnode)},
      ...>   {EX.p3, "foo"}
      ...> ]) |> RDF.Description.objects
      MapSet.new([RDF.iri(EX.O1), RDF.iri(EX.O2), RDF.bnode(:bnode)])
  """
  @spec objects(t) :: MapSet.t()
  def objects(%__MODULE__{} = description),
    do: objects(description, &RDF.resource?/1)

  @doc """
  The set of all resources used in the objects within a `RDF.Description` satisfying the given filter criterion.
  """
  @spec objects(t, (Statement.object() -> boolean)) :: MapSet.t()
  def objects(%__MODULE__{predications: predications}, filter_fn) do
    Enum.reduce(predications, MapSet.new(), fn {_, objects}, acc ->
      objects
      |> Map.keys()
      |> Enum.filter(filter_fn)
      |> MapSet.new()
      |> MapSet.union(acc)
    end)
  end

  @doc """
  The set of all resources used within a `RDF.Description`.

  ## Examples

      iex> RDF.Description.new(EX.S1) |> RDF.Description.add([
      ...>   {EX.p1, EX.O1},
      ...>   {EX.p2, EX.O2},
      ...>   {EX.p1, EX.O2},
      ...>   {EX.p2, RDF.bnode(:bnode)},
      ...>   {EX.p3, "foo"}
      ...> ]) |> RDF.Description.resources
      MapSet.new([RDF.iri(EX.O1), RDF.iri(EX.O2), RDF.bnode(:bnode), EX.p1, EX.p2, EX.p3])
  """
  @spec resources(t) :: MapSet.t()
  def resources(description) do
    description
    |> objects
    |> MapSet.union(predicates(description))
  end

  @doc """
  The list of all triples within a `RDF.Description`.
  """
  @spec triples(t) :: keyword
  def triples(description = %__MODULE__{}), do: Enum.to_list(description)

  defdelegate statements(description), to: __MODULE__, as: :triples

  @doc """
  Returns the number of statements of a `RDF.Description`.
  """
  @spec count(t) :: non_neg_integer
  def count(%__MODULE__{predications: predications}) do
    Enum.reduce(predications, 0, fn {_, objects}, count -> count + Enum.count(objects) end)
  end

  @doc """
  Checks if the given statement exists within a `RDF.Description`.
  """
  @spec include?(t, input) :: boolean
  def include?(description, input)

  def include?(description, predications) when is_map(predications) or is_list(predications) do
    Enum.all?(predications, fn predication -> include?(description, predication) end)
  end

  def include?(%__MODULE__{} = description, {subject, predicate, objects}) do
    coerce_subject(subject) == description.subject &&
      include?(description, {predicate, objects})
  end

  def include?(%__MODULE__{} = description, {predicate, objects}) do
    if existing_objects = description.predications[coerce_predicate(predicate)] do
      objects
      |> List.wrap()
      |> Enum.map(&coerce_object/1)
      |> Enum.all?(fn object -> Map.has_key?(existing_objects, object) end)
    else
      false
    end
  end

  @doc """
  Checks if a `RDF.Description` has the given resource as subject.

  ## Examples

        iex> RDF.Description.new({EX.S1, EX.p1, EX.O1}) |> RDF.Description.describes?(EX.S1)
        true
        iex> RDF.Description.new({EX.S1, EX.p1, EX.O1}) |> RDF.Description.describes?(EX.S2)
        false
  """
  @spec describes?(t, Statement.subject()) :: boolean
  def describes?(%__MODULE__{subject: subject}, other_subject) do
    subject == coerce_subject(other_subject)
  end

  @doc """
  Returns a map of the native Elixir values of a `RDF.Description`.

  The subject is not part of the result. It can be converted separately with
  `RDF.Term.value/1`.

  The optional second argument allows to specify a custom mapping with a function
  which will receive a tuple `{statement_position, rdf_term}` where
  `statement_position` is one of the atoms `:predicate` or `:object`,
  while `rdf_term` is the RDF term to be mapped.

  ## Examples

      iex> {~I<http://example.com/S>, ~I<http://example.com/p>, ~L"Foo"}
      ...> |> RDF.Description.new()
      ...> |> RDF.Description.values()
      %{"http://example.com/p" => ["Foo"]}

      iex> {~I<http://example.com/S>, ~I<http://example.com/p>, ~L"Foo"}
      ...> |> RDF.Description.new()
      ...> |> RDF.Description.values(fn
      ...>      {:predicate, predicate} ->
      ...>        predicate
      ...>        |> to_string()
      ...>        |> String.split("/")
      ...>        |> List.last()
      ...>        |> String.to_atom()
      ...>    {_, term} ->
      ...>      RDF.Term.value(term)
      ...>    end)
      %{p: ["Foo"]}

  """
  @spec values(t, Statement.term_mapping()) :: map
  def values(description, mapping \\ &RDF.Statement.default_term_mapping/1)

  def values(%__MODULE__{predications: predications}, mapping) do
    Map.new(predications, fn {predicate, objects} ->
      {
        mapping.({:predicate, predicate}),
        objects |> Map.keys() |> Enum.map(&mapping.({:object, &1}))
      }
    end)
  end

  @doc """
  Creates a description from another one by limiting its statements to those using one of the given `predicates`.

  If `predicates` contains properties that are not used in the `description`, they're simply ignored.

  If `nil` is passed, the description is left untouched.
  """
  @spec take(t, [Statement.coercible_predicate()] | Enum.t() | nil) :: t
  def take(description, predicates)

  def take(%__MODULE__{} = description, nil), do: description

  def take(%__MODULE__{predications: predications} = description, predicates) do
    predicates = Enum.map(predicates, &coerce_predicate/1)
    %__MODULE__{description | predications: Map.take(predications, predicates)}
  end

  @doc """
  Checks if two `RDF.Description`s are equal.

  Two `RDF.Description`s are considered to be equal if they contain the same triples.
  """
  @spec equal?(t, t) :: boolean
  def equal?(description1, description2)

  def equal?(%__MODULE__{} = description1, %__MODULE__{} = description2) do
    description1 == description2
  end

  def equal?(_, _), do: false

  defimpl Enumerable do
    alias RDF.Description

    def member?(desc, triple), do: {:ok, Description.include?(desc, triple)}
    def count(desc), do: {:ok, Description.count(desc)}
    def slice(_desc), do: {:error, __MODULE__}

    def reduce(%Description{predications: predications}, {:cont, acc}, _fun)
        when map_size(predications) == 0,
        do: {:done, acc}

    def reduce(description = %Description{}, {:cont, acc}, fun) do
      {triple, rest} = Description.pop(description)
      reduce(rest, fun.(triple, acc), fun)
    end

    def reduce(_, {:halt, acc}, _fun), do: {:halted, acc}

    def reduce(description = %Description{}, {:suspend, acc}, fun) do
      {:suspended, acc, &reduce(description, &1, fun)}
    end
  end

  defimpl Collectable do
    alias RDF.Description

    def into(original) do
      collector_fun = fn
        description, {:cont, list} when is_list(list) ->
          Description.add(description, List.to_tuple(list))

        description, {:cont, elem} ->
          Description.add(description, elem)

        description, :done ->
          description

        _description, :halt ->
          :ok
      end

      {original, collector_fun}
    end
  end
end
