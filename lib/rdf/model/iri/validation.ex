defmodule RDF.IRI.Validation do
  @moduledoc false

  @ucschar "\\x{00A0}-\\x{D7FF}\\x{F900}-\\x{FDCF}\\x{FDF0}-\\x{FFEF}" <>
             "\\x{10000}-\\x{1FFFD}\\x{20000}-\\x{2FFFD}\\x{30000}-\\x{3FFFD}" <>
             "\\x{40000}-\\x{4FFFD}\\x{50000}-\\x{5FFFD}\\x{60000}-\\x{6FFFD}" <>
             "\\x{70000}-\\x{7FFFD}\\x{80000}-\\x{8FFFD}\\x{90000}-\\x{9FFFD}" <>
             "\\x{A0000}-\\x{AFFFD}\\x{B0000}-\\x{BFFFD}\\x{C0000}-\\x{CFFFD}" <>
             "\\x{D0000}-\\x{DFFFD}\\x{E1000}-\\x{EFFFD}"

  @iprivate "[\\x{E000}-\\x{F8FF}\\x{F0000}-\\x{FFFFD}\\x{100000}-\\x{10FFFD}]"
  @scheme "[A-Za-z](?:[A-Za-z0-9+\\-\\.])*"
  @port "[0-9]*"
  # Simplified, no IPvFuture
  @ip_literal "\\[[0-9A-Fa-f:\\.]*\\]"
  @pct_encoded "%[0-9A-Fa-f][0-9A-Fa-f]"
  @sub_delims "[!\\$&'\\(\\)\\*\\+,;=]"
  @unreserved "[A-Za-z0-9\\._~\\-]"
  @iunreserved "(#{@unreserved}|[#{@ucschar}])"

  @ipchar "(#{@iunreserved}|#{@pct_encoded}|#{@sub_delims}|[:@])"
  @iquery "(?:#{@ipchar}|#{@iprivate}|/|\\?)*"
  @ifragment "(?:#{@ipchar}|/|\\?)*"
  @isegment "(?:#{@ipchar})*"
  @isegment_nz "(?:#{@ipchar})+"

  @ipath_abempty "(?:/#{@isegment})*"
  @ipath_absolute "/(?:#{@isegment_nz}(?:/#{@isegment})*)?"
  @ipath_rootless "(?:#{@isegment_nz})(?:/#{@isegment})*"
  @ipath_empty ""

  @ireg_name "(?:(?:#{@iunreserved})|(?:#{@pct_encoded})|(?:#{@sub_delims}))*"
  @ihost "(#{@ip_literal}|#{@ireg_name})"
  @iuserinfo "(?:(?:#{@iunreserved})|(?:#{@pct_encoded})|(?:#{@sub_delims})|:)*"
  @iauthority "(?:#{@iuserinfo}@)?#{@ihost}(?::#{@port})?"

  @ihier_part "(?://#{@iauthority}(?:#{@ipath_abempty}))|(?:#{@ipath_absolute})|(?:#{@ipath_rootless})|(?:#{@ipath_empty})"
  @iri_regex ~r/^#{@scheme}:(?:#{@ihier_part})(?:\?#{@iquery})?(?:##{@ifragment})?$/u

  @spec valid?(String.t()) :: boolean
  def valid?(iri) do
    RDF.Utils.Regex.match?(@iri_regex, iri)
  end
end
