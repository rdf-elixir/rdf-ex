locals_without_parens = [
  defvocab: 2,
  bgp: 1
]

[
  inputs: ["{mix,.formatter}.exs", "{bench,config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: locals_without_parens,
  export: [
    locals_without_parens: locals_without_parens
  ]
]
