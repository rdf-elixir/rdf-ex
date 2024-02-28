#!/usr/bin/env ruby
# Generate vocab.jsonld and vocab.html from vocab.ttl and vocab_template.
#
# Generating vocab.jsonld is equivalent to running the following:
#
#    rdf serialize -o vocab.jsonld --output-format jsonld --context vocab_context.jsonld vocab.ttl
require 'linkeddata'
require 'haml'
require 'active_support'
require 'htmlbeautifier'

File.open("vocab.jsonld", "w") do |f|
  r = RDF::Repository.load("vocab.ttl")
  JSON::LD::API.fromRDF(r, useNativeTypes: true) do |expanded|
    # Remove leading/trailing and multiple whitespace from rdf:comments
    expanded.each do |o|
      c = o[RDF::RDFS.comment.to_s].first['@value']
      o[RDF::RDFS.comment.to_s].first['@value'] = c.strip.gsub(/\s+/m, ' ')
    end
    JSON::LD::API.compact(expanded, File.open("vocab_context.jsonld")) do |compacted|
      # Create vocab.jsonld
      f.write(compacted.to_json(JSON::LD::JSON_STATE))

      # Create vocab.html using vocab_template.haml and compacted vocabulary
      template = File.read("vocab_template.haml")
      
      html = Haml::Template.new(format: :html5) {template}.render(self,
        ontology:   compacted['@graph'].detect {|o| o['@id'] == "https://w3c.github.io/rdf-canon/tests/vocab#"},
        classes:    compacted['@graph'].select {|o| %w(rdfs:Class rdfc:Test).include?(o['@type'])}.sort_by {|o| o['rdfs:label']},
        properties: compacted['@graph'].select {|o| o['@type'] == "rdf:Property"}.sort_by {|o| o['rdfs:label']}
      )
      File.open("vocab.html", "w") {|fh| fh.write HtmlBeautifier.beautify(html)}
    end
  end
end
