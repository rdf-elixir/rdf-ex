## General instructions for running the RDF Dataset Canonicalization Test suites

### Tests for RDFC-1.0 take input files, specified as N-Quads, and generate Canonical N-Quads output as required by the RDFC-1.0 algorithm.

The result file is in the N-Quads format.
The test passes if the result compares identically as the expected result as text files.

For a negative evaluation test, the test passes if the implementation generates an error due to excessive calls to
[Hash N-Degree Quads](https://www.w3.org/TR/rdf-canon/#hash-nd-quads-algorithm).

### Tests for RDFC-1.0 Issued Identifiers Map.

The result file is in the JSON format with keys representing
the blank node identifiers from the test input,
and values representing the associated canonical identifier
from the [issued identifiers map](https://www.w3.org/TR/rdf-canon/#dfn-issued-identifiers-map)
created as an alternate result
from [Step 7](https://www.w3.org/TR/rdf-canon/#ca.7) of the
[RDFC1.0 Canonicalization Algorithm](https://www.w3.org/TR/rdf-canon/#canon-algo-algo).
The test passes if the value of the resulting
[issued identifiers map](https://www.w3.org/TR/rdf-canon/#dfn-issued-identifiers-map)
matches the corresponding expected test result that can be loaded via the `result` field of the test.

Additionally, the keys of the [issued identifiers map](https://www.w3.org/TR/rdf-canon/#dfn-issued-identifiers-map)
must exactly match the values of the [input blank node identifier map](https://www.w3.org/TR/rdf-canon/#dfn-input-blank-node-identifier-map).
Note that all blank nodes appearing in the test appear in input blank node identifier map represent blank nodes and the specific value is not considered for test purposes

## Contributing Tests
The test manifests and entries are built automatically from
[manifest.csv](manifest.csv) using [mk_manifest.rb](mk_manifest.rb),
where each row defines a combination of Validation tests for the same
_action_ and implicit files.
Tests may be contributed via pull request to
[https://github.com/w3c/rdf-canon](https://github.com/w3c/rdf-canon)
with suitable changes to the
[manifest.csv](manifest.csv) and necessary _action_ and _result_ files. 

The [manifest-rdfc10.ttl](manifest-rdfc10.ttl), [manifest-rdfc10.jsonld](manifest-rdfc10.jsonld), and [index.html](index.html) files are built automatically via a GitHub Action when files change in this directory, and should not be edited directly.

The [vocab.html](vocab.html) and [vocab.jsonld](vocab.jsonld) files are built using [mk_vocab.rb](mk_vocab.rb) and are not build automatically by GitHub PR, as they change infrequently.

## Distribution
Distributed under both the
[W3C Test Suite License](http://www.w3.org/Consortium/Legal/2008/04-testsuite-license)
and the
[W3C 3-clause BSD License](http://www.w3.org/Consortium/Legal/2008/03-bsd-license).
To contribute to a W3C Test Suite, see the
[policies and contribution forms](http://www.w3.org/2004/10/27-testcases).

## Disclaimer
UNDER BOTH MUTUALLY EXCLUSIVE LICENSES, THIS DOCUMENT AND ALL DOCUMENTS,
TESTS AND SOFTWARE THAT LINK THIS STATEMENT ARE PROVIDED "AS IS,"
AND COPYRIGHT HOLDERS MAKE NO REPRESENTATIONS OR WARRANTIES,
EXPRESS OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE,
NON-INFRINGEMENT, OR TITLE;
THAT THE CONTENTS OF THE DOCUMENT ARE SUITABLE FOR ANY PURPOSE;
NOR THAT THE IMPLEMENTATION OF SUCH CONTENTS
WILL NOT INFRINGE ANY THIRD PARTY PATENTS,
COPYRIGHTS, TRADEMARKS OR OTHER RIGHTS.
COPYRIGHT HOLDERS WILL NOT BE LIABLE FOR ANY DIRECT, INDIRECT, SPECIAL
OR CONSEQUENTIAL DAMAGES ARISING OUT OF ANY USE OF THE DOCUMENT
OR THE PERFORMANCE OR IMPLEMENTATION OF THE CONTENTS THEREOF.
