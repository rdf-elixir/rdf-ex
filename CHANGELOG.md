# Change Log

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/) and
[Keep a CHANGELOG](http://keepachangelog.com).


## Unreleased

### Added

- Turtle decoder
- `RDF.Data.descriptions/1` returns all descriptions within a RDF data structure 
- `RDF.Description.first/2` returns a single object a predicate of a `RDF.Description` 

### Changed

- Don't support Elixir versions < 1.4 

### Fixed

- booleans weren't recognized as convertible literals on object positions
- N-Triples and N-Quads decoder didn't handle escaping properly



## 0.1.1 - 2017-06-25

### Fixed

- Add `src` directory to package files.

[Compare v0.1.0...v0.1.1](https://github.com/marcelotto/rdf-ex/compare/v0.1.0...v0.1.1)



## 0.1.0 - 2017-06-25

Initial release

Note: This version is not usable, since the `src` directory is not part of the 
package, which has been immediately fixed on version 0.1.1.
