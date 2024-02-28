#! /usr/bin/env ruby
# Parse test manifest to create driver and area-specific test manifests

require 'getoptlong'
require 'csv'
require 'json'
require 'haml'
require 'fileutils'
require 'htmlbeautifier'

class Manifest
  JSON_STATE = JSON::State.new(
    :indent       => "  ",
    :space        => " ",
    :space_before => "",
    :object_nl    => "\n",
    :array_nl     => "\n"
  )

  TITLE = "RDF Dataset Canonicalization (RDFC-1.0) Test Suite"
  DESCRIPTION = "Tests the 1.0 version of RDF Dataset Canonicalization and the generation of canonical maps."

  Test = Struct.new(:id, :name, :comment, :complexity, :approval, :hashAlgorithm, :action, :rdfc10, :rdfc10map) do
    def anchor(variant)
      %(#{self.id}#{variant == :rdfc10 ? "c" : "m"})
    end

    def type(variant)
      case variant
      when :rdfc10
        case self.rdfc10
        when 'FALSE' then nil
        when 'TRUE' then 'rdfc:RDFC10EvalTest'
        else "rdfc:#{self.rdfc10}"
        end
      when :rdfc10map
        case self.rdfc10map
        when 'FALSE' then nil
        when 'TRUE' then 'rdfc:RDFC10MapTest'
        else "rdfc:#{self.rdfc10}"
        end
      end
    end

    def result(variant)
      return nil if self.send(variant) == 'FALSE'
      case variant
      when :rdfc10    then "rdfc10/#{self.id}-rdfc10.nq" unless self.send(variant).to_s.match?(/negative/i)
      when :rdfc10map then "rdfc10/#{self.id}-rdfc10map.json"
      end
    end

    def computational_complexity
      case self.complexity.to_i
      when 0 then 'low'
      when 1..10 then 'medium'
      else 'high'
      end
    end
  end

  attr_accessor :tests

  def initialize
    csv = CSV.new(File.open(File.expand_path("../manifest.csv", __FILE__)))

    columns = []
    csv.shift.each_with_index {|c, i| columns[i] = c.to_sym if c}

    @tests = csv.map do |line|
      entry = {}
      # Create entry as object indexed by symbolized column name
      line.each_with_index {|v, i| entry[columns[i]] = v ? v.gsub("\r", "\n").gsub("\\", "\\\\") : nil}

      Test.new(entry[:test], entry[:name], entry[:comment], entry[:complexity], entry[:approval], entry[:hashAlgorithm],
               "rdfc10/#{entry[:test]}-in.nq",
               entry[:rdfc10],
               entry[:rdfc10map])
    end
  end

  # Create files referenced in the manifest
  def create_files
    tests.each do |test|
      files = [test.action, test.rdfc10, test.rdfc10map].compact
      files.compact.select {|f| !File.exist?(f)}.each do |f|
        File.open(f, "w") {|io| io.puts( f.end_with?('.json') ? "{}" : "")}
      end
    end
  end

  def to_jsonld
    context = ::JSON.parse %({
      "@base": "manifest",
      "xsd": "http://www.w3.org/2001/XMLSchema#",
      "rdfs": "http://www.w3.org/2000/01/rdf-schema#",
      "mf": "http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#",
      "mq": "http://www.w3.org/2001/sw/DataAccess/tests/test-query#",
      "rdfc": "https://w3c.github.io/rdf-canon/tests/vocab#",
      "rdft": "http://www.w3.org/ns/rdftest#",
      "id": "@id",
      "type": "@type",
      "action": {"@id": "mf:action",  "@type": "@id"},
      "approval": {"@id": "rdft:approval", "@type": "@id"},
      "comment": "rdfs:comment",
      "entries": {"@id": "mf:entries", "@type": "@id", "@container": "@list"},
      "hashAlgorithm": "rdfc:hashAlgorithm",
      "label": "rdfs:label",
      "name": "mf:name",
      "computationalComplexity": "rdfc:computationalComplexity",
      "result": {"@id": "mf:result", "@type": "@id"}
    })

    manifest = {
      "@context" => context,
      "id" => "manifest",
      "type" => "mf:Manifest",
      "label" => TITLE,
      "comment" => DESCRIPTION,
      "entries" => []
    }

    tests.each do |test|
      %i{rdfc10 rdfc10map}.each do |variant|
        next if test.send(variant) == 'FALSE'
        name = test.name +
        if variant == :rdfc10map
          ' (map test)'
        elsif test.type(variant).to_s.match?(/negative/i)
          ' (negative test)'
        else
          ''
        end

        entry = {
          "id" => "##{test.anchor(variant)}",
          "type" => test.type(variant),
          "name" => name,
          "comment" => test.comment,
          "computationalComplexity" => test.computational_complexity,
          "hashAlgorithm" => test.hashAlgorithm,
          "approval" => (test.approval ? "rdft:#{test.approval}" : "rdft:Proposed"),
          "action" => test.action,
          "result" => test.result(variant)
        }
        entry.delete('result') unless entry['result']
        entry.delete('hashAlgorithm') unless entry['hashAlgorithm']
        manifest["entries"] << entry
      end
    end

    manifest.to_json(JSON_STATE)
  end

  def to_html
    # Create vocab.html using vocab_template.haml and compacted vocabulary
    template = File.read(File.expand_path("../template.haml", __FILE__))
    json_man = File.expand_path("../manifest.jsonld", __FILE__)
    manifest = ::JSON.load(File.read(json_man))

    rendered = Haml::Template.new(format: :html5) {template}.render(self,
      man: manifest
    )
    HtmlBeautifier.beautify(rendered)
  end

  def to_ttl
    output = []
    output << %(## RDF Dataset Canonicalization tests
## Distributed under both the W3C Test Suite License[1] and the W3C 3-
## clause BSD License[2]. To contribute to a W3C Test Suite, see the
## policies and contribution forms [3]
##
## 1. http://www.w3.org/Consortium/Legal/2008/04-testsuite-license
## 2. http://www.w3.org/Consortium/Legal/2008/03-bsd-license
## 3. http://www.w3.org/2004/10/27-testcases
##
## This file is generated automatciallly from manifest.csv, and should not be edited directly.
##
## Test types
## * rdfc:RDFC10EvalTest – Canonicalization using RDFC-1.0
## * rdfc:RDFC10MapTest  – RDFC-1.0 Issued Identifiers Test

@prefix : <manifest#> .
@prefix rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix mf:   <http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#> .
@prefix rdfc: <https://w3c.github.io/rdf-canon/tests/vocab#> .
@prefix rdft: <http://www.w3.org/ns/rdftest#> .

<manifest>  a mf:Manifest ;
)
    output << %(  rdfs:label "#{TITLE}";)
    output << %(  rdfs:comment "#{DESCRIPTION}";)
    output << %(  mf:entries \()

    # Entries for each test and variant
    tests.map do |test|
      %I(rdfc10 rdfc10map).map do |variant|
        ":#{test.anchor(variant)}" unless test.send(variant) == 'FALSE'
      end
    end.flatten.compact.each_slice(8) do |entries|
      output << %(    #{entries.join(' ')})
    end
    output << %(  \) .)

    tests.each do |test|
      %I(rdfc10 rdfc10map).
        select {|v| test.send(v) != 'FALSE'}.
        map do |variant|
        
        name = test.name + 
        if variant == :rdfc10map
          ' (map test)'
        elsif test.type(variant).to_s.match?(/negative/i)
          ' (negative test)'
        else
          ''
        end

        output << "" # separator
        output << ":#{test.anchor(variant)} a #{test.type(variant)};"
        output << %(  mf:name "#{name}";)
        output << %(  rdfs:comment "#{test.comment}";) if test.comment
        output << %(  rdfc:hashAlgorithm "#{test.hashAlgorithm}";) if test.hashAlgorithm
        output << %(  rdfc:computationalComplexity "#{test.computational_complexity}";)
        output << %(  rdft:approval #{(test.approval ? "rdft:#{test.approval}" : "rdft:Proposed")};)
        output << %(  mf:action <#{test.action}>;)
        output << %(  mf:result <#{test.result(variant)}>;) if test.result(variant)
        output << %(  .)
      end
    end
    output.join("\n")
  end
end

options = {
  output: $stdout
}

OPT_ARGS = [
  ["--format", "-f",  GetoptLong::REQUIRED_ARGUMENT,"Output format, default #{options[:format].inspect}"],
  ["--output", "-o",  GetoptLong::REQUIRED_ARGUMENT,"Output to the specified file path"],
  ["--quiet",         GetoptLong::NO_ARGUMENT,      "Supress most output other than progress indicators"],
  ["--touch",         GetoptLong::NO_ARGUMENT,      "Create referenced files and directories if missing"],
  ["--help", "-?",    GetoptLong::NO_ARGUMENT,      "This message"]
]
def usage
  STDERR.puts %{Usage: #{$0} [options] URL ...}
  width = OPT_ARGS.map do |o|
    l = o.first.length
    l += o[1].length + 2 if o[1].is_a?(String)
    l
  end.max
  OPT_ARGS.each do |o|
    s = "  %-*s  " % [width, (o[1].is_a?(String) ? "#{o[0,2].join(', ')}" : o[0])]
    s += o.last
    STDERR.puts s
  end
  exit(1)
end

opts = GetoptLong.new(*OPT_ARGS.map {|o| o[0..-2]})

opts.each do |opt, arg|
  case opt
  when '--format'       then options[:format] = arg.to_sym
  when '--output'       then options[:output] = File.open(arg, "w")
  when '--quiet'        then options[:quiet] = true
  when '--touch'        then options[:touch] = true
  when '--help'         then usage
  end
end

man = Manifest.new
man.create_files if options[:touch]
if options[:format] || options[:variant]
  case options[:format]
  when :jsonld  then options[:output].puts(man.to_jsonld)
  when :ttl     then options[:output].puts(man.to_ttl)
  when :html    then options[:output].puts(man.to_html)
  else  STDERR.puts "Unknown format #{options[:format].inspect}"
  end
else
  %I(jsonld ttl).each do |format|
    path = File.expand_path("../manifest.#{format}", __FILE__)
    File.open(path, "w") do |output|
      output.puts(man.send("to_#{format}".to_sym))
    end
  end
  
  index  = File.expand_path("../index.html", __FILE__)
  File.open(index, "w") do |output|
    output.puts(man.to_html)
  end
end
