locals_without_parens = [
  defvocab: 2,
  defnamespace: 2,
  defnamespace: 3,
  def_facet_constraint: 2,
  def_applicable_facet: 1,
  bgp: 1,
  build: 2,
  exclude: 1
]

[
  inputs: ["{mix,.formatter}.exs", "{bench,config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: locals_without_parens,
  export: [
    locals_without_parens: locals_without_parens
  ]
]
