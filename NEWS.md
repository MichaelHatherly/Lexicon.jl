### v0.1.5dev

* Add optional API-Index for markdown output. Contributed by [@peter1000](https://github.com/peter1000).
* Add optional Permalink for markdown output. Contributed by [@peter1000](https://github.com/peter1000).
* Add some additional explanatory code comments / documentation.
* Adjusted some documentation for the new API-Index. (Shorter first line ect.)

### v0.1.4

* Add optional style configuration for markdown output. Contributed by [@peter1000](https://github.com/peter1000).

### v0.1.3

* Use relative paths instead of `Pkg.dir()`.

### v0.1.2

* Fix `beginswith`/`startswith` deprecation warnings.

### v0.1.1

* Add filtering and sorting methods for docstrings. Contributed by [@tshort](https://github.com/tshort).
* Fix compatibility issues with Julia 0.4-dev.

## v0.1.0

* Add markdown output.
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
