### Viewing Documentation

This package provides several ways to search and view documentation.

`query` and `@query` can be used to search for documented objects in modules
that are **currently** loaded.

`manual` displays external documentation that doesn't belong to any
particular object and is intended to be an overview of the entire
package.

To see examples of their use please consult the
[reference](#module-reference) section below.

### Generating Documentation

Documentation may be exported using the provided `save` function. It
currently supports HTML output which can be hosted on a package's
`gh-pages` branch or any other hosting service.

### Doctests

*Lexicon.jl* includes a `doctest` function that runs code blocks in
docstrings and generates summaries of the results.
