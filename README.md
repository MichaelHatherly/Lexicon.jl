# Lexicon

[![Build Status][travis-img]][travis-url]

## Installation

*Lexicon.jl* is not currently in `METADATA` and requires recent changes
that were made to [*Docile.jl*][docile-url]. To try this package out
now:

```julia
Pkg.clone("https://github.com/MichaelHatherly/Lexicon.jl")
Pkg.checkout("Docile")

using Lexicon
doctest(Lexicon)
```

## About

*Docile.jl* retains the documentation layer (`@doc`, `@docstrings`,
`@tex_mstr`), while *Lexicon.jl* takes over the presentation of
documentation stored by *Docile.jl*.

*Lexicon.jl* separates the non-essential parts from *Docile.jl* so that
package load times are not impacted when documenting packages using
`@doc`. See [this issue][issue-url] for details regarding the change.


[travis-img]: https://travis-ci.org/MichaelHatherly/Lexicon.jl.svg?branch=master
[travis-url]: https://travis-ci.org/MichaelHatherly/Lexicon.jl

[docile-url]: https://github.com/MichaelHatherly/Docile.jl

[issue-url]: https://github.com/MichaelHatherly/Docile.jl/issues/27
