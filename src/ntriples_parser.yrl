%% Grammar for N-Triples as specified in https://www.w3.org/TR/2014/REC-n-triples-20140225/

Nonterminals ntriplesDoc nonEmptyNtriplesDoc triple subject predicate object literal quoted_triple eols.
Terminals iriref blank_node_label string_literal_quote langtag '^^' '.' '<<' '>>' eol.
Rootsymbol ntriplesDoc.

eols -> eols eol.
eols -> eol.

ntriplesDoc -> nonEmptyNtriplesDoc      : ['$1'].
ntriplesDoc -> eols nonEmptyNtriplesDoc : ['$2'].
ntriplesDoc -> eols                     : [].
ntriplesDoc -> '$empty'                 : [].

nonEmptyNtriplesDoc -> triple eols nonEmptyNtriplesDoc : ['$1' | '$3'].
nonEmptyNtriplesDoc -> triple eols                     : ['$1'].
nonEmptyNtriplesDoc -> triple                          : ['$1'].

triple -> subject predicate object '.' : { '$1', '$2', '$3' }.

subject   -> iriref            : to_iri('$1').
subject   -> blank_node_label  : to_bnode('$1').
subject   -> quoted_triple     : '$1'.
predicate -> iriref            : to_iri('$1').
object    -> iriref            : to_iri('$1').
object    -> blank_node_label  : to_bnode('$1').
object    -> literal           : '$1'.
object    -> quoted_triple     : '$1'.

literal -> string_literal_quote '^^' iriref : to_literal('$1', {datatype, to_iri('$3')}).
literal -> string_literal_quote langtag     : to_literal('$1', {language, to_langtag('$2')}).
literal -> string_literal_quote             : to_literal('$1').

quoted_triple -> '<<' subject predicate object '>>' : { '$2', '$3', '$4' }.

Erlang code.

to_iri(IRIREF) ->
  case 'Elixir.RDF.Serialization.ParseHelper':to_iri(IRIREF) of
    {ok, URI} -> URI;
    {error, ErrorLine, Message} -> return_error(ErrorLine, Message)
  end.
to_bnode(BLANK_NODE_LABEL) -> 'Elixir.RDF.Serialization.ParseHelper':to_bnode(BLANK_NODE_LABEL).
to_literal(STRING_LITERAL_QUOTE) -> 'Elixir.RDF.Serialization.ParseHelper':to_literal(STRING_LITERAL_QUOTE).
to_literal(STRING_LITERAL_QUOTE, Type) -> 'Elixir.RDF.Serialization.ParseHelper':to_literal(STRING_LITERAL_QUOTE, Type).
to_langtag(LANGTAG) -> 'Elixir.RDF.Serialization.ParseHelper':to_langtag(LANGTAG).
