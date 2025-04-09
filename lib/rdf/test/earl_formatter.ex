defmodule RDF.Test.EarlFormatter do
  @moduledoc """
  An `ExUnit.Formatter` implementation that generates EARL reports.

  see <https://www.w3.org/TR/EARL10-Schema/>
  """
  use GenServer

  defmodule NS do
    @moduledoc false

    use RDF.Vocabulary.Namespace

    @vocabdoc false
    defvocab EARL, base_iri: "http://www.w3.org/ns/earl#", terms: [], strict: false
    @vocabdoc false
    defvocab DC, base_iri: "http://purl.org/dc/terms/", terms: [], strict: false
    @vocabdoc false
    defvocab FOAF, base_iri: "http://xmlns.com/foaf/0.1/", terms: [], strict: false
    @vocabdoc false
    defvocab DOAP, base_iri: "http://usefulinc.com/ns/doap#", terms: [], strict: false
  end

  @compile {:no_warn_undefined, RDF.Test.EarlFormatter.NS.EARL}
  @compile {:no_warn_undefined, RDF.Test.EarlFormatter.NS.DC}
  @compile {:no_warn_undefined, RDF.Test.EarlFormatter.NS.FOAF}
  @compile {:no_warn_undefined, RDF.Test.EarlFormatter.NS.DOAP}

  alias RDF.Test.EarlFormatter.NS.{EARL, DC, FOAF, DOAP}
  alias RDF.{Graph, Turtle}

  @prefixes RDF.prefix_map(
              xsd: RDF.NS.XSD,
              rdf: RDF,
              rdfs: RDF.NS.RDFS,
              earl: EARL,
              dc: DC,
              foaf: FOAF,
              doap: DOAP
            )

  def config do
    mix_config = Mix.Project.config()
    app = mix_config[:app]
    version = mix_config[:version]
    hex_url = "https://hex.pm/packages/#{app}"
    version_url = hex_url <> "/" <> version

    config =
      %{
        doap_path: "doap.ttl",
        project_iri: RDF.iri(hex_url),
        version_iri: RDF.iri(version_url),
        version: version,
        name: mix_config[:name],
        output_path: "earl_reports"
      }
      |> Map.merge(Map.new(Application.get_env(app, :earl_formatter, %{})))

    unless config[:author_iri], do: print_failed("author_iri missing in EarlFormatter config")

    Map.update!(config, :author_iri, &RDF.iri/1)
  end

  @impl true
  def init(_opts) do
    results = %{}
    config = Map.put(config(), :time, RDF.XSD.DateTime.now())

    {:ok, {results, config}}
  end

  @impl true
  def handle_cast({:suite_finished, %{async: _, load: _, run: _}}, {results, config} = state) do
    finish(results, config)
    {:noreply, state}
  end

  def handle_cast({:suite_finished, _run_us, _load_us}, {results, config} = state) do
    finish(results, config)
    {:noreply, state}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: nil} = test}, {results, config}) do
    print_success("PASSED: #{test.name}")

    {:noreply,
     {add_result(results, test, assertion(test.tags.test_case, :passed, config)), config}}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: {:skipped, _}} = test}, {results, config}) do
    result = test.tags[:earl_result] || :failed
    mode = test.tags[:earl_mode]
    print_warn("SKIPPED (#{mode} #{result}): #{test.name}")

    {:noreply,
     {add_result(results, test, assertion(test.tags.test_case, result, mode, config)), config}}
  end

  def handle_cast(
        {:test_finished, %ExUnit.Test{state: {:failed, _failed}} = test},
        {results, config}
      ) do
    print_failed("FAILED: #{test.name}")

    {:noreply,
     {add_result(results, test, assertion(test.tags.test_case, :failed, config)), config}}
  end

  def handle_cast(
        {:test_finished, %ExUnit.Test{state: {:invalid, _module}} = test},
        {results, config}
      ) do
    print_failed("INVALID: #{test.name}")

    {:noreply,
     {add_result(results, test, assertion(test.tags.test_case, :failed, config)), config}}
  end

  def handle_cast(_event, state), do: {:noreply, state}

  defp add_result(results, test, assertion) do
    Map.update(
      results,
      test_suite(test),
      RDF.graph(assertion, prefixes: @prefixes),
      &Graph.add(&1, assertion)
    )
  end

  defp finish(results, config) do
    project_metadata = project_metadata(config)

    IO.puts("---------------------------------")

    Enum.each(results, fn {test_suite, results} ->
      IO.puts("Writing report for #{test_suite}")
      path = Path.join(config.output_path, "#{test_suite}.ttl")

      results
      |> Graph.add(project_metadata)
      |> Turtle.write_file!(path, force: true, base_description: document_description(config))
    end)
  end

  defp project_metadata(config) do
    project_iri = config.project_iri
    version = config.version
    version_iri = config.version_iri
    author_iri = config.author_iri

    version_description =
      version_iri
      |> DOAP.name("#{config.name} #{version}")
      |> DOAP.revision(version)

    doap = Turtle.read_file!(config.doap_path)

    # ensure the URIs we use here are consistent we the ones in the DOAP file
    %RDF.Description{} = doap[project_iri]
    %RDF.Description{} = doap[author_iri]

    doap
    |> Graph.add(
      project_iri
      |> RDF.type([EARL.TestSubject, EARL.Software])
      |> DOAP.release(version_iri)
    )
    |> Graph.add(author_iri |> RDF.type(EARL.Assertor))
    |> Graph.add(version_description)
  end

  defp document_description(config) do
    %{
      FOAF.primaryTopic() => config.project_iri,
      FOAF.maker() => config.author_iri,
      DC.issued() => config.time
    }
  end

  defp base_assertion(test_id, config) do
    RDF.bnode()
    |> RDF.type(EARL.Assertion)
    |> EARL.assertedBy(config.author_iri)
    |> EARL.subject(config.project_iri)
    |> EARL.test(test_id)
  end

  defp assertion(test_id, outcome, mode \\ nil, config)

  defp assertion(test_id, outcome, nil, config),
    do: assertion(test_id, outcome, :automatic, config)

  defp assertion(%RDF.Description{subject: id}, outcome, mode, config),
    do: assertion(id, outcome, mode, config)

  defp assertion(test_id, outcome, mode, config) do
    result = result(outcome, config)

    assertion =
      test_id
      |> base_assertion(config)
      |> EARL.result(result.subject)
      |> EARL.mode(mode(mode))

    [assertion, result]
  end

  defp base_result(config) do
    RDF.bnode()
    |> RDF.type(EARL.TestResult)
    |> DC.date(config.time)
  end

  defp result(outcome, config) do
    base_result(config)
    |> EARL.outcome(outcome(outcome))
  end

  # earl:passed := the subject passed the test.
  defp outcome(:passed), do: EARL.passed()
  # earl:failed := the subject failed the test.
  defp outcome(:failed), do: EARL.failed()
  # earl:cantTell := it is unclear if the subject passed or failed the test.
  defp outcome(:cant_tell), do: EARL.cantTell()
  # earl:inapplicable := the test is not applicable to the subject.
  defp outcome(:inapplicable), do: EARL.inapplicable()
  # earl:untested := the test has not been carried out.
  defp outcome(:untested), do: EARL.untested()

  # earl:automatic := where the test was carried out automatically by the software tool and without any human intervention.
  defp mode(:automatic), do: EARL.automatic()

  # earl:manual := where the test was carried out by human evaluators. This includes the case where the evaluators are aided by instructions or guidance provided by software tools, but where the evaluators carried out the actual test procedure.
  defp mode(:manual), do: EARL.manual()

  # earl:semiAuto := where the test was partially carried out by software tools, but where human input or judgment was still required to decide or help decide the outcome of the test.
  defp mode(:semi_auto), do: EARL.semiAuto()

  # earl:undisclosed := where the exact testing process is undisclosed.
  defp mode(:undisclosed), do: EARL.undisclosed()

  # earl:unknownMode := where the testing process is unknown or undetermined.
  defp mode(:unknown_mode), do: EARL.unknownMode()

  defmacro __using__(opts) do
    earl_test_suite = Keyword.fetch!(opts, :test_suite)

    quote do
      def earl_test_suite, do: unquote(earl_test_suite)
    end
  end

  defp test_suite(test), do: test.module.earl_test_suite()

  defp print_success(msg), do: IO.puts(IO.ANSI.format([:green, msg]))
  defp print_failed(msg), do: IO.puts(IO.ANSI.format([:red, msg]))
  defp print_warn(msg), do: IO.puts(IO.ANSI.format([:yellow, msg]))
end
