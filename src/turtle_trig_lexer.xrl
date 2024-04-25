%% \00=NULL
%% \01-\x1F=control codes
%% \x20=space

Definitions.

COMMENT = #[^\n\r]*

WS	  =	[\s\t\n\r]
ANON	=	\[{WS}*\]

HEX           = ([0-9]|[A-F]|[a-f])
UCHAR         = (\\u({HEX})({HEX})({HEX})({HEX}))|(\\U({HEX})({HEX})({HEX})({HEX})({HEX})({HEX})({HEX})({HEX}))
ECHAR         = \\[tbnrf"'\\]
PERCENT	      =	(%{HEX}{HEX})
PN_CHARS_BASE = ([A-Z]|[a-z]|[\xC0-\xD6]|[\xD8-\xF6]|[\xF8-\x{02FF}]|[\x{0370}-\x{037D}]|[\x{037F}-\x{1FFF}]|[\x{200C}-\x{200D}]|[\x{2070}-\x{218F}]|[\x{2C00}-\x{2FEF}]|[\x{3001}-\x{D7FF}]|[\x{F900}-\x{FDCF}]|[\x{FDF0}-\x{FFFD}]|[\x{10000}-\x{EFFFF}])
PN_CHARS_U    = ({PN_CHARS_BASE}|_)
PN_CHARS      = ({PN_CHARS_U}|-|[0-9]|\xB7|[\x{0300}-\x{036F}]|[\x{203F}-\x{2040}])
PN_PREFIX	    =	({PN_CHARS_BASE}(({PN_CHARS}|\.)*{PN_CHARS})?)
PN_LOCAL_ESC  =	\\(_|~|\.|\-|\!|\$|\&|\'|\(|\)|\*|\+|\,|\;|\=|\/|\?|\#|\@|\%)
PLX           =	({PERCENT}|{PN_LOCAL_ESC})
PN_LOCAL	    =	({PN_CHARS_U}|:|[0-9]|{PLX})(({PN_CHARS}|\.|:|{PLX})*({PN_CHARS}|:|{PLX}))?
PNAME_NS	    =	{PN_PREFIX}?:
PNAME_LN	    =	{PNAME_NS}{PN_LOCAL}

EXPONENT	=	([eE][+-]?[0-9]+)
BOOLEAN   = true|false
INTEGER	  =	[+-]?[0-9]+
DECIMAL	  =	[+-]?[0-9]*\.[0-9]+
DOUBLE	  =	[+-]?([0-9]+\.[0-9]*{EXPONENT}|\.[0-9]+{EXPONENT}|[0-9]+{EXPONENT})

IRIREF = <([^\x00-\x20<>"{}|^`\\]|{UCHAR})*>
STRING_LITERAL_QUOTE              = "([^"\\\n\r]|{ECHAR}|{UCHAR})*"
STRING_LITERAL_SINGLE_QUOTE	      =	'([^'\\\n\r]|{ECHAR}|{UCHAR})*'
STRING_LITERAL_LONG_SINGLE_QUOTE	=	'''(('|'')?([^'\\]|{ECHAR}|{UCHAR}))*'''
STRING_LITERAL_LONG_QUOTE	        =	"""(("|"")?([^"\\]|{ECHAR}|{UCHAR}))*"""
BLANK_NODE_LABEL = _:({PN_CHARS_U}|[0-9])(({PN_CHARS}|\.)*({PN_CHARS}))?
LANGTAG	=	@[a-zA-Z]+(-[a-zA-Z0-9]+)*

BASE    = [Bb][Aa][Ss][Ee]
PREFIX  = [Pp][Rr][Ee][Ff][Ii][Xx]

GRAPH    = [Gg][Rr][Aa][Pp][Hh]

Rules.

@prefix                            : {token, {'@prefix', TokenLine}}.
@base                              : {token, {'@base', TokenLine}}.
{BASE}                             : {token, {'BASE', TokenLine}}.
{PREFIX}                           : {token, {'PREFIX', TokenLine}}.
{GRAPH}                            : {token, {'GRAPH', TokenLine}}.
{LANGTAG}                          : {token, {langtag, TokenLine, langtag_str(TokenChars)}}.
{IRIREF}                           : {token, {iriref,  TokenLine, quoted_content_str(TokenChars)}}.
{DOUBLE}                           : {token, {double, TokenLine, double(TokenChars)}}.
{DECIMAL}                          : {token, {decimal, TokenLine, decimal(TokenChars)}}.
{INTEGER}	                         : {token, {integer,  TokenLine, integer(TokenChars)}}.
{BOOLEAN}                          : {token, {boolean, TokenLine, boolean(TokenChars)}}.
{STRING_LITERAL_SINGLE_QUOTE}      : {token, {string_literal_quote, TokenLine, quoted_content_str(TokenChars)}}.
{STRING_LITERAL_QUOTE}             : {token, {string_literal_quote, TokenLine, quoted_content_str(TokenChars)}}.
{STRING_LITERAL_LONG_SINGLE_QUOTE} : {token, {string_literal_quote, TokenLine, long_quoted_content_str(TokenChars)}}.
{STRING_LITERAL_LONG_QUOTE}        : {token, {string_literal_quote, TokenLine, long_quoted_content_str(TokenChars)}}.
{BLANK_NODE_LABEL}                 : {token, {blank_node_label, TokenLine, bnode_str(TokenChars)}}.
{ANON}	                           : {token, {anon, TokenLine}}.
a                                  : {token, {'a', TokenLine}}.
{PNAME_NS}                         : {token, {prefix_ns, TokenLine, prefix_ns(TokenChars)}}.
{PNAME_LN}                         : {token, {prefix_ln, TokenLine, prefix_ln(TokenChars)}}.
; 	                               : {token, {';', TokenLine}}.
, 	                               : {token, {',', TokenLine}}.
\.	                               : {token, {'.', TokenLine}}.
\[	                               : {token, {'[', TokenLine}}.
\]	                               : {token, {']', TokenLine}}.
\(	                               : {token, {'(', TokenLine}}.
\)	                               : {token, {')', TokenLine}}.
\{            	                   : {token, {'{', TokenLine}}.
\}            	                   : {token, {'}', TokenLine}}.
\^\^	                             : {token, {'^^', TokenLine}}.
\<\<           	                   : {token, {'<<', TokenLine}}.
\>\>           	                   : {token, {'>>', TokenLine}}.
\{\|           	                   : {token, {'{|', TokenLine}}.
\|\}           	                   : {token, {'|}', TokenLine}}.

{WS}+                              : skip_token.
{COMMENT}                          : skip_token.


Erlang code.

integer(TokenChars)  -> 'Elixir.RDF.Serialization.ParseHelper':integer(TokenChars).
decimal(TokenChars)  -> 'Elixir.RDF.Serialization.ParseHelper':decimal(TokenChars).
double(TokenChars)   -> 'Elixir.RDF.Serialization.ParseHelper':double(TokenChars).
boolean(TokenChars)  -> 'Elixir.RDF.Serialization.ParseHelper':boolean(TokenChars).
quoted_content_str(TokenChars) -> 'Elixir.RDF.Serialization.ParseHelper':quoted_content_str(TokenChars).
long_quoted_content_str(TokenChars) -> 'Elixir.RDF.Serialization.ParseHelper':long_quoted_content_str(TokenChars).
bnode_str(TokenChars) -> 'Elixir.RDF.Serialization.ParseHelper':bnode_str(TokenChars).
langtag_str(TokenChars) -> 'Elixir.RDF.Serialization.ParseHelper':langtag_str(TokenChars).
prefix_ns(TokenChars) -> 'Elixir.RDF.Serialization.ParseHelper':prefix_ns(TokenChars).
prefix_ln(TokenChars) -> 'Elixir.RDF.Serialization.ParseHelper':prefix_ln(TokenChars).

