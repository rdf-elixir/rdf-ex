%% Grammar for N-Triples as specified in https://www.w3.org/TR/2014/REC-n-triples-20140225/

Nonterminals ntriplesDoc nonEmptyNtriplesDoc triple subject predicate object literal eols.
Terminals iriref blank_node_label string_literal_quote langtag '^^' '.' eol.
Rootsymbol ntriplesDoc.

eols -> eols eol.
eols -> eol.

ntriplesDoc -> nonEmptyNtriplesDoc : [ '$1'].
ntriplesDoc -> eols nonEmptyNtriplesDoc : [ '$2'].
ntriplesDoc -> eols                 : [].
ntriplesDoc -> '$empty'            : [].

%nonEmptyNtriplesDoc -> triple eol nonEmptyNtriplesDoc : [ '$1' | '$3' ].
%nonEmptyNtriplesDoc -> triple eol            : [ '$1' ].
%nonEmptyNtriplesDoc -> triple                : [ '$1' ].

nonEmptyNtriplesDoc -> triple eols nonEmptyNtriplesDoc : [ '$1' | '$3' ].
nonEmptyNtriplesDoc -> triple eols            : [ '$1' ].
nonEmptyNtriplesDoc -> triple                : [ '$1' ].

triple -> subject predicate object '.' : { '$1', '$2', '$3' }.

subject   -> iriref            : to_uri('$1').
subject   -> blank_node_label  : to_bnode('$1').
predicate -> iriref            : to_uri('$1').
object    -> iriref            : to_uri('$1').
object    -> blank_node_label  : to_bnode('$1').
object    -> literal           : '$1'.

literal -> string_literal_quote '^^' iriref : to_literal('$1', {datatype, to_uri('$3')}).
literal -> string_literal_quote langtag     : to_literal('$1', {language, to_langtag('$2')}).
literal -> string_literal_quote             : to_literal('$1').


Erlang code.

to_uri(IRIREF) ->
  case 'Elixir.RDF.Serialization.ParseHelper':to_uri(IRIREF) of
    {ok, URI} -> URI;
    {error, ErrorLine, Message} -> return_error(ErrorLine, Message)
  end.
to_bnode(BLANK_NODE_LABEL) -> 'Elixir.RDF.Serialization.ParseHelper':to_bnode(BLANK_NODE_LABEL).
to_literal(STRING_LITERAL_QUOTE) -> 'Elixir.RDF.Serialization.ParseHelper':to_literal(STRING_LITERAL_QUOTE).
to_literal(STRING_LITERAL_QUOTE, Type) -> 'Elixir.RDF.Serialization.ParseHelper':to_literal(STRING_LITERAL_QUOTE, Type).
to_langtag(LANGTAG) -> 'Elixir.RDF.Serialization.ParseHelper':to_langtag(LANGTAG).
