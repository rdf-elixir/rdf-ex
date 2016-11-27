# RDF.ex Core

An implementation of the RDF and the basic accompanied standards for Elixir.


## Installation

The [Hex package](https://hex.pm/docs/publish) can be installed as usual:

  1. Add `rdf_core` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:rdf_core, "~> 0.1.0"}]
    end
    ```

  2. Ensure `rdf_core` is started before your application:

    ```elixir
    def application do
      [applications: [:rdf_core]]
    end
    ```

## Introduction

The [RDF standard](http://www.w3.org/TR/rdf11-concepts/) defines a Graph data model for distributed information on the web. A RDF graph is a set of RDF triples, consistenting of a three nodes:

1. a subject node with an IRI or a blank node,
2. a predicate node with the IRI of a RDF property, 
3. an object nodes with an IRI, a blank node or a RDF literal value.

Let's start examining how the different types of nodes - the RDF standards also calls them RDF terms - are represented in Elixir.

### Nodes

#### Literals

#### URIs

Although the RDF standards speaks of IRIs, an internationalized generalization of URIs, RDF.ex currently supports only URIs. They are represented by Elixirs builtin [`URI`](http://elixir-lang.org/docs/stable/elixir/URI.html) struct.

The `RDF` module defines a handy generator function `RDF.uri`

```elixir
RDF.uri("http://www.example.com/foo")
```

Besides being shorter than `URI.parse`, it will provide a gentlier migration, if we decide to switch to a dedicated, more optimized URI-representation for RDF.ex.

#### Vocabularies

But rather than having to pass a fully qualified URI string to `RDF.uri`, it allows for something similar to QNames of XML.



#### Blank nodes


### Triples

### Graphs and Descriptions

### Serializations

### Repositories


## Getting help

- [Hex]()
- [Slack]()


## Development



## Contributing

see [CONTRIBUTING](CONTRIBUTING.md) for details.


## License and Copyright

(c) 2016 Marcel Otto. MIT Licensed, see [LICENSE](LICENSE.txt) for details.
