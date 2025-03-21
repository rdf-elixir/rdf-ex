locals_without_parens = [
  defvocab: 2,
  defnamespace: 2,
  defnamespace: 3,
  act_as_namespace: 1,
  def_facet_constraint: 2,
  def_applicable_facet: 1,
  bgp: 1,
  build: 2,
  exclude: 1,
  assert_rdf_isomorphic: 2
]

[
  inputs: ["{mix,.formatter}.exs", "{bench,config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: [{:assert_order_independent, 1} | locals_without_parens],
  export: [
    locals_without_parens: locals_without_parens
  ]
]
