# Lexicon

[![Build Status][travis-img]][travis-url]
[![Build status][appveyor-img]][appveyor-url]
[![Coverage Status][coveralls-img]][coveralls-url]
[![Lexicon][pkgeval-img]][pkgeval-url]

*Lexicon.jl* provides access to the documentation created by the `@doc`
macro from [*Docile.jl*][docile-url]. It
allows querying of package documentation from the Julia REPL and
building HTML documentation.

## Installation

*Lexicon.jl* is available from `METADATA` and may be installed via:

```julia
Pkg.add("Lexicon")
```

## About

*Docile.jl* retains the documentation layer (`@doc`, `@docstrings`,
`@tex_mstr`), while *Lexicon.jl* takes over the presentation of
documentation stored by *Docile.jl*.

*Lexicon.jl* separates the non-essential parts from *Docile.jl* so that
package load times are not impacted when documenting packages using
`@doc`. See [this issue][issue-url] for details regarding the change.

## Documentation

Documentation for this package is available for the following versions:

**Stable (0.0.2):**

[`Lexicon`][docs-stable-url]

**Master:**

[`Lexicon`][docs-master-url]

[travis-img]: https://travis-ci.org/MichaelHatherly/Lexicon.jl.svg?branch=master
[travis-url]: https://travis-ci.org/MichaelHatherly/Lexicon.jl

[appveyor-img]: https://ci.appveyor.com/api/projects/status/qmuv67ku625ioiwc/branch/master
[appveyor-url]: https://ci.appveyor.com/project/MichaelHatherly/lexicon-jl/branch/master

[coveralls-img]: https://img.shields.io/coveralls/MichaelHatherly/Lexicon.jl.svg
[coveralls-url]: https://coveralls.io/r/MichaelHatherly/Lexicon.jl

[pkgeval-img]: http://pkg.julialang.org/badges/Lexicon_release.svg
[pkgeval-url]: http://pkg.julialang.org/?pkg=Lexicon&ver=release

[docile-url]: https://github.com/MichaelHatherly/Docile.jl

[issue-url]: https://github.com/MichaelHatherly/Docile.jl/issues/27

[docs-stable-url]: https://michaelhatherly.github.io/Lexicon.jl/stable/index.html
[docs-master-url]: https://michaelhatherly.github.io/Lexicon.jl/master/index.html
