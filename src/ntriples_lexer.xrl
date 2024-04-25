Definitions.

WHITESPACE = [\s\t]
COMMENT = #[^\n\r]*
EOL = [\n\r]+
HEX	=	[0-9]|[A-F]|[a-f]
UCHAR = (\\u({HEX})({HEX})({HEX})({HEX}))|(\\U({HEX})({HEX})({HEX})({HEX})({HEX})({HEX})({HEX})({HEX}))
ECHAR = \\[tbnrf"'\\]
PN_CHARS_BASE = ([A-Z]|[a-z]|[\x{00C0}-\x{00D6}]|[\x{00D8}-\x{00F6}]|[\x{00F8}-\x{02FF}]|[\x{0370}-\x{037D}]|[\x{037F}-\x{1FFF}]|[\x{200C}-\x{200D}]|[\x{2070}-\x{218F}]|[\x{2C00}-\x{2FEF}]|[\x{3001}-\x{D7FF}]|[\x{F900}-\x{FDCF}]|[\x{FDF0}-\x{FFFD}]|[\x{10000}-\x{EFFFF}])
PN_CHARS_U = ({PN_CHARS_BASE}|_)
PN_CHARS = ({PN_CHARS_U}|-|[0-9]|\xB7|[\x{0300}-\x{036F}]|[\x{203F}-\x{2040}])
IRIREF = <([^\x00-\x20<>"{}|^`\\]|{UCHAR})*>
STRING_LITERAL_QUOTE = "([^\x22\x5C\x0A\x0D]|{ECHAR}|{UCHAR})*"
BLANK_NODE_LABEL = _:({PN_CHARS_U}|[0-9])(({PN_CHARS}|\.)*({PN_CHARS}))?
LANGTAG	=	@[a-zA-Z]+(-[a-zA-Z0-9]+)*


Rules.

{LANGTAG}               : {token, {langtag, TokenLine, langtag_str(TokenChars)}}.
{IRIREF}                : {token, {iriref, TokenLine, quoted_content_str(TokenChars)}}.
{STRING_LITERAL_QUOTE}  : {token, {string_literal_quote, TokenLine, quoted_content_str(TokenChars)}}.
{BLANK_NODE_LABEL}      : {token, {blank_node_label, TokenLine, bnode_str(TokenChars)}}.
{EOL}	                  :	{token, {eol, TokenLine}}.
\.	                    :	{token, {'.', TokenLine}}.
\^\^	                  :	{token, {'^^', TokenLine}}.
\<\<	                  :	{token, {'<<', TokenLine}}.
\>\>	                  :	{token, {'>>', TokenLine}}.
{WHITESPACE}+           : skip_token.
{COMMENT}               : skip_token.


Erlang code.

quoted_content_str(TokenChars) -> 'Elixir.RDF.Serialization.ParseHelper':quoted_content_str(TokenChars).
bnode_str(TokenChars) -> 'Elixir.RDF.Serialization.ParseHelper':bnode_str(TokenChars).
langtag_str(TokenChars) -> 'Elixir.RDF.Serialization.ParseHelper':langtag_str(TokenChars).
