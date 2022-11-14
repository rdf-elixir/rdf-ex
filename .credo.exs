%{
  configs: [
    %{
      name: "default",
      checks: [
        {Credo.Check.Design.TagTODO, false},
        {Credo.Check.Refactor.Nesting, false},
        {Credo.Check.Refactor.MatchInCondition, false},
        {Credo.Check.Refactor.CyclomaticComplexity, false},
      ],
    }
  ]
}
