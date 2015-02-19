### v0.1.2

* Fix `beginswith`/`startswith` deprecation warnings.

### v0.1.1

* Add filtering and sorting methods for docstrings.
* Fix compatibility issues with Julia 0.4-dev.

## v0.1.0

* Add matkdown output.
* New package documentation using MkDocs.
* Rework query system.
    * Search globals without prepending `global` to query.
    * Summary for multiple results.

### v0.0.6

* Use new Docile syntax for `@docstrings` and `@doc` metadata.

### v0.0.5

* Correctly display `:parameter` metadata in HTML output.

### v0.0.4

* Reinstate missing `manual` method.
* Run Lint.jl on package to catch compatibility problems.

### v0.0.3

* Add `query(f::Function, sig)` method with partial signature matching.
* Split rendering code into format-specific files.
* Fix some minor display quirks.
* Add NEWS.md file.
