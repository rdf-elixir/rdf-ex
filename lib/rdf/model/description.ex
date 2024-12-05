defmodule RDF.Description do
  @moduledoc """
  A set of RDF triples about the same subject.

  `RDF.Description` implements:

  - Elixir's `Access` behaviour
  - Elixir's `Enumerable` protocol
  - Elixir's `Collectable` protocol
  - Elixir's `Inspect` protocol
  - the `RDF.Data` protocol

  """

  @enforce_keys [:subject]
  defstruct subject: nil, predications: %{}

  @behaviour Access

  alias RDF.{Graph, Dataset, PropertyMap}
  alias RDF.Star.{Statement, Triple}

  import RDF.Guards

  @type t :: %__MODULE__{
          subject: Statement.subject(),
          predications: predications
        }

  @type predications :: %{Statement.predicate() => %{Statement.object() => nil}}

  @type input ::
          Statement.coercible()
          | {
              Statement.coercible_predicate(),
              Statement.coercible_object() | [Statement.coercible_object()]
            }
          | %{
              Statement.coercible_predicate() =>
                Statement.coercible_object() | [Statement.coercible_object()]
            }
          | [
              Statement.coercible()
              | {
                  Statement.coercible_predicate(),
                  Statement.coercible_object() | [Statement.coercible_object()]
                }
              | t
            ]
          | t

  @doc """
  Creates an `RDF.Description` about the given subject.

  The created `RDF.Description` can be initialized with any form of data which
  `add/2` understands with the `:init` option. Additionally, a function returning
  the initialization data in any of these forms can be as the `:init` value.

  ## Examples

      RDF.Description.new(EX.S)
      RDF.Description.new(EX.S, init: {EX.S, EX.p, EX.O})
      RDF.Description.new(EX.S, init: {EX.p, [EX.O1, EX.O2]})
      RDF.Description.new(EX.S, init: [{EX.p1, EX.O1}, {EX.p2, EX.O2}])
      RDF.Description.new(EX.S, init: RDF.Description.new(EX.S, init: {EX.P, EX.O}))
      RDF.Description.new(EX.S, init: fn -> {EX.p, EX.O} end)

  """
  @spec new(Statement.coercible_subject() | t, keyword) :: t
  def new(subject, opts \\ [])

  def new(%__MODULE__{} = description, opts), do: new(description.subject, opts)

  def new(subject, opts) do
    {data, opts} = Keyword.pop(opts, :init)

    %__MODULE__{subject: RDF.coerce_subject(subject)}
    |> init(data, opts)
  end

  defp init(description, nil, _), do: description
  defp init(description, fun, opts) when is_function(fun), do: add(description, fun.(), opts)
  defp init(description, data, opts), do: add(description, data, opts)

  @doc """
  Returns the subject IRI or blank node of a description.
  """
  @spec subject(t) :: Statement.subject()
  def subject(%__MODULE__{} = description), do: description.subject

  @doc """
  Changes the subject of a description.
  """
  @spec change_subject(t, Statement.coercible_subject()) :: t
  def change_subject(%__MODULE__{} = description, new_subject) do
    %__MODULE__{description | subject: RDF.coerce_subject(new_subject)}
  end

  @doc """
  Add statements to a `RDF.Description`.

  Note: When the statements to be added are given as another `RDF.Description`,
  the subject must not match subject of the description to which the statements
  are added. As opposed to that `RDF.Data.merge/2` will produce a `RDF.Graph`
  containing both descriptions.

  ## Examples

      iex> RDF.Description.new(EX.S, init: {EX.P1, EX.O1})
      ...> |> RDF.Description.add({EX.P2, EX.O2})
      RDF.Description.new(EX.S, init: [{EX.P1, EX.O1}, {EX.P2, EX.O2}])

      iex> RDF.Description.new(EX.S, init: {EX.P, EX.O1})
      ...> |> RDF.Description.add({EX.P, [EX.O2, EX.O3]})
      RDF.Description.new(EX.S, init: [{EX.P, EX.O1}, {EX.P, EX.O2}, {EX.P, EX.O3}])

  """
  @spec add(t, input, keyword) :: t
  def add(description, input, opts \\ [])

  def add(%__MODULE__{} = description, {subject, predicate, objects, _}, opts) do
    add(description, {subject, predicate, objects}, opts)
  end

  def add(%__MODULE__{} = description, {subject, predicate, objects}, opts) do
    if RDF.coerce_subject(subject) == description.subject do
      add(description, {predicate, objects}, opts)
    else
      description
    end
  end

  def add(%__MODULE__{} = description, {predicate, objects}, opts) do
    normalized_objects =
      objects
      |> List.wrap()
      |> Map.new(&{RDF.coerce_object(&1), nil})

    if Enum.empty?(normalized_objects) do
      description
    else
      %__MODULE__{
        description
        | predications:
            Map.update(
              description.predications,
              RDF.coerce_predicate(predicate, PropertyMap.from_opts(opts)),
              normalized_objects,
              &Map.merge(&1, normalized_objects)
            )
      }
    end
  end

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

  def add(description, input, opts)
      when is_list(input) or (is_map(input) and not is_struct(input)) do
    Enum.reduce(input, description, &add(&2, &1, opts))
  end

  @doc """
  Adds statements to a `RDF.Description` and overwrites all existing statements with already used predicates.

  Note: As it is a destructive function this function is stricter in its handling of
  `RDF.Description`s than `add/3`. The subject of a `RDF.Description` to be put must
  match. If you want to overwrite existing statements with those from the description of
  another subject, you'll have to explicitly change the subject with `change_subject/2`
  first before using `put/3`.

  ## Examples

      iex> RDF.Description.new(EX.S, init: {EX.P, EX.O1})
      ...> |> RDF.Description.put({EX.P, EX.O2})
      RDF.Description.new(EX.S, init: {EX.P, EX.O2})

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
    put(description, description.subject |> new() |> add(input, opts), opts)
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

  def delete(%__MODULE__{} = description, {subject, predicate, objects}, opts) do
    if RDF.coerce_subject(subject) == description.subject do
      delete(description, {predicate, objects}, opts)
    else
      description
    end
  end

  def delete(%__MODULE__{} = description, {subject, predicate, objects, _}, opts) do
    delete(description, {subject, predicate, objects}, opts)
  end

  def delete(%__MODULE__{} = description, {predicate, objects}, opts) do
    predicate = RDF.coerce_predicate(predicate, PropertyMap.from_opts(opts))

    if current_objects = Map.get(description.predications, predicate) do
      normalized_objects =
        objects
        |> List.wrap()
        |> Enum.map(&RDF.coerce_object/1)

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

  def delete(description, input, opts)
      when is_list(input) or (is_map(input) and not is_struct(input)) do
    Enum.reduce(input, description, &delete(&2, &1, opts))
  end

  @doc """
  Deletes all statements with the given properties.
  """
  @spec delete_predicates(t, Statement.coercible_predicate() | [Statement.coercible_predicate()]) ::
          t
  def delete_predicates(description, properties)

  def delete_predicates(%__MODULE__{} = description, properties) when is_list(properties) do
    Enum.reduce(properties, description, &delete_predicates(&2, &1))
  end

  def delete_predicates(%__MODULE__{} = description, property) do
    %__MODULE__{
      description
      | predications: Map.delete(description.predications, RDF.coerce_predicate(property))
    }
  end

  @doc """
  Fetches the objects for the given predicate of a Description.

  When the predicate can not be found `:error` is returned.

  ## Examples

      iex> RDF.Description.new(EX.S, init: {EX.p, EX.O}) |> RDF.Description.fetch(EX.p)
      {:ok, [RDF.iri(EX.O)]}
      iex> RDF.Description.new(EX.S, init: [{EX.P, EX.O1}, {EX.P, EX.O2}])
      ...> |> RDF.Description.fetch(EX.P)
      {:ok, [RDF.iri(EX.O1), RDF.iri(EX.O2)]}
      iex> RDF.Description.new(EX.S) |> RDF.Description.fetch(EX.foo)
      :error
  """
  @impl Access
  @spec fetch(t, Statement.coercible_predicate()) :: {:ok, [Statement.object()]} | :error
  def fetch(%__MODULE__{} = description, predicate) do
    with {:ok, objects} <-
           Access.fetch(description.predications, RDF.coerce_predicate(predicate)) do
      {:ok, Map.keys(objects)}
    end
  end

  @doc """
  Gets the objects for the given predicate of a Description.

  When the predicate can not be found, the optionally given default value or `nil` is returned.

  ## Examples

      iex> RDF.Description.new(EX.S, init: {EX.P, EX.O}) |> RDF.Description.get(EX.P)
      [RDF.iri(EX.O)]
      iex> RDF.Description.new(EX.S) |> RDF.Description.get(EX.foo)
      nil
      iex> RDF.Description.new(EX.S) |> RDF.Description.get(EX.foo, :bar)
      :bar
  """
  @spec get(t, Statement.coercible_predicate(), any) :: [Statement.object()] | any
  def get(%__MODULE__{} = description, predicate, default \\ nil) do
    case fetch(description, predicate) do
      {:ok, value} -> value
      :error -> default
    end
  end

  @doc """
  Gets a single object for the given predicate of a Description.

  When the predicate can not be found, the optionally given default value or `nil` is returned.

  ## Examples

      iex> RDF.Description.new(EX.S, init: {EX.P, EX.O}) |> RDF.Description.first(EX.P)
      RDF.iri(EX.O)
      iex> RDF.Description.new(EX.S) |> RDF.Description.first(EX.foo)
      nil
      iex> RDF.Description.new(EX.S) |> RDF.Description.first(EX.foo, :bar)
      :bar
  """
  @spec first(t, Statement.coercible_predicate(), any) :: Statement.object() | nil
  def first(%__MODULE__{} = description, predicate, default \\ nil) do
    description
    |> get(predicate, [])
    |> List.first() || default
  end

  @doc """
  Updates the objects of the `predicate` in `description` with the given function.

  If `predicate` is present in `description` with `objects` as value,
  `fun` is invoked with argument `objects` and its result is used as the new
  list of objects of `predicate`. If `predicate` is not present in `description`,
  `initial` is inserted as the objects of `predicate`. The initial value will
  not be passed through the update function.

  The initial value and the returned objects by the update function will be automatically
  coerced to proper RDF object values before added.

  ## Examples

      iex> RDF.Description.new(EX.S, init: {EX.p, EX.O})
      ...> |> RDF.Description.update(EX.p, fn objects -> [EX.O2 | objects] end)
      RDF.Description.new(EX.S, init: [{EX.p, EX.O}, {EX.p, EX.O2}])
      iex> RDF.Description.new(EX.S)
      ...> |> RDF.Description.update(EX.p, EX.O, fn _ -> EX.O2 end)
      RDF.Description.new(EX.S, init: {EX.p, EX.O})

  """
  @spec update(
          t,
          Statement.coercible_predicate(),
          Statement.coercible_object() | nil,
          ([Statement.object()] ->
             [Statement.coercible_object()] | Statement.coercible_object() | nil)
        ) :: t
  def update(%__MODULE__{} = description, predicate, initial \\ nil, fun) do
    predicate = RDF.coerce_predicate(predicate)

    case get(description, predicate) do
      nil when is_nil(initial) ->
        description

      nil ->
        put(description, {predicate, initial})

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
  Updates all predications in `description` with the given function.

  `fun` is invoked with a tuple `{predicate, objects}` for each predicate in `description`.
  If `nil` is returned by `fun`, the respective predications will be removed from `description`.
  The returned values by the update function will be coerced to proper RDF object values before added.

  ## Examples

      iex> EX.S |> EX.p1(1) |> EX.p2([2, 3])
      ...> |> RDF.Description.update_all_predicates(fn {_predicate, objects} -> ["foo" | objects] end)
      EX.S
      |> EX.p1([1, "foo"])
      |> EX.p2([2, 3, "foo"])

  """
  @spec update_all_predicates(
          t,
          ({Statement.predicate(), [Statement.object()]} ->
             [Statement.coercible_object()] | Statement.coercible_object() | nil)
        ) :: t
  def update_all_predicates(%__MODULE__{} = description, fun) do
    description
    |> predicates()
    |> Enum.reduce(description, fn predicate, description ->
      update(description, predicate, fn objects -> fun.({predicate, objects}) end)
    end)
  end

  @doc """
  Updates all objects in `description` with the given function.

  `fun` is invoked for each object in `description` with the predicate and the object as two arguments.
  If `nil` is returned by `fun`, the respective object will be removed from `description`.
  The returned values by the update function will be coerced to proper RDF object values before added.

  ## Examples

      iex> EX.S |> EX.p1(1) |> EX.p2([2, 3])
      ...> |> RDF.Description.update_all_objects(fn _predicate, object ->
      ...>      RDF.XSD.Numeric.add(object, 1)
      ...>    end)
      EX.S
      |> EX.p1(2)
      |> EX.p2([3, 4])
  """
  @spec update_all_objects(
          t,
          (Statement.predicate(), Statement.object() ->
             [Statement.coercible_object()] | Statement.coercible_object() | nil)
        ) :: t
  def update_all_objects(%__MODULE__{} = description, fun) do
    update_all_predicates(description, fn {predicate, objects} ->
      Enum.flat_map(objects, &List.wrap(fun.(predicate, &1)))
    end)
  end

  @doc """
  Replaces all occurrences of `old_id` in `description` with `new_id`.
  """
  @spec rename_resource(t(), RDF.Resource.coercible(), RDF.Resource.coercible()) :: t()
  def rename_resource(description, old_id, old_id)

  def rename_resource(%__MODULE__{} = description, id, id), do: description

  def rename_resource(%__MODULE__{subject: old_id} = description, old_id, new_id)
      when is_rdf_resource(old_id) and is_rdf_resource(new_id) do
    description
    |> change_subject(new_id)
    |> rename_resource(old_id, new_id)
  end

  def rename_resource(%__MODULE__{} = description, old_id, new_id)
      when is_rdf_resource(old_id) and is_rdf_resource(new_id) do
    case pop(description, old_id) do
      {nil, description} -> description
      {objects, description} -> description |> add({new_id, objects})
    end
    |> update_all_objects(fn
      _, ^old_id -> new_id
      _, other -> other
    end)
  end

  def rename_resource(%__MODULE__{} = description, old_id, new_id)
      when not is_rdf_resource(old_id) do
    rename_resource(description, RDF.iri(old_id), new_id)
  end

  def rename_resource(%__MODULE__{} = description, old_id, new_id)
      when not is_rdf_resource(new_id) do
    rename_resource(description, old_id, RDF.iri(new_id))
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

      iex> RDF.Description.new(EX.S, init: {EX.P, EX.O})
      ...> |> RDF.Description.get_and_update(EX.P, fn current_objects ->
      ...>      {current_objects, EX.New}
      ...>    end)
      {[RDF.iri(EX.O)], RDF.Description.new(EX.S, init: {EX.P, EX.New})}
      iex> RDF.Graph.new([{EX.S, EX.P1, EX.O1}, {EX.S, EX.P2, EX.O2}])
      ...> |> RDF.Graph.description(EX.S)
      ...> |> RDF.Description.get_and_update(EX.P1, fn _ -> :pop end)
      {[RDF.iri(EX.O1)], RDF.Description.new(EX.S, init: {EX.P2, EX.O2})}
  """
  @impl Access
  @spec get_and_update(
          t,
          Statement.coercible_predicate(),
          ([Statement.Object] -> {[Statement.Object], t} | :pop)
        ) :: {[Statement.Object], t}
  def get_and_update(%__MODULE__{} = description, predicate, fun) do
    triple_predicate = RDF.coerce_predicate(predicate)

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

  def pop(%__MODULE__{predications: predications} = description)
      when map_size(predications) == 0,
      do: {nil, description}

  def pop(%__MODULE__{predications: predications} = description) do
    [{predicate, objects}] = Enum.take(predications, 1)
    [{object, _}] = Enum.take(objects, 1)

    popped =
      if map_size(objects) == 1,
        do: elem(Map.pop(predications, predicate), 1),
        else: elem(pop_in(predications, [predicate, object]), 1)

    {
      {description.subject, predicate, object},
      %__MODULE__{description | predications: popped}
    }
  end

  @doc """
  Pops the objects of the given predicate of a Description.

  Removes the objects for the given `predicate` from `description`.

  Returns a tuple containing a list the objects for the given predicate
  and the updated description without the respective statements.
  `nil` is returned instead of the objects if `description` does
  not contain any statements with the given `predicate`.

  ## Examples

      iex> RDF.Description.new(EX.S, init: {EX.P, EX.O})
      ...> |> RDF.Description.pop(EX.P)
      {[RDF.iri(EX.O)], RDF.Description.new(EX.S)}

      iex> RDF.Description.new(EX.S, init: {EX.P, EX.O})
      ...> |> RDF.Description.pop(EX.Missing)
      {nil, RDF.Description.new(EX.S, init: {EX.P, EX.O})}
  """
  @impl Access
  @spec pop(t, Statement.coercible_predicate()) :: {[Statement.object()] | nil, t}
  def pop(%__MODULE__{} = description, predicate) do
    case Access.pop(description.predications, RDF.coerce_predicate(predicate)) do
      {nil, _} ->
        {nil, description}

      {objects, new_predications} ->
        {
          Map.keys(objects),
          %__MODULE__{description | predications: new_predications}
        }
    end
  end

  @doc """
  The set of all properties used in the predicates within a `RDF.Description`.

  ## Examples

      iex> RDF.Description.new(EX.S1, init: [
      ...>   {EX.p1, EX.O1},
      ...>   {EX.p2, EX.O2},
      ...>   {EX.p2, EX.O3}])
      ...> |> RDF.Description.predicates()
      MapSet.new([EX.p1, EX.p2])
  """
  @spec predicates(t) :: MapSet.t()
  def predicates(%__MODULE__{} = description) do
    description.predications |> Map.keys() |> MapSet.new()
  end

  @doc """
  The set of all resources used in the objects within a `RDF.Description`.

  Note: This function does collect only IRIs and BlankNodes, not Literals.

  ## Examples

      iex> RDF.Description.new(EX.S1, init: [
      ...>   {EX.p1, EX.O1},
      ...>   {EX.p2, EX.O2},
      ...>   {EX.p3, EX.O2},
      ...>   {EX.p4, RDF.bnode(:bnode)},
      ...>   {EX.p3, "foo"}])
      ...> |> RDF.Description.objects()
      MapSet.new([RDF.iri(EX.O1), RDF.iri(EX.O2), RDF.bnode(:bnode)])
  """
  @spec objects(t) :: MapSet.t()
  def objects(%__MODULE__{} = description) do
    objects(description, &RDF.resource?/1)
  end

  @doc """
  The set of all resources used in the objects within a `RDF.Description` satisfying the given filter criterion.
  """
  @spec objects(t, (Statement.object() -> boolean)) :: MapSet.t()
  def objects(%__MODULE__{} = description, filter_fn) do
    Enum.reduce(description.predications, MapSet.new(), fn {_, objects}, acc ->
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

      iex> RDF.Description.new(EX.S1, init: [
      ...>   {EX.p1, EX.O1},
      ...>   {EX.p2, EX.O2},
      ...>   {EX.p1, EX.O2},
      ...>   {EX.p2, RDF.bnode(:bnode)},
      ...>   {EX.p3, "foo"}])
      ...> |> RDF.Description.resources()
      MapSet.new([RDF.iri(EX.O1), RDF.iri(EX.O2), RDF.bnode(:bnode), EX.p1, EX.p2, EX.p3])
  """
  @spec resources(t) :: MapSet.t()
  def resources(%__MODULE__{} = description) do
    objects(description)
    |> MapSet.union(predicates(description))
  end

  @doc """
  The list of all triples within a `RDF.Description`.

  When the optional `:filter_star` flag is set to `true` RDF-star triples with a triple as subject or object
  will be filtered. So, for a description with a triple as a subject you'll always get an empty list.
  The default value of the `:filter_star` flag is `false`.
  """
  @spec triples(t, keyword) :: list(Triple.t())
  def triples(%__MODULE__{subject: s} = description, opts \\ []) do
    filter_star = Keyword.get(opts, :filter_star, false)

    cond do
      filter_star and is_tuple(s) ->
        []

      filter_star ->
        for {p, os} <- description.predications, {o, _} when not is_tuple(o) <- os do
          {s, p, o}
        end

      true ->
        for {p, os} <- description.predications, {o, _} <- os do
          {s, p, o}
        end
    end
  end

  defdelegate statements(description, opts \\ []), to: __MODULE__, as: :triples

  @doc false
  @spec quads(t, keyword) :: list(RDF.Quad.t())
  def quads(%__MODULE__{subject: s} = description, graph, opts \\ []) do
    filter_star = Keyword.get(opts, :filter_star, false)

    cond do
      filter_star and is_tuple(s) ->
        []

      filter_star ->
        for {p, os} <- description.predications, {o, _} when not is_tuple(o) <- os do
          {s, p, o, graph}
        end

      true ->
        for {p, os} <- description.predications, {o, _} <- os do
          {s, p, o, graph}
        end
    end
  end

  @doc """
  Returns the number of statements of a `RDF.Description`.
  """
  @spec statement_count(t) :: non_neg_integer
  def statement_count(%__MODULE__{} = description) do
    Enum.reduce(description.predications, 0, fn {_, objects}, count ->
      count + map_size(objects)
    end)
  end

  defdelegate count(description), to: __MODULE__, as: :statement_count

  @doc """
  Returns if the given `description` is empty.

  Note: You should always prefer this over the use of `Enum.empty?/1` as it is significantly faster.
  """
  @spec empty?(t) :: boolean
  def empty?(%__MODULE__{} = description) do
    Enum.empty?(description.predications)
  end

  @doc """
  Checks if the given `input` statements exist within `description`.
  """
  @spec include?(t, input, keyword) :: boolean
  def include?(description, input, opts \\ [])

  def include?(%__MODULE__{} = description, {subject, predicate, objects}, opts) do
    RDF.coerce_subject(subject) == description.subject &&
      include?(description, {predicate, objects}, opts)
  end

  def include?(%__MODULE__{} = description, {subject, predicate, objects, _}, opts) do
    include?(description, {subject, predicate, objects}, opts)
  end

  def include?(%__MODULE__{} = description, {predicate, objects}, opts) do
    if existing_objects =
         description.predications[RDF.coerce_predicate(predicate, PropertyMap.from_opts(opts))] do
      objects
      |> List.wrap()
      |> Enum.map(&RDF.coerce_object/1)
      |> Enum.all?(fn object -> Map.has_key?(existing_objects, object) end)
    else
      false
    end
  end

  def include?(
        %__MODULE__{subject: subject, predications: predications},
        %__MODULE__{subject: subject} = input,
        _opts
      ) do
    Enum.all?(input.predications, fn {predicate, objects} ->
      if existing_objects = predications[predicate] do
        Enum.all?(objects, fn {object, _} ->
          Map.has_key?(existing_objects, object)
        end)
      else
        false
      end
    end)
  end

  def include?(%__MODULE__{}, %__MODULE__{}, _), do: false

  def include?(description, input, opts)
      when is_list(input) or (is_map(input) and not is_struct(input)) do
    Enum.all?(input, &include?(description, &1, opts))
  end

  @doc """
  Checks if a `RDF.Description` has the given resource as subject.

  ## Examples

        iex> RDF.Description.new(EX.S1, init: {EX.p1, EX.O1})
        ...> |> RDF.Description.describes?(EX.S1)
        true
        iex> RDF.Description.new(EX.S1, init: {EX.p1, EX.O1})
        ...> |> RDF.Description.describes?(EX.S2)
        false
  """
  @spec describes?(t, Statement.subject()) :: boolean
  def describes?(%__MODULE__{subject: subject}, other_subject) do
    subject == RDF.coerce_subject(other_subject)
  end

  @doc """
  Returns a map of the native Elixir values of a `RDF.Description`.

  The subject is not part of the result. It can be converted separately with
  `RDF.Term.value/1`, or, if you want the subject in an outer map, just put the
  description in a graph and use `RDF.Graph.values/2`.

  When a `:context` option is given with a `RDF.PropertyMap`, predicates will
  be mapped to the terms defined in the `RDF.PropertyMap`, if present.

  Note: RDF-star statements where the object is a triple will be ignored.

  ## Examples

      iex> RDF.Description.new(~I<http://example.com/S>, init: {~I<http://example.com/p>, ~L"Foo"})
      ...> |> RDF.Description.values()
      %{"http://example.com/p" => ["Foo"]}

      iex> RDF.Description.new(~I<http://example.com/S>, init: {~I<http://example.com/p>, ~L"Foo"})
      ...> |> RDF.Description.values(context: %{p: ~I<http://example.com/p>})
      %{p: ["Foo"]}

  """
  @spec values(t, keyword) :: map
  def values(%__MODULE__{} = description, opts \\ []) do
    if property_map = PropertyMap.from_opts(opts) do
      map(description, RDF.Statement.default_property_mapping(property_map))
    else
      map(description, &RDF.Statement.default_term_mapping/1)
    end
  end

  @doc """
  Returns a map of a `RDF.Description` where each element from its triples is mapped with the given function.

  The subject is not part of the result. If you want the subject in an outer map,
  just put the description in a graph and use `RDF.Graph.map/2`.

  The function `fun` will receive a tuple `{statement_position, rdf_term}` where
  `statement_position` is one of the atoms `:predicate` or `:object`, while
  `rdf_term` is the RDF term to be mapped. When the given function returns
  `nil` this will be interpreted as an error and will become the overhaul result
  of the `map/2` call.

  Note: RDF-star statements where the object is a triple will be ignored.

  ## Examples

      iex> RDF.Description.new(~I<http://example.com/S>, init: {~I<http://example.com/p>, ~L"Foo"})
      ...> |> RDF.Description.map(fn
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
  @spec map(t, Statement.term_mapping()) :: map
  def map(description, fun)

  def map(%__MODULE__{} = description, fun) do
    Enum.reduce(description.predications, %{}, fn {predicate, objects}, map ->
      objects
      |> Map.keys()
      |> Enum.reject(&is_tuple/1)
      |> case do
        [] ->
          map

        objects ->
          Map.put(
            map,
            fun.({:predicate, predicate}),
            Enum.map(objects, &fun.({:object, &1}))
          )
      end
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

  def take(%__MODULE__{} = description, predicates) do
    %__MODULE__{
      description
      | predications:
          Map.take(description.predications, Enum.map(predicates, &RDF.coerce_predicate/1))
    }
  end

  # This function relies on Map.intersect/3 that was added in Elixir v1.15
  if Version.match?(System.version(), ">= 1.15.0") do
    @doc """
    Returns a new description that is the intersection of the given `description` with the given `data`.

    The `data` can be given in any form an `RDF.Graph` can be created from.
    When a `RDF.Dataset` is given, the aggregated description of the subject of
    `description` is used for the intersection.

    ## Examples

        iex> EX.S
        ...> |> EX.p(EX.O1, EX.O2)
        ...> |> RDF.Description.intersection(EX.S |> EX.p(EX.O2, EX.O3))
        EX.S |> EX.p(EX.O2)

        iex> EX.S
        ...> |> EX.p(EX.O1, EX.O2)
        ...> |> RDF.Description.intersection({EX.Other, EX.p, EX.O2, EX.O3})
        RDF.Description.new(EX.S)

    """
    @spec intersection(t(), t() | Graph.t() | Dataset.t() | Graph.input()) :: t()
    def intersection(description, data)

    def intersection(
          %__MODULE__{subject: subject} = description1,
          %__MODULE__{subject: subject} = description2
        ) do
      intersection =
        description1.predications
        |> Map.intersect(description2.predications, fn _, o1, o2 ->
          objects_intersection = Map.intersect(o1, o2)
          if objects_intersection != %{}, do: objects_intersection
        end)
        |> RDF.Utils.reject_empty_map_values()

      %__MODULE__{description1 | predications: intersection}
    end

    def intersection(%__MODULE__{subject: subject}, %__MODULE__{}), do: new(subject)

    def intersection(%__MODULE__{subject: subject} = description, %Graph{} = graph) do
      if description2 = Graph.get(graph, subject) do
        intersection(description, description2)
      else
        new(subject)
      end
    end

    def intersection(%__MODULE__{subject: subject} = description, %Dataset{} = dataset) do
      description2 = RDF.Data.description(dataset, subject)

      if empty?(description2) do
        new(subject)
      else
        intersection(description, description2)
      end
    end

    def intersection(%__MODULE__{} = description, data) do
      intersection(description, Graph.new(data))
    end
  end

  @doc """
  Removes all objects from a description which are quoted triples.
  """
  @spec without_quoted_triple_objects(t) :: t
  def without_quoted_triple_objects(%__MODULE__{} = description) do
    %__MODULE__{
      description
      | predications:
          Enum.reduce(description.predications, description.predications, fn
            {predicate, objects}, predications ->
              original_object_count = map_size(predications)

              filtered_objects =
                Enum.reject(objects, &match?({quoted_triple, _} when is_tuple(quoted_triple), &1))

              case Enum.count(filtered_objects) do
                0 -> Map.delete(predications, predicate)
                ^original_object_count -> predications
                _ -> Map.put(predications, predicate, Map.new(filtered_objects))
              end
          end)
    }
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

  @doc """
  Returns a hash of the canonical form of the given description.

  See `RDF.Dataset.canonical_hash/2` for more information.

  ## Example

      iex> RDF.Description.new(EX.S, init: {EX.p(), EX.O})
      ...> |> RDF.Description.canonical_hash()
      "4a883e60f7b38b89b72492f16114ea62cf9a21d0e232d066b1f59ef61c69ea12"
  """
  @spec canonical_hash(t(), keyword) :: binary
  def canonical_hash(%__MODULE__{} = description, opts \\ []) do
    description
    |> Dataset.new()
    |> Dataset.canonical_hash(opts)
  end

  defimpl Enumerable do
    alias RDF.Description

    def member?(desc, triple), do: {:ok, Description.include?(desc, triple)}

    def count(desc), do: {:ok, Description.statement_count(desc)}

    def slice(desc) do
      size = Description.statement_count(desc)
      {:ok, size, &Description.triples/1}
    end

    def reduce(desc, acc, fun) do
      desc
      |> Description.triples()
      |> Enumerable.List.reduce(acc, fun)
    end
  end

  defimpl Collectable do
    alias RDF.Description

    def into(original) do
      collector_fun = fn
        description, {:cont, list} when is_list(list) ->
          IO.warn(
            "triples as lists in `Collectable` implementation of `RDF.Description` are deprecated and will be removed in RDF.ex v2.0; use triples as tuples instead"
          )

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
