# RDF.ex

An implementation of the [RDF](https://www.w3.org/TR/rdf11-primer/) data model in Elixir.



## Installation

The [Hex package](https://hex.pm/docs/publish) can be installed as usual:

  1. Add `rdf` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:rdf, "~> 0.1.0"}]
    end
    ```

  2. Ensure `rdf` is started before your application:

    ```elixir
    def application do
      [applications: [:rdf]]
    end
    ```

## Introduction

The [RDF standard](http://www.w3.org/TR/rdf11-concepts/) defines a graph data model for distributed information on the web. A RDF graph is a set of statements aka RDF triples consistenting of a three nodes:

1. a subject node with an IRI or a blank node,
2. a predicate node with the IRI of a RDF property, 
3. an object nodes with an IRI, a blank node or a RDF literal value.

Let's see how the different types of nodes are represented with RDF.ex in Elixir.

### URIs

Although the RDF standards speaks of IRIs, an internationalized generalization of URIs, RDF.ex currently supports only URIs. They are represented with Elixirs builtin [`URI`](http://elixir-lang.org/docs/stable/elixir/URI.html) struct. Its a pragmatic, temporary decision, which will be subject to changes very probably, in favour of a more dedicated representation of IRIs specialised for its usage within RDF data. See this [issue]() for progress on this matter.

The `RDF` module defines a handy constructor function `RDF.uri/1`:

```elixir
RDF.uri("http://www.example.com/foo")
```

Besides being a little shorter than `URI.parse` and better `import`able, it will provide a gentlier migration to the mentioned, more optimized URI-representation in RDF.ex.

An URI can also be created with the `~I` sigil:

```elixir
~I<http://www.example.com/foo>
```

But there's an even shorter way notation for providing URI literals.


### Vocabularies

RDF.ex supports modules which represent a RDF vocabulary as a `RDF.Vocabulary.Namespace` and comes with predefined modules for some fundamentals vocabularies in the `RDF.NS` module.
Furthermore, the [rdf_vocab](https://hex.pm/packages/rdf_vocab) package
contains predefined `RDF.Vocabulary.Namespace`s for popular vocabularies.

These `RDF.Vocabulary.Namespace`s (a special case of a `RDF.Namespace`) allows for something similar to QNames of XML: a qualified atom with a Elixir module can be resolved to an URI. 

There are two types of terms in a `RDF.Vocabulary.Namespace` which are
resolved differently:

1. Capitalized terms are by standard Elixir semantics modules names, i.e.
   atoms. In all places in RDF.ex, where an URI is expected, you can use atoms
   qualified with a `RDF.Namespace` directly, but if you want to resolve it
   manually, you can pass the `RDF.Namespace` qualified atom to `RDF.uri`.
2. Lowercased terms for RDF properties are represented as functions on a
   `RDF.Vocabulary.Namespace` module and return the URI directly, but since `RDF.uri` can also handle URIs directly, you can safely and consistently use it with lowercased terms too.

```elixir
iex> import RDF, only: [uri: 1]
iex> alias RDF.NS.{RDFS}
iex> RDFS.Class
RDF.NS.RDFS.Class
iex> uri(RDFS.Class)
%URI{authority: "www.w3.org", fragment: "Class", host: "www.w3.org",
 path: "/2000/01/rdf-schema", port: 80, query: nil, scheme: "http",
 userinfo: nil}
iex> RDFS.subClassOf
%URI{authority: "www.w3.org", fragment: "subClassOf", host: "www.w3.org",
 path: "/2000/01/rdf-schema", port: 80, query: nil, scheme: "http",
 userinfo: nil}
iex> uri(RDFS.subClassOf)
%URI{authority: "www.w3.org", fragment: "subClassOf", host: "www.w3.org",
 path: "/2000/01/rdf-schema", port: 80, query: nil, scheme: "http",
 userinfo: nil}
```

As this example shows the namespace modules can be easily `alias`ed. When required they can be also aliased to different a different module. Since the `RDF` vocabulary namespace in `RDF.NS.RDF` can't be aliased, since it would clash with top-level `RDF` module, all of its elements can be accessed directly from the `RDF` module (without an alias).

```elixir
iex> import RDF, only: [uri: 1]
iex> RDF.type

iex> uri(RDF.Property)

```

This way of expressing URIs has the additional benefit, that the existence of the referenced URI is checked at compile time, i.e. whenever a term is used that is not part of the resp. vocabulary an error is raised by the Elixir compiler (unless the vocabulary namespace is non-strict; see below).

For terms not adhering to the capitalization rules (properties lowercased, non-properties capitalized) or containing characters not allowed within atoms, these namespace define aliases accordingly. If not sure, you can look in the documentation or the vocabulary namespace definition. 

#### Description DSL

The functions on the vocabulary namespace modules for properties, also are also available in description builder variant, which accepts subject and objects as arguments.

```elixir
RDF.type(EX.Foo, EX.Bar)
```

If you want to state multiple statements with the same subject and predicate, you can either pass the objects as a list or, if there are not more not five of them, as additional arguments:

```elixir
RDF.type(EX.Foo, EX.Bar, EX.Baz)
EX.foo(EX.Bar, [1, 2, 3, 4, 5, 6])
```

In combination with Elixirs pipe operators this leads to a description DSL which resembles Turtle:

```elixir
EX.Foo
|> RDF.type(EX.Bar)
|> EX.baz(1, 2, 3)
```

The produced statements are returned by this function as a `RDF.Description` structure which will be described below.


#### Defining vocabulary namespaces

There are two basic ways to define a namespace for a vocabulary:

1. You can define all terms manually.
2. You can extract the terms from existing RDF data for URIs of resources under the specified base URI. 

It's recommended to introduce a dedicated module for the defined namespace. On this module you'll `use RDF.Vocabulary.Namespace` and define your vocabulary namespaces with the `defvocab` macro.

A vocabulary namespace with manually defined terms can be defined in this way like that:

```elixir
defmodule YourApp.NS do
  use RDF.Vocabulary.Namespace

  defvocab EX,
    base_uri: "http://www.example.com/ns/",
    terms: ~w[Foo bar]
    
end
```

The `base_uri` argument with the URI prefix of all the terms in the defined
vocabulary is required and expects a valid URI ending with either a `"/"` or
a `"#"`. Terms will be checked for invalid character at compile-time and will raise a compile error. This handling of invalid characters can be modified with the `invalid_characters` options, which is by default set to `:fail`. By setting it explicitly to `:warn` only warnings will be raised or it can be turned off completely with `:ignore`.

A vocabulary namespace with extracted terms can be by either providing RDF data directly with the `data` option or from serialized RDF data file in the `priv/vocabs` directory:

```elixir
defmodule YourApp.NS do
  use RDF.Vocabulary.Namespace

  defvocab EX,
    base_uri: "http://www.example.com/ns/",
    file: "your_vocabulary.nt"
    
end
```

Currently only NTriple and NQuad files are supported at this place.

During compilation the terms will be validated, if they are properly capitalized (properties lowercased, non-properties capitalized), by analyzing the schema description of the resp. resource in the given data. 
This validation behaviour can be modified with the `case_violations` options, which is by default set to `:warn`. By setting it explicitly to `:fail` errors will be raised during compilation or it can be turned off with `:ignore`.

When the terms contain invalid characters or violate the capitalization rules, you can fix these by defining aliases for these terms with the `alias` option and a keyword list:

```elixir
defmodule YourApp.NS do
  use RDF.Vocabulary.Namespace

  defvocab EX,
    base_uri: "http://www.example.com/ns/",
    terms: ~w[example-term],
    alias: [example_term: "example-term"]

end
```

Though strictly discouraged, a vocabulary namespace can be defined as non-strict with the `strict` option set to `false`. A non-strict vocabulary doesn't require any terms to be defined (although they can). A term is resolved dynamically at runtime by simple concatentating the term with the base uri of the resp. namespace module:

```elixir
defmodule YourApp.NS do
  use RDF.Vocabulary.Namespace

  defvocab EX,
    base_uri: "http://www.example.com/ns/",
    terms: [], 
    strict: false
end

iex> import RDF, only: [uri: 1]
iex> alias YourApp.NS.{EX}
iex> uri(EX.Foo)
%URI{authority: "www.example.com", fragment: nil, host: "www.example.com",
 path: "/ns/Foo", port: 80, query: nil, scheme: "http", userinfo: nil}
iex> EX.bar
%URI{authority: "www.example.com", fragment: nil, host: "www.example.com",
 path: "/ns/bar", port: 80, query: nil, scheme: "http", userinfo: nil}
iex> EX.Foo |> EX.bar(EX.Baz)
#RDF.Description{subject: ~I<http://www.example.com/ns/Foo>
     ~I<http://www.example.com/ns/bar>
         ~I<http://www.example.com/ns/Baz>}
```


### Blank nodes

TODO


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

A language-tagged literal can be created by providing the `language` option with a [BCP47](https://tools.ietf.org/html/bcp47)-conform language or by adding the language as a modifier to the `~L` sigil:

```elixir
RDF.literal("foo", language: "en")

import RDF.Sigils
~L"foo"en
```

Note: Only languages without subtags are supported as modifiers of the `~L` sigil, i.e. if you want to use `en-US` as a language tag, you would have to use `RDF.literal` or `RDF.Literal.new`.

A typed literal can be created by providing the `datatype` option with an URI of a datatype. Most of the time this will be an [XML schema datatype](https://www.w3.org/TR/xmlschema11-2/):

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

So the former example literal can be created equivalently like this:

```elixir
RDF.literal(42)
```

For all of these known datatypes the `value` struct field contains the native Elixir value representation according to this mapping. When a known XSD datatype is specified the given value will be converted automatically if needed and possible.

```elixir
iex> RDF.literal(42, datatype: XSD.double).value
42.0
```

For all of these supported XSD datatypes `RDF.Datatype`s are available, which are modules that allow the creation of `RDF.Literal`s with the respective datatype:

```elixir
iex> RDF.Double.new("0042").value
42.0
iex> RDF.Double.new(42).value
42.0
```

The `RDF.Literal.valid?/1` function checks if a given literal is valid according to the [XML schema datatype specification](https://www.w3.org/TR/xmlschema11-2/).

```elixir
iex> RDF.Literal.valid? RDF.Integer.new("42")
true
iex> RDF.Literal.valid? RDF.Integer.new("foo")
false
```

A RDF literal is bound to the lexical form of the initially given value. This lexical representation can be retrieved with the `RDF.Literal.lexical/1` function:

```elixir
iex> RDF.Literal.lexical RDF.Integer.new("0042")
"0042"
iex> RDF.Literal.lexical RDF.Integer.new(42)
"42"
```

Although two literals might have the same value, they are not equal when they don't have the same lexical form:

```elixir
iex> RDF.Integer.new("0042").value == RDF.Integer.new("42").value
true
iex> RDF.Integer.new("0042") == RDF.Integer.new("42")
false
```

The `RDF.Literal.canonical/1` function returns the given literal with its canonical lexical form according its datatype:

```elixir
iex> RDF.Integer.new("0042") |> RDF.Literal.canonical |> RDF.Literal.lexical
"42"
iex> RDF.Literal.canonical(RDF.Integer.new("0042")) == 
     RDF.Literal.canonical(RDF.Integer.new("42"))
true
```

Note: Although you can create any XSD datatype by using the resp. URI with the `datatype` option of `RDF.Literal.new`, not all of them support the validation and conversion behaviour of `RDF.Literal`s and the `value` field simple contains the initially given value unvalidated and unconverted. See [this project]() for the missing XSD datatypes.



### RDF data structures

#### Statements

#### Descriptions

#### Graphs

#### Datasets

Multiple graphs in an RDF document constitute an RDF dataset. An RDF dataset may have multiple named graphs and at most one unnamed ("default") graph.



#### `RDF.Data` protocol


### Serializations



## Getting help

- [Hex]()
- [Slack]()


## Development



## Contributing

see [CONTRIBUTING](CONTRIBUTING.md) for details.


## License and Copyright

(c) 2017 Marcel Otto. MIT Licensed, see [LICENSE](LICENSE.txt) for details.

