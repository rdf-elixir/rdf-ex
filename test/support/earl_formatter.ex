defmodule EarlFormatter do
  @moduledoc """
  An `ExUnit.Formatter` implementation that generates EARL reports.

  see <https://www.w3.org/TR/EARL10-Schema/>
  """
  use GenServer

  defmodule NS do
    @moduledoc false

    use RDF.Vocabulary.Namespace

    defvocab EARL, base_iri: "http://www.w3.org/ns/earl#", terms: [], strict: false
    defvocab DC, base_iri: "http://purl.org/dc/terms/", terms: [], strict: false
    defvocab FOAF, base_iri: "http://xmlns.com/foaf/0.1/", terms: [], strict: false
    defvocab DOAP, base_iri: "http://usefulinc.com/ns/doap#", terms: [], strict: false
  end

  @compile {:no_warn_undefined, EarlFormatter.NS.EARL}
  @compile {:no_warn_undefined, EarlFormatter.NS.DC}
  @compile {:no_warn_undefined, EarlFormatter.NS.FOAF}
  @compile {:no_warn_undefined, EarlFormatter.NS.DOAP}

  alias EarlFormatter.NS.{EARL, DC, FOAF, DOAP}
  alias RDF.{Graph, Turtle}

  import RDF.Sigils

  @output_path "earl_reports"
  @doap_file "doap.ttl"

  @marcel ~I<http://marcelotto.net/#me>
  @rdf_ex ~I<https://hex.pm/packages/rdf>

  @prefixes RDF.prefix_map(
              xsd: RDF.NS.XSD,
              rdf: RDF,
              rdfs: RDF.NS.RDFS,
              mf: RDF.TestSuite.NS.MF,
              earl: EARL,
              dc: DC,
              foaf: FOAF,
              doap: DOAP
            )

  @impl true
  def init(_opts) do
    {:ok, {%{}, %{time: RDF.XSD.DateTime.now()}}}
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

  def handle_cast({:test_finished, %ExUnit.Test{state: {:excluded, _}} = test}, {results, config}) do
    print_warn("EXCLUDED: #{test.name}")

    {:noreply,
     {add_result(results, test, assertion(test.tags.test_case, :untested, config)), config}}
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
    project_metadata = project_metadata()

    IO.puts("---------------------------------")

    Enum.each(results, fn {test_suite, results} ->
      IO.puts("Writing report for #{test_suite}")
      path = Path.join(@output_path, "#{test_suite}.ttl")

      results
      |> Graph.add(project_metadata)
      |> Turtle.write_file!(path, force: true, base_description: document_description(config))
    end)
  end

  defp project_metadata do
    version = Mix.Project.config()[:version]
    version_url = RDF.iri("https://hex.pm/packages/rdf/#{version}")

    version_description =
      version_url
      |> DOAP.name("RDF.ex #{version}")
      |> DOAP.revision(version)

    doap = Turtle.read_file!(@doap_file)

    # ensure the URIs we use here are consistent we the ones in the DOAP file
    %RDF.Description{} = doap[@rdf_ex]
    %RDF.Description{} = doap[@marcel]

    doap
    |> Graph.add(
      @rdf_ex
      |> RDF.type([EARL.TestSubject, EARL.Software])
      |> DOAP.release(version_url)
    )
    |> Graph.add(@marcel |> RDF.type(EARL.Assertor))
    |> Graph.add(version_description)
  end

  defp document_description(config) do
    %{
      FOAF.primaryTopic() => @rdf_ex,
      FOAF.maker() => @marcel,
      DC.issued() => config.time
    }
  end

  defp base_assertion(test_case) do
    RDF.bnode()
    |> RDF.type(EARL.Assertion)
    |> EARL.assertedBy(@marcel)
    |> EARL.subject(@rdf_ex)
    |> EARL.test(test_case.subject)
  end

  defp assertion(test_case, outcome, mode \\ nil, config)

  defp assertion(test_case, outcome, nil, config),
    do: assertion(test_case, outcome, :automatic, config)

  defp assertion(test_case, outcome, mode, config) do
    result = result(outcome, config)

    assertion =
      test_case
      |> base_assertion()
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
      def earl_test_suite(), do: unquote(earl_test_suite)
    end
  end

  defp test_suite(test), do: test.module.earl_test_suite()

  defp print_success(msg), do: IO.puts(IO.ANSI.format([:green, msg]))
  defp print_failed(msg), do: IO.puts(IO.ANSI.format([:red, msg]))
  defp print_warn(msg), do: IO.puts(IO.ANSI.format([:yellow, msg]))
end
