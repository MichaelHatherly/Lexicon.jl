# Lexicon

> **Please Note**
>
> Documentation generation using Docile.jl and Lexicon.jl is being deprecated in Julia
> 0.4 and above in favour of [Documenter.jl](https://github.com/MichaelHatherly/Documenter.jl).

---

Any questions about using this package? Ask them in the Gitter linked below:

[![Join the chat at https://gitter.im/MichaelHatherly/Lexicon.jl](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/MichaelHatherly/Lexicon.jl?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

**Documentation**

[![Stable Documentation][stable-docs-img]][stable-docs-url]
[![Latest Documentation][latest-docs-img]][latest-docs-url]

**Builds**

[![Build Status][travis-img]][travis-url]
[![Build status][appveyor-img]][appveyor-url]

**Package Status**

[![Coverage Status][coveralls-img]][coveralls-url]
[![Docile][pkgeval-img]][pkgeval-url]

## Overview

*Lexicon* is a [Julia](http://www.julialang.org) package documentation generator
and viewer.

It provides access to the documentation created by the `@doc` macro from
[*Docile*][docile-url]. *Lexicon* allows querying of package documentation from
the Julia REPL and building standalone documentation that can be hosted on GitHub
Pages or [Read the Docs](https://readthedocs.org/).

*Lexicon* separates the non-essential parts from *Docile* so that
package load times are not impacted when documenting packages using
`@doc`. See [this issue][issue-url] for details regarding the split.

## Installation

*Lexicon* is available from `METADATA` and may be installed via:

```julia
Pkg.add("Lexicon")
```

## Documentation

Package documentation is available for the [stable][stable-docs-url] and
[development][latest-docs-url] versions.

## Issues and Support

Please file any issues or feature requests you might have through the GitHub
[issue tracker][issue-tracker].

[travis-img]: https://travis-ci.org/MichaelHatherly/Lexicon.jl.svg?branch=master
[travis-url]: https://travis-ci.org/MichaelHatherly/Lexicon.jl

[appveyor-img]: https://ci.appveyor.com/api/projects/status/qmuv67ku625ioiwc/branch/master?svg=true
[appveyor-url]: https://ci.appveyor.com/project/MichaelHatherly/lexicon-jl/branch/master

[coveralls-img]: https://img.shields.io/coveralls/MichaelHatherly/Lexicon.jl.svg
[coveralls-url]: https://coveralls.io/r/MichaelHatherly/Lexicon.jl

[pkgeval-img]: http://pkg.julialang.org/badges/Lexicon_release.svg
[pkgeval-url]: http://pkg.julialang.org/?pkg=Lexicon&ver=release

[docile-url]: https://github.com/MichaelHatherly/Docile.jl

[issue-url]: https://github.com/MichaelHatherly/Docile.jl/issues/27

[issue-tracker]: https://github.com/MichaelHatherly/Lexicon.jl/issues

[latest-docs-img]: https://readthedocs.org/projects/lexiconjl/badge/?version=latest
[stable-docs-img]: https://readthedocs.org/projects/lexiconjl/badge/?version=stable

[latest-docs-url]: http://lexiconjl.readthedocs.org/en/latest/
[stable-docs-url]: http://lexiconjl.readthedocs.org/en/stable/
