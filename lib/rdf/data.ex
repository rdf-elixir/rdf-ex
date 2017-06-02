defprotocol RDF.Data do
  @moduledoc """
  An abstraction over the different data structures for collections of RDF statements.
  """

  @doc """
  Deletes statements from a RDF data structure.
  """
  def delete(data, statements)

  @doc """
  Deletes one statement from a RDF data structure and returns a tuple with deleted statement and the changed data structure.
  """
  def pop(data)

  @doc """
  Checks if the given statement exists within a RDF data structure.
  """
  def include?(data, statements)

  @doc """
  Returns the list of all statements of a RDF data structure.
  """
  def statements(data)

  @doc """
  Returns the set of all resources which are subject of the statements of a RDF data structure.
  """
  def subjects(data)

  @doc """
  Returns the set of all properties used within the statements of RDF data structure.
  """
  def predicates(data)

  @doc """
  Returns the  set of all resources used in the objects within the statements of a RDF data structure.
  """
  def objects(data)

  @doc """
  Returns the set of all resources used within the statements of a RDF data structure
  """
  def resources(data)

  @doc """
  Returns the count of all resources which are subject of the statements of a RDF data structure.
  """
  def subject_count(data)

  @doc """
  Returns the count of all statements of a RDF data structure.
  """
  def statement_count(data)

end
