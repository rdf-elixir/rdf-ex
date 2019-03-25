# RDF.ex

[![Travis](https://img.shields.io/travis/marcelotto/rdf-ex.svg?style=flat-square)](https://travis-ci.org/marcelotto/rdf-ex)
[![Hex.pm](https://img.shields.io/hexpm/v/rdf.svg?style=flat-square)](https://hex.pm/packages/rdf)
[![Inline docs](http://inch-ci.org/github/marcelotto/rdf-ex.svg)](http://inch-ci.org/github/marcelotto/rdf-ex)


An implementation of the [RDF](https://www.w3.org/TR/rdf11-primer/) data model in Elixir.

## Features

- fully compatible with the RDF 1.1 specification
- in-memory data structures for RDF descriptions, RDF graphs and RDF datasets
- ability to execute SPARQL queries against the in-memory data structures via the [SPARQL.ex] package or against any SPARQL endpoint via the [SPARQL.Client] package
- support for RDF vocabularies via Elixir modules for safe, i.e. compile-time checked and concise usage of IRIs
- XML schema datatypes for RDF literals (not yet all supported)
- sigils for the most common types of nodes, i.e. IRIs, literals, blank nodes and lists
- a description DSL resembling Turtle in Elixir
- implementations for the [N-Triples], [N-Quads] and [Turtle] serialization formats
    - [JSON-LD] is implemented in the separate [JSON-LD.ex] package


## Installation

The [RDF.ex] Hex package can be installed as usual, by adding `rdf` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:rdf, "~> 0.5"}]
end
```


## Usage

The [RDF standard](http://www.w3.org/TR/rdf11-concepts/) defines a graph data model for distributed information on the web. A RDF graph is a set of statements aka RDF triples consisting of three nodes:

1. a subject node with an IRI or a blank node,
2. a predicate node with the IRI of a RDF property, 
3. an object node with an IRI, a blank node or a RDF literal value.

Let's see how the different types of nodes are represented with RDF.ex in Elixir.

### IRIs

RDF.ex follows the RDF specs and supports [IRIs](https://en.wikipedia.org/wiki/Internationalized_Resource_Identifier), an internationalized generalization of URIs, permitting a wider range of Unicode characters. They are represented with the `RDF.IRI` structure and can be constructed either with `RDF.IRI.new/1` or `RDF.IRI.new!/1`, the latter of which additionally validates, that the given IRI is actually a valid absolute IRI or raises an exception otherwise.

```elixir
RDF.IRI.new("http://www.example.com/foo")
RDF.IRI.new!("http://www.example.com/foo")
```

The `RDF` module defines the alias functions `RDF.iri/1` and `RDF.iri!/1` delegating the resp. `new` function:

```elixir
RDF.iri("http://www.example.com/foo")
RDF.iri!("http://www.example.com/foo")
```

Besides being a little shorter than `RDF.IRI.new` and better `import`able, their usage will automatically benefit from any future IRI creation optimizations and is therefore recommended over the original functions.

A literal IRI can also be written with the `~I` sigil:

```elixir
~I<http://www.example.com/foo>
```

But there's an even shorter notation for IRI literals.


### Vocabularies

RDF.ex supports modules which represent RDF vocabularies as `RDF.Vocabulary.Namespace`s. It comes with predefined modules for some fundamental vocabularies defined in the `RDF.NS` module.

These `RDF.Vocabulary.Namespace`s (a special case of a `RDF.Namespace`) allow for something similar to QNames in XML: an atom or function qualified with a `RDF.Vocabulary.Namespace` can be resolved to an IRI. 

There are two types of terms in a `RDF.Vocabulary.Namespace` which are
resolved differently:

1. Capitalized terms are by standard Elixir semantics module names, i.e.
   atoms. At all places in RDF.ex where an IRI is expected, you can use atoms
   qualified with a `RDF.Namespace` instead. If you want to resolve them
   manually, you can pass a `RDF.Namespace` qualified atom to `RDF.iri`.
2. Lowercased terms for RDF properties are represented as functions on a
   `RDF.Vocabulary.Namespace` module and return the IRI directly, but since `RDF.iri` can also handle IRIs directly, you can safely and consistently use it with lowercased terms too.

```elixir
iex> import RDF, only: [iri: 1]
iex> alias RDF.NS.{RDFS}

iex> RDFS.Class
RDF.NS.RDFS.Class

iex> iri(RDFS.Class)
~I<http://www.w3.org/2000/01/rdf-schema#Class>

iex> RDFS.subClassOf
~I<http://www.w3.org/2000/01/rdf-schema#subClassOf>

iex> iri(RDFS.subClassOf)
~I<http://www.w3.org/2000/01/rdf-schema#subClassOf>
```

As this example shows, the namespace modules can be easily `alias`ed. When required, they can be also aliased to a completely different name. Since the `RDF` vocabulary namespace in `RDF.NS.RDF` can't be aliased (it would clash with the top-level `RDF` module), all of its elements can be accessed directly from the `RDF` module (without an alias).

```elixir
iex> import RDF, only: [iri: 1]
iex> RDF.type
~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>

iex> iri(RDF.Property)
~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#Property>
```

This way of expressing IRIs has the additional benefit, that the existence of the referenced IRI is checked at compile time, i.e. whenever a term is used that is not part of the resp. vocabulary an error is raised by the Elixir compiler (unless the vocabulary namespace is non-strict; see below).

For terms not adhering to the capitalization rules (lowercase properties, capitalized non-properties) or containing characters not allowed within atoms, the predefined namespaces in `RDF.NS` define aliases accordingly. If unsure, have a look at the documentation or their definitions. 


#### Description DSL

The functions for the properties on a vocabulary namespace module, are also available in a description builder variant, which accepts subject and objects as arguments.

```elixir
RDF.type(EX.Foo, EX.Bar)
```

If you want to state multiple statements with the same subject and predicate, you can either pass the objects as a list or as additional arguments, if there are not more than five of them:

```elixir
RDF.type(EX.Foo, EX.Bar, EX.Baz)
EX.foo(EX.Bar, [1, 2, 3, 4, 5, 6])
```

In combination with Elixirs pipe operators this leads to a description DSL resembling [Turtle](https://www.w3.org/TR/turtle/):

```elixir
EX.Foo
|> RDF.type(EX.Bar)
|> EX.baz(1, 2, 3)
```

The produced statements are returned by this function as a `RDF.Description` structure which will be described below.


#### Defining vocabulary namespaces

There are two basic ways to define a namespace for a vocabulary:

1. You can define all terms manually.
2. You can extract the terms from existing RDF data for IRIs of resources under the specified base IRI.

It's recommended to introduce a dedicated module for the defined namespaces. In this module you'll `use RDF.Vocabulary.Namespace` and define your vocabulary namespaces with the `defvocab` macro.

A vocabulary namespace with manually defined terms can be defined in this way like that:

```elixir
defmodule YourApp.NS do
  use RDF.Vocabulary.Namespace

  defvocab EX,
    base_iri: "http://www.example.com/ns/",
    terms: ~w[Foo bar]
    
end
```

The `base_iri` argument with the IRI prefix of all the terms in the defined
vocabulary is required and expects a valid IRI ending with either a `"/"` or
a `"#"`. Terms will be checked for invalid characters at compile-time and will raise a compiler error. This handling of invalid characters can be modified with the `invalid_characters` options, which is set to `:fail` by default. By setting it to `:warn` only warnings will be raised or it can be turned off completely with `:ignore`.

A vocabulary namespace with extracted terms can be defined either by providing RDF data directly with the `data` option or files with serialized RDF data in the `priv/vocabs` directory using the `file` option:

```elixir
defmodule YourApp.NS do
  use RDF.Vocabulary.Namespace

  defvocab EX,
    base_iri: "http://www.example.com/ns/",
    file: "your_vocabulary.nt"
    
end
```

During compilation the terms will be validated and checked for proper capitalisation by analysing the schema description of the resp. resource  in the given data.
This validation behaviour can be modified with the `case_violations` options, which is by default set to `:warn`. By setting it explicitly to `:fail` errors will be raised during compilation or it can be turned off with `:ignore`.

Invalid characters or violations of capitalization rules can be fixed by defining aliases for these terms with the `alias` option and a keyword list:

```elixir
defmodule YourApp.NS do
  use RDF.Vocabulary.Namespace

  defvocab EX,
    base_iri: "http://www.example.com/ns/",
    file: "your_vocabulary.nt"
    alias: [example_term: "example-term"]

end
```

The `:ignore` option allows to ignore terms:

```elixir
defmodule YourApp.NS do
  use RDF.Vocabulary.Namespace

  defvocab EX,
    base_iri: "http://www.example.com/ns/",
    file: "your_vocabulary.nt",
    ignore: ~w[Foo bar]
    
end
```

Though strictly discouraged, a vocabulary namespace can be defined as non-strict with the `strict` option set to `false`. A non-strict vocabulary doesn't require any terms to be defined (although they can). A term is resolved dynamically at runtime by concatenation of the term and the base IRI of the resp. namespace module:

```elixir
defmodule YourApp.NS do
  use RDF.Vocabulary.Namespace

  defvocab EX,
    base_iri: "http://www.example.com/ns/",
    terms: [], 
    strict: false
end

iex> import RDF, only: [iri: 1]
iex> alias YourApp.NS.{EX}

iex> iri(EX.Foo)
~I<http://www.example.com/ns/Foo>

iex> EX.bar
~I<http://www.example.com/ns/bar>

iex> EX.Foo |> EX.bar(EX.Baz)
#RDF.Description{subject: ~I<http://www.example.com/ns/Foo>
     ~I<http://www.example.com/ns/bar>
         ~I<http://www.example.com/ns/Baz>}
```


### Blank nodes

Blank nodes are nodes of an RDF graph without an IRI. They are always local to that graph and mostly used as helper nodes. 

They can be created with `RDF.BlankNode.new` or its alias function `RDF.bnode`. You can either pass an atom, string, integer or Erlang reference with a custom local identifier or call it without any arguments, which will create a local identifier automatically.

```elixir
RDF.bnode(:foo)
RDF.bnode(42)
RDF.bnode
```

You can also use the `~B` sigil to create a blank node with a custom name:

```elixir
import RDF.Sigils
~B<foo>
```


### Literals

Literals are used for values such as strings, numbers, and dates. They can be untyped, languaged-tagged or typed. In general they are created with the `RDF.Literal.new` constructor function or its alias function `RDF.literal`:

```elixir
RDF.Literal.new("foo")
RDF.literal("foo")
```

The actual value can be accessed via the `value` struct field:

```elixir
RDF.literal("foo").value
```

An untyped literal can also be created with the `~L` sigil:

```elixir
import RDF.Sigils

~L"foo"
```

A language-tagged literal can be created by providing the `language` option with a [BCP47]-conform language or by adding the language as a modifier to the `~L` sigil:

```elixir
import RDF.Sigils

RDF.literal("foo", language: "en")

~L"foo"en
```

Note: Only languages without subtags are supported as modifiers of the `~L` sigil, i.e. if you want to use `en-US` as a language tag, you would have to use `RDF.literal` or `RDF.Literal.new`.

A typed literal can be created by providing the `datatype` option with an IRI of a datatype. Most of the time this will be an [XML schema datatype]:

```elixir
RDF.literal("42", datatype: XSD.integer)
```

It is also possible to create a typed literal by using a native Elixir non-string value, for which the following datatype mapping will be applied:

| Elixir datatype | XSD datatype   |
| :-------------- | :------------- |
| `boolean`       | `xsd:boolean`  |
| `integer`       | `xsd:integer`  |
| `float`         | `xsd:double`   |
| `Time`          | `xsd:time`     |
| `Date`          | `xsd:date`     |
| `DateTime`      | `xsd:dateTime` |
| `NaiveDateTime` | `xsd:dateTime` |
| [`Decimal`]     | `xsd:decimal`  |

So the former example literal can be created equivalently like this:

```elixir
RDF.literal(42)
```

For all of these known datatypes the `value` struct field contains the native Elixir value representation according to this mapping. When a known XSD datatype is specified, the given value will be converted automatically if needed and possible.

```elixir
iex> RDF.literal(42, datatype: XSD.double).value
42.0
```

For all of these supported XSD datatypes there are `RDF.Datatype`s available that allow the creation of `RDF.Literal`s with the respective datatype. Their `new` constructor function can be called also via the alias functions on the top-level `RDF` namespace.

```elixir
iex> RDF.Double.new("0042").value
42.0

iex> RDF.Double.new(42).value
42.0

iex> RDF.double(42).value
42.0
```

The `RDF.Literal.valid?/1` function checks if a given literal is valid according to the [XML schema datatype] specification.

```elixir
iex> RDF.Literal.valid? RDF.integer("42")
true

iex> RDF.Literal.valid? RDF.integer("foo")
false
```

If you want to prohibit the creation of invalid literals, you can use the `new!` constructor function of `RDF.Datatype` or `RDF.Literal`, which will fail in case of invalid values.

A RDF literal is bound to the lexical form of the initially given value. This lexical representation can be retrieved with the `RDF.Literal.lexical/1` function:

```elixir
iex> RDF.Literal.lexical RDF.integer("0042")
"0042"

iex> RDF.Literal.lexical RDF.integer(42)
"42"
```

Although two literals might have the same value, they are not equal if they don't have the same lexical form:

```elixir
iex> RDF.integer("0042").value == RDF.integer("42").value
true

iex> RDF.integer("0042") == RDF.integer("42")
false
```

The `RDF.Literal.canonical/1` function returns the given literal with its canonical lexical form according its datatype:

```elixir
iex> RDF.integer("0042") |> RDF.Literal.canonical |> RDF.Literal.lexical
"42"

iex> RDF.Literal.canonical(RDF.integer("0042")) == 
     RDF.Literal.canonical(RDF.integer("42"))
true
```

Note: Although you can create any XSD datatype by using the resp. IRI with the `datatype` option of `RDF.Literal.new`, not all of them support the validation and conversion behaviour of `RDF.Literal`s and the `value` field simply contains the initially given value unvalidated and unconverted. 



### Statements

RDF statements are generally represented in RDF.ex as native Elixir tuples, either as 3-element tuples for triples or as 4-element tuples for quads.

The `RDF.Triple` and `RDF.Quad` modules both provide a function `new` for such tuples, which coerces the elements to proper nodes when possible or raises an error when such a coercion is not possible. In particular these functions also resolve qualified terms from a vocabulary namespace. They can also be called with the alias functions `RDF.triple` and `RDF.quad`.

```elixir
iex> RDF.triple(EX.S, EX.p, 1)
{~I<http://example.com/S>, ~I<http://example.com/p>, RDF.integer(1)}

iex> RDF.triple {EX.S, EX.p, 1}
{~I<http://example.com/S>, ~I<http://example.com/p>, RDF.integer(1)}

iex> RDF.quad(EX.S, EX.p, 1, EX.Graph)
{~I<http://example.com/S>, ~I<http://example.com/p>, RDF.integer(1),
 ~I<http://example.com/Graph>}

iex> RDF.triple {EX.S, 1, EX.O}
** (RDF.Triple.InvalidPredicateError) '1' is not a valid predicate of a RDF.Triple
    (rdf) lib/rdf/statement.ex:53: RDF.Statement.coerce_predicate/1
    (rdf) lib/rdf/triple.ex:26: RDF.Triple.new/3
```

If you want to explicitly create a quad in the default graph context, you can use `nil` as the graph name. The `nil` value is used consistently as the name of the default graph within RDF.ex.

```elixir
iex> RDF.quad(EX.S, EX.p, 1, nil)
{~I<http://example.com/S>, ~I<http://example.com/p>, RDF.integer(1), nil}
```


### RDF data structures

RDF.ex provides various data structures for collections of statements:

- `RDF.Description`: a collection of triples about the same subject
- `RDF.Graph`: a named collection of statements
- `RDF.Dataset`:  a named collection of graphs, i.e. a collection of statements from different graphs; it may have multiple named graphs and at most one unnamed ("default") graph

All of these structures have similar sets of functions and implement Elixirs `Enumerable` and `Collectable` protocol, Elixirs `Access` behaviour and the `RDF.Data` protocol of RDF.ex.

The `new` function of these data structures create new instances of the struct and optionally initialize them with initial statements. `RDF.Description.new` requires at least an IRI or blank node for the subject, while `RDF.Graph.new` and `RDF.Dataset.new` take an optional IRI for the name of the graph or dataset.

```elixir
empty_description = RDF.Description.new(EX.Subject)

empty_unnamed_graph = RDF.Graph.new
empty_named_graph   = RDF.Graph.new(EX.Graph)

empty_unnamed_dataset = RDF.Dataset.new
empty_named_dataset   = RDF.Dataset.new(EX.Dataset)
```

As you can see, qualified terms from a vocabulary namespace can be given instead of an IRI and will be resolved automatically. This applies to all of the functions discussed below.

The `new` functions can be called more shortly with the resp. delegator functions `RDF.description`, `RDF.graph` and `RDF.dataset`.  

The `new` functions also take optional initial data, which can be provided in various forms. Basically it takes the given data and hands it to the `add` function with the newly created struct. 

#### Adding statements

So let's look at these various forms of data the `add` function can handle. 

Firstly, they can handle single statements:

```elixir
description |> RDF.Description.add {EX.S, EX.p, EX.O}
graph       |> RDF.Graph.add {EX.S, EX.p, EX.O}
dataset     |> RDF.Dataset.add {EX.S, EX.p, EX.O, EX.Graph}
```

When the subject of a statement doesn't match the subject of the description, `RDF.Description.add` ignores it and is a no-op. 

`RDF.Description.add` also accepts a property-value pair as a tuple.

```elixir
RDF.Description.new(EX.S, {EX.p, EX.O1})
|> RDF.Description.add {EX.p, EX.O2}
```

In general, the object position of a statement can be a list of values, which will be interpreted as multiple statements with the same subject and predicate. So the former could be written more shortly:

```elixir
RDF.Description.new(EX.S, {EX.p, [EX.O1, EX.O2]})
```

Multiple statements with different subject and/or predicate can be given as a list of statements, where everything said before on single statements applies to the individual statements of these lists:

```elixir
description |> RDF.Description.add [{EX.p1, EX.O}, {EX.p2, [EX.O1, EX.O2]}
graph       |> RDF.Graph.add [{EX.S1, EX.p1, EX.o1}, {EX.S2, EX.p2, EX.o2}]
dataset     |> RDF.Dataset.add [{EX.S, EX.p, EX.o}, {EX.S, EX.p, EX.o, EX.Graph}
```

A `RDF.Description` can be added to any of the three data structures:

```elixir
input = RDF.Description.new(EX.S, {EX.p, EX.O1})
description |> RDF.Description.add input
graph       |> RDF.Graph.add input
dataset     |> RDF.Dataset.add input
```

Note that, unlike mismatches in the subjects of directly given statements, `RDF.Description.add` ignores the subject of a given `RDF.Description` and just adds the property-value pairs of the given description, because this is a common use case when merging the descriptions of differently named resources (eg. because they are linked via `owl:sameAs`).

`RDF.Graph.add` and `RDF.Dataset.add` can also add other graphs and `RDF.Dataset.add` can add the contents of another dataset.

`RDF.Dataset.add` is also special, in that it allows to overwrite the explicit or implicit graph context of the input data and redirect the input into another graph. For example, the following examples all add the given statements to the `EX.Other` graph:

```elixir
RDF.Dataset.new
|> RDF.Dataset.add({EX.S, EX.p, EX.O}, EX.Other)
|> RDF.Dataset.add[{EX.S, EX.p, EX.O1, nil}, {EX.S, EX.p, EX.O2, EX.Graph}], EX.Other)
|> RDF.Dataset.add(RDF.Graph.new(EX.Graph, {EX.S, EX.p, EX.O3}), EX.Other)
```

Unlike the `add` function, which always returns the same data structure as the data structure to which the addition happens, which possible means ignoring some input statements (eg. when the subject of a statement doesn't match the description subject) or reinterpreting some parts of the input statement (eg. ignoring the subject of another description), the `merge` function of the `RDF.Data` protocol implemented by all three data structures will always add all of the input and possibly creates another type of data structure. For example, merging two `RDF.Description`s with different subjects results in a `RDF.Graph`. Or adding a quad to a `RDF.Graph` with a different name than the quad’s graph context results in a `RDF.Dataset`.

```elixir
RDF.Description.new(EX.S1, {EX.p, EX.O}) 
|> RDF.Data.merge(RDF.Description.new(EX.S2, {EX.p, EX.O})) # returns an unnamed RDF.Graph
|> RDF.Data.merge(RDF.Graph.new(EX.Graph, {EX.S2, EX.p, EX.O2})) # returns a RDF.Dataset
```

Statements added with `put` overwrite all existing statements with the same subject and predicate.

```elixir
iex> RDF.Graph.new({EX.S1, EX.p, EX.O1}) |> RDF.Graph.put({EX.S1, EX.p, EX.O2})
#RDF.Graph{name: nil
     ~I<http://example.com/S1>
         ~I<http://example.com/p>
             ~I<http://example.com/O2>}
```

It is available on all three data structures and can handle all of the input data types as their `add` counterpart.


#### Accessing the content of RDF data structures

All three RDF data structures implement the `Enumerable` protocol over the set of contained statements. As a set of triples in the case of `RDF.Description` and `RDF.Graph` and as a set of quads in case of `RDF.Dataset`. This means you can use all `Enum` functions over the contained statements as tuples.

```elixir
RDF.Description.new(EX.S1, {EX.p, [EX.O1, EX.O2]})
|> Enum.each(&IO.inspect/1)
```

The `RDF.Data` protocol offers various functions to access the contents of RDF data structures:

- `RDF.Data.subjects/1` returns the set of all subject resources.
- `RDF.Data.predicates/1` returns the set of all used properties.
- `RDF.Data.objects/1` returns the set of all resources on the object position of statements. Note: Literals not included.
- `RDF.Data.resources/1` returns the set of all used resources at any position in the contained RDF statements.
- `RDF.Data.description/2` returns all statements from a data structure about the given resource as a `RDF.Description`. It will be empty if no such statements exist. On a `RDF.Dataset` it will aggregate the statements about the resource from all graphs.
- `RDF.Data.descriptions/1` returns all `RDF.Description`s within a data structure (possible aggregated in the case of a `RDF.Dataset`)
- `RDF.Data.statements/1` returns a list of all contained RDF statements.

The `get` functions return individual elements of a RDF data structure:

- `RDF.Description.get` returns the list of all object values for a given property.
- `RDF.Graph.get` returns the `RDF.Description` for a given subject resource.
- `RDF.Dataset.get` returns the `RDF.Graph` with the given graph name.

All of these `get` functions return `nil` or the optionally given default value, when the given element can not be found.

```elixir
iex> RDF.Description.new(EX.S1, {EX.p, [EX.O1, EX.O2]})
...> |> RDF.Description.get(EX.p)
[~I<http://example.com/O1>, ~I<http://example.com/O2>]

iex> RDF.Graph.new({EX.S1, EX.p, [EX.O1, EX.O2]})
...> |> RDF.Graph.get(EX.p2, :not_found)
:not_found
```

You can get a single object value for a given predicate in a `RDF.Description` with the `RDF.Description.first/2` function:

```elixir
iex> RDF.Description.new(EX.S1, {EX.p, EX.O1})
...> |> RDF.Description.first(EX.p)
~I<http://example.com/O1>
```

Since all three RDF data structures implement the `Access` behaviour, you can also use `data[key]` syntax, which basically just calls the resp. `get` function.

```elixir
iex> description[EX.p]
[~I<http://example.com/O1>, ~I<http://example.com/O2>]

iex> graph[EX.p2] 
nil
```

Also, the familiar `fetch` function of the `Access` behaviour, as a variant of `get` which returns `ok` tuples, is available on all RDF data structures.

```elixir
iex> RDF.Description.new(EX.S1, {EX.p, [EX.O1, EX.O2]})
...> |> RDF.Description.fetch(EX.p)
{:ok, [~I<http://example.com/O1>, ~I<http://example.com/O2>]}

iex> RDF.Graph.new({EX.S1, EX.p, [EX.O1, EX.O2]})
...> |> RDF.Graph.fetch(EX.p2)
:error
```

`RDF.Dataset` also provides the following functions to access individual graphs:

- `RDF.Dataset.graphs` returns the list of all the graphs of the dataset
- `RDF.Dataset.default_graph` returns the default graph of the dataset
- `RDF.Dataset.graph` returns the graph of the dataset with the given name 


#### Querying graphs with the SPARQL query language

The [SPARQL.ex] package allows you to execute SPARQL queries against RDF.ex data structures. It's still very limited at the moment. It just supports `SELECT` queries with basic graph pattern matching, filtering and projection and works on `RDF.Graph`s only. But even in this early, limited form it allows to express more powerful queries in a simpler way than with the plain `RDF.Graph` API.

See the [SPARQL.ex README](https://github.com/marcelotto/sparql-ex#sparqlex) for more information and some examples.


#### Deleting statements

Statements can be deleted in two slightly different ways. One way is to use the `delete` function of the resp. data structure. It accepts all the supported ways for specifying collections of statements supported by the resp. `add` counterparts and removes the found triples.

```elixir
iex> RDF.Description.new(EX.S1, {EX.p, [EX.O1, EX.O2]})
...> |> RDF.Description.delete({EX.S1, EX.p, EX.O1})
#RDF.Description{subject: ~I<http://example.com/S1>
     ~I<http://example.com/p>
         ~I<http://example.com/O2>}
```

Another way to delete statements is the `delete` function of the `RDF.Data` protocol. The only difference to `delete` functions on the data structures directly is how it handles the deletion of a `RDF.Description` from another `RDF.Description` or `RDF.Graph` from another `RDF.Graph`. While the dedicated RDF data structure function ignores the description subject or graph name and removes the statements even when they don't match, `RDF.Data.delete` only deletes when the description’s subject resp. graph name matches.

```elixir
iex> RDF.Description.new(EX.S1, {EX.p, [EX.O1, EX.O2]})
...> |> RDF.Description.delete(RDF.Description.new(EX.S2, {EX.p, EX.O1}))
#RDF.Description{subject: ~I<http://example.com/S1>
     ~I<http://example.com/p>
         ~I<http://example.com/O2>}

iex> RDF.Description.new(EX.S1, {EX.p, [EX.O1, EX.O2]})
...> |> RDF.Data.delete(RDF.Description.new(EX.S2, {EX.p, EX.O1}))
#RDF.Description{subject: ~I<http://example.com/S1>
     ~I<http://example.com/p>
         ~I<http://example.com/O1>
         ~I<http://example.com/O2>}
```

Beyond that, there is 

- `RDF.Description.delete_predicates` which deletes all statements with the given property from a `RDF.Description`,
- `RDF.Graph.delete_subjects` which deletes all statements with the given subject resource from a `RDF.Graph`,
- `RDF.Dataset.delete_graph` which deletes all graphs with the given graph name from a `RDF.Dataset` and
- `RDF.Dataset.delete_default_graph` which deletes the default graph of a `RDF.Dataset`.


### Lists

RDF lists can be represented with the `RDF.List` structure.

An existing `RDF.List` in a given graph can be created with `RDF.List.new` or its alias `RDF.list`, passing it the head node of a list and the graph containing the statements constituting the list.

```elixir
graph = 
  Graph.new(
       ~B<Foo>
       |> RDF.first(1)
       |> RDF.rest(EX.Foo))
    |> Graph.add(
       EX.Foo
       |> RDF.first(2)
       |> RDF.rest(RDF.nil))
    )

list = RDF.List.new(~B<Foo>, graph)
```

If the given head node does not refer to a well-formed RDF list in the graph, `nil` is returned.

An entirely new `RDF.List` can be created with `RDF.List.from` or `RDF.list` and a native Elixir list or an Elixir `Enumerable` with values of all types that are allowed for objects of statements (including nested lists). 

```elixir
list = RDF.list(["foo", EX.bar, ~B<bar>, [1, 2, 3]])
```
If you want to add the graph statements to an existing graph, you can do that via the `graph` option.

```elixir
existing_graph = RDF.Graph.new({EX.S, EX.p, EX.O})
RDF.list([1, 2, 3], graph: existing_graph)
```

The `head` option also allows to specify a custom node for the head of the list.

The function `RDF.List.values/1` allows to get the values of a RDF list (including nested lists) as a native Elixir list.

```elixir
iex> RDF.list(["foo", EX.Bar, ~B<bar>, [1, 2]]) |> RDF.List.values
[~L"foo", ~I<http://www.example.com/ns/Bar>, ~B<bar>,
 [%RDF.Literal{value: 1, datatype: ~I<http://www.w3.org/2001/XMLSchema#integer>},
  %RDF.Literal{value: 2, datatype: ~I<http://www.w3.org/2001/XMLSchema#integer>}]]
```

### Mapping of RDF terms and structures

The `RDF.Term.value/1` function converts RDF terms to Elixir values:

```elixir
iex> RDF.Term.value(~I<http://example.com/>)
"http://example.com/"
iex> RDF.Term.value(~L"foo")
"foo"
iex> RDF.integer(42) |> RDF.Term.value()
42
```

It returns `nil` if no conversion is possible.

All structures of RDF terms also support a `values` function. The `values` functions on `RDF.Triple`, `RDF.Quad` and `RDF.Statement` are converting a tuple of RDF terms to a tuple of the resp. Elixir values. On all of the other RDF data structures (`RDF.Description`, `RDF.Graph` and `RDF.Dataset`) and the general `RDF.Data` protocol the `values` functions are producing a map of the converted Elixir values.

```elixir
iex> RDF.Triple.values {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42)}
{"http://example.com/S", "http://example.com/p", 42}

iex> {~I<http://example.com/S>, ~I<http://example.com/p>, ~L"Foo"}
...> |> RDF.Description.new()
...> |> RDF.Description.values()
%{"http://example.com/p" => ["Foo"]}

iex> [
...>   {~I<http://example.com/S1>, ~I<http://example.com/p>, ~L"Foo"},
...>   {~I<http://example.com/S2>, ~I<http://example.com/p>, RDF.integer(42)}
...> ]
...> |> RDF.Graph.new()
...> |> RDF.Graph.values()
%{
  "http://example.com/S1" => %{"http://example.com/p" => ["Foo"]},
  "http://example.com/S2" => %{"http://example.com/p" => [42]}
}

iex> [
...>   {~I<http://example.com/S>, ~I<http://example.com/p>, ~L"Foo", ~I<http://example.com/Graph>},
...>   {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.integer(42), }
...> ]
...> |> RDF.Dataset.new()
...> |> RDF.Dataset.values()
%{
  "http://example.com/Graph" => %{
    "http://example.com/S" => %{"http://example.com/p" => ["Foo"]}
  },
  nil => %{
    "http://example.com/S" => %{"http://example.com/p" => [42]}
  }
}
```

All of these `values` functions also support an optional second argument for a function with a custom mapping of the terms depending on their statement position. The function will be called with a tuple `{statement_position, rdf_term}` where `statement_position` is one of the atoms `:subject`, `:predicate`, `:object` or `:graph_name`, while `rdf_term` is the RDF term to be mapped.

```elixir
iex> [
...>   {~I<http://example.com/S1>, ~I<http://example.com/p>, ~L"Foo"},
...>   {~I<http://example.com/S2>, ~I<http://example.com/p>, RDF.integer(42)}
...> ]
...> |> RDF.Graph.new()
...> |> RDF.Graph.values(fn 
...>      {:predicate, predicate} ->
...>        predicate 
...>        |> to_string() 
...>        |> String.split("/") 
...>        |> List.last() 
...>        |> String.to_atom()
...>    {_, term} ->
...>      RDF.Term.value(term)
...>    end)
%{
  "http://example.com/S1" => %{p: ["Foo"]},
  "http://example.com/S2" => %{p: [42]}
}
```


### Serializations

The RDF.ex package comes with implementations of the [N-Triples], [N-Quads] and [Turtle] serialization formats. 
Formats which require additional dependencies should be implemented in separate Hex packages.
The [JSON-LD] format for example is available with the [JSON-LD.ex] package.

RDF graphs and datasets can be read and written to files or strings in a RDF serialization format using the  `read_file`, `read_string` and `write_file`, `write_string` functions of the resp. `RDF.Serialization.Format` module.

```elixir
{:ok, graph} = RDF.NTriples.read_file("/path/to/some_file.nt")
{:ok, nquad_string} = RDF.NQuads.write_string(graph)
```

All of the read and write functions are also available in bang variants which will fail in error cases.

All of these `read_*` and `write_*` functions are also available in the top-level `RDF` module, where the serialization format can be specified in various ways, either by providing the format name via the `format` option, or via the `media_type` option. 

```elixir
{:ok, graph} = RDF.read_file("/path/to/some_file", format: :turtle)
json_ld_string = RDF.write_string!(graph, media_type: "application/ld+json")
```

Note: The later command requires the `json_ld` package to be defined as a dependency in the Mixfile of your application.

The file read and write functions are also able to infer the format from the file extension of the given filename.

```elixir
RDF.read_file!("/path/to/some_file.ttl")
|> RDF.write_file!("/path/to/some_file.jsonld")
```

For serialization formats which support it, you can provide a base IRI on the read functions with the `base` option. You can also provide a default base IRI in your application configuration, which will be used when no `base` option is given.

```elixir
config :rdf,
  default_base_iri: "http://my_app.example/"
```



## Caveats

The `Date` and `DateTime` modules of Elixir versions < 1.7.2 don't handle negative years properly. In case you're data contains negative years in `xsd:date` or `xsd:dateTime` literals, you'll have to upgrade to a newer Elixir version.



## Getting help

- [Documentation](http://hexdocs.pm/rdf)
- [A tutorial about working with RDF.ex vocabularies by Tony Hammond](https://medium.com/@tonyhammond/early-steps-in-elixir-and-rdf-5078a4ebfe0f)
- [Google Group](https://groups.google.com/d/forum/rdfex)



## TODO

There's still much to do for a complete RDF ecosystem for Elixir, which means there are plenty of opportunities for you to contribute. Here are some suggestions:

- more serialization formats
    - [RDFa]
    - [RDF-XML]
    - [N3]
    - et al.
- more XSD datatypes
- improve documentation



## Contributing

see [CONTRIBUTING](CONTRIBUTING.md) for details.



## License and Copyright

(c) 2017-2018 Marcel Otto. MIT Licensed, see [LICENSE](LICENSE.md) for details.


[RDF.ex]:               https://hex.pm/packages/rdf
[rdf_vocab]:            https://hex.pm/packages/rdf_vocab
[JSON-LD.ex]:           https://hex.pm/packages/json_ld
[SPARQL.ex]:            https://hex.pm/packages/sparql
[SPARQL.Client]:        https://hex.pm/packages/sparql_client
[N-Triples]:            https://www.w3.org/TR/n-triples/
[N-Quads]:              https://www.w3.org/TR/n-quads/
[Turtle]:               https://www.w3.org/TR/turtle/
[N3]:                   https://www.w3.org/TeamSubmission/n3/
[JSON-LD]:              http://www.w3.org/TR/json-ld/
[RDFa]:                 https://www.w3.org/TR/rdfa-syntax/
[RDF-XML]:              https://www.w3.org/TR/rdf-syntax-grammar/
[BCP47]:                https://tools.ietf.org/html/bcp47
[XML schema datatype]:  https://www.w3.org/TR/xmlschema11-2/
[`Decimal`]:            https://github.com/ericmj/decimal
