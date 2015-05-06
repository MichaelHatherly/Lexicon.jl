### v0.1.9

* Backport Julia `0.4` `Markdown` codebase.

Contributed by [@peter1000](https://github.com/peter1000):

* Add additional output filtering based on category.
* Add optional output grouping by category.
* Add optional API-Index pages for markdown output.
* Add optional permalink for markdown output.
* Add additional output filtering of metadata for markdown and html.

### v0.1.8

* Update for new behaviour of `cp` in Julia 0.4.
* Refactoring of header / footer rendering code.
* Fix for `html` not passing validation issue #65.

### v0.1.7

* Fix for changes in import behaviour.

### v0.1.6

* Fix error in `save`.

### v0.1.5

* Fix for tuple changes in julia.

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
